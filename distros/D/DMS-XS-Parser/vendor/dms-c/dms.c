/* DMS parser — C99 implementation. Direct port of the Rust reference. */
#include "dms.h"

#include <ctype.h>
#include <inttypes.h>
#include <math.h>
#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

/* SPEC §Unicode normalization: utf8proc gives us NFC. */
#include "vendor/utf8proc/utf8proc.h"

/* Per-string NFC. Takes ownership of `s` (frees it), returns a newly
   malloc'd NFC string. NULL on allocation failure. */
static char *nfc_string(char *s) {
    if (!s) return NULL;
    utf8proc_uint8_t *out = utf8proc_NFC((const utf8proc_uint8_t *)s);
    free(s);
    return (char *)out;
}

/* ---------- helpers ---------- */

static char *xstrndup(const char *s, size_t n) {
    char *r = (char *)malloc(n + 1);
    if (!r) return NULL;
    memcpy(r, s, n);
    r[n] = 0;
    return r;
}

static char *xstrdup(const char *s) {
    return xstrndup(s, strlen(s));
}

static void *xrealloc(void *p, size_t n) {
    void *r = realloc(p, n);
    return r;
}

/* growable byte buffer */
typedef struct {
    char *data;
    size_t len;
    size_t cap;
} buf;

static void buf_init(buf *b) {
    b->data = NULL;
    b->len = 0;
    b->cap = 0;
}

static void buf_ensure(buf *b, size_t add) {
    if (b->len + add + 1 > b->cap) {
        size_t nc = b->cap ? b->cap * 2 : 64;
        while (nc < b->len + add + 1) nc *= 2;
        b->data = (char *)xrealloc(b->data, nc);
        b->cap = nc;
    }
}

static void buf_push(buf *b, char c) {
    buf_ensure(b, 1);
    b->data[b->len++] = c;
    b->data[b->len] = 0;
}

static void buf_push_str(buf *b, const char *s, size_t n) {
    buf_ensure(b, n);
    memcpy(b->data + b->len, s, n);
    b->len += n;
    b->data[b->len] = 0;
}

static void buf_clear(buf *b) {
    b->len = 0;
    if (b->data) b->data[0] = 0;
}

/* Decode one UTF-8 codepoint at s; returns codepoint and *len bytes consumed.
   Returns -1 on invalid UTF-8 (caller should treat as ASCII fallback). */
static int utf8_decode(const char *s, size_t maxlen, size_t *len) {
    if (maxlen == 0) { *len = 0; return -1; }
    unsigned char b0 = (unsigned char)s[0];
    if (b0 < 0x80) { *len = 1; return b0; }
    if ((b0 & 0xE0) == 0xC0 && maxlen >= 2) {
        unsigned char b1 = (unsigned char)s[1];
        if ((b1 & 0xC0) != 0x80) { *len = 1; return -1; }
        *len = 2;
        return ((b0 & 0x1F) << 6) | (b1 & 0x3F);
    }
    if ((b0 & 0xF0) == 0xE0 && maxlen >= 3) {
        unsigned char b1 = (unsigned char)s[1], b2 = (unsigned char)s[2];
        if ((b1 & 0xC0) != 0x80 || (b2 & 0xC0) != 0x80) { *len = 1; return -1; }
        *len = 3;
        return ((b0 & 0x0F) << 12) | ((b1 & 0x3F) << 6) | (b2 & 0x3F);
    }
    if ((b0 & 0xF8) == 0xF0 && maxlen >= 4) {
        unsigned char b1 = (unsigned char)s[1], b2 = (unsigned char)s[2], b3 = (unsigned char)s[3];
        if ((b1 & 0xC0) != 0x80 || (b2 & 0xC0) != 0x80 || (b3 & 0xC0) != 0x80) { *len = 1; return -1; }
        *len = 4;
        return ((b0 & 0x07) << 18) | ((b1 & 0x3F) << 12) | ((b2 & 0x3F) << 6) | (b3 & 0x3F);
    }
    *len = 1;
    return -1;
}

static int utf8_encode(unsigned cp, char out[5]) {
    if (cp < 0x80) { out[0] = (char)cp; out[1] = 0; return 1; }
    if (cp < 0x800) {
        out[0] = (char)(0xC0 | (cp >> 6));
        out[1] = (char)(0x80 | (cp & 0x3F));
        out[2] = 0; return 2;
    }
    if (cp < 0x10000) {
        out[0] = (char)(0xE0 | (cp >> 12));
        out[1] = (char)(0x80 | ((cp >> 6) & 0x3F));
        out[2] = (char)(0x80 | (cp & 0x3F));
        out[3] = 0; return 3;
    }
    out[0] = (char)(0xF0 | (cp >> 18));
    out[1] = (char)(0x80 | ((cp >> 12) & 0x3F));
    out[2] = (char)(0x80 | ((cp >> 6) & 0x3F));
    out[3] = (char)(0x80 | (cp & 0x3F));
    out[4] = 0;
    return 4;
}

/* SPEC §"What counts as a bare key": non-ASCII bare-key chars are
   UAX #31 XID_Continue minus Default_Ignorable_Code_Point (UAX #31 §2
   default identifier syntax). Ranges generated from Unicode 15.1 data. */
static const struct { uint32_t start, end; } XID_CONTINUE_RANGES[] = {
    {0x00AA, 0x00AA},
    {0x00B5, 0x00B5},
    {0x00B7, 0x00B7},
    {0x00BA, 0x00BA},
    {0x00C0, 0x00D6},
    {0x00D8, 0x00F6},
    {0x00F8, 0x02C1},
    {0x02C6, 0x02D1},
    {0x02E0, 0x02E4},
    {0x02EC, 0x02EC},
    {0x02EE, 0x02EE},
    {0x0300, 0x034E},
    {0x0350, 0x0374},
    {0x0376, 0x0377},
    {0x037B, 0x037D},
    {0x037F, 0x037F},
    {0x0386, 0x038A},
    {0x038C, 0x038C},
    {0x038E, 0x03A1},
    {0x03A3, 0x03F5},
    {0x03F7, 0x0481},
    {0x0483, 0x0487},
    {0x048A, 0x052F},
    {0x0531, 0x0556},
    {0x0559, 0x0559},
    {0x0560, 0x0588},
    {0x0591, 0x05BD},
    {0x05BF, 0x05BF},
    {0x05C1, 0x05C2},
    {0x05C4, 0x05C5},
    {0x05C7, 0x05C7},
    {0x05D0, 0x05EA},
    {0x05EF, 0x05F2},
    {0x0610, 0x061A},
    {0x0620, 0x0669},
    {0x066E, 0x06D3},
    {0x06D5, 0x06DC},
    {0x06DF, 0x06E8},
    {0x06EA, 0x06FC},
    {0x06FF, 0x06FF},
    {0x0710, 0x074A},
    {0x074D, 0x07B1},
    {0x07C0, 0x07F5},
    {0x07FA, 0x07FA},
    {0x07FD, 0x07FD},
    {0x0800, 0x082D},
    {0x0840, 0x085B},
    {0x0860, 0x086A},
    {0x0870, 0x0887},
    {0x0889, 0x088E},
    {0x0898, 0x08E1},
    {0x08E3, 0x0963},
    {0x0966, 0x096F},
    {0x0971, 0x0983},
    {0x0985, 0x098C},
    {0x098F, 0x0990},
    {0x0993, 0x09A8},
    {0x09AA, 0x09B0},
    {0x09B2, 0x09B2},
    {0x09B6, 0x09B9},
    {0x09BC, 0x09C4},
    {0x09C7, 0x09C8},
    {0x09CB, 0x09CE},
    {0x09D7, 0x09D7},
    {0x09DC, 0x09DD},
    {0x09DF, 0x09E3},
    {0x09E6, 0x09F1},
    {0x09FC, 0x09FC},
    {0x09FE, 0x09FE},
    {0x0A01, 0x0A03},
    {0x0A05, 0x0A0A},
    {0x0A0F, 0x0A10},
    {0x0A13, 0x0A28},
    {0x0A2A, 0x0A30},
    {0x0A32, 0x0A33},
    {0x0A35, 0x0A36},
    {0x0A38, 0x0A39},
    {0x0A3C, 0x0A3C},
    {0x0A3E, 0x0A42},
    {0x0A47, 0x0A48},
    {0x0A4B, 0x0A4D},
    {0x0A51, 0x0A51},
    {0x0A59, 0x0A5C},
    {0x0A5E, 0x0A5E},
    {0x0A66, 0x0A75},
    {0x0A81, 0x0A83},
    {0x0A85, 0x0A8D},
    {0x0A8F, 0x0A91},
    {0x0A93, 0x0AA8},
    {0x0AAA, 0x0AB0},
    {0x0AB2, 0x0AB3},
    {0x0AB5, 0x0AB9},
    {0x0ABC, 0x0AC5},
    {0x0AC7, 0x0AC9},
    {0x0ACB, 0x0ACD},
    {0x0AD0, 0x0AD0},
    {0x0AE0, 0x0AE3},
    {0x0AE6, 0x0AEF},
    {0x0AF9, 0x0AFF},
    {0x0B01, 0x0B03},
    {0x0B05, 0x0B0C},
    {0x0B0F, 0x0B10},
    {0x0B13, 0x0B28},
    {0x0B2A, 0x0B30},
    {0x0B32, 0x0B33},
    {0x0B35, 0x0B39},
    {0x0B3C, 0x0B44},
    {0x0B47, 0x0B48},
    {0x0B4B, 0x0B4D},
    {0x0B55, 0x0B57},
    {0x0B5C, 0x0B5D},
    {0x0B5F, 0x0B63},
    {0x0B66, 0x0B6F},
    {0x0B71, 0x0B71},
    {0x0B82, 0x0B83},
    {0x0B85, 0x0B8A},
    {0x0B8E, 0x0B90},
    {0x0B92, 0x0B95},
    {0x0B99, 0x0B9A},
    {0x0B9C, 0x0B9C},
    {0x0B9E, 0x0B9F},
    {0x0BA3, 0x0BA4},
    {0x0BA8, 0x0BAA},
    {0x0BAE, 0x0BB9},
    {0x0BBE, 0x0BC2},
    {0x0BC6, 0x0BC8},
    {0x0BCA, 0x0BCD},
    {0x0BD0, 0x0BD0},
    {0x0BD7, 0x0BD7},
    {0x0BE6, 0x0BEF},
    {0x0C00, 0x0C0C},
    {0x0C0E, 0x0C10},
    {0x0C12, 0x0C28},
    {0x0C2A, 0x0C39},
    {0x0C3C, 0x0C44},
    {0x0C46, 0x0C48},
    {0x0C4A, 0x0C4D},
    {0x0C55, 0x0C56},
    {0x0C58, 0x0C5A},
    {0x0C5D, 0x0C5D},
    {0x0C60, 0x0C63},
    {0x0C66, 0x0C6F},
    {0x0C80, 0x0C83},
    {0x0C85, 0x0C8C},
    {0x0C8E, 0x0C90},
    {0x0C92, 0x0CA8},
    {0x0CAA, 0x0CB3},
    {0x0CB5, 0x0CB9},
    {0x0CBC, 0x0CC4},
    {0x0CC6, 0x0CC8},
    {0x0CCA, 0x0CCD},
    {0x0CD5, 0x0CD6},
    {0x0CDD, 0x0CDE},
    {0x0CE0, 0x0CE3},
    {0x0CE6, 0x0CEF},
    {0x0CF1, 0x0CF3},
    {0x0D00, 0x0D0C},
    {0x0D0E, 0x0D10},
    {0x0D12, 0x0D44},
    {0x0D46, 0x0D48},
    {0x0D4A, 0x0D4E},
    {0x0D54, 0x0D57},
    {0x0D5F, 0x0D63},
    {0x0D66, 0x0D6F},
    {0x0D7A, 0x0D7F},
    {0x0D81, 0x0D83},
    {0x0D85, 0x0D96},
    {0x0D9A, 0x0DB1},
    {0x0DB3, 0x0DBB},
    {0x0DBD, 0x0DBD},
    {0x0DC0, 0x0DC6},
    {0x0DCA, 0x0DCA},
    {0x0DCF, 0x0DD4},
    {0x0DD6, 0x0DD6},
    {0x0DD8, 0x0DDF},
    {0x0DE6, 0x0DEF},
    {0x0DF2, 0x0DF3},
    {0x0E01, 0x0E3A},
    {0x0E40, 0x0E4E},
    {0x0E50, 0x0E59},
    {0x0E81, 0x0E82},
    {0x0E84, 0x0E84},
    {0x0E86, 0x0E8A},
    {0x0E8C, 0x0EA3},
    {0x0EA5, 0x0EA5},
    {0x0EA7, 0x0EBD},
    {0x0EC0, 0x0EC4},
    {0x0EC6, 0x0EC6},
    {0x0EC8, 0x0ECE},
    {0x0ED0, 0x0ED9},
    {0x0EDC, 0x0EDF},
    {0x0F00, 0x0F00},
    {0x0F18, 0x0F19},
    {0x0F20, 0x0F29},
    {0x0F35, 0x0F35},
    {0x0F37, 0x0F37},
    {0x0F39, 0x0F39},
    {0x0F3E, 0x0F47},
    {0x0F49, 0x0F6C},
    {0x0F71, 0x0F84},
    {0x0F86, 0x0F97},
    {0x0F99, 0x0FBC},
    {0x0FC6, 0x0FC6},
    {0x1000, 0x1049},
    {0x1050, 0x109D},
    {0x10A0, 0x10C5},
    {0x10C7, 0x10C7},
    {0x10CD, 0x10CD},
    {0x10D0, 0x10FA},
    {0x10FC, 0x115E},
    {0x1161, 0x1248},
    {0x124A, 0x124D},
    {0x1250, 0x1256},
    {0x1258, 0x1258},
    {0x125A, 0x125D},
    {0x1260, 0x1288},
    {0x128A, 0x128D},
    {0x1290, 0x12B0},
    {0x12B2, 0x12B5},
    {0x12B8, 0x12BE},
    {0x12C0, 0x12C0},
    {0x12C2, 0x12C5},
    {0x12C8, 0x12D6},
    {0x12D8, 0x1310},
    {0x1312, 0x1315},
    {0x1318, 0x135A},
    {0x135D, 0x135F},
    {0x1369, 0x1371},
    {0x1380, 0x138F},
    {0x13A0, 0x13F5},
    {0x13F8, 0x13FD},
    {0x1401, 0x166C},
    {0x166F, 0x167F},
    {0x1681, 0x169A},
    {0x16A0, 0x16EA},
    {0x16EE, 0x16F8},
    {0x1700, 0x1715},
    {0x171F, 0x1734},
    {0x1740, 0x1753},
    {0x1760, 0x176C},
    {0x176E, 0x1770},
    {0x1772, 0x1773},
    {0x1780, 0x17B3},
    {0x17B6, 0x17D3},
    {0x17D7, 0x17D7},
    {0x17DC, 0x17DD},
    {0x17E0, 0x17E9},
    {0x1810, 0x1819},
    {0x1820, 0x1878},
    {0x1880, 0x18AA},
    {0x18B0, 0x18F5},
    {0x1900, 0x191E},
    {0x1920, 0x192B},
    {0x1930, 0x193B},
    {0x1946, 0x196D},
    {0x1970, 0x1974},
    {0x1980, 0x19AB},
    {0x19B0, 0x19C9},
    {0x19D0, 0x19DA},
    {0x1A00, 0x1A1B},
    {0x1A20, 0x1A5E},
    {0x1A60, 0x1A7C},
    {0x1A7F, 0x1A89},
    {0x1A90, 0x1A99},
    {0x1AA7, 0x1AA7},
    {0x1AB0, 0x1ABD},
    {0x1ABF, 0x1ACE},
    {0x1B00, 0x1B4C},
    {0x1B50, 0x1B59},
    {0x1B6B, 0x1B73},
    {0x1B80, 0x1BF3},
    {0x1C00, 0x1C37},
    {0x1C40, 0x1C49},
    {0x1C4D, 0x1C7D},
    {0x1C80, 0x1C88},
    {0x1C90, 0x1CBA},
    {0x1CBD, 0x1CBF},
    {0x1CD0, 0x1CD2},
    {0x1CD4, 0x1CFA},
    {0x1D00, 0x1F15},
    {0x1F18, 0x1F1D},
    {0x1F20, 0x1F45},
    {0x1F48, 0x1F4D},
    {0x1F50, 0x1F57},
    {0x1F59, 0x1F59},
    {0x1F5B, 0x1F5B},
    {0x1F5D, 0x1F5D},
    {0x1F5F, 0x1F7D},
    {0x1F80, 0x1FB4},
    {0x1FB6, 0x1FBC},
    {0x1FBE, 0x1FBE},
    {0x1FC2, 0x1FC4},
    {0x1FC6, 0x1FCC},
    {0x1FD0, 0x1FD3},
    {0x1FD6, 0x1FDB},
    {0x1FE0, 0x1FEC},
    {0x1FF2, 0x1FF4},
    {0x1FF6, 0x1FFC},
    {0x203F, 0x2040},
    {0x2054, 0x2054},
    {0x2071, 0x2071},
    {0x207F, 0x207F},
    {0x2090, 0x209C},
    {0x20D0, 0x20DC},
    {0x20E1, 0x20E1},
    {0x20E5, 0x20F0},
    {0x2102, 0x2102},
    {0x2107, 0x2107},
    {0x210A, 0x2113},
    {0x2115, 0x2115},
    {0x2118, 0x211D},
    {0x2124, 0x2124},
    {0x2126, 0x2126},
    {0x2128, 0x2128},
    {0x212A, 0x2139},
    {0x213C, 0x213F},
    {0x2145, 0x2149},
    {0x214E, 0x214E},
    {0x2160, 0x2188},
    {0x2C00, 0x2CE4},
    {0x2CEB, 0x2CF3},
    {0x2D00, 0x2D25},
    {0x2D27, 0x2D27},
    {0x2D2D, 0x2D2D},
    {0x2D30, 0x2D67},
    {0x2D6F, 0x2D6F},
    {0x2D7F, 0x2D96},
    {0x2DA0, 0x2DA6},
    {0x2DA8, 0x2DAE},
    {0x2DB0, 0x2DB6},
    {0x2DB8, 0x2DBE},
    {0x2DC0, 0x2DC6},
    {0x2DC8, 0x2DCE},
    {0x2DD0, 0x2DD6},
    {0x2DD8, 0x2DDE},
    {0x2DE0, 0x2DFF},
    {0x3005, 0x3007},
    {0x3021, 0x302F},
    {0x3031, 0x3035},
    {0x3038, 0x303C},
    {0x3041, 0x3096},
    {0x3099, 0x309A},
    {0x309D, 0x309F},
    {0x30A1, 0x30FF},
    {0x3105, 0x312F},
    {0x3131, 0x3163},
    {0x3165, 0x318E},
    {0x31A0, 0x31BF},
    {0x31F0, 0x31FF},
    {0x3400, 0x4DBF},
    {0x4E00, 0xA48C},
    {0xA4D0, 0xA4FD},
    {0xA500, 0xA60C},
    {0xA610, 0xA62B},
    {0xA640, 0xA66F},
    {0xA674, 0xA67D},
    {0xA67F, 0xA6F1},
    {0xA717, 0xA71F},
    {0xA722, 0xA788},
    {0xA78B, 0xA7CA},
    {0xA7D0, 0xA7D1},
    {0xA7D3, 0xA7D3},
    {0xA7D5, 0xA7D9},
    {0xA7F2, 0xA827},
    {0xA82C, 0xA82C},
    {0xA840, 0xA873},
    {0xA880, 0xA8C5},
    {0xA8D0, 0xA8D9},
    {0xA8E0, 0xA8F7},
    {0xA8FB, 0xA8FB},
    {0xA8FD, 0xA92D},
    {0xA930, 0xA953},
    {0xA960, 0xA97C},
    {0xA980, 0xA9C0},
    {0xA9CF, 0xA9D9},
    {0xA9E0, 0xA9FE},
    {0xAA00, 0xAA36},
    {0xAA40, 0xAA4D},
    {0xAA50, 0xAA59},
    {0xAA60, 0xAA76},
    {0xAA7A, 0xAAC2},
    {0xAADB, 0xAADD},
    {0xAAE0, 0xAAEF},
    {0xAAF2, 0xAAF6},
    {0xAB01, 0xAB06},
    {0xAB09, 0xAB0E},
    {0xAB11, 0xAB16},
    {0xAB20, 0xAB26},
    {0xAB28, 0xAB2E},
    {0xAB30, 0xAB5A},
    {0xAB5C, 0xAB69},
    {0xAB70, 0xABEA},
    {0xABEC, 0xABED},
    {0xABF0, 0xABF9},
    {0xAC00, 0xD7A3},
    {0xD7B0, 0xD7C6},
    {0xD7CB, 0xD7FB},
    {0xF900, 0xFA6D},
    {0xFA70, 0xFAD9},
    {0xFB00, 0xFB06},
    {0xFB13, 0xFB17},
    {0xFB1D, 0xFB28},
    {0xFB2A, 0xFB36},
    {0xFB38, 0xFB3C},
    {0xFB3E, 0xFB3E},
    {0xFB40, 0xFB41},
    {0xFB43, 0xFB44},
    {0xFB46, 0xFBB1},
    {0xFBD3, 0xFC5D},
    {0xFC64, 0xFD3D},
    {0xFD50, 0xFD8F},
    {0xFD92, 0xFDC7},
    {0xFDF0, 0xFDF9},
    {0xFE20, 0xFE2F},
    {0xFE33, 0xFE34},
    {0xFE4D, 0xFE4F},
    {0xFE71, 0xFE71},
    {0xFE73, 0xFE73},
    {0xFE77, 0xFE77},
    {0xFE79, 0xFE79},
    {0xFE7B, 0xFE7B},
    {0xFE7D, 0xFE7D},
    {0xFE7F, 0xFEFC},
    {0xFF10, 0xFF19},
    {0xFF21, 0xFF3A},
    {0xFF3F, 0xFF3F},
    {0xFF41, 0xFF5A},
    {0xFF65, 0xFF9F},
    {0xFFA1, 0xFFBE},
    {0xFFC2, 0xFFC7},
    {0xFFCA, 0xFFCF},
    {0xFFD2, 0xFFD7},
    {0xFFDA, 0xFFDC},
    {0x10000, 0x1000B},
    {0x1000D, 0x10026},
    {0x10028, 0x1003A},
    {0x1003C, 0x1003D},
    {0x1003F, 0x1004D},
    {0x10050, 0x1005D},
    {0x10080, 0x100FA},
    {0x10140, 0x10174},
    {0x101FD, 0x101FD},
    {0x10280, 0x1029C},
    {0x102A0, 0x102D0},
    {0x102E0, 0x102E0},
    {0x10300, 0x1031F},
    {0x1032D, 0x1034A},
    {0x10350, 0x1037A},
    {0x10380, 0x1039D},
    {0x103A0, 0x103C3},
    {0x103C8, 0x103CF},
    {0x103D1, 0x103D5},
    {0x10400, 0x1049D},
    {0x104A0, 0x104A9},
    {0x104B0, 0x104D3},
    {0x104D8, 0x104FB},
    {0x10500, 0x10527},
    {0x10530, 0x10563},
    {0x10570, 0x1057A},
    {0x1057C, 0x1058A},
    {0x1058C, 0x10592},
    {0x10594, 0x10595},
    {0x10597, 0x105A1},
    {0x105A3, 0x105B1},
    {0x105B3, 0x105B9},
    {0x105BB, 0x105BC},
    {0x10600, 0x10736},
    {0x10740, 0x10755},
    {0x10760, 0x10767},
    {0x10780, 0x10785},
    {0x10787, 0x107B0},
    {0x107B2, 0x107BA},
    {0x10800, 0x10805},
    {0x10808, 0x10808},
    {0x1080A, 0x10835},
    {0x10837, 0x10838},
    {0x1083C, 0x1083C},
    {0x1083F, 0x10855},
    {0x10860, 0x10876},
    {0x10880, 0x1089E},
    {0x108E0, 0x108F2},
    {0x108F4, 0x108F5},
    {0x10900, 0x10915},
    {0x10920, 0x10939},
    {0x10980, 0x109B7},
    {0x109BE, 0x109BF},
    {0x10A00, 0x10A03},
    {0x10A05, 0x10A06},
    {0x10A0C, 0x10A13},
    {0x10A15, 0x10A17},
    {0x10A19, 0x10A35},
    {0x10A38, 0x10A3A},
    {0x10A3F, 0x10A3F},
    {0x10A60, 0x10A7C},
    {0x10A80, 0x10A9C},
    {0x10AC0, 0x10AC7},
    {0x10AC9, 0x10AE6},
    {0x10B00, 0x10B35},
    {0x10B40, 0x10B55},
    {0x10B60, 0x10B72},
    {0x10B80, 0x10B91},
    {0x10C00, 0x10C48},
    {0x10C80, 0x10CB2},
    {0x10CC0, 0x10CF2},
    {0x10D00, 0x10D27},
    {0x10D30, 0x10D39},
    {0x10E80, 0x10EA9},
    {0x10EAB, 0x10EAC},
    {0x10EB0, 0x10EB1},
    {0x10EFD, 0x10F1C},
    {0x10F27, 0x10F27},
    {0x10F30, 0x10F50},
    {0x10F70, 0x10F85},
    {0x10FB0, 0x10FC4},
    {0x10FE0, 0x10FF6},
    {0x11000, 0x11046},
    {0x11066, 0x11075},
    {0x1107F, 0x110BA},
    {0x110C2, 0x110C2},
    {0x110D0, 0x110E8},
    {0x110F0, 0x110F9},
    {0x11100, 0x11134},
    {0x11136, 0x1113F},
    {0x11144, 0x11147},
    {0x11150, 0x11173},
    {0x11176, 0x11176},
    {0x11180, 0x111C4},
    {0x111C9, 0x111CC},
    {0x111CE, 0x111DA},
    {0x111DC, 0x111DC},
    {0x11200, 0x11211},
    {0x11213, 0x11237},
    {0x1123E, 0x11241},
    {0x11280, 0x11286},
    {0x11288, 0x11288},
    {0x1128A, 0x1128D},
    {0x1128F, 0x1129D},
    {0x1129F, 0x112A8},
    {0x112B0, 0x112EA},
    {0x112F0, 0x112F9},
    {0x11300, 0x11303},
    {0x11305, 0x1130C},
    {0x1130F, 0x11310},
    {0x11313, 0x11328},
    {0x1132A, 0x11330},
    {0x11332, 0x11333},
    {0x11335, 0x11339},
    {0x1133B, 0x11344},
    {0x11347, 0x11348},
    {0x1134B, 0x1134D},
    {0x11350, 0x11350},
    {0x11357, 0x11357},
    {0x1135D, 0x11363},
    {0x11366, 0x1136C},
    {0x11370, 0x11374},
    {0x11400, 0x1144A},
    {0x11450, 0x11459},
    {0x1145E, 0x11461},
    {0x11480, 0x114C5},
    {0x114C7, 0x114C7},
    {0x114D0, 0x114D9},
    {0x11580, 0x115B5},
    {0x115B8, 0x115C0},
    {0x115D8, 0x115DD},
    {0x11600, 0x11640},
    {0x11644, 0x11644},
    {0x11650, 0x11659},
    {0x11680, 0x116B8},
    {0x116C0, 0x116C9},
    {0x11700, 0x1171A},
    {0x1171D, 0x1172B},
    {0x11730, 0x11739},
    {0x11740, 0x11746},
    {0x11800, 0x1183A},
    {0x118A0, 0x118E9},
    {0x118FF, 0x11906},
    {0x11909, 0x11909},
    {0x1190C, 0x11913},
    {0x11915, 0x11916},
    {0x11918, 0x11935},
    {0x11937, 0x11938},
    {0x1193B, 0x11943},
    {0x11950, 0x11959},
    {0x119A0, 0x119A7},
    {0x119AA, 0x119D7},
    {0x119DA, 0x119E1},
    {0x119E3, 0x119E4},
    {0x11A00, 0x11A3E},
    {0x11A47, 0x11A47},
    {0x11A50, 0x11A99},
    {0x11A9D, 0x11A9D},
    {0x11AB0, 0x11AF8},
    {0x11C00, 0x11C08},
    {0x11C0A, 0x11C36},
    {0x11C38, 0x11C40},
    {0x11C50, 0x11C59},
    {0x11C72, 0x11C8F},
    {0x11C92, 0x11CA7},
    {0x11CA9, 0x11CB6},
    {0x11D00, 0x11D06},
    {0x11D08, 0x11D09},
    {0x11D0B, 0x11D36},
    {0x11D3A, 0x11D3A},
    {0x11D3C, 0x11D3D},
    {0x11D3F, 0x11D47},
    {0x11D50, 0x11D59},
    {0x11D60, 0x11D65},
    {0x11D67, 0x11D68},
    {0x11D6A, 0x11D8E},
    {0x11D90, 0x11D91},
    {0x11D93, 0x11D98},
    {0x11DA0, 0x11DA9},
    {0x11EE0, 0x11EF6},
    {0x11F00, 0x11F10},
    {0x11F12, 0x11F3A},
    {0x11F3E, 0x11F42},
    {0x11F50, 0x11F59},
    {0x11FB0, 0x11FB0},
    {0x12000, 0x12399},
    {0x12400, 0x1246E},
    {0x12480, 0x12543},
    {0x12F90, 0x12FF0},
    {0x13000, 0x1342F},
    {0x13440, 0x13455},
    {0x14400, 0x14646},
    {0x16800, 0x16A38},
    {0x16A40, 0x16A5E},
    {0x16A60, 0x16A69},
    {0x16A70, 0x16ABE},
    {0x16AC0, 0x16AC9},
    {0x16AD0, 0x16AED},
    {0x16AF0, 0x16AF4},
    {0x16B00, 0x16B36},
    {0x16B40, 0x16B43},
    {0x16B50, 0x16B59},
    {0x16B63, 0x16B77},
    {0x16B7D, 0x16B8F},
    {0x16E40, 0x16E7F},
    {0x16F00, 0x16F4A},
    {0x16F4F, 0x16F87},
    {0x16F8F, 0x16F9F},
    {0x16FE0, 0x16FE1},
    {0x16FE3, 0x16FE4},
    {0x16FF0, 0x16FF1},
    {0x17000, 0x187F7},
    {0x18800, 0x18CD5},
    {0x18D00, 0x18D08},
    {0x1AFF0, 0x1AFF3},
    {0x1AFF5, 0x1AFFB},
    {0x1AFFD, 0x1AFFE},
    {0x1B000, 0x1B122},
    {0x1B132, 0x1B132},
    {0x1B150, 0x1B152},
    {0x1B155, 0x1B155},
    {0x1B164, 0x1B167},
    {0x1B170, 0x1B2FB},
    {0x1BC00, 0x1BC6A},
    {0x1BC70, 0x1BC7C},
    {0x1BC80, 0x1BC88},
    {0x1BC90, 0x1BC99},
    {0x1BC9D, 0x1BC9E},
    {0x1CF00, 0x1CF2D},
    {0x1CF30, 0x1CF46},
    {0x1D165, 0x1D169},
    {0x1D16D, 0x1D172},
    {0x1D17B, 0x1D182},
    {0x1D185, 0x1D18B},
    {0x1D1AA, 0x1D1AD},
    {0x1D242, 0x1D244},
    {0x1D400, 0x1D454},
    {0x1D456, 0x1D49C},
    {0x1D49E, 0x1D49F},
    {0x1D4A2, 0x1D4A2},
    {0x1D4A5, 0x1D4A6},
    {0x1D4A9, 0x1D4AC},
    {0x1D4AE, 0x1D4B9},
    {0x1D4BB, 0x1D4BB},
    {0x1D4BD, 0x1D4C3},
    {0x1D4C5, 0x1D505},
    {0x1D507, 0x1D50A},
    {0x1D50D, 0x1D514},
    {0x1D516, 0x1D51C},
    {0x1D51E, 0x1D539},
    {0x1D53B, 0x1D53E},
    {0x1D540, 0x1D544},
    {0x1D546, 0x1D546},
    {0x1D54A, 0x1D550},
    {0x1D552, 0x1D6A5},
    {0x1D6A8, 0x1D6C0},
    {0x1D6C2, 0x1D6DA},
    {0x1D6DC, 0x1D6FA},
    {0x1D6FC, 0x1D714},
    {0x1D716, 0x1D734},
    {0x1D736, 0x1D74E},
    {0x1D750, 0x1D76E},
    {0x1D770, 0x1D788},
    {0x1D78A, 0x1D7A8},
    {0x1D7AA, 0x1D7C2},
    {0x1D7C4, 0x1D7CB},
    {0x1D7CE, 0x1D7FF},
    {0x1DA00, 0x1DA36},
    {0x1DA3B, 0x1DA6C},
    {0x1DA75, 0x1DA75},
    {0x1DA84, 0x1DA84},
    {0x1DA9B, 0x1DA9F},
    {0x1DAA1, 0x1DAAF},
    {0x1DF00, 0x1DF1E},
    {0x1DF25, 0x1DF2A},
    {0x1E000, 0x1E006},
    {0x1E008, 0x1E018},
    {0x1E01B, 0x1E021},
    {0x1E023, 0x1E024},
    {0x1E026, 0x1E02A},
    {0x1E030, 0x1E06D},
    {0x1E08F, 0x1E08F},
    {0x1E100, 0x1E12C},
    {0x1E130, 0x1E13D},
    {0x1E140, 0x1E149},
    {0x1E14E, 0x1E14E},
    {0x1E290, 0x1E2AE},
    {0x1E2C0, 0x1E2F9},
    {0x1E4D0, 0x1E4F9},
    {0x1E7E0, 0x1E7E6},
    {0x1E7E8, 0x1E7EB},
    {0x1E7ED, 0x1E7EE},
    {0x1E7F0, 0x1E7FE},
    {0x1E800, 0x1E8C4},
    {0x1E8D0, 0x1E8D6},
    {0x1E900, 0x1E94B},
    {0x1E950, 0x1E959},
    {0x1EE00, 0x1EE03},
    {0x1EE05, 0x1EE1F},
    {0x1EE21, 0x1EE22},
    {0x1EE24, 0x1EE24},
    {0x1EE27, 0x1EE27},
    {0x1EE29, 0x1EE32},
    {0x1EE34, 0x1EE37},
    {0x1EE39, 0x1EE39},
    {0x1EE3B, 0x1EE3B},
    {0x1EE42, 0x1EE42},
    {0x1EE47, 0x1EE47},
    {0x1EE49, 0x1EE49},
    {0x1EE4B, 0x1EE4B},
    {0x1EE4D, 0x1EE4F},
    {0x1EE51, 0x1EE52},
    {0x1EE54, 0x1EE54},
    {0x1EE57, 0x1EE57},
    {0x1EE59, 0x1EE59},
    {0x1EE5B, 0x1EE5B},
    {0x1EE5D, 0x1EE5D},
    {0x1EE5F, 0x1EE5F},
    {0x1EE61, 0x1EE62},
    {0x1EE64, 0x1EE64},
    {0x1EE67, 0x1EE6A},
    {0x1EE6C, 0x1EE72},
    {0x1EE74, 0x1EE77},
    {0x1EE79, 0x1EE7C},
    {0x1EE7E, 0x1EE7E},
    {0x1EE80, 0x1EE89},
    {0x1EE8B, 0x1EE9B},
    {0x1EEA1, 0x1EEA3},
    {0x1EEA5, 0x1EEA9},
    {0x1EEAB, 0x1EEBB},
    {0x1FBF0, 0x1FBF9},
    {0x20000, 0x2A6DF},
    {0x2A700, 0x2B739},
    {0x2B740, 0x2B81D},
    {0x2B820, 0x2CEA1},
    {0x2CEB0, 0x2EBE0},
    {0x2EBF0, 0x2EE5D},
    {0x2F800, 0x2FA1D},
    {0x30000, 0x3134A},
    {0x31350, 0x323AF},
};
static const size_t XID_CONTINUE_COUNT =
    sizeof(XID_CONTINUE_RANGES) / sizeof(XID_CONTINUE_RANGES[0]);

static bool is_xid_continue_cp(int cp) {
    if (cp < 0x80) return false;
    uint32_t u = (uint32_t)cp;
    size_t lo = 0, hi = XID_CONTINUE_COUNT;
    while (lo < hi) {
        size_t mid = lo + (hi - lo) / 2;
        if (u < XID_CONTINUE_RANGES[mid].start) hi = mid;
        else if (u > XID_CONTINUE_RANGES[mid].end) lo = mid + 1;
        else return true;
    }
    return false;
}

/* SPEC §"What counts as a bare key": ASCII alnum, '_', '-', or
   non-ASCII UAX #31 XID_Continue. */
static bool is_bare_key_char_cp(int cp) {
    if (cp == '_' || cp == '-') return true;
    if (cp < 128) return isalnum(cp) != 0;
    return is_xid_continue_cp(cp);
}

/* ASCII-only fast path for bare-key characters. Inlined into the hot
 * parse-key loop so we avoid an indirect utf8_decode call for the
 * common case (keys are ASCII). Returns 1 if c is a valid bare-key
 * character, 0 if it isn't. Callers must have already checked c < 0x80. */
static inline int is_bare_key_char_ascii(unsigned char c) {
    /* 0-9, A-Z, a-z, _, - */
    return (c >= '0' && c <= '9')
        || (c >= 'A' && c <= 'Z')
        || (c >= 'a' && c <= 'z')
        || c == '_' || c == '-';
}

/* ---------- value constructors ---------- */

static dms_value *new_value(dms_type t) {
    dms_value *v = (dms_value *)calloc(1, sizeof(dms_value));
    v->type = t;
    return v;
}

/* FNV-1a over NUL-terminated key. Good enough for string dedup. */
static uint32_t dms_str_hash(const char *s) {
    uint32_t h = 2166136261u;
    for (const unsigned char *p = (const unsigned char *)s; *p; p++) {
        h ^= *p;
        h *= 16777619u;
    }
    return h;
}

/* Build / rebuild the hash-slot index over the current items[] array.
   new_cap must be a power of two. */
static void dms_table_rehash(dms_table *t, size_t new_cap) {
    size_t *slots = (size_t *)calloc(new_cap, sizeof(size_t));
    size_t mask = new_cap - 1;
    for (size_t i = 0; i < t->len; i++) {
        uint32_t h = dms_str_hash(t->items[i].key);
        size_t pos = (size_t)h & mask;
        while (slots[pos] != 0) pos = (pos + 1) & mask;
        slots[pos] = i + 1;   /* 1-based */
    }
    free(t->hash_slots);
    t->hash_slots = slots;
    t->hash_cap = new_cap;
}

bool dms_table_has(const dms_table *t, const char *key) {
    if (t->hash_cap == 0) {
        /* Small-table fast path: no hash index yet; linear scan. */
        for (size_t i = 0; i < t->len; i++) {
            if (strcmp(t->items[i].key, key) == 0) return true;
        }
        return false;
    }
    uint32_t h = dms_str_hash(key);
    size_t mask = t->hash_cap - 1;
    size_t pos = (size_t)h & mask;
    while (t->hash_slots[pos] != 0) {
        size_t idx = t->hash_slots[pos] - 1;
        if (strcmp(t->items[idx].key, key) == 0) return true;
        pos = (pos + 1) & mask;
    }
    return false;
}

static dms_value *table_get(const dms_table *t, const char *key) {
    if (t->hash_cap == 0) {
        for (size_t i = 0; i < t->len; i++) {
            if (strcmp(t->items[i].key, key) == 0) return t->items[i].value;
        }
        return NULL;
    }
    uint32_t h = dms_str_hash(key);
    size_t mask = t->hash_cap - 1;
    size_t pos = (size_t)h & mask;
    while (t->hash_slots[pos] != 0) {
        size_t idx = t->hash_slots[pos] - 1;
        if (strcmp(t->items[idx].key, key) == 0) return t->items[idx].value;
        pos = (pos + 1) & mask;
    }
    return NULL;
}

static void table_set(dms_table *t, const char *key, dms_value *v) {
    if (t->len == t->cap) {
        size_t nc = t->cap ? t->cap * 2 : 8;
        t->items = (dms_kv *)xrealloc(t->items, nc * sizeof(dms_kv));
        t->cap = nc;
    }
    t->items[t->len].key = xstrdup(key);
    t->items[t->len].value = v;
    t->len++;
    /* Hash-index maintenance: switch on once len crosses 16; grow at
       75% load. Small tables stay on the cheap linear path. */
    if (t->hash_cap == 0) {
        if (t->len >= 16) dms_table_rehash(t, 64);
    } else {
        if (t->len * 4 > t->hash_cap * 3) {
            dms_table_rehash(t, t->hash_cap * 2);
        } else {
            uint32_t h = dms_str_hash(t->items[t->len - 1].key);
            size_t mask = t->hash_cap - 1;
            size_t pos = (size_t)h & mask;
            while (t->hash_slots[pos] != 0) pos = (pos + 1) & mask;
            t->hash_slots[pos] = t->len;   /* 1-based */
        }
    }
}

static void list_push(dms_list *l, dms_value *v) {
    if (l->len == l->cap) {
        size_t nc = l->cap ? l->cap * 2 : 8;
        l->items = (dms_value **)xrealloc(l->items, nc * sizeof(dms_value *));
        l->cap = nc;
    }
    l->items[l->len++] = v;
}

void dms_free(dms_value *v) {
    if (!v) return;
    switch (v->type) {
    case DMS_STRING:
    case DMS_OFFSET_DT:
    case DMS_LOCAL_DT:
    case DMS_LOCAL_DATE:
    case DMS_LOCAL_TIME:
        free(v->u.s);
        break;
    case DMS_TABLE:
        for (size_t i = 0; i < v->u.t.len; i++) {
            free(v->u.t.items[i].key);
            dms_free(v->u.t.items[i].value);
        }
        free(v->u.t.items);
        free(v->u.t.hash_slots);
        break;
    case DMS_LIST:
        for (size_t i = 0; i < v->u.l.len; i++) dms_free(v->u.l.items[i]);
        free(v->u.l.items);
        break;
    default: break;
    }
    free(v);
}

/* ---------- comment-attachment state ---------- */

/* A pending comment is one captured from a comment-only line that has
   not yet been attached to a sibling or container. It becomes Leading on
   the next sibling (if no blank-line gap) or Floating otherwise. */
typedef struct {
    char *content;           /* owned */
    dms_comment_kind kind;
} pending_comment;

typedef struct {
    pending_comment *items;
    size_t len, cap;
} pending_vec;

typedef struct {
    dms_breadcrumb_seg *items;
    size_t len, cap;
} path_vec;

typedef struct {
    dms_attached_comment *items;
    size_t len, cap;
} attached_vec;

typedef struct {
    dms_original_form_entry *items;
    size_t len, cap;
} original_vec;

/* ---------- parser ---------- */

typedef struct {
    const char *src;
    size_t len;
    size_t pos;
    int line;
    size_t line_start;
    dms_error err;
    int has_err;
    /* Comment-attachment state. */
    pending_vec pending;
    path_vec path;
    attached_vec comments;
    /* Original-form records (SPEC §encode). Suppressed during key parses
       and heredoc modifier-arg parses (`record_forms == 0`). */
    original_vec original_forms;
    int record_forms;
    /* Lite mode: skip comment-AST + original_forms bookkeeping. Same
       grammar, same errors. SPEC §Parsing modes — full and lite. */
    int lite;
    /* Unordered mode: post-parse, every body table is marked unordered
       and its items[] array is shuffled. Same grammar, same errors.
       SPEC §"Unordered tables". */
    int unordered;
} parser;

/* ---- breadcrumb / pending / attached helpers ---- */

static void path_push_key(path_vec *v, const char *key) {
    if (v->len == v->cap) {
        size_t nc = v->cap ? v->cap * 2 : 4;
        v->items = (dms_breadcrumb_seg *)xrealloc(v->items, nc * sizeof(dms_breadcrumb_seg));
        v->cap = nc;
    }
    v->items[v->len].is_index = 0;
    v->items[v->len].key = xstrdup(key);
    v->items[v->len].idx = 0;
    v->len++;
}

static void path_push_index(path_vec *v, size_t idx) {
    if (v->len == v->cap) {
        size_t nc = v->cap ? v->cap * 2 : 4;
        v->items = (dms_breadcrumb_seg *)xrealloc(v->items, nc * sizeof(dms_breadcrumb_seg));
        v->cap = nc;
    }
    v->items[v->len].is_index = 1;
    v->items[v->len].key = NULL;
    v->items[v->len].idx = idx;
    v->len++;
}

static void path_pop(path_vec *v) {
    if (v->len == 0) return;
    v->len--;
    if (!v->items[v->len].is_index) {
        free(v->items[v->len].key);
        v->items[v->len].key = NULL;
    }
}

/* Deep-copy the current path. Caller owns result + its key strings. */
static dms_breadcrumb_seg *path_clone(const path_vec *v, size_t *out_len) {
    *out_len = v->len;
    if (v->len == 0) return NULL;
    dms_breadcrumb_seg *out = (dms_breadcrumb_seg *)calloc(v->len, sizeof(dms_breadcrumb_seg));
    for (size_t i = 0; i < v->len; i++) {
        out[i].is_index = v->items[i].is_index;
        out[i].idx = v->items[i].idx;
        out[i].key = v->items[i].is_index ? NULL : xstrdup(v->items[i].key);
    }
    return out;
}

static void breadcrumb_seg_free(dms_breadcrumb_seg *seg) {
    if (!seg->is_index) free(seg->key);
}

static void attached_free_one(dms_attached_comment *ac) {
    free(ac->content);
    for (size_t i = 0; i < ac->path_len; i++) breadcrumb_seg_free(&ac->path[i]);
    free(ac->path);
}

static void pending_push(pending_vec *v, char *content, dms_comment_kind k) {
    if (v->len == v->cap) {
        size_t nc = v->cap ? v->cap * 2 : 4;
        v->items = (pending_comment *)xrealloc(v->items, nc * sizeof(pending_comment));
        v->cap = nc;
    }
    v->items[v->len].content = content;
    v->items[v->len].kind = k;
    v->len++;
}

static void attached_push(attached_vec *a, dms_attached_comment ac) {
    if (a->len == a->cap) {
        size_t nc = a->cap ? a->cap * 2 : 4;
        a->items = (dms_attached_comment *)xrealloc(a->items, nc * sizeof(dms_attached_comment));
        a->cap = nc;
    }
    a->items[a->len++] = ac;
}

/* ---------- original_forms helpers ---------- */

static void heredoc_modifier_call_free(dms_heredoc_modifier_call *m) {
    free(m->name);
    for (size_t i = 0; i < m->num_args; i++) dms_free(m->args[i]);
    free(m->args);
}

static void string_form_free(dms_string_form *sf) {
    if (!sf) return;
    free(sf->label);
    for (size_t i = 0; i < sf->num_modifiers; i++) {
        heredoc_modifier_call_free(&sf->modifiers[i]);
    }
    free(sf->modifiers);
    free(sf);
}

static void original_literal_free(dms_original_literal *lit) {
    if (lit->is_string_form) {
        string_form_free(lit->string_form);
        lit->string_form = NULL;
    } else {
        free(lit->integer_lit);
        lit->integer_lit = NULL;
    }
}

static void original_entry_free(dms_original_form_entry *e) {
    for (size_t i = 0; i < e->path_len; i++) breadcrumb_seg_free(&e->path[i]);
    free(e->path);
    original_literal_free(&e->lit);
}

static void original_free(original_vec *v) {
    for (size_t i = 0; i < v->len; i++) original_entry_free(&v->items[i]);
    free(v->items);
    v->items = NULL; v->len = v->cap = 0;
}

static void original_truncate(original_vec *v, size_t n) {
    while (v->len > n) {
        v->len--;
        original_entry_free(&v->items[v->len]);
    }
}

static void original_push(original_vec *v, dms_original_form_entry e) {
    if (v->len == v->cap) {
        size_t nc = v->cap ? v->cap * 2 : 4;
        v->items = (dms_original_form_entry *)xrealloc(v->items, nc * sizeof(dms_original_form_entry));
        v->cap = nc;
    }
    v->items[v->len++] = e;
}

/* Deep-clone a dms_value (forward decl used by heredoc modifier-arg
   record copy). Defined just below. */
static dms_value *dms_value_clone(const dms_value *v);

static dms_value *dms_value_clone(const dms_value *v) {
    if (!v) return NULL;
    dms_value *out = new_value(v->type);
    switch (v->type) {
    case DMS_BOOL:
        out->u.b = v->u.b;
        break;
    case DMS_INTEGER:
        out->u.i = v->u.i;
        break;
    case DMS_FLOAT:
        out->u.f = v->u.f;
        break;
    case DMS_STRING:
    case DMS_OFFSET_DT:
    case DMS_LOCAL_DT:
    case DMS_LOCAL_DATE:
    case DMS_LOCAL_TIME:
        out->u.s = v->u.s ? xstrdup(v->u.s) : NULL;
        break;
    case DMS_TABLE:
        for (size_t i = 0; i < v->u.t.len; i++) {
            table_set(&out->u.t, v->u.t.items[i].key, dms_value_clone(v->u.t.items[i].value));
        }
        break;
    case DMS_LIST:
        for (size_t i = 0; i < v->u.l.len; i++) {
            list_push(&out->u.l, dms_value_clone(v->u.l.items[i]));
        }
        break;
    }
    return out;
}

/* Record an OriginalLiteral at the current path. Consumes ownership of `lit`.
   Also bails in lite mode (SPEC §Parsing modes — full and lite). */
static void record_form_integer(parser *p, char *lit_str /* owned */) {
    if (p->lite || !p->record_forms) { free(lit_str); return; }
    dms_original_form_entry e;
    e.path = path_clone(&p->path, &e.path_len);
    e.lit.is_string_form = 0;
    e.lit.integer_lit = lit_str;
    e.lit.string_form = NULL;
    original_push(&p->original_forms, e);
}

static void record_form_string(parser *p, dms_string_form *sf /* owned */) {
    if (p->lite || !p->record_forms) { string_form_free(sf); return; }
    dms_original_form_entry e;
    e.path = path_clone(&p->path, &e.path_len);
    e.lit.is_string_form = 1;
    e.lit.integer_lit = NULL;
    e.lit.string_form = sf;
    original_push(&p->original_forms, e);
}

/* Parser-level wrappers for the comment-collection helpers: drop on the
   floor in lite mode (frees ownership rather than pushing). */
static void p_pending_push(parser *p, char *content /* owned */, dms_comment_kind k) {
    if (p->lite) { free(content); return; }
    pending_push(&p->pending, content, k);
}
static void p_attached_push(parser *p, dms_attached_comment ac /* takes ownership */) {
    if (p->lite) { attached_free_one(&ac); return; }
    attached_push(&p->comments, ac);
}

static void flush_pending_with_position(parser *p, dms_comment_position pos) {
    if (p->pending.len == 0) return;
    for (size_t i = 0; i < p->pending.len; i++) {
        dms_attached_comment ac;
        ac.content = p->pending.items[i].content;  /* take ownership */
        ac.kind = p->pending.items[i].kind;
        ac.position = pos;
        ac.path = path_clone(&p->path, &ac.path_len);
        attached_push(&p->comments, ac);
    }
    p->pending.len = 0;
}

static void flush_pending_as_floating(parser *p) {
    flush_pending_with_position(p, DMS_COMMENT_FLOATING);
}

static void flush_pending_as_leading_on_current(parser *p) {
    flush_pending_with_position(p, DMS_COMMENT_LEADING);
}

/* Free all pending comments without attaching (used on parse error). */
static void pending_free(pending_vec *v) {
    for (size_t i = 0; i < v->len; i++) free(v->items[i].content);
    free(v->items);
    v->items = NULL; v->len = v->cap = 0;
}

static void path_free(path_vec *v) {
    for (size_t i = 0; i < v->len; i++) breadcrumb_seg_free(&v->items[i]);
    free(v->items);
    v->items = NULL; v->len = v->cap = 0;
}

static void attached_free(attached_vec *a) {
    for (size_t i = 0; i < a->len; i++) attached_free_one(&a->items[i]);
    free(a->items);
    a->items = NULL; a->len = a->cap = 0;
}

/* Truncate to `n` entries, freeing tails. Used when speculative front-matter
   detection has to be undone. */
static void pending_truncate(pending_vec *v, size_t n) {
    while (v->len > n) {
        v->len--;
        free(v->items[v->len].content);
    }
}

static void attached_truncate(attached_vec *a, size_t n) {
    while (a->len > n) {
        a->len--;
        attached_free_one(&a->items[a->len]);
    }
}

static int set_err_at(parser *p, int line, size_t line_start, size_t pos, const char *fmt, ...) {
    p->has_err = 1;
    p->err.line = line;
    p->err.column = (int)(pos - line_start + 1);
    va_list ap;
    va_start(ap, fmt);
    vsnprintf(p->err.message, sizeof(p->err.message), fmt, ap);
    va_end(ap);
    return 0;
}

static int set_err(parser *p, const char *fmt, ...) {
    p->has_err = 1;
    p->err.line = p->line;
    p->err.column = (int)(p->pos - p->line_start + 1);
    va_list ap;
    va_start(ap, fmt);
    vsnprintf(p->err.message, sizeof(p->err.message), fmt, ap);
    va_end(ap);
    return 0;
}

static char peek(parser *p) {
    return p->pos < p->len ? p->src[p->pos] : 0;
}

static char peek_at(parser *p, size_t off) {
    return p->pos + off < p->len ? p->src[p->pos + off] : 0;
}

static const char *rest(parser *p) { return p->src + p->pos; }
static size_t rest_len(parser *p) { return p->len - p->pos; }

static bool starts_with(parser *p, const char *s) {
    size_t n = strlen(s);
    if (p->len - p->pos < n) return false;
    return memcmp(p->src + p->pos, s, n) == 0;
}

static bool eof(parser *p) { return p->pos >= p->len; }

/* SPEC §Lexical: the ten characters `! @ $ % ^ & * | ~ \`` are reserved
   as decorator sigils at line-start. A body line whose first
   non-whitespace character is one of these must produce a parse error.
   Underscore is intentionally NOT in this set. The rule fires only at
   line-start dispatch sites (parse_document / parse_table_block /
   parse_list_block / parse_block_value); sigils inside string literals,
   comments, heredoc bodies, and quoted keys are unaffected because
   those paths never reach this helper. */
static bool is_reserved_line_start_sigil(char c) {
    switch (c) {
        case '!': case '@': case '$': case '%':
        case '^': case '&': case '*': case '|':
        case '~': case '`':
        case '.': case ',': case '>': case '<':
        case '?': case ';': case '=':
            return true;
        default:
            return false;
    }
}

/* Helper: when the parser is positioned at the first non-whitespace
   char of a body line, reject if that char is a reserved sigil.
   Returns 1 (continue) if OK, 0 (and sets err) if the line must be
   rejected. */
static int reject_reserved_line_start_sigil(parser *p) {
    if (p->pos < p->len && is_reserved_line_start_sigil(p->src[p->pos])) {
        return set_err(p,
            "reserved decorator sigil '%c' at line start (SPEC §Lexical: ! @ $ %% ^ & * | ~ ` . , > < ? ; = are reserved at line-start)",
            p->src[p->pos]);
    }
    return 1;
}

static void advance_line(parser *p) {
    p->line++;
    p->line_start = p->pos;
}

static void skip_inline_ws(parser *p) {
    while (p->pos < p->len && (p->src[p->pos] == ' ' || p->src[p->pos] == '\t')) p->pos++;
}

static bool consume_eol(parser *p) {
    if (peek(p) == '\n') { p->pos++; advance_line(p); return true; }
    if (starts_with(p, "\r\n")) { p->pos += 2; advance_line(p); return true; }
    return false;
}

static int skip_c_block_comment(parser *p);
static int skip_hash_block_comment(parser *p);
static char *read_c_block_comment(parser *p);
static char *read_hash_block_comment(parser *p);

static void skip_line_comment_to_eol(parser *p) {
    while (p->pos < p->len) {
        char c = p->src[p->pos];
        if (c == '\n' || c == '\r') break;
        p->pos++;
    }
}

/* Capture line-comment text (no EOL, including the leading delimiter
   characters). Caller owns the returned string. */
static char *read_line_comment_to_eol(parser *p) {
    size_t start = p->pos;
    while (p->pos < p->len) {
        char c = p->src[p->pos];
        if (c == '\n' || c == '\r') break;
        p->pos++;
    }
    return xstrndup(p->src + start, p->pos - start);
}

/* Skip blank lines and capture full-line/block comments into the pending
   queue. A blank line with non-empty pending → flush pending as Floating
   on the current path. Stops at the first non-trivia character at the
   line's first column with indent preserved. */
static int skip_trivia(parser *p) {
    while (1) {
        size_t start = p->pos;
        skip_inline_ws(p);
        char c = peek(p);
        if (c == '\n' || c == '\r') {
            if (c == '\r' && !starts_with(p, "\r\n"))
                return set_err(p, "bare CR is not a valid line terminator");
            /* Blank line: any pending comments are separated from the
               next sibling, so they float on the enclosing container. */
            flush_pending_as_floating(p);
            consume_eol(p);
        } else if (c == '#') {
            if (starts_with(p, "###")) {
                char *raw = read_hash_block_comment(p);
                if (!raw) return 0;
                p_pending_push(p, raw, DMS_COMMENT_BLOCK);
            } else {
                char *raw = read_line_comment_to_eol(p);
                consume_eol(p);
                p_pending_push(p, raw, DMS_COMMENT_LINE);
            }
        } else if (c == '/' && starts_with(p, "//")) {
            char *raw = read_line_comment_to_eol(p);
            consume_eol(p);
            p_pending_push(p, raw, DMS_COMMENT_LINE);
        } else if (c == '/' && starts_with(p, "/*")) {
            char *raw = read_c_block_comment(p);
            if (!raw) return 0;
            p_pending_push(p, raw, DMS_COMMENT_BLOCK);
        } else {
            p->pos = start;
            return 1;
        }
        if (eof(p)) return 1;
    }
}

static int skip_c_block_comment(parser *p) {
    int sl = p->line;
    size_t sls = p->line_start, sp = p->pos;
    p->pos += 2;
    int depth = 1;
    while (depth > 0) {
        if (eof(p)) return set_err_at(p, sl, sls, sp, "unterminated /* block comment");
        char c = peek(p);
        if (c == '/' && starts_with(p, "/*")) { p->pos += 2; depth++; }
        else if (c == '*' && starts_with(p, "*/")) { p->pos += 2; depth--; }
        else if (c == '\n') { p->pos++; advance_line(p); }
        else if (c == '\r' && starts_with(p, "\r\n")) { p->pos += 2; advance_line(p); }
        else { p->pos++; }
    }
    return 1;
}

static int skip_hash_block_comment(parser *p) {
    int sl = p->line;
    size_t sls = p->line_start, sp = p->pos;
    p->pos += 3;
    size_t ls = p->pos;
    while (p->pos < p->len) {
        char c = p->src[p->pos];
        if (!(c == '_' || isalnum((unsigned char)c))) break;
        p->pos++;
    }
    char *label = xstrndup(p->src + ls, p->pos - ls);
    if (label[0] && !(label[0] == '_' || isalpha((unsigned char)label[0]))) {
        free(label);
        return set_err_at(p, sl, sls, sp, "block comment label must start with a letter or underscore");
    }
    const char *terminator = label[0] ? label : "###";
    skip_inline_ws(p);
    if (!(consume_eol(p) || eof(p))) {
        free(label);
        return set_err(p, "block comment opener must be on its own line");
    }
    while (1) {
        if (eof(p)) {
            free(label);
            return set_err_at(p, sl, sls, sp, "unterminated ### block comment");
        }
        size_t lb = p->pos;
        while (p->pos < p->len) {
            char c = p->src[p->pos];
            if (c == '\n' || c == '\r') break;
            p->pos++;
        }
        size_t end = p->pos;
        consume_eol(p);
        /* trim ASCII whitespace from line and compare */
        size_t t_start = lb, t_end = end;
        while (t_start < t_end && (p->src[t_start] == ' ' || p->src[t_start] == '\t')) t_start++;
        while (t_end > t_start && (p->src[t_end-1] == ' ' || p->src[t_end-1] == '\t')) t_end--;
        size_t tlen = t_end - t_start;
        size_t want = strlen(terminator);
        if (tlen == want && memcmp(p->src + t_start, terminator, want) == 0) {
            free(label);
            return 1;
        }
    }
}

/* Capture variant of skip_c_block_comment: returns owned raw text
   including delimiters. NULL on error (sets p->err). */
static char *read_c_block_comment(parser *p) {
    size_t start = p->pos;
    if (!skip_c_block_comment(p)) return NULL;
    return xstrndup(p->src + start, p->pos - start);
}

/* Capture variant of skip_hash_block_comment: returns owned raw text
   including delimiters but NOT the trailing EOL after the terminator
   line (matches the Rust reference). NULL on error. */
static char *read_hash_block_comment(parser *p) {
    int sl = p->line;
    size_t sls = p->line_start, sp = p->pos;
    size_t start = p->pos;
    p->pos += 3;
    size_t ls = p->pos;
    while (p->pos < p->len) {
        char c = p->src[p->pos];
        if (!(c == '_' || isalnum((unsigned char)c))) break;
        p->pos++;
    }
    char *label = xstrndup(p->src + ls, p->pos - ls);
    if (label[0] && !(label[0] == '_' || isalpha((unsigned char)label[0]))) {
        free(label);
        set_err_at(p, sl, sls, sp, "block comment label must start with a letter or underscore");
        return NULL;
    }
    const char *terminator = label[0] ? label : "###";
    skip_inline_ws(p);
    if (!(consume_eol(p) || eof(p))) {
        free(label);
        set_err(p, "block comment opener must be on its own line");
        return NULL;
    }
    while (1) {
        if (eof(p)) {
            free(label);
            set_err_at(p, sl, sls, sp, "unterminated ### block comment");
            return NULL;
        }
        size_t lb = p->pos;
        while (p->pos < p->len) {
            char c = p->src[p->pos];
            if (c == '\n' || c == '\r') break;
            p->pos++;
        }
        size_t end = p->pos;
        size_t line_end_excl_eol = p->pos;
        consume_eol(p);
        size_t t_start = lb, t_end = end;
        while (t_start < t_end && (p->src[t_start] == ' ' || p->src[t_start] == '\t')) t_start++;
        while (t_end > t_start && (p->src[t_end-1] == ' ' || p->src[t_end-1] == '\t')) t_end--;
        size_t tlen = t_end - t_start;
        size_t want = strlen(terminator);
        if (tlen == want && memcmp(p->src + t_start, terminator, want) == 0) {
            free(label);
            /* Capture content excluding the terminator's trailing EOL
               (matches Rust reference). */
            return xstrndup(p->src + start, line_end_excl_eol - start);
        }
    }
}

static bool is_value_terminator(char c) {
    if (c == 0) return true;
    return c == ' ' || c == '\t' || c == '\n' || c == '\r' || c == '#' || c == '/' || c == ',' || c == ']' || c == '}';
}

/* ---------- forward decls ---------- */
static dms_value *parse_document(parser *p);
static dms_value *parse_table_block(parser *p, int indent);
static dms_value *parse_list_block(parser *p, int indent);
static dms_value *parse_block_value(parser *p, int indent);
static dms_value *parse_inline_value_or_heredoc(parser *p);
static dms_value *parse_basic_string(parser *p);
static dms_value *parse_literal_string(parser *p);
static dms_value *parse_number_or_datetime(parser *p);
static dms_value *parse_bool_v(parser *p);
static dms_value *parse_inf_v(parser *p);
static dms_value *parse_nan_v(parser *p);
static dms_value *parse_flow_array(parser *p);
static dms_value *parse_flow_table(parser *p);
static dms_value *parse_heredoc_basic(parser *p);
static dms_value *parse_heredoc_literal(parser *p);
static int parse_kvpair(parser *p, int parent_indent, char **out_key, dms_value **out_val);
static char *parse_key(parser *p);
static char *parse_basic_string_str(parser *p);
static char *parse_literal_string_str(parser *p);
static int consume_after_value(parser *p, int allow_eof);
static int capture_inner_block_comments(parser *p);

/* ---------- entry ---------- */

static dms_table *parse_front_matter_tbl(parser *p);

static void free_table_inplace(dms_table *t) {
    if (!t) return;
    for (size_t i = 0; i < t->len; i++) {
        free(t->items[i].key);
        dms_free(t->items[i].value);
    }
    free(t->items);
    free(t->hash_slots);
    free(t);
}

void dms_document_free(dms_document *d) {
    if (!d) return;
    free_table_inplace(d->meta);
    dms_free(d->body);
    for (size_t i = 0; i < d->num_comments; i++) {
        free(d->comments[i].content);
        for (size_t j = 0; j < d->comments[i].path_len; j++) {
            if (!d->comments[i].path[j].is_index) free(d->comments[i].path[j].key);
        }
        free(d->comments[i].path);
    }
    free(d->comments);
    for (size_t i = 0; i < d->num_original_forms; i++) {
        original_entry_free(&d->original_forms[i]);
    }
    free(d->original_forms);
    free(d);
}

int dms_document_append_comment(dms_document *doc, dms_attached_comment comment) {
    size_t new_len = doc->num_comments + 1;
    dms_attached_comment *grown = (dms_attached_comment *)realloc(
        doc->comments, new_len * sizeof(dms_attached_comment));
    if (!grown) return -1;
    grown[doc->num_comments] = comment;
    doc->comments = grown;
    doc->num_comments = new_len;
    return 0;
}

void dms_document_remove_comment(dms_document *doc, size_t idx) {
    if (idx >= doc->num_comments) return;
    attached_free_one(&doc->comments[idx]);
    if (idx + 1 < doc->num_comments) {
        memmove(&doc->comments[idx], &doc->comments[idx + 1],
                (doc->num_comments - idx - 1) * sizeof(dms_attached_comment));
    }
    doc->num_comments--;
}

int dms_document_append_original_form(dms_document *doc, dms_original_form_entry entry) {
    size_t new_len = doc->num_original_forms + 1;
    dms_original_form_entry *grown = (dms_original_form_entry *)realloc(
        doc->original_forms, new_len * sizeof(dms_original_form_entry));
    if (!grown) return -1;
    grown[doc->num_original_forms] = entry;
    doc->original_forms = grown;
    doc->num_original_forms = new_len;
    return 0;
}

void dms_document_remove_original_form(dms_document *doc, size_t idx) {
    if (idx >= doc->num_original_forms) return;
    original_entry_free(&doc->original_forms[idx]);
    if (idx + 1 < doc->num_original_forms) {
        memmove(&doc->original_forms[idx], &doc->original_forms[idx + 1],
                (doc->num_original_forms - idx - 1) * sizeof(dms_original_form_entry));
    }
    doc->num_original_forms--;
}

static void mark_unordered_walk(dms_value *v);

/* SPEC §"Unordered tables": after parsing in unordered mode we walk
   the tree, set `unordered = true` on every `dms_table`, and shuffle
   its `items[]` array in place. The shuffle uses a fixed splitmix64
   seed derived from the table's address so order is reproducible
   within one process run but bears no relation to insertion order —
   matching the spec contract that callers MUST NOT rely on order in
   unordered mode. After shuffling we drop the open-addressed hash
   index (it's keyed on item indices that just changed); subsequent
   reads fall back to the linear-scan path, and the encoders don't
   need it. */
static uint64_t splitmix64_step(uint64_t *state) {
    uint64_t z = (*state += 0x9E3779B97F4A7C15ULL);
    z = (z ^ (z >> 30)) * 0xBF58476D1CE4E5B9ULL;
    z = (z ^ (z >> 27)) * 0x94D049BB133111EBULL;
    return z ^ (z >> 31);
}

static void shuffle_table_items(dms_table *t) {
    if (t->len < 2) return;
    uint64_t state = (uint64_t)(uintptr_t)t ^ 0xD1B54A32D192ED03ULL;
    /* Fisher-Yates over items[]. */
    for (size_t i = t->len - 1; i > 0; i--) {
        uint64_t r = splitmix64_step(&state);
        size_t j = (size_t)(r % (uint64_t)(i + 1));
        if (j != i) {
            dms_kv tmp = t->items[i];
            t->items[i] = t->items[j];
            t->items[j] = tmp;
        }
    }
    /* The open-addressed hash slots indexed the pre-shuffle layout;
       drop them. dms_table_has / table_get fall back to linear scan
       when hash_cap == 0, which is fine for the read paths we still
       care about (encoder + lite emit walk items[] directly). */
    if (t->hash_slots) {
        free(t->hash_slots);
        t->hash_slots = NULL;
        t->hash_cap = 0;
    }
}

static void mark_unordered_walk(dms_value *v) {
    if (!v) return;
    switch (v->type) {
        case DMS_TABLE:
            v->u.t.unordered = true;
            shuffle_table_items(&v->u.t);
            for (size_t i = 0; i < v->u.t.len; i++) {
                mark_unordered_walk(v->u.t.items[i].value);
            }
            return;
        case DMS_LIST:
            for (size_t i = 0; i < v->u.l.len; i++) {
                mark_unordered_walk(v->u.l.items[i]);
            }
            return;
        default:
            return;
    }
}

static dms_document *parse_document_with_mode(const char *src, size_t srclen, dms_error *err, int lite, int unordered) {
    parser p;
    memset(&p, 0, sizeof p);
    p.src = src;
    p.len = srclen;
    p.line = 1;
    p.record_forms = 1;
    p.lite = lite;
    p.unordered = unordered;
    /* SPEC §"UTF-8 only, NFC-normalized": DMS source is plain UTF-8 with
       no byte-order mark. A leading U+FEFF is not silently consumed —
       reject it explicitly so encoding mistakes surface loudly. (BOMs
       *inside* string/heredoc bodies are fine; this only fires at offset 0.) */
    if (srclen >= 3 && (unsigned char)src[0] == 0xEF && (unsigned char)src[1] == 0xBB && (unsigned char)src[2] == 0xBF) {
        set_err_at(&p, 1, 0, 0,
                   "BOM (U+FEFF) at file start is not allowed; DMS source is plain UTF-8");
        if (err) *err = p.err;
        pending_free(&p.pending);
        path_free(&p.path);
        attached_free(&p.comments);
        original_free(&p.original_forms);
        return NULL;
    }
    /* U+0000 is not allowed anywhere in DMS source (see SPEC §Strings). */
    for (size_t i = 0; i < srclen; i++) {
        if (src[i] == '\0') {
            size_t line = 1, line_start = 0;
            for (size_t j = 0; j < i; j++) {
                if (src[j] == '\n') { line++; line_start = j + 1; }
            }
            set_err_at(&p, line, line_start, line_start + (i - line_start),
                       "U+0000 (NUL) is not allowed in DMS source");
            if (err) *err = p.err;
            pending_free(&p.pending);
            path_free(&p.path);
            attached_free(&p.comments);
            original_free(&p.original_forms);
            return NULL;
        }
    }
    /* SPEC §Unicode normalization: NFC the source before tokenization.
       utf8proc allocates; we free at every exit path.

       Fast path: if the source is pure ASCII (every byte < 0x80), NFC
       is a no-op — the output is byte-identical. utf8proc_map still
       walks every byte and allocates a fresh buffer (~420 µs on a
       25 KB input vs ~9 µs for the ASCII scan). Skip it: borrow `src`
       directly, leave `normalized` NULL, and let the existing
       `free(normalized)` cleanup paths no-op (free(NULL) is a no-op).
       Pure-ASCII is the common case for config / values files. */
    utf8proc_uint8_t *normalized = NULL;
    {
        const char *scan_src = src + p.pos;
        size_t scan_len = srclen - p.pos;
        int all_ascii = 1;
        for (size_t i = 0; i < scan_len; i++) {
            if ((unsigned char)scan_src[i] >= 0x80) { all_ascii = 0; break; }
        }
        if (all_ascii) {
            p.src = scan_src;
            p.len = scan_len;
            p.pos = 0;
            p.line_start = 0;
        } else {
            utf8proc_ssize_t n = utf8proc_map(
                (const utf8proc_uint8_t *)scan_src,
                (utf8proc_ssize_t)scan_len,
                &normalized,
                UTF8PROC_STABLE | UTF8PROC_COMPOSE);
            if (n < 0) {
                set_err_at(&p, 1, 0, 0, "input is not valid UTF-8");
                if (err) *err = p.err;
                pending_free(&p.pending);
                path_free(&p.path);
                attached_free(&p.comments);
                original_free(&p.original_forms);
                return NULL;
            }
            p.src = (const char *)normalized;
            p.len = (size_t)n;
            p.pos = 0;
            p.line_start = 0;
        }
    }
    dms_table *meta = parse_front_matter_tbl(&p);
    if (p.has_err) {
        if (err) *err = p.err;
        free(normalized);
        free_table_inplace(meta);
        pending_free(&p.pending);
        path_free(&p.path);
        attached_free(&p.comments);
        original_free(&p.original_forms);
        return NULL;
    }
    dms_value *body = parse_document(&p);
    if (p.has_err) {
        if (err) *err = p.err;
        free(normalized);
        free_table_inplace(meta);
        if (body) dms_free(body);
        pending_free(&p.pending);
        path_free(&p.path);
        attached_free(&p.comments);
        original_free(&p.original_forms);
        return NULL;
    }
    /* All pending should have been flushed; free defensively in case. */
    pending_free(&p.pending);
    path_free(&p.path);
    free(normalized);
    /* Unordered mode: walk the body and mark every dms_table unordered,
       shuffling its items[] in place. The front-matter table (meta) is
       left ordered. SPEC §"Unordered tables". */
    if (unordered && body) {
        mark_unordered_walk(body);
    }
    dms_document *d = (dms_document *)calloc(1, sizeof(dms_document));
    d->meta = meta;
    d->body = body;
    /* Transfer ownership of comments array to document. */
    d->comments = p.comments.items;
    d->num_comments = p.comments.len;
    /* Transfer ownership of original-form records. */
    d->original_forms = p.original_forms.items;
    d->num_original_forms = p.original_forms.len;
    return d;
}

/* SPEC v0.14 canonical names. */

dms_document *dms_decode_document(const char *src, size_t srclen, dms_error *err) {
    return parse_document_with_mode(src, srclen, err, 0, 0);
}

dms_document *dms_decode_document_lite(const char *src, size_t srclen, dms_error *err) {
    return parse_document_with_mode(src, srclen, err, 1, 0);
}

dms_document *dms_decode_document_unordered(const char *src, size_t srclen, dms_error *err) {
    return parse_document_with_mode(src, srclen, err, 0, 1);
}

dms_document *dms_decode_document_lite_unordered(const char *src, size_t srclen, dms_error *err) {
    return parse_document_with_mode(src, srclen, err, 1, 1);
}

dms_value *dms_decode(const char *src, size_t srclen, dms_error *err) {
    dms_document *d = dms_decode_document(src, srclen, err);
    if (!d) return NULL;
    dms_value *v = d->body;
    free_table_inplace(d->meta);
    for (size_t i = 0; i < d->num_comments; i++) {
        free(d->comments[i].content);
        for (size_t j = 0; j < d->comments[i].path_len; j++) {
            if (!d->comments[i].path[j].is_index) free(d->comments[i].path[j].key);
        }
        free(d->comments[i].path);
    }
    free(d->comments);
    for (size_t i = 0; i < d->num_original_forms; i++) {
        original_entry_free(&d->original_forms[i]);
    }
    free(d->original_forms);
    free(d);
    return v;
}

void dms_table_free(dms_table *t) {
    free_table_inplace(t);
}

/* Fast byte-level pre-scan that bounds the front-matter region without
   touching body bytes. Mirrors the line-by-line shape of
   `skip_trivia` + `parse_front_matter_tbl`'s closer scan, but operates
   on raw (pre-NFC) bytes and only resolves comment delimiters, blank
   lines, and `+++` literals — never tokenizes keys/values.

   Returns:
     1  → `*fm_end_out` is the byte offset (in raw `src`) one past the
          closing `+++`'s EOL. The caller can NUL/NFC-validate just
          `src[0..*fm_end_out]` and feed that slice to
          `parse_front_matter_tbl` — body bytes are skipped entirely.
     0  → "no FM present": leading trivia walks cleanly, but the next
          non-trivia byte is not `+++`. `*fm_end_out` is unset.
    -1  → bail to the slow path. The fast scanner can't bound the FM
          region without doing real validation work — either the input
          starts with a BOM, contains an unterminated/malformed comment
          in leading trivia, or never closes the FM. The slow path
          surfaces the matching diagnostic.

   The closing `+++` is detected by the same trimmed-line test
   `parse_front_matter_tbl` uses (lines 2202-2206), so the bounded
   region byte-matches what the slow path would have consumed. */
static int find_fm_end_fast(const char *src, size_t srclen, size_t *fm_end_out) {
    /* BOM at offset 0 — slow path so the dedicated diagnostic fires. */
    if (srclen >= 3
        && (unsigned char)src[0] == 0xEF
        && (unsigned char)src[1] == 0xBB
        && (unsigned char)src[2] == 0xBF) {
        return -1;
    }
    size_t pos = 0;
    /* ----- leading trivia: blank lines + line/block comments ----- */
    while (pos < srclen) {
        /* skip inline ws */
        size_t ls = pos;
        while (pos < srclen && (src[pos] == ' ' || src[pos] == '\t')) pos++;
        if (pos >= srclen) break;
        char c = src[pos];
        if (c == '\n') {
            pos++;
            continue;
        }
        if (c == '\r') {
            /* bare CR is a parse error per skip_trivia — slow path. */
            if (pos + 1 >= srclen || src[pos + 1] != '\n') return -1;
            pos += 2;
            continue;
        }
        if (c == '#') {
            if (pos + 2 < srclen && src[pos + 1] == '#' && src[pos + 2] == '#') {
                /* ### [LABEL] block comment. Replicate the byte shape
                   of skip_hash_block_comment: read a label, expect EOL,
                   then scan for a line trimmed to the terminator. */
                size_t op = pos;
                pos += 3;
                size_t label_start = pos;
                while (pos < srclen) {
                    char lc = src[pos];
                    if (!(lc == '_' || (lc >= '0' && lc <= '9') ||
                          (lc >= 'a' && lc <= 'z') || (lc >= 'A' && lc <= 'Z'))) break;
                    pos++;
                }
                size_t label_len = pos - label_start;
                /* Empty label OK (matches `###`); first-char rule
                   ("must start with a letter or underscore") is a
                   diagnostic the slow path owns — bail if violated. */
                if (label_len > 0) {
                    char fc = src[label_start];
                    if (!(fc == '_' || (fc >= 'a' && fc <= 'z') || (fc >= 'A' && fc <= 'Z'))) {
                        return -1;
                    }
                }
                /* trailing ws + EOL on opener line */
                while (pos < srclen && (src[pos] == ' ' || src[pos] == '\t')) pos++;
                if (pos < srclen) {
                    if (src[pos] == '\n') pos++;
                    else if (pos + 1 < srclen && src[pos] == '\r' && src[pos + 1] == '\n') pos += 2;
                    else return -1; /* opener-must-be-on-its-own-line diag */
                }
                /* scan for terminator */
                int closed = 0;
                while (pos < srclen) {
                    size_t lb = pos;
                    while (pos < srclen && src[pos] != '\n' && src[pos] != '\r') pos++;
                    size_t le = pos;
                    if (pos < srclen) {
                        if (src[pos] == '\n') pos++;
                        else if (pos + 1 < srclen && src[pos] == '\r' && src[pos + 1] == '\n') pos += 2;
                        else return -1; /* bare CR */
                    }
                    /* trim ws */
                    size_t ts = lb, te = le;
                    while (ts < te && (src[ts] == ' ' || src[ts] == '\t')) ts++;
                    while (te > ts && (src[te - 1] == ' ' || src[te - 1] == '\t')) te--;
                    size_t tl = te - ts;
                    if (label_len == 0) {
                        if (tl == 3 && src[ts] == '#' && src[ts + 1] == '#' && src[ts + 2] == '#') {
                            closed = 1; break;
                        }
                    } else {
                        if (tl == label_len && memcmp(src + ts, src + label_start, label_len) == 0) {
                            closed = 1; break;
                        }
                    }
                }
                if (!closed) return -1; /* unterminated */
                (void)op;
                continue;
            }
            /* `#` line comment — to EOL */
            while (pos < srclen && src[pos] != '\n' && src[pos] != '\r') pos++;
            if (pos < srclen) {
                if (src[pos] == '\n') pos++;
                else if (pos + 1 < srclen && src[pos] == '\r' && src[pos + 1] == '\n') pos += 2;
                else return -1;
            }
            continue;
        }
        if (c == '/' && pos + 1 < srclen && src[pos + 1] == '/') {
            /* `//` line comment */
            while (pos < srclen && src[pos] != '\n' && src[pos] != '\r') pos++;
            if (pos < srclen) {
                if (src[pos] == '\n') pos++;
                else if (pos + 1 < srclen && src[pos] == '\r' && src[pos + 1] == '\n') pos += 2;
                else return -1;
            }
            continue;
        }
        if (c == '/' && pos + 1 < srclen && src[pos + 1] == '*') {
            /* `/* ... *\/` block comment, with nesting. */
            pos += 2;
            int depth = 1;
            while (depth > 0) {
                if (pos >= srclen) return -1;
                if (pos + 1 < srclen && src[pos] == '/' && src[pos + 1] == '*') {
                    pos += 2; depth++;
                } else if (pos + 1 < srclen && src[pos] == '*' && src[pos + 1] == '/') {
                    pos += 2; depth--;
                } else {
                    pos++;
                }
            }
            continue;
        }
        /* non-trivia byte: rewind to line start (we may have consumed
           leading inline ws that turns out to be indentation before a
           non-trivia char — `skip_trivia` rewinds to `start` in that
           case at line 1513). */
        pos = ls;
        break;
    }
    /* ----- opener: expect "+++" ----- */
    if (pos + 3 > srclen || src[pos] != '+' || src[pos + 1] != '+' || src[pos + 2] != '+') {
        /* No FM present. */
        return 0;
    }
    pos += 3;
    /* opener line must end in EOL (with optional trailing ws). Trailing
       junk is a parse error owned by the slow path — bail in that case
       so the right diagnostic surfaces. */
    while (pos < srclen && (src[pos] == ' ' || src[pos] == '\t')) pos++;
    if (pos < srclen) {
        if (src[pos] == '\n') pos++;
        else if (pos + 1 < srclen && src[pos] == '\r' && src[pos + 1] == '\n') pos += 2;
        else return -1; /* trailing junk → "opener must be on its own line" */
    }
    /* ----- inner lines until closing "+++" (trimmed-line test) ----- */
    while (pos < srclen) {
        size_t lb = pos;
        while (pos < srclen && src[pos] != '\n' && src[pos] != '\r') pos++;
        size_t le = pos;
        size_t after_eol = pos;
        if (pos < srclen) {
            if (src[pos] == '\n') after_eol = pos + 1;
            else if (pos + 1 < srclen && src[pos] == '\r' && src[pos + 1] == '\n') after_eol = pos + 2;
            else return -1; /* bare CR */
        }
        /* trim ws */
        size_t ts = lb, te = le;
        while (ts < te && (src[ts] == ' ' || src[ts] == '\t')) ts++;
        while (te > ts && (src[te - 1] == ' ' || src[te - 1] == '\t')) te--;
        if (te - ts == 3 && src[ts] == '+' && src[ts + 1] == '+' && src[ts + 2] == '+') {
            *fm_end_out = after_eol;
            return 1;
        }
        if (after_eol == pos) {
            /* EOF without closer — slow path emits "unterminated FM". */
            return -1;
        }
        pos = after_eol;
    }
    /* Hit EOF without finding closer. */
    return -1;
}

/* SPEC §Front-matter-only decode (tier-0, required).

   Pre-scans raw bytes to bound the FM region (`find_fm_end_fast`),
   then BOM/NUL/NFC-validates only that prefix and feeds it to
   `parse_front_matter_tbl`. Body bytes are never visited — call cost
   scales with FM-region size, not source size. On any pre-scan
   ambiguity (BOM, malformed leading comment, missing closer, etc.)
   we fall through to the slow path which validates the entire source
   and emits the canonical diagnostic.

   `parse_front_matter_tbl`'s contract:
     - returns NULL with `p.has_err == 0` when the document has no
       opening `+++` (no FM present),
     - returns a calloc'd `dms_table *` (possibly with `len == 0`
       for an empty `+++\n+++`) on success,
     - returns NULL with `p.has_err == 1` on any in-FM error.

   We translate that into `(has_front_matter, return value, err)`. */
dms_table *dms_decode_front_matter(const char *src, size_t srclen,
                                   bool *has_front_matter,
                                   dms_error *err) {
    if (has_front_matter) *has_front_matter = false;
    parser p;
    memset(&p, 0, sizeof p);
    p.src = src;
    p.len = srclen;
    p.line = 1;
    p.record_forms = 1;
    /* SPEC §Front-matter-only decode: this entry point runs in lite
       mode (no comment AST, no original_forms inside the FM). */
    p.lite = 1;
    p.unordered = 0;
    /* Fast pre-scan: bound the FM region so the BOM/NUL/NFC pass below
       only touches FM bytes. NFC of a stable-boundary prefix equals
       the prefix of NFC(full) (the closing `+++` is ASCII and therefore
       a stable boundary), so byte offsets and line numbers inside the
       FM region are identical to the full-source path — diagnostics
       remain byte-identical per SPEC. */
    size_t scan_len = srclen;
    {
        size_t fm_end = 0;
        int rc = find_fm_end_fast(src, srclen, &fm_end);
        if (rc == 0) {
            /* No FM present — fast bail without touching body bytes. */
            if (has_front_matter) *has_front_matter = false;
            return NULL;
        } else if (rc == 1) {
            /* Restrict validation/parse to the FM region. */
            scan_len = fm_end;
        }
        /* rc == -1: fall through to the slow full-source path. */
    }
    /* SPEC §"UTF-8 only, NFC-normalized": reject a leading BOM so
       encoding mistakes surface loudly. */
    if (scan_len >= 3
        && (unsigned char)src[0] == 0xEF
        && (unsigned char)src[1] == 0xBB
        && (unsigned char)src[2] == 0xBF) {
        set_err_at(&p, 1, 0, 0,
                   "BOM (U+FEFF) at file start is not allowed; DMS source is plain UTF-8");
        if (err) *err = p.err;
        pending_free(&p.pending);
        path_free(&p.path);
        attached_free(&p.comments);
        original_free(&p.original_forms);
        return NULL;
    }
    /* U+0000 is not allowed anywhere in DMS source. We scan the FM
       region only — body NULs are not surfaced by this entry point
       per SPEC (body bytes aren't tokenized here). */
    for (size_t i = 0; i < scan_len; i++) {
        if (src[i] == '\0') {
            size_t line = 1, line_start = 0;
            for (size_t j = 0; j < i; j++) {
                if (src[j] == '\n') { line++; line_start = j + 1; }
            }
            set_err_at(&p, line, line_start, line_start + (i - line_start),
                       "U+0000 (NUL) is not allowed in DMS source");
            if (err) *err = p.err;
            pending_free(&p.pending);
            path_free(&p.path);
            attached_free(&p.comments);
            original_free(&p.original_forms);
            return NULL;
        }
    }
    /* NFC-normalize the FM region. ASCII fast path matches the body
       decoder so the in-FM byte offsets reported in error messages
       are identical. */
    utf8proc_uint8_t *normalized = NULL;
    {
        const char *scan_src = src + p.pos;
        size_t inner_len = scan_len - p.pos;
        int all_ascii = 1;
        for (size_t i = 0; i < inner_len; i++) {
            if ((unsigned char)scan_src[i] >= 0x80) { all_ascii = 0; break; }
        }
        if (all_ascii) {
            p.src = scan_src;
            p.len = inner_len;
            p.pos = 0;
            p.line_start = 0;
        } else {
            utf8proc_ssize_t n = utf8proc_map(
                (const utf8proc_uint8_t *)scan_src,
                (utf8proc_ssize_t)inner_len,
                &normalized,
                UTF8PROC_STABLE | UTF8PROC_COMPOSE);
            if (n < 0) {
                set_err_at(&p, 1, 0, 0, "input is not valid UTF-8");
                if (err) *err = p.err;
                pending_free(&p.pending);
                path_free(&p.path);
                attached_free(&p.comments);
                original_free(&p.original_forms);
                return NULL;
            }
            p.src = (const char *)normalized;
            p.len = (size_t)n;
            p.pos = 0;
            p.line_start = 0;
        }
    }
    dms_table *meta = parse_front_matter_tbl(&p);
    bool got_err = p.has_err;
    /* parse_front_matter_tbl signals "no FM present" by returning NULL
       and rewinding — without setting has_err. Anything else where the
       return is non-NULL means an FM block was actually parsed. */
    bool fm_present = (meta != NULL) || got_err;
    if (got_err) {
        if (err) *err = p.err;
        free(normalized);
        free_table_inplace(meta);
        pending_free(&p.pending);
        path_free(&p.path);
        attached_free(&p.comments);
        original_free(&p.original_forms);
        return NULL;
    }
    /* No error at this point. Free the parser's accumulated scratch —
       lite mode still pushes the occasional thing into pending /
       comments / originals during trivia-skip; drop it all. */
    free(normalized);
    pending_free(&p.pending);
    path_free(&p.path);
    attached_free(&p.comments);
    original_free(&p.original_forms);
    if (has_front_matter) *has_front_matter = fm_present;
    return meta;
}

/* ---------- deprecated thin aliases (pre-v0.14 names) ----------
   Header marks these DMS_DEPRECATED so call sites get a warning, but
   the definitions themselves should not. Suppress just for this
   block on GCC/Clang; MSVC silently allows defining a deprecated
   function. */
#if defined(__GNUC__) || defined(__clang__)
#  pragma GCC diagnostic push
#  pragma GCC diagnostic ignored "-Wdeprecated-declarations"
#endif

dms_document *dms_parse_document(const char *src, size_t srclen, dms_error *err) {
    return dms_decode_document(src, srclen, err);
}

dms_document *dms_parse_document_lite(const char *src, size_t srclen, dms_error *err) {
    return dms_decode_document_lite(src, srclen, err);
}

dms_document *dms_parse_document_unordered(const char *src, size_t srclen, dms_error *err) {
    return dms_decode_document_unordered(src, srclen, err);
}

dms_document *dms_parse_document_lite_unordered(const char *src, size_t srclen, dms_error *err) {
    return dms_decode_document_lite_unordered(src, srclen, err);
}

dms_value *dms_parse(const char *src, size_t srclen, dms_error *err) {
    return dms_decode(src, srclen, err);
}

#if defined(__GNUC__) || defined(__clang__)
#  pragma GCC diagnostic pop
#endif

/* ---------- front matter ---------- */

static bool peek_after_plus_is_space_or_eol(parser *p);
static bool line_starts_kvpair(parser *p);

static dms_table *parse_front_matter_tbl(parser *p) {
    size_t save_pos = p->pos;
    int save_line = p->line;
    size_t save_ls = p->line_start;
    /* Speculative skip_trivia may capture comments into pending; if we
       end up rewinding (no front matter present), undo so the body
       parser re-captures them with the correct path. */
    size_t save_pending = p->pending.len;
    size_t save_comments = p->comments.len;
    size_t save_originals = p->original_forms.len;
    if (!skip_trivia(p)) return NULL;
    if (!starts_with(p, "+++")) {
        p->pos = save_pos; p->line = save_line; p->line_start = save_ls;
        pending_truncate(&p->pending, save_pending);
        attached_truncate(&p->comments, save_comments);
        original_truncate(&p->original_forms, save_originals);
        return NULL;
    }
    /* Any trailing content on the opener line is a parse error
       (SPEC §Front matter: "each `+++` must appear on its own line,
       with no trailing content"). Advance past `+++` and let the
       strict EOL check below diagnose. */
    int ol = p->line;
    size_t ols = p->line_start, op = p->pos;
    p->pos += 3;
    skip_inline_ws(p);
    if (!(consume_eol(p) || eof(p))) {
        set_err(p, "front matter opener must be on its own line");
        return NULL;
    }
    /* accumulate inner source */
    buf inner; buf_init(&inner);
    while (1) {
        if (eof(p)) {
            set_err_at(p, ol, ols, op, "unterminated front matter: missing closing '+++'");
            free(inner.data);
            return NULL;
        }
        size_t lb = p->pos;
        while (p->pos < p->len) {
            char c = p->src[p->pos];
            if (c == '\n' || c == '\r') break;
            p->pos++;
        }
        size_t end = p->pos;
        /* check if trimmed line == "+++" */
        size_t ts = lb, te = end;
        while (ts < te && (p->src[ts] == ' ' || p->src[ts] == '\t')) ts++;
        while (te > ts && (p->src[te-1] == ' ' || p->src[te-1] == '\t')) te--;
        if (te - ts == 3 && memcmp(p->src + ts, "+++", 3) == 0) {
            consume_eol(p);
            break;
        }
        buf_push_str(&inner, p->src + lb, end - lb);
        if (consume_eol(p)) buf_push(&inner, '\n');
    }
    /* Sub-parse the inner content as a table. Sub-parser has its own
       comment-attachment state; we hoist its captured comments after.
       Inherit the outer parser's lite flag — front matter shouldn't
       preserve metadata if the outer doesn't. */
    parser sp;
    memset(&sp, 0, sizeof sp);
    sp.src = inner.data ? inner.data : "";
    sp.len = inner.len;
    sp.record_forms = 1;
    sp.line = 1;
    sp.lite = p->lite;
    if (!skip_trivia(&sp)) {
        p->has_err = 1; p->err = sp.err;
        pending_free(&sp.pending);
        path_free(&sp.path);
        attached_free(&sp.comments);
        original_free(&sp.original_forms);
        free(inner.data);
        return NULL;
    }
    dms_value *tbl_val = NULL;
    if (eof(&sp)) {
        /* FM body is empty or comments-only — flush pending as floating
           on the (empty) FM root so they survive the hoist. */
        flush_pending_as_floating(&sp);
    } else {
        char c = peek(&sp);
        if (c == ' ' || c == '\t') {
            set_err_at(p, ol, ols, op, "unexpected indentation inside front matter");
            pending_free(&sp.pending); path_free(&sp.path); attached_free(&sp.comments); original_free(&sp.original_forms);
            free(inner.data); return NULL;
        }
        if (c == '+' && peek_after_plus_is_space_or_eol(&sp)) {
            set_err_at(p, ol, ols, op, "front matter block cannot have a list root");
            pending_free(&sp.pending); path_free(&sp.path); attached_free(&sp.comments); original_free(&sp.original_forms);
            free(inner.data); return NULL;
        }
        if (!line_starts_kvpair(&sp)) {
            set_err_at(p, ol, ols, op, "front matter block must be a table");
            pending_free(&sp.pending); path_free(&sp.path); attached_free(&sp.comments); original_free(&sp.original_forms);
            free(inner.data); return NULL;
        }
        dms_value *out_t = parse_table_block(&sp, 0);
        if (!out_t) {
            if (sp.has_err) { p->has_err = 1; p->err = sp.err; }
            pending_free(&sp.pending); path_free(&sp.path); attached_free(&sp.comments); original_free(&sp.original_forms);
            free(inner.data);
            return NULL;
        }
        tbl_val = out_t;
        if (!skip_trivia(&sp)) {
            dms_free(tbl_val);
            pending_free(&sp.pending); path_free(&sp.path); attached_free(&sp.comments); original_free(&sp.original_forms);
            free(inner.data);
            p->has_err = 1; p->err = sp.err;
            return NULL;
        }
        if (!eof(&sp)) {
            set_err_at(p, ol, ols, op, "trailing content inside front matter");
            dms_free(tbl_val);
            pending_free(&sp.pending); path_free(&sp.path); attached_free(&sp.comments); original_free(&sp.original_forms);
            free(inner.data);
            return NULL;
        }
    }
    free(inner.data);
    /* Hoist sub-parser comments into outer parser, prefixing each path
       with Key("__fm__"). Drop comments attached to reserved (`_dms_*`)
       kvpairs, since those nodes are consumed and don't appear in the
       final document. */
    for (size_t ci = 0; ci < sp.comments.len; ci++) {
        dms_attached_comment *src_ac = &sp.comments.items[ci];
        bool attached_to_reserved =
            src_ac->path_len > 0
            && !src_ac->path[0].is_index
            && src_ac->path[0].key
            && src_ac->path[0].key[0] == '_';
        dms_attached_comment dst;
        dst.content = src_ac->content;
        dst.kind = src_ac->kind;
        if (attached_to_reserved) {
            /* Reserved key was consumed — re-attach the comment as
               floating on the FM table so it survives. */
            dst.position = DMS_COMMENT_FLOATING;
            dst.path_len = 1;
            dst.path = (dms_breadcrumb_seg *)calloc(1, sizeof(dms_breadcrumb_seg));
            dst.path[0].is_index = 0;
            dst.path[0].key = xstrdup("__fm__");
            dst.path[0].idx = 0;
            /* Free src_ac path (we don't reuse its segments). */
            for (size_t j = 0; j < src_ac->path_len; j++) {
                if (!src_ac->path[j].is_index) free(src_ac->path[j].key);
            }
            free(src_ac->path);
            src_ac->path = NULL;
            src_ac->path_len = 0;
            src_ac->content = NULL;
            attached_push(&p->comments, dst);
            continue;
        }
        dst.position = src_ac->position;
        dst.path_len = src_ac->path_len + 1;
        dst.path = (dms_breadcrumb_seg *)calloc(dst.path_len, sizeof(dms_breadcrumb_seg));
        dst.path[0].is_index = 0;
        dst.path[0].key = xstrdup("__fm__");
        dst.path[0].idx = 0;
        for (size_t j = 0; j < src_ac->path_len; j++) {
            dst.path[j + 1].is_index = src_ac->path[j].is_index;
            dst.path[j + 1].idx = src_ac->path[j].idx;
            dst.path[j + 1].key = src_ac->path[j].is_index ? NULL : src_ac->path[j].key;
            /* steal the key — null out so attached_free below doesn't free it */
            if (!src_ac->path[j].is_index) src_ac->path[j].key = NULL;
        }
        /* Free remnants of src_ac path (idx-only entries / nulled-out keys). */
        free(src_ac->path);
        src_ac->path = NULL;
        src_ac->path_len = 0;
        /* content stolen; clear pointer so attached_free won't double-free. */
        src_ac->content = NULL;
        attached_push(&p->comments, dst);
    }
    /* Free sub-parser scratch state — comments items have been emptied. */
    free(sp.comments.items);
    pending_free(&sp.pending);
    path_free(&sp.path);
    /* Hoist sub-parser original_forms entries, prefixing each path with
       Key("__fm__"). Drop entries whose first path segment starts with
       `_` (reserved-key kvpairs are consumed and don't appear in the
       final document). */
    for (size_t oi = 0; oi < sp.original_forms.len; oi++) {
        dms_original_form_entry *src_e = &sp.original_forms.items[oi];
        if (src_e->path_len > 0
            && !src_e->path[0].is_index
            && src_e->path[0].key
            && src_e->path[0].key[0] == '_') {
            original_entry_free(src_e);
            continue;
        }
        dms_original_form_entry dst;
        dst.path_len = src_e->path_len + 1;
        dst.path = (dms_breadcrumb_seg *)calloc(dst.path_len, sizeof(dms_breadcrumb_seg));
        dst.path[0].is_index = 0;
        dst.path[0].key = xstrdup("__fm__");
        dst.path[0].idx = 0;
        for (size_t j = 0; j < src_e->path_len; j++) {
            dst.path[j + 1].is_index = src_e->path[j].is_index;
            dst.path[j + 1].idx = src_e->path[j].idx;
            dst.path[j + 1].key = src_e->path[j].is_index ? NULL : src_e->path[j].key;
            if (!src_e->path[j].is_index) src_e->path[j].key = NULL;
        }
        /* steal the lit */
        dst.lit = src_e->lit;
        src_e->lit.integer_lit = NULL;
        src_e->lit.string_form = NULL;
        free(src_e->path);
        src_e->path = NULL;
        src_e->path_len = 0;
        original_push(&p->original_forms, dst);
    }
    free(sp.original_forms.items);
    /* process reserved keys */
    dms_table *meta = (dms_table *)calloc(1, sizeof(dms_table));
    bool err_flag = false;

    if (tbl_val) {
        for (size_t idx = 0; idx < tbl_val->u.t.len; idx++) {
            const char *k = tbl_val->u.t.items[idx].key;
            dms_value *v = tbl_val->u.t.items[idx].value;
            if (k[0] == '_') {
                if (strcmp(k, "_dms_tier") == 0) {
                    if (v->type != DMS_INTEGER) {
                        set_err_at(p, ol, ols, op, "%s", "_dms_tier must be a non-negative integer");
                        err_flag = true; break;
                    }
                    if (v->u.i < 0) {
                        set_err_at(p, ol, ols, op, "%s", "_dms_tier must be non-negative");
                        err_flag = true; break;
                    }
                    if (v->u.i >= 1) {
                        char msg[192];
                        snprintf(msg, sizeof msg,
                            "_dms_tier: %lld is not supported (no tier >= 1 is defined in this version of DMS)",
                            (long long)v->u.i);
                        set_err_at(p, ol, ols, op, "%s", msg);
                        err_flag = true; break;
                    }
                    /* _dms_tier: 0 — accept and discard. */
                } else {
                    char msg[128];
                    snprintf(msg, sizeof msg, "unknown reserved key: %s", k);
                    set_err_at(p, ol, ols, op, "%s", msg);
                    err_flag = true; break;
                }
            } else {
                /* transfer to meta */
                if (meta->len == meta->cap) {
                    size_t nc = meta->cap ? meta->cap * 2 : 8;
                    meta->items = (dms_kv *)xrealloc(meta->items, nc * sizeof(dms_kv));
                    meta->cap = nc;
                }
                meta->items[meta->len].key = xstrdup(k);
                meta->items[meta->len].value = v;
                /* null out so tbl free doesn't double-free */
                tbl_val->u.t.items[idx].value = NULL;
                meta->len++;
            }
        }
    }
    if (err_flag) {
        if (tbl_val) dms_free(tbl_val);
        free_table_inplace(meta);
        return NULL;
    }
    if (tbl_val) dms_free(tbl_val);
    return meta;
}

/* ---------- line_starts_kvpair / peek_after_plus ---------- */

static bool peek_after_plus_is_space_or_eol(parser *p) {
    char c = peek_at(p, 1);
    return c == 0 || c == ' ' || c == '\t' || c == '\n' || c == '\r';
}

static bool line_starts_kvpair(parser *p) {
    size_t pp = p->pos;
    if (pp < p->len && p->src[pp] == '"') {
        pp++;
        while (pp < p->len) {
            char c = p->src[pp];
            if (c == '\\') pp += 2;
            else if (c == '"') { pp++; break; }
            else if (c == '\n' || c == '\r') return false;
            else pp++;
        }
    } else if (pp < p->len && p->src[pp] == '\'') {
        pp++;
        while (pp < p->len) {
            char c = p->src[pp];
            if (c == '\'') { pp++; break; }
            else if (c == '\n' || c == '\r') return false;
            else pp++;
        }
    } else {
        bool any = false;
        while (pp < p->len) {
            size_t clen;
            int cp = utf8_decode(p->src + pp, p->len - pp, &clen);
            if (cp < 0 || !is_bare_key_char_cp(cp)) break;
            pp += clen;
            any = true;
        }
        if (!any) return false;
    }
    if (pp >= p->len || p->src[pp] != ':') return false;
    if (pp + 1 >= p->len) return true;
    char c = p->src[pp + 1];
    return c == ' ' || c == '\t' || c == '\n' || c == '\r';
}

/* ---------- parse_document ---------- */

static dms_value *parse_document(parser *p) {
    if (!skip_trivia(p)) return NULL;
    if (eof(p)) {
        /* Empty / comment-only body: pending comments float on root. */
        flush_pending_as_floating(p);
        return new_value(DMS_TABLE);
    }
    char c = peek(p);
    if (c == ' ' || c == '\t') { set_err(p, "unexpected indentation at document root"); return NULL; }
    if (!reject_reserved_line_start_sigil(p)) return NULL;
    dms_value *result = NULL;
    if (c == '+' && peek_after_plus_is_space_or_eol(p)) {
        result = parse_list_block(p, 0);
        if (!result) return NULL;
        if (!skip_trivia(p)) { dms_free(result); return NULL; }
        if (!eof(p)) { set_err(p, "trailing content after list root"); dms_free(result); return NULL; }
    } else if (line_starts_kvpair(p)) {
        result = parse_table_block(p, 0);
        if (!result) return NULL;
        if (!skip_trivia(p)) { dms_free(result); return NULL; }
        if (!eof(p)) { set_err(p, "trailing content after table root"); dms_free(result); return NULL; }
    } else {
        result = parse_inline_value_or_heredoc(p);
        if (!result) return NULL;
        if (!consume_after_value(p, 1)) { dms_free(result); return NULL; }
        if (!skip_trivia(p)) { dms_free(result); return NULL; }
        if (!eof(p)) { set_err(p, "scalar root cannot be followed by more content"); dms_free(result); return NULL; }
    }
    /* Any post-body trivia comments float on root. */
    flush_pending_as_floating(p);
    return result;
}

/* ---------- block parsers ---------- */

static int measure_line_indent(parser *p) {
    int n = 0;
    size_t i = p->line_start;
    while (i < p->len && p->src[i] == ' ') { n++; i++; }
    return n;
}

static dms_value *parse_table_block(parser *p, int indent) {
    dms_value *out = new_value(DMS_TABLE);
    while (1) {
        if (!skip_trivia(p)) { dms_free(out); return NULL; }
        if (eof(p)) break;
        int li = measure_line_indent(p);
        if (li < indent) break;
        if (li != indent) {
            set_err_at(p, p->line, p->line_start, p->line_start + indent,
                "inconsistent indent: expected %d spaces, got %d", indent, li);
            dms_free(out);
            return NULL;
        }
        p->pos = p->line_start + indent;
        if (!reject_reserved_line_start_sigil(p)) { dms_free(out); return NULL; }
        char *k; dms_value *v;
        if (!parse_kvpair(p, indent, &k, &v)) { dms_free(out); return NULL; }
        if (dms_table_has(&out->u.t, k)) {
            set_err(p, "duplicate key: %s", k);
            free(k); dms_free(v); dms_free(out);
            return NULL;
        }
        table_set(&out->u.t, k, v);
        free(k);
    }
    /* Block close: leftover pending become floating on the enclosing
       container (this table). */
    flush_pending_as_floating(p);
    return out;
}

static dms_value *parse_list_item_value(parser *p, int list_indent);

static dms_value *parse_list_block(parser *p, int indent) {
    dms_value *out = new_value(DMS_LIST);
    while (1) {
        if (!skip_trivia(p)) { dms_free(out); return NULL; }
        if (eof(p)) break;
        int li = measure_line_indent(p);
        if (li < indent) break;
        if (li != indent) {
            set_err_at(p, p->line, p->line_start, p->line_start + indent,
                "inconsistent indent: expected %d spaces, got %d", indent, li);
            dms_free(out);
            return NULL;
        }
        p->pos = p->line_start + indent;
        if (!reject_reserved_line_start_sigil(p)) { dms_free(out); return NULL; }
        if (peek(p) != '+') break;
        /* Committed to a new list item: push its index, attach pending
           leading comments to it, then parse. */
        size_t idx = out->u.l.len;
        path_push_index(&p->path, idx);
        flush_pending_as_leading_on_current(p);
        p->pos++;
        char c = peek(p);
        dms_value *item = NULL;
        bool item_err = false;
        if (c == ' ' || c == '\t') {
            p->pos++;
            skip_inline_ws(p);
            if (!capture_inner_block_comments(p)) { item_err = true; }
            else {
                char c2 = peek(p);
                if (c2 == '\n' || c2 == '\r' || c2 == 0) {
                    /* "+ INNER[EOL]" — empty item with inner comments. */
                    consume_eol(p);
                    if (!skip_trivia(p)) { item_err = true; }
                    else if (eof(p)) { set_err(p, "expected indented block after empty '+' marker"); item_err = true; }
                    else {
                        int inner_i = measure_line_indent(p);
                        if (inner_i <= indent) { set_err(p, "expected indented block after empty '+' marker"); item_err = true; }
                        else {
                            item = parse_block_value(p, inner_i);
                            if (!item) item_err = true;
                        }
                    }
                } else {
                    item = parse_list_item_value(p, indent);
                    if (!item) item_err = true;
                }
            }
        } else if (c == '\n' || c == '\r' || c == 0) {
            consume_eol(p);
            if (!skip_trivia(p)) { item_err = true; }
            else if (eof(p)) { set_err(p, "expected indented block after empty '+' marker"); item_err = true; }
            else {
                int inner = measure_line_indent(p);
                if (inner <= indent) { set_err(p, "expected indented block after empty '+' marker"); item_err = true; }
                else {
                    item = parse_block_value(p, inner);
                    if (!item) item_err = true;
                }
            }
        } else {
            set_err(p, "expected space after '+'");
            item_err = true;
        }
        path_pop(&p->path);
        if (item_err) { dms_free(out); return NULL; }
        list_push(&out->u.l, item);
    }
    /* Block close: leftover pending become floating on the list itself. */
    flush_pending_as_floating(p);
    return out;
}

static dms_value *parse_block_value(parser *p, int indent) {
    p->pos = p->line_start + indent;
    if (!reject_reserved_line_start_sigil(p)) return NULL;
    if (peek(p) == '+' && peek_after_plus_is_space_or_eol(p)) {
        return parse_list_block(p, indent);
    }
    return parse_table_block(p, indent);
}

static dms_value *parse_list_item_value(parser *p, int list_indent) {
    (void)list_indent;
    if (line_starts_kvpair(p)) {
        int key_col = (int)(p->pos - p->line_start);
        char *k; dms_value *v;
        if (!parse_kvpair(p, key_col, &k, &v)) return NULL;
        dms_value *t = new_value(DMS_TABLE);
        table_set(&t->u.t, k, v);
        free(k);
        while (1) {
            if (!skip_trivia(p)) { dms_free(t); return NULL; }
            if (eof(p)) break;
            int li = measure_line_indent(p);
            if (li < key_col) break;
            if (li != key_col) {
                set_err_at(p, p->line, p->line_start, p->line_start + key_col,
                    "list-item table sibling key must align with first key");
                dms_free(t); return NULL;
            }
            p->pos = p->line_start + key_col;
            if (!reject_reserved_line_start_sigil(p)) { dms_free(t); return NULL; }
            if (peek(p) == '+') { set_err(p, "'+' marker at sibling-key column is ambiguous"); dms_free(t); return NULL; }
            if (!line_starts_kvpair(p)) break;
            char *k2; dms_value *v2;
            if (!parse_kvpair(p, key_col, &k2, &v2)) { dms_free(t); return NULL; }
            if (dms_table_has(&t->u.t, k2)) { set_err(p, "duplicate key: %s", k2); free(k2); dms_free(v2); dms_free(t); return NULL; }
            table_set(&t->u.t, k2, v2);
            free(k2);
        }
        /* End of inline-table-in-list-item: any pending leading comments
           belong to the enclosing list item itself (Floating). */
        flush_pending_as_floating(p);
        return t;
    }
    dms_value *v = parse_inline_value_or_heredoc(p);
    if (!v) return NULL;
    if (!consume_after_value(p, 0)) { dms_free(v); return NULL; }
    return v;
}

/* ---------- kvpair / key ---------- */

static int parse_kvpair(parser *p, int parent_indent, char **out_key, dms_value **out_val) {
    char *key = parse_key(p);
    if (!key) return 0;
    if (peek(p) != ':') { free(key); return set_err(p, "expected ':' after key"); }
    /* Push breadcrumb so leading comments attach to this kvpair, and
       trailing/floating comments captured during value parsing get the
       right path. Pop on exit (success or failure). */
    path_push_key(&p->path, key);
    flush_pending_as_leading_on_current(p);
    p->pos++;
    char c = peek(p);
    if (c == ' ' || c == '\t') {
        p->pos++;
        skip_inline_ws(p);
        if (!capture_inner_block_comments(p)) { path_pop(&p->path); free(key); return 0; }
        char c2 = peek(p);
        if (c2 == '\n' || c2 == '\r' || c2 == 0) {
            /* "key: INNER[EOL]" — child block with inner. */
            consume_eol(p);
            if (!skip_trivia(p)) { path_pop(&p->path); free(key); return 0; }
            if (eof(p)) { path_pop(&p->path); free(key); return set_err(p, "expected indented child block"); }
            int child = measure_line_indent(p);
            if (child <= parent_indent) { path_pop(&p->path); free(key); return set_err(p, "expected indented child block"); }
            dms_value *v = parse_block_value(p, child);
            if (!v) { path_pop(&p->path); free(key); return 0; }
            path_pop(&p->path);
            *out_key = key; *out_val = v; return 1;
        }
        dms_value *v = parse_inline_value_or_heredoc(p);
        if (!v) { path_pop(&p->path); free(key); return 0; }
        if (!consume_after_value(p, 0)) { path_pop(&p->path); free(key); dms_free(v); return 0; }
        path_pop(&p->path);
        *out_key = key; *out_val = v; return 1;
    }
    if (c == '\n' || c == '\r' || c == 0) {
        consume_eol(p);
        if (!skip_trivia(p)) { path_pop(&p->path); free(key); return 0; }
        if (eof(p)) { path_pop(&p->path); free(key); return set_err(p, "expected indented child block"); }
        int child = measure_line_indent(p);
        if (child <= parent_indent) { path_pop(&p->path); free(key); return set_err(p, "expected indented child block"); }
        dms_value *v = parse_block_value(p, child);
        if (!v) { path_pop(&p->path); free(key); return 0; }
        path_pop(&p->path);
        *out_key = key; *out_val = v; return 1;
    }
    path_pop(&p->path);
    free(key);
    return set_err(p, "expected whitespace after ':'");
}

static char *parse_bare_key_str(parser *p);

static char *parse_key(parser *p) {
    char c = peek(p);
    if (c == '"') {
        if (starts_with(p, "\"\"\"")) { set_err(p, "triple-quoted strings are not allowed as keys"); return NULL; }
        return parse_basic_string_str(p);
    }
    if (c == '\'') {
        if (starts_with(p, "'''")) { set_err(p, "triple-quoted strings are not allowed as keys"); return NULL; }
        return parse_literal_string_str(p);
    }
    if (c == 0) { set_err(p, "expected key"); return NULL; }
    return parse_bare_key_str(p);
}

static char *parse_bare_key_str(parser *p) {
    size_t start = p->pos;
    const char *src = p->src;
    size_t end = p->len;
    size_t pos = p->pos;
    /* ASCII fast path: ~6 chars/key × 50k keys is the bench's biggest
     * utf8_decode caller. Stepping byte-by-byte here is ~10× faster. */
    while (pos < end) {
        unsigned char b0 = (unsigned char)src[pos];
        if (b0 < 0x80) {
            if (!is_bare_key_char_ascii(b0)) break;
            pos++;
            continue;
        }
        /* Non-ASCII: fall through to the multi-byte decoder. */
        size_t clen;
        int cp = utf8_decode(src + pos, end - pos, &clen);
        if (cp < 0 || !is_bare_key_char_cp(cp)) break;
        pos += clen;
    }
    p->pos = pos;
    if (pos == start) { set_err(p, "expected key"); return NULL; }
    return xstrndup(src + start, pos - start);
}

/* ---------- string parsers ---------- */

static char *parse_basic_string_str(parser *p) {
    int sl = p->line;
    size_t sls = p->line_start, sp = p->pos;
    p->pos++; /* opening " */
    buf b; buf_init(&b);
    while (1) {
        if (eof(p)) { set_err_at(p, sl, sls, sp, "unterminated string"); free(b.data); return NULL; }
        char c = peek(p);
        if (c == '\n' || c == '\r') { set_err(p, "strings cannot span lines"); free(b.data); return NULL; }
        if (c == '"') { p->pos++; /* SPEC §Unicode normalization: re-NFC after escape decoding. */ if (!b.data) { return nfc_string(xstrdup("")); } return nfc_string(b.data); }
        if (c == '\\') {
            p->pos++;
            if (eof(p)) { set_err(p, "unterminated escape"); free(b.data); return NULL; }
            char esc = p->src[p->pos++];
            char out[5];
            int outlen;
            unsigned cp;
            switch (esc) {
                case '"': buf_push(&b, '"'); break;
                case '\\': buf_push(&b, '\\'); break;
                case 'n': buf_push(&b, '\n'); break;
                case 't': buf_push(&b, '\t'); break;
                case 'r': buf_push(&b, '\r'); break;
                case 'b': buf_push(&b, '\b'); break;
                case 'f': buf_push(&b, '\f'); break;
                case 'u':
                case 'U': {
                    int n = (esc == 'u') ? 4 : 8;
                    if ((int)(p->len - p->pos) < n) {
                        set_err(p, "expected %d hex digits in unicode escape", n);
                        free(b.data); return NULL;
                    }
                    cp = 0;
                    for (int i = 0; i < n; i++) {
                        char h = p->src[p->pos + i];
                        int d;
                        if (h >= '0' && h <= '9') d = h - '0';
                        else if (h >= 'a' && h <= 'f') d = h - 'a' + 10;
                        else if (h >= 'A' && h <= 'F') d = h - 'A' + 10;
                        else { set_err(p, "invalid hex in unicode escape"); free(b.data); return NULL; }
                        cp = (cp << 4) | d;
                    }
                    p->pos += n;
                    /* SPEC: U+0000 is forbidden anywhere in DMS source, including via
                       escape decoding. ` ` / `\U00000000` must not slip through. */
                    if (cp == 0) {
                        set_err(p, "\\u0000 escape forbidden"); free(b.data); return NULL;
                    }
                    /* SPEC §basic-string escapes: surrogate codepoints (U+D800..U+DFFF)
                       are not valid Unicode scalars and are a parse error in `\uXXXX` /
                       `\UXXXXXXXX` escapes. */
                    if (cp >= 0xD800 && cp <= 0xDFFF) {
                        set_err(p, "surrogate codepoint U+%04X in escape", cp); free(b.data); return NULL;
                    }
                    if (cp > 0x10FFFF) {
                        set_err(p, "unicode escape is not a scalar value"); free(b.data); return NULL;
                    }
                    outlen = utf8_encode(cp, out);
                    buf_push_str(&b, out, outlen);
                    break;
                }
                default:
                    set_err(p, "invalid escape '\\%c'", esc);
                    free(b.data); return NULL;
            }
        } else {
            /* preserve raw bytes */
            buf_push(&b, c);
            p->pos++;
        }
    }
}

static char *parse_literal_string_str(parser *p) {
    int sl = p->line;
    size_t sls = p->line_start, sp = p->pos;
    p->pos++; /* opening ' */
    buf b; buf_init(&b);
    while (1) {
        if (eof(p)) { set_err_at(p, sl, sls, sp, "unterminated string"); free(b.data); return NULL; }
        char c = peek(p);
        if (c == '\n' || c == '\r') { set_err(p, "strings cannot span lines"); free(b.data); return NULL; }
        if (c == '\'') { p->pos++; if (!b.data) return xstrdup(""); return b.data; }
        buf_push(&b, c);
        p->pos++;
    }
}

static dms_value *parse_basic_string(parser *p) {
    char *s = parse_basic_string_str(p);
    if (!s) return NULL;
    dms_value *v = new_value(DMS_STRING);
    v->u.s = s;
    return v;
}

static dms_value *parse_literal_string(parser *p) {
    char *s = parse_literal_string_str(p);
    if (!s) return NULL;
    dms_value *v = new_value(DMS_STRING);
    v->u.s = s;
    /* Record original form (Literal). Basic-string form is the emitter
       default and not recorded. */
    if (p->record_forms) {
        dms_string_form *sf = (dms_string_form *)calloc(1, sizeof(dms_string_form));
        sf->kind = DMS_STRING_LITERAL;
        record_form_string(p, sf);
    }
    return v;
}

/* ---------- numbers / datetimes ---------- */

static bool valid_underscores(const char *s) {
    size_t n = strlen(s);
    if (n == 0) return true;
    if (s[0] == '_' || s[n-1] == '_') return false;
    bool prev = false;
    for (size_t i = 0; i < n; i++) {
        if (s[i] == '_') { if (prev) return false; prev = true; }
        else prev = false;
    }
    return true;
}

static int hex_digit(char c) {
    if (c >= '0' && c <= '9') return c - '0';
    if (c >= 'a' && c <= 'f') return c - 'a' + 10;
    if (c >= 'A' && c <= 'F') return c - 'A' + 10;
    return -1;
}

/* Parse integer; returns 0 on success. */
static int parse_integer_str(const char *s, int64_t *out, char *errmsg, size_t errsize) {
    int64_t sign = 1;
    if (*s == '-') { sign = -1; s++; }
    else if (*s == '+') { s++; }
    if (s[0] == '0' && s[1] == 'X') { snprintf(errmsg, errsize, "hex prefix must be lowercase '0x'"); return -1; }
    int radix = 10;
    const char *body = s;
    if (s[0] == '0' && s[1] == 'x') { radix = 16; body = s + 2; }
    else if (s[0] == '0' && s[1] == 'o') { radix = 8; body = s + 2; }
    else if (s[0] == '0' && s[1] == 'b') { radix = 2; body = s + 2; }
    if (!*body) { snprintf(errmsg, errsize, "empty number"); return -1; }
    if (body[0] == '_' || body[strlen(body)-1] == '_') {
        snprintf(errmsg, errsize, "underscore must be between digits"); return -1;
    }
    if (radix == 10 && strlen(s) > 1 && s[0] == '0') {
        snprintf(errmsg, errsize, "leading zeros are not allowed on decimal integers");
        return -1;
    }
    /* Parse digits, handling underscores. Use uint64 then sign/range check. */
    uint64_t acc = 0;
    bool prev_is_digit = false;
    for (const char *q = body; *q; q++) {
        char c = *q;
        if (c == '_') {
            if (!prev_is_digit) { snprintf(errmsg, errsize, "underscore must be between digits"); return -1; }
            prev_is_digit = false;
            continue;
        }
        int d = hex_digit(c);
        if (d < 0 || d >= radix) {
            snprintf(errmsg, errsize, "invalid digit '%c' for base %d", c, radix); return -1;
        }
        /* Overflow-safe multiply-add for uint64 */
        if (acc > (UINT64_MAX - d) / radix) { snprintf(errmsg, errsize, "integer out of i64 range"); return -1; }
        acc = acc * radix + d;
        prev_is_digit = true;
    }
    if (!prev_is_digit) { snprintf(errmsg, errsize, "underscore must be between digits"); return -1; }
    /* i64 range */
    if (sign == -1) {
        if (acc > (uint64_t)1 << 63) { snprintf(errmsg, errsize, "integer out of i64 range"); return -1; }
        if (acc == ((uint64_t)1 << 63)) *out = INT64_MIN;
        else *out = -(int64_t)acc;
    } else {
        if (acc > (uint64_t)INT64_MAX) { snprintf(errmsg, errsize, "integer out of i64 range"); return -1; }
        *out = (int64_t)acc;
    }
    return 0;
}

static int parse_dec_float_str(const char *s, double *out, char *errmsg, size_t errsize) {
    /* Find e/E */
    const char *e_idx = NULL;
    for (const char *q = s; *q; q++) {
        if (*q == 'e' || *q == 'E') { e_idx = q; break; }
    }
    /* mantissa */
    size_t mlen = e_idx ? (size_t)(e_idx - s) : strlen(s);
    char *m = xstrndup(s, mlen);
    char *dot = strchr(m, '.');
    if (!dot) { free(m); snprintf(errmsg, errsize, "decimal float requires '.'"); return -1; }
    *dot = 0;
    char *ip = m;
    char *fp = dot + 1;
    if (!*ip || !*fp) { free(m); snprintf(errmsg, errsize, "decimal float requires digit on both sides of '.'"); return -1; }
    for (char *q = ip; *q; q++) if (!(isdigit((unsigned char)*q) || *q == '_')) { free(m); snprintf(errmsg, errsize, "invalid character in mantissa"); return -1; }
    for (char *q = fp; *q; q++) if (!(isdigit((unsigned char)*q) || *q == '_')) { free(m); snprintf(errmsg, errsize, "invalid character in mantissa"); return -1; }
    if (!valid_underscores(ip) || !valid_underscores(fp)) { free(m); snprintf(errmsg, errsize, "bad underscore"); return -1; }
    /* Strip underscores from ip and fp */
    char *ipc = (char *)malloc(strlen(ip) + 1); char *fpc = (char *)malloc(strlen(fp) + 1);
    char *q1 = ipc; for (char *r = ip; *r; r++) if (*r != '_') *q1++ = *r; *q1 = 0;
    char *q2 = fpc; for (char *r = fp; *r; r++) if (*r != '_') *q2++ = *r; *q2 = 0;
    /* build full string */
    buf b; buf_init(&b);
    buf_push_str(&b, ipc, strlen(ipc));
    buf_push(&b, '.');
    buf_push_str(&b, fpc, strlen(fpc));
    if (e_idx) {
        const char *eraw = e_idx + 1;
        const char *ec = eraw;
        if (*ec == '+' || *ec == '-') ec++;
        if (strchr(eraw, '_')) { free(m); free(ipc); free(fpc); free(b.data); snprintf(errmsg, errsize, "underscore not allowed in exponent"); return -1; }
        for (const char *r = eraw; *r; r++) if (!(isdigit((unsigned char)*r) || *r == '+' || *r == '-')) { free(m); free(ipc); free(fpc); free(b.data); snprintf(errmsg, errsize, "invalid character in exponent"); return -1; }
        if (!*ec) { free(m); free(ipc); free(fpc); free(b.data); snprintf(errmsg, errsize, "empty exponent"); return -1; }
        buf_push(&b, 'e');
        buf_push_str(&b, eraw, strlen(eraw));
    }
    char *endp;
    *out = strtod(b.data, &endp);
    int ok = (endp && *endp == 0);
    free(m); free(ipc); free(fpc); free(b.data);
    if (!ok) { snprintf(errmsg, errsize, "invalid float"); return -1; }
    return 0;
}

static int parse_nondec_float_str(const char *s, double *out, char *errmsg, size_t errsize) {
    int radix;
    const char *rest;
    if (s[0] == '0' && s[1] == 'x') { radix = 16; rest = s + 2; }
    else if (s[0] == '0' && s[1] == 'o') { radix = 8; rest = s + 2; }
    else if (s[0] == '0' && s[1] == 'b') { radix = 2; rest = s + 2; }
    else { snprintf(errmsg, errsize, "non-decimal float prefix required"); return -1; }
    const char *p_idx = strchr(rest, 'p');
    if (!p_idx) { snprintf(errmsg, errsize, "non-decimal float requires 'p' exponent"); return -1; }
    size_t mant_len = (size_t)(p_idx - rest);
    char *mant = xstrndup(rest, mant_len);
    const char *exp_str = p_idx + 1;
    if (!*exp_str) { free(mant); snprintf(errmsg, errsize, "empty exponent"); return -1; }
    if (strchr(exp_str, '_')) { free(mant); snprintf(errmsg, errsize, "underscore not allowed in exponent"); return -1; }
    for (const char *q = exp_str; *q; q++) if (!(isdigit((unsigned char)*q) || *q == '+' || *q == '-')) { free(mant); snprintf(errmsg, errsize, "invalid exponent character"); return -1; }
    int exp = atoi(exp_str);
    char *dot = strchr(mant, '.');
    char *ip; char *fp;
    if (dot) {
        *dot = 0;
        ip = mant;
        fp = dot + 1;
        if (!*ip || !*fp) { free(mant); snprintf(errmsg, errsize, "digit required on both sides of '.'"); return -1; }
    } else {
        ip = mant;
        fp = "";
    }
    if (!valid_underscores(ip) || !valid_underscores(fp)) { free(mant); snprintf(errmsg, errsize, "bad underscore"); return -1; }
    /* validate digits */
    for (char *q = ip; *q; q++) {
        if (*q == '_') continue;
        int d = hex_digit(*q);
        if (d < 0 || d >= radix) { free(mant); snprintf(errmsg, errsize, "invalid digit for base %d", radix); return -1; }
    }
    for (char *q = fp; *q; q++) {
        if (*q == '_') continue;
        int d = hex_digit(*q);
        if (d < 0 || d >= radix) { free(mant); snprintf(errmsg, errsize, "invalid digit for base %d", radix); return -1; }
    }
    /* compute */
    double int_val = 0;
    for (char *q = ip; *q; q++) {
        if (*q == '_') continue;
        int d = hex_digit(*q);
        int_val = int_val * radix + d;
    }
    double frac_val = 0;
    double div = (double)radix;
    for (char *q = fp; *q; q++) {
        if (*q == '_') continue;
        int d = hex_digit(*q);
        frac_val += d / div;
        div *= radix;
    }
    *out = (int_val + frac_val) * pow(2.0, (double)exp);
    free(mant);
    return 0;
}

static int parse_float_val(const char *s, double *out, char *errmsg, size_t errsize) {
    double sign = 1.0;
    const char *rest = s;
    if (*rest == '-') { sign = -1; rest++; }
    else if (*rest == '+') { rest++; }
    int rc;
    if (rest[0] == '0' && (rest[1] == 'x' || rest[1] == 'o' || rest[1] == 'b')) {
        rc = parse_nondec_float_str(rest, out, errmsg, errsize);
    } else {
        rc = parse_dec_float_str(rest, out, errmsg, errsize);
    }
    if (rc != 0) return rc;
    *out *= sign;
    return 0;
}

static int days_in_month(int y, int m) {
    if (m == 1 || m == 3 || m == 5 || m == 7 || m == 8 || m == 10 || m == 12) return 31;
    if (m == 4 || m == 6 || m == 9 || m == 11) return 30;
    if (m == 2) {
        bool leap = (y % 4 == 0 && y % 100 != 0) || y % 400 == 0;
        return leap ? 29 : 28;
    }
    return 0;
}

static bool looks_like_date_prefix(const char *s, size_t n) {
    if (n < 10) return false;
    for (int i = 0; i < 10; i++) if (i != 4 && i != 7 && !(s[i] >= '0' && s[i] <= '9')) return false;
    return s[4] == '-' && s[7] == '-';
}

static bool looks_like_time_prefix(const char *s, size_t n) {
    if (n < 8) return false;
    for (int i = 0; i < 8; i++) if (i != 2 && i != 5 && !(s[i] >= '0' && s[i] <= '9')) return false;
    return s[2] == ':' && s[5] == ':';
}

static int validate_date(const char *s, char *errmsg, size_t errsize) {
    int y = (s[0]-'0')*1000 + (s[1]-'0')*100 + (s[2]-'0')*10 + (s[3]-'0');
    int m = (s[5]-'0')*10 + (s[6]-'0');
    int d = (s[8]-'0')*10 + (s[9]-'0');
    if (m < 1 || m > 12) { snprintf(errmsg, errsize, "month out of range"); return -1; }
    if (d < 1 || d > days_in_month(y, m)) { snprintf(errmsg, errsize, "day out of range"); return -1; }
    return 0;
}

static int validate_time(const char *s, char *errmsg, size_t errsize) {
    int h = (s[0]-'0')*10 + (s[1]-'0');
    int m = (s[3]-'0')*10 + (s[4]-'0');
    int sec = (s[6]-'0')*10 + (s[7]-'0');
    if (h > 23) { snprintf(errmsg, errsize, "hour out of range"); return -1; }
    if (m > 59) { snprintf(errmsg, errsize, "minute out of range"); return -1; }
    if (sec > 59) { snprintf(errmsg, errsize, "second out of range (leap seconds not supported)"); return -1; }
    return 0;
}

static dms_value *parse_local_time_value(parser *p) {
    const char *r = rest(p);
    size_t rl = rest_len(p);
    char errmsg[128];
    if (validate_time(r, errmsg, sizeof errmsg) != 0) { set_err(p, "%s", errmsg); return NULL; }
    size_t consumed = 8;
    if (rl > consumed && r[consumed] == '.') {
        size_t k = 1;
        while (consumed + k < rl && r[consumed + k] >= '0' && r[consumed + k] <= '9') k++;
        size_t digits = k - 1;
        if (digits == 0) { set_err(p, "expected fractional digits after '.'"); return NULL; }
        if (digits > 9) { set_err(p, "fractional seconds limited to 9 digits"); return NULL; }
        consumed += k;
    }
    char nxt = consumed < rl ? r[consumed] : 0;
    if (!is_value_terminator(nxt)) { set_err(p, "invalid character after time"); return NULL; }
    dms_value *v = new_value(DMS_LOCAL_TIME);
    v->u.s = xstrndup(r, consumed);
    p->pos += consumed;
    return v;
}

static dms_value *parse_datetime_value(parser *p) {
    const char *r = rest(p);
    size_t rl = rest_len(p);
    char errmsg[128];
    if (validate_date(r, errmsg, sizeof errmsg) != 0) { set_err(p, "%s", errmsg); return NULL; }
    if (rl <= 10 || (r[10] != 'T' && r[10] != ' ')) {
        if (rl > 10 && r[10] == 't') {
            set_err(p, "date and time separator must be uppercase 'T' (lowercase 't' not permitted)");
            return NULL;
        }
        char nxt = rl > 10 ? r[10] : 0;
        if (!is_value_terminator(nxt)) { set_err(p, "invalid character after date"); return NULL; }
        dms_value *v = new_value(DMS_LOCAL_DATE);
        v->u.s = xstrndup(r, 10);
        p->pos += 10;
        return v;
    }
    if (r[10] == ' ') {
        size_t k = 11;
        while (k < rl && (r[k] == ' ' || r[k] == '\t')) k++;
        if (k < rl && r[k] >= '0' && r[k] <= '9') { set_err(p, "date and time must be separated by 'T' (space not permitted)"); return NULL; }
        dms_value *v = new_value(DMS_LOCAL_DATE);
        v->u.s = xstrndup(r, 10);
        p->pos += 10;
        return v;
    }
    if (!looks_like_time_prefix(r + 11, rl - 11)) { set_err(p, "expected HH:MM:SS after 'T'"); return NULL; }
    if (validate_time(r + 11, errmsg, sizeof errmsg) != 0) { set_err(p, "%s", errmsg); return NULL; }
    size_t consumed = 19;
    if (rl > consumed && r[consumed] == '.') {
        size_t k = 1;
        while (consumed + k < rl && r[consumed + k] >= '0' && r[consumed + k] <= '9') k++;
        size_t digits = k - 1;
        if (digits == 0) { set_err(p, "expected fractional digits after '.'"); return NULL; }
        if (digits > 9) { set_err(p, "fractional seconds limited to 9 digits (nanosecond precision)"); return NULL; }
        consumed += k;
    }
    char tz = consumed < rl ? r[consumed] : 0;
    if (tz == 'Z' || tz == 'z') {
        consumed++;
        dms_value *v = new_value(DMS_OFFSET_DT);
        v->u.s = xstrndup(r, consumed);
        p->pos += consumed;
        return v;
    }
    if (tz == '+' || tz == '-') {
        if (consumed + 6 > rl
            || !(r[consumed+1] >= '0' && r[consumed+1] <= '9')
            || !(r[consumed+2] >= '0' && r[consumed+2] <= '9')
            || r[consumed+3] != ':'
            || !(r[consumed+4] >= '0' && r[consumed+4] <= '9')
            || !(r[consumed+5] >= '0' && r[consumed+5] <= '9')) {
            set_err(p, "invalid offset; expected ±HH:MM"); return NULL;
        }
        int oh = (r[consumed+1]-'0')*10 + (r[consumed+2]-'0');
        int om = (r[consumed+4]-'0')*10 + (r[consumed+5]-'0');
        if (oh > 23 || om > 59) { set_err(p, "offset out of range"); return NULL; }
        consumed += 6;
        dms_value *v = new_value(DMS_OFFSET_DT);
        v->u.s = xstrndup(r, consumed);
        p->pos += consumed;
        return v;
    }
    if (!is_value_terminator(tz)) { set_err(p, "invalid character after datetime"); return NULL; }
    dms_value *v = new_value(DMS_LOCAL_DT);
    v->u.s = xstrndup(r, consumed);
    p->pos += consumed;
    return v;
}

static int scan_number_token(parser *p, size_t *outlen, bool *is_float) {
    const char *s = rest(p);
    size_t n = rest_len(p);
    size_t i = 0;
    if (i < n && (s[i] == '+' || s[i] == '-')) i++;
    bool is_prefixed = i + 1 < n && s[i] == '0' && (s[i+1] == 'x' || s[i+1] == 'o' || s[i+1] == 'b');
    bool saw_dot = false, saw_p = false, saw_e = false;
    if (is_prefixed) {
        i += 2;
        while (i < n) {
            char c = s[i];
            if (c == '_' || (c >= '0' && c <= '9') || (c >= 'a' && c <= 'f') || (c >= 'A' && c <= 'F')) {
                i++;
            } else if (c == '.' && !saw_dot && !saw_p) { saw_dot = true; i++; }
            else if (c == 'p' && !saw_p) {
                saw_p = true; i++;
                if (i < n && (s[i] == '+' || s[i] == '-')) i++;
            } else if (saw_p && c >= '0' && c <= '9') i++;
            else break;
        }
        *outlen = i; *is_float = saw_dot || saw_p; return 1;
    }
    while (i < n) {
        char c = s[i];
        if ((c >= '0' && c <= '9') || c == '_') i++;
        else if (c == '.' && !saw_dot && !saw_e) { saw_dot = true; i++; }
        else if ((c == 'e' || c == 'E') && !saw_e) {
            saw_e = true; i++;
            if (i < n && (s[i] == '+' || s[i] == '-')) i++;
        } else break;
    }
    *outlen = i; *is_float = saw_dot || saw_e;
    return 1;
}

static dms_value *parse_number_or_datetime(parser *p) {
    const char *r = rest(p);
    size_t rl = rest_len(p);
    bool starts_sign = peek(p) == '+' || peek(p) == '-';
    if (!starts_sign && looks_like_date_prefix(r, rl)) return parse_datetime_value(p);
    if (!starts_sign && looks_like_time_prefix(r, rl)) return parse_local_time_value(p);
    if (starts_sign && rl >= 4 && r[1] == 'i' && r[2] == 'n' && r[3] == 'f') {
        char after = rl > 4 ? r[4] : 0;
        if (is_value_terminator(after)) {
            bool neg = r[0] == '-';
            p->pos += 4;
            dms_value *v = new_value(DMS_FLOAT);
            v->u.f = neg ? -INFINITY : INFINITY;
            return v;
        }
    }
    /* Fast path: simple unsigned decimal integer — [0-9]+ followed by a
     * value terminator. Covers the overwhelmingly common case (counts,
     * ports, IDs); skips the xstrndup → parse_integer_str → free round
     * trip for every one of those. Falls through to the general path
     * for signs, bases (0x/0o/0b), underscores, floats, and datetimes. */
    if (!starts_sign && rl > 0 && r[0] >= '0' && r[0] <= '9') {
        size_t t = 0;
        uint64_t acc = 0;
        bool overflow = false;
        while (t < rl && r[t] >= '0' && r[t] <= '9') {
            uint64_t next = acc * 10 + (uint64_t)(r[t] - '0');
            if (next < acc) overflow = true;
            acc = next;
            t++;
        }
        char term = t < rl ? r[t] : 0;
        bool no_leading_zero = !(t > 1 && r[0] == '0');
        if (t > 0 && no_leading_zero && is_value_terminator(term)) {
            if (overflow || acc > (uint64_t)INT64_MAX) {
                set_err(p, "integer out of i64 range");
                return NULL;
            }
            p->pos += t;
            dms_value *v = new_value(DMS_INTEGER);
            v->u.i = (int64_t)acc;
            return v;
        }
        /* Not a simple plain integer (has leading zero, or has extra
         * chars like '_' / '.' / 'e' / 'x'). Fall through. */
    }
    size_t tok; bool is_float;
    scan_number_token(p, &tok, &is_float);
    char *s = xstrndup(r, tok);
    if (is_float) {
        double f;
        char errmsg[128];
        if (parse_float_val(s, &f, errmsg, sizeof errmsg) != 0) {
            set_err(p, "invalid float: %s (%s)", s, errmsg);
            free(s); return NULL;
        }
        free(s);
        p->pos += tok;
        dms_value *v = new_value(DMS_FLOAT);
        v->u.f = f;
        return v;
    }
    int64_t n;
    char errmsg[128];
    if (parse_integer_str(s, &n, errmsg, sizeof errmsg) != 0) {
        set_err(p, "%s", errmsg);
        free(s); return NULL;
    }
    p->pos += tok;
    /* Record original lexeme when it differs from the canonical decimal
       form used by the default emitter (i.e. `%lld`). Anything else —
       hex/oct/bin, underscore separators, explicit `+` sign — gets
       recorded. `s` is owned; steal or free based on comparison. */
    char canonical[32];
    snprintf(canonical, sizeof canonical, "%lld", (long long)n);
    if (strcmp(s, canonical) == 0) {
        free(s);
    } else {
        record_form_integer(p, s);  /* takes ownership */
    }
    dms_value *v = new_value(DMS_INTEGER);
    v->u.i = n;
    return v;
}

static dms_value *parse_bool_v(parser *p) {
    if (starts_with(p, "true") && is_value_terminator(peek_at(p, 4))) {
        p->pos += 4;
        dms_value *v = new_value(DMS_BOOL); v->u.b = true; return v;
    }
    if (starts_with(p, "false") && is_value_terminator(peek_at(p, 5))) {
        p->pos += 5;
        dms_value *v = new_value(DMS_BOOL); v->u.b = false; return v;
    }
    set_err(p, "expected value"); return NULL;
}

static dms_value *parse_inf_v(parser *p) {
    if (starts_with(p, "inf") && is_value_terminator(peek_at(p, 3))) {
        p->pos += 3;
        dms_value *v = new_value(DMS_FLOAT); v->u.f = INFINITY; return v;
    }
    set_err(p, "expected 'inf'"); return NULL;
}

static dms_value *parse_nan_v(parser *p) {
    if (starts_with(p, "nan") && is_value_terminator(peek_at(p, 3))) {
        p->pos += 3;
        dms_value *v = new_value(DMS_FLOAT); v->u.f = NAN; return v;
    }
    set_err(p, "expected 'nan'"); return NULL;
}

/* ---------- heredocs ---------- */

typedef struct {
    char *text;       /* line text (no trailing newline) */
    int line;
    size_t line_start;
} h_line;

typedef struct {
    h_line *lines;
    size_t len;
    size_t cap;
    size_t strip_depth;
} h_body;

static void hbody_push(h_body *b, h_line ln) {
    if (b->len == b->cap) {
        size_t nc = b->cap ? b->cap * 2 : 8;
        b->lines = (h_line *)xrealloc(b->lines, nc * sizeof(h_line));
        b->cap = nc;
    }
    b->lines[b->len++] = ln;
}

static void hbody_free(h_body *b) {
    for (size_t i = 0; i < b->len; i++) free(b->lines[i].text);
    free(b->lines);
}

typedef struct {
    char *name;
    dms_value **args;
    size_t nargs;
} h_mod;

typedef struct {
    h_mod *mods;
    size_t len;
    size_t cap;
} h_mods;

static void hmods_push(h_mods *m, h_mod mod) {
    if (m->len == m->cap) {
        size_t nc = m->cap ? m->cap * 2 : 4;
        m->mods = (h_mod *)xrealloc(m->mods, nc * sizeof(h_mod));
        m->cap = nc;
    }
    m->mods[m->len++] = mod;
}

static void hmods_free(h_mods *m) {
    for (size_t i = 0; i < m->len; i++) {
        free(m->mods[i].name);
        for (size_t j = 0; j < m->mods[i].nargs; j++) dms_free(m->mods[i].args[j]);
        free(m->mods[i].args);
    }
    free(m->mods);
}

static char *parse_heredoc_label(parser *p) {
    char c = peek(p);
    if (!(c == '_' || isalpha((unsigned char)c))) return xstrdup("");
    size_t start = p->pos;
    while (p->pos < p->len) {
        char cc = p->src[p->pos];
        if (!(cc == '_' || isalnum((unsigned char)cc))) break;
        p->pos++;
    }
    return xstrndup(p->src + start, p->pos - start);
}

static int parse_one_modifier(parser *p, h_mod *out) {
    size_t ns = p->pos;
    while (p->pos < p->len) {
        char c = p->src[p->pos];
        if (!(c == '_' || isalnum((unsigned char)c))) break;
        p->pos++;
    }
    char *name = xstrndup(p->src + ns, p->pos - ns);
    if (peek(p) != '(') { free(name); return set_err(p, "modifiers require parentheses"); }
    p->pos++;
    /* Suppress original-form recording while parsing modifier args: these
       values live inside the modifier-call record on the host heredoc's
       path, and should not generate separate OriginalLiteral entries. */
    int saved_rec = p->record_forms;
    p->record_forms = 0;
    dms_value **args = NULL;
    size_t nargs = 0, cap = 0;
    int ok = 1;
    while (1) {
        skip_inline_ws(p);
        if (peek(p) == ')') { p->pos++; break; }
        dms_value *v = parse_inline_value_or_heredoc(p);
        if (!v) { ok = 0; break; }
        if (nargs == cap) {
            cap = cap ? cap * 2 : 4;
            args = (dms_value **)xrealloc(args, cap * sizeof(dms_value *));
        }
        args[nargs++] = v;
        skip_inline_ws(p);
        char c = peek(p);
        if (c == ',') p->pos++;
        else if (c == ')') { p->pos++; break; }
        else { set_err(p, "expected ',' or ')' in modifier args"); ok = 0; break; }
    }
    p->record_forms = saved_rec;
    if (!ok) {
        free(name);
        for (size_t i = 0; i < nargs; i++) dms_free(args[i]);
        free(args);
        return 0;
    }
    out->name = name;
    out->args = args;
    out->nargs = nargs;
    return 1;
}

static int parse_heredoc_modifiers(parser *p, h_mods *out) {
    out->mods = NULL; out->len = 0; out->cap = 0;
    while (1) {
        size_t ws_start = p->pos;
        skip_inline_ws(p);
        bool had_ws = p->pos > ws_start;
        char c = peek(p);
        if (c == '_' || isalpha((unsigned char)c)) {
            if (!had_ws) { hmods_free(out); return set_err(p, "modifier must be preceded by whitespace"); }
            h_mod m;
            if (!parse_one_modifier(p, &m)) { hmods_free(out); return 0; }
            hmods_push(out, m);
        } else {
            p->pos = ws_start;
            return 1;
        }
    }
}

static int collect_heredoc_body(parser *p, const char *terminator, h_body *out) {
    out->lines = NULL; out->len = 0; out->cap = 0; out->strip_depth = 0;
    int sl = p->line;
    size_t sls = p->line_start, sp = p->pos;
    size_t tlen = strlen(terminator);
    while (1) {
        if (eof(p)) { hbody_free(out); return set_err_at(p, sl, sls, sp, "unterminated heredoc"); }
        size_t lb = p->pos;
        while (p->pos < p->len) {
            char c = p->src[p->pos];
            if (c == '\n' || c == '\r') break;
            p->pos++;
        }
        size_t end = p->pos;
        int this_line = p->line;
        size_t this_lstart = p->line_start;
        /* trim ASCII whitespace */
        size_t t_start = lb, t_end = end;
        while (t_start < t_end && (p->src[t_start] == ' ' || p->src[t_start] == '\t')) t_start++;
        while (t_end > t_start && (p->src[t_end-1] == ' ' || p->src[t_end-1] == '\t')) t_end--;
        if (t_end - t_start == tlen && memcmp(p->src + t_start, terminator, tlen) == 0) {
            size_t depth = 0;
            for (size_t i = lb; i < end && p->src[i] == ' '; i++) depth++;
            out->strip_depth = depth;
            return 1;
        }
        consume_eol(p);
        h_line ln;
        ln.text = xstrndup(p->src + lb, end - lb);
        ln.line = this_line;
        ln.line_start = this_lstart;
        hbody_push(out, ln);
    }
}

static int strip_indent_and_continuations(const h_body *body, bool allow_cont, char **out_str, parser *p) {
    buf out; buf_init(&out);
    bool first = true;
    bool pending = false;
    int last_line = 1;
    for (size_t i = 0; i < body->len; i++) {
        const h_line *ln = &body->lines[i];
        last_line = ln->line;
        bool is_blank = true;
        for (char *q = ln->text; *q; q++) if (*q != ' ' && *q != '\t') { is_blank = false; break; }
        const char *stripped;
        if (is_blank) {
            stripped = "";
        } else {
            size_t leading = 0;
            for (char *q = ln->text; *q == ' '; q++) leading++;
            if (leading < body->strip_depth) {
                p->has_err = 1;
                p->err.line = ln->line;
                p->err.column = (int)leading + 1;
                snprintf(p->err.message, sizeof p->err.message,
                    "heredoc body line indented %zu spaces, less than strip depth %zu",
                    leading, body->strip_depth);
                free(out.data);
                return 0;
            }
            stripped = ln->text + body->strip_depth;
        }
        char *piece = xstrdup(stripped);
        size_t plen = strlen(piece);
        bool splice = false;
        if (allow_cont) {
            /* trim trailing space/tab */
            while (plen > 0 && (piece[plen-1] == ' ' || piece[plen-1] == '\t')) plen--;
            piece[plen] = 0;
            /* find last \ */
            char *idx = strrchr(piece, '\\');
            if (idx && idx == piece + plen - 1) {
                size_t preceding = 0;
                ptrdiff_t k = (idx - piece) - 1;
                while (k >= 0 && piece[k] == '\\') { preceding++; k--; }
                if (preceding % 2 == 0) {
                    *idx = 0;
                    plen--;
                    splice = true;
                }
            }
        }
        if (first) {
            buf_push_str(&out, piece, strlen(piece));
            first = false;
        } else if (pending) {
            char *q = piece;
            while (*q == ' ' || *q == '\t') q++;
            if (!is_blank) buf_push_str(&out, q, strlen(q));
        } else {
            buf_push(&out, '\n');
            buf_push_str(&out, piece, strlen(piece));
        }
        free(piece);
        pending = splice;
    }
    if (pending) {
        p->has_err = 1;
        p->err.line = last_line;
        p->err.column = 1;
        snprintf(p->err.message, sizeof p->err.message, "trailing line continuation has nothing to splice to");
        free(out.data);
        return 0;
    }
    if (!out.data) out.data = xstrdup("");
    *out_str = out.data;
    return 1;
}

static char *fold_paragraphs(const char *s) {
    /* Split by "\n\n" → for each paragraph, split lines, join non-empty by " ", join paragraphs by "\n" */
    buf out; buf_init(&out);
    const char *p = s;
    bool first_para = true;
    while (1) {
        const char *para_end = strstr(p, "\n\n");
        size_t plen = para_end ? (size_t)(para_end - p) : strlen(p);
        if (!first_para) buf_push(&out, '\n');
        first_para = false;
        /* iterate lines within paragraph */
        const char *l = p;
        const char *end = p + plen;
        bool first_line = true;
        while (l < end) {
            const char *nl = (const char *)memchr(l, '\n', (size_t)(end - l));
            const char *line_end = nl ? nl : end;
            if (line_end > l) {
                if (!first_line) buf_push(&out, ' ');
                buf_push_str(&out, l, (size_t)(line_end - l));
                first_line = false;
            }
            l = nl ? nl + 1 : end;
        }
        if (!para_end) break;
        p = para_end + 2;
    }
    if (!out.data) out.data = xstrdup("");
    return out.data;
}

static bool in_char_set(unsigned char c, const char *chars) {
    for (const unsigned char *p = (const unsigned char *)chars; *p; p++) {
        if (*p == c) return true;
    }
    return false;
}

static char *replace_all_runs(const char *s, const char *chars, const char *replacement) {
    buf b; buf_init(&b);
    size_t rl = strlen(replacement);
    const unsigned char *p = (const unsigned char *)s;
    while (*p) {
        if (in_char_set(*p, chars)) {
            while (*p && in_char_set(*p, chars)) p++;
            buf_push_str(&b, replacement, rl);
        } else {
            buf_push(&b, (char)*p);
            p++;
        }
    }
    return b.data ? b.data : xstrdup("");
}

static char *replace_leading_run(const char *s, const char *chars, const char *replacement) {
    size_t len = strlen(s);
    size_t end = 0;
    while (end < len && in_char_set((unsigned char)s[end], chars)) end++;
    if (end == 0) return xstrdup(s);
    buf b; buf_init(&b);
    buf_push_str(&b, replacement, strlen(replacement));
    buf_push_str(&b, s + end, len - end);
    return b.data ? b.data : xstrdup("");
}

static char *replace_trailing_run(const char *s, const char *chars, const char *replacement) {
    size_t len = strlen(s);
    size_t start = len;
    while (start > 0 && in_char_set((unsigned char)s[start - 1], chars)) start--;
    if (start == len) return xstrdup(s);
    buf b; buf_init(&b);
    buf_push_str(&b, s, start);
    buf_push_str(&b, replacement, strlen(replacement));
    return b.data ? b.data : xstrdup("");
}

static char *per_line_edges(const char *s, const char *chars, const char *replacement) {
    buf b; buf_init(&b);
    const char *q = s;
    bool first = true;
    while (*q) {
        const char *nl = strchr(q, '\n');
        size_t llen = nl ? (size_t)(nl - q) : strlen(q);
        char *line = xstrndup(q, llen);
        char *after_lead = replace_leading_run(line, chars, replacement);
        free(line);
        char *after_trail = replace_trailing_run(after_lead, chars, replacement);
        free(after_lead);
        if (!first) buf_push(&b, '\n');
        first = false;
        buf_push_str(&b, after_trail, strlen(after_trail));
        free(after_trail);
        if (!nl) break;
        q = nl + 1;
    }
    return b.data ? b.data : xstrdup("");
}

static char *apply_trim_c(const char *s, const char *chars, const char *where, const char *replacement) {
    if (!*chars) return xstrdup(s);
    bool has_star = strchr(where, '*') != NULL;
    bool has_pipe = strchr(where, '|') != NULL;
    bool has_lt = strchr(where, '<') != NULL;
    bool has_gt = strchr(where, '>') != NULL;
    if (!(has_star || has_pipe || has_lt || has_gt)) return xstrdup(s);
    if (has_star) return replace_all_runs(s, chars, replacement);
    char *cur = xstrdup(s);
    if (has_pipe) { char *n = per_line_edges(cur, chars, replacement); free(cur); cur = n; }
    if (has_lt) { char *n = replace_leading_run(cur, chars, replacement); free(cur); cur = n; }
    if (has_gt) { char *n = replace_trailing_run(cur, chars, replacement); free(cur); cur = n; }
    return cur;
}

static int apply_modifiers(const char *s, h_mods *mods, char **out_str, parser *p) {
    char *cur = xstrdup(s);
    for (size_t i = 0; i < mods->len; i++) {
        h_mod *m = &mods->mods[i];
        if (strcmp(m->name, "_fold_paragraphs") == 0) {
            if (m->nargs != 0) { free(cur); return set_err(p, "fold_paragraphs() takes no arguments"); }
            char *next = fold_paragraphs(cur);
            free(cur); cur = next;
        } else if (strcmp(m->name, "_trim") == 0) {
            if (m->nargs < 2 || m->nargs > 3) {
                free(cur); return set_err(p, "trim(chars, where, replacement = \"\") expects 2 or 3 arguments");
            }
            if (m->args[0]->type != DMS_STRING) {
                free(cur); return set_err(p, "trim: first argument (chars) must be a string");
            }
            if (m->args[1]->type != DMS_STRING) {
                free(cur); return set_err(p, "trim: second argument (where) must be a string");
            }
            const char *replacement = "";
            if (m->nargs == 3) {
                if (m->args[2]->type != DMS_STRING) {
                    free(cur); return set_err(p, "trim: third argument (replacement) must be a string");
                }
                replacement = m->args[2]->u.s;
            }
            char *next = apply_trim_c(cur, m->args[0]->u.s, m->args[1]->u.s, replacement);
            free(cur); cur = next;
        } else {
            free(cur); return set_err(p, "unknown modifier: %s", m->name);
        }
    }
    *out_str = cur;
    return 1;
}

/* Build a dms_string_form descriptor from label+flavor+modifiers. Label
   is cloned (unlabeled → NULL); modifier arg values are deep-cloned. */
static dms_string_form *build_heredoc_string_form(
    dms_heredoc_flavor flavor, const char *label, const h_mods *mods)
{
    dms_string_form *sf = (dms_string_form *)calloc(1, sizeof(dms_string_form));
    sf->kind = DMS_STRING_HEREDOC;
    sf->heredoc_flavor = flavor;
    sf->label = (label && label[0]) ? xstrdup(label) : NULL;
    sf->num_modifiers = mods->len;
    if (mods->len > 0) {
        sf->modifiers = (dms_heredoc_modifier_call *)calloc(mods->len, sizeof(dms_heredoc_modifier_call));
        for (size_t i = 0; i < mods->len; i++) {
            sf->modifiers[i].name = xstrdup(mods->mods[i].name);
            sf->modifiers[i].num_args = mods->mods[i].nargs;
            if (mods->mods[i].nargs > 0) {
                sf->modifiers[i].args = (dms_value **)calloc(mods->mods[i].nargs, sizeof(dms_value *));
                for (size_t j = 0; j < mods->mods[i].nargs; j++) {
                    sf->modifiers[i].args[j] = dms_value_clone(mods->mods[i].args[j]);
                }
            }
        }
    }
    return sf;
}

/* SPEC §basic-string escapes: a `\uXXXX` / `\UXXXXXXXX` escape whose
   decoded value falls in the surrogate range U+D800..U+DFFF is not a
   Unicode scalar and is a parse error. The basic-string lexer
   (parse_basic_string_str) already enforces this; basic-heredoc body
   lines are collected raw, so we validate the same rule by scanning
   the body for surrogate escape sequences. Returns 1 on OK, sets the
   parser error and returns 0 on a surrogate escape. */
static int validate_heredoc_basic_surrogates(const h_body *body, parser *p) {
    for (size_t li = 0; li < body->len; li++) {
        const h_line *ln = &body->lines[li];
        const char *text = ln->text;
        size_t tl = strlen(text);
        size_t i = 0;
        while (i < tl) {
            if ((unsigned char)text[i] == '\\') {
                /* find the run of consecutive backslashes starting at i */
                size_t j = i;
                while (j < tl && text[j] == '\\') j++;
                size_t run = j - i;
                /* pairs of `\\` consume themselves; only the last `\` of
                   an odd-length run is an escape introducer. */
                if ((run % 2) == 1 && j < tl) {
                    char intro = text[j];
                    int n = 0;
                    if (intro == 'u') n = 4;
                    else if (intro == 'U') n = 8;
                    if (n > 0 && j + 1 + (size_t)n <= tl) {
                        int all_hex = 1;
                        unsigned cp = 0;
                        for (int k = 0; k < n; k++) {
                            char h = text[j + 1 + k];
                            int d;
                            if (h >= '0' && h <= '9') d = h - '0';
                            else if (h >= 'a' && h <= 'f') d = h - 'a' + 10;
                            else if (h >= 'A' && h <= 'F') d = h - 'A' + 10;
                            else { all_hex = 0; break; }
                            cp = (cp << 4) | (unsigned)d;
                        }
                        if (all_hex && cp >= 0xD800 && cp <= 0xDFFF) {
                            /* column points at the leading `\` of the escape
                               (1-based, byte col). */
                            size_t esc_off = j - 1;
                            return set_err_at(p, ln->line, ln->line_start,
                                              ln->line_start + esc_off,
                                              "surrogate codepoint U+%04X in escape", cp);
                        }
                    }
                }
                i = j;
            } else {
                i++;
            }
        }
    }
    return 1;
}

static dms_value *parse_heredoc_basic(parser *p) {
    p->pos += 3;
    char *label = parse_heredoc_label(p);
    h_mods mods;
    if (!parse_heredoc_modifiers(p, &mods)) { free(label); return NULL; }
    skip_inline_ws(p);
    if (!(consume_eol(p) || eof(p))) {
        hmods_free(&mods); free(label);
        set_err(p, "heredoc opener must be followed by end of line"); return NULL;
    }
    const char *terminator = label[0] ? label : "\"\"\"";
    h_body body;
    if (!collect_heredoc_body(p, terminator, &body)) { hmods_free(&mods); free(label); return NULL; }
    /* SPEC §basic-string escapes: surrogate codepoints (U+D800..U+DFFF)
       are not valid Unicode scalars and are a parse error in `\uXXXX` /
       `\UXXXXXXXX` escapes. Basic-heredoc bodies process the same
       escapes as basic strings, so apply the same rejection here. */
    if (!validate_heredoc_basic_surrogates(&body, p)) {
        hbody_free(&body); hmods_free(&mods); free(label); return NULL;
    }
    char *stripped;
    if (!strip_indent_and_continuations(&body, true, &stripped, p)) { hbody_free(&body); hmods_free(&mods); free(label); return NULL; }
    hbody_free(&body);
    char *final;
    if (!apply_modifiers(stripped, &mods, &final, p)) { free(stripped); hmods_free(&mods); free(label); return NULL; }
    free(stripped);
    /* Record string-form (deep-cloning modifier args) while mods are live. */
    if (p->record_forms) {
        dms_string_form *sf = build_heredoc_string_form(DMS_HEREDOC_BASIC_TRIPLE, label, &mods);
        record_form_string(p, sf);
    }
    hmods_free(&mods); free(label);
    dms_value *v = new_value(DMS_STRING);
    /* SPEC §Unicode normalization: re-NFC after escape decoding. */
    v->u.s = nfc_string(final);
    return v;
}

static dms_value *parse_heredoc_literal(parser *p) {
    p->pos += 3;
    char *label = parse_heredoc_label(p);
    h_mods mods;
    if (!parse_heredoc_modifiers(p, &mods)) { free(label); return NULL; }
    skip_inline_ws(p);
    if (!(consume_eol(p) || eof(p))) {
        hmods_free(&mods); free(label);
        set_err(p, "heredoc opener must be followed by end of line"); return NULL;
    }
    const char *terminator = label[0] ? label : "'''";
    h_body body;
    if (!collect_heredoc_body(p, terminator, &body)) { hmods_free(&mods); free(label); return NULL; }
    char *stripped;
    if (!strip_indent_and_continuations(&body, false, &stripped, p)) { hbody_free(&body); hmods_free(&mods); free(label); return NULL; }
    hbody_free(&body);
    char *final;
    if (!apply_modifiers(stripped, &mods, &final, p)) { free(stripped); hmods_free(&mods); free(label); return NULL; }
    free(stripped);
    if (p->record_forms) {
        dms_string_form *sf = build_heredoc_string_form(DMS_HEREDOC_LITERAL_TRIPLE, label, &mods);
        record_form_string(p, sf);
    }
    hmods_free(&mods); free(label);
    dms_value *v = new_value(DMS_STRING);
    v->u.s = final;
    return v;
}

/* ---------- flow forms ---------- */

static int skip_flow_ws(parser *p) {
    while (1) {
        char c = peek(p);
        if (c == ' ' || c == '\t') p->pos++;
        else if (c == '\n') { p->pos++; advance_line(p); }
        else if (c == '\r' && starts_with(p, "\r\n")) { p->pos += 2; advance_line(p); }
        else if (c == '#') return set_err(p, "comments not allowed inside flow forms");
        else if (c == '/' && starts_with(p, "//")) return set_err(p, "comments not allowed inside flow forms");
        else if (c == '/' && starts_with(p, "/*")) return set_err(p, "comments not allowed inside flow forms");
        else return 1;
    }
}

static dms_value *parse_inline_value_in_flow(parser *p) {
    if (peek(p) == '"' && starts_with(p, "\"\"\"")) { set_err(p, "heredocs are not allowed inside flow forms"); return NULL; }
    if (peek(p) == '\'' && starts_with(p, "'''")) { set_err(p, "heredocs are not allowed inside flow forms"); return NULL; }
    return parse_inline_value_or_heredoc(p);
}

static dms_value *parse_flow_array(parser *p) {
    p->pos++;
    dms_value *out = new_value(DMS_LIST);
    while (1) {
        if (!skip_flow_ws(p)) { dms_free(out); return NULL; }
        if (peek(p) == ']') { p->pos++; return out; }
        /* Push breadcrumb so OriginalLiteral records on the value land at
           the right path. */
        size_t idx = out->u.l.len;
        path_push_index(&p->path, idx);
        dms_value *v = parse_inline_value_in_flow(p);
        path_pop(&p->path);
        if (!v) { dms_free(out); return NULL; }
        list_push(&out->u.l, v);
        if (!skip_flow_ws(p)) { dms_free(out); return NULL; }
        char c = peek(p);
        if (c == ',') p->pos++;
        else if (c == ']') { p->pos++; return out; }
        else if (c == 0) { set_err(p, "unterminated flow array"); dms_free(out); return NULL; }
        else { set_err(p, "unexpected '%c' in flow array; expected ',' or ']'", c); dms_free(out); return NULL; }
    }
}

static dms_value *parse_flow_table(parser *p) {
    p->pos++;
    dms_value *out = new_value(DMS_TABLE);
    while (1) {
        if (!skip_flow_ws(p)) { dms_free(out); return NULL; }
        if (peek(p) == '}') { p->pos++; return out; }
        char *key = parse_key(p);
        if (!key) { dms_free(out); return NULL; }
        if (peek(p) != ':') { free(key); dms_free(out); set_err(p, "expected ':' after flow-table key"); return NULL; }
        p->pos++;
        char c = peek(p);
        if (!(c == ' ' || c == '\t' || c == '\n' || c == '\r')) {
            free(key); dms_free(out); set_err(p, "expected whitespace after ':'"); return NULL;
        }
        if (!skip_flow_ws(p)) { free(key); dms_free(out); return NULL; }
        /* Push breadcrumb so OriginalLiteral records on the value land at
           the right path. */
        path_push_key(&p->path, key);
        dms_value *v = parse_inline_value_in_flow(p);
        path_pop(&p->path);
        if (!v) { free(key); dms_free(out); return NULL; }
        if (dms_table_has(&out->u.t, key)) { set_err(p, "duplicate key: %s", key); free(key); dms_free(v); dms_free(out); return NULL; }
        table_set(&out->u.t, key, v);
        free(key);
        if (!skip_flow_ws(p)) { dms_free(out); return NULL; }
        char c2 = peek(p);
        if (c2 == ',') p->pos++;
        else if (c2 == '}') { p->pos++; return out; }
        else if (c2 == 0) { set_err(p, "unterminated flow table"); dms_free(out); return NULL; }
        else { set_err(p, "unexpected '%c' in flow table; expected ',' or '}'", c2); dms_free(out); return NULL; }
    }
}

/* ---------- inline value dispatcher ---------- */

/* Capture mid-token slash-star block comments and inline whitespace,
   pushing each as `inner` on the current p->path. Caller must have
   pushed the kvpair / list-item breadcrumb. Returns 1 on success. */
static int capture_inner_block_comments(parser *p) {
    while (peek(p) == '/' && starts_with(p, "/*")) {
        char *raw = read_c_block_comment(p);
        if (!raw) return 0;
        if (p->lite) {
            free(raw);
        } else {
            dms_attached_comment ac;
            ac.content = raw;
            ac.kind = DMS_COMMENT_BLOCK;
            ac.position = DMS_COMMENT_INNER;
            ac.path = path_clone(&p->path, &ac.path_len);
            attached_push(&p->comments, ac);
        }
        skip_inline_ws(p);
    }
    return 1;
}

static dms_value *parse_inline_value_or_heredoc(parser *p) {
    /* Inner block comments are captured by the caller via
       capture_inner_block_comments before this function runs. */
    char c = peek(p);
    if (c == '"') {
        if (starts_with(p, "\"\"\"")) return parse_heredoc_basic(p);
        return parse_basic_string(p);
    }
    if (c == '\'') {
        if (starts_with(p, "'''")) return parse_heredoc_literal(p);
        return parse_literal_string(p);
    }
    if (c == '[') return parse_flow_array(p);
    if (c == '{') return parse_flow_table(p);
    if (c == 't' || c == 'f') return parse_bool_v(p);
    if (c == 'i') return parse_inf_v(p);
    if (c == 'n') return parse_nan_v(p);
    if (c == '+' || c == '-' || (c >= '0' && c <= '9')) return parse_number_or_datetime(p);
    if (c == 0) { set_err(p, "expected value"); return NULL; }
    set_err(p, "unexpected character '%c' in value", c);
    return NULL;
}

/* ---------- consume_after_value ---------- */

static int consume_after_value(parser *p, int allow_eof) {
    (void)allow_eof;
    /* Same-line comment(s) after a value attach as `trailing`. Multiple
       block comments may stack; a `#`/`//` line comment, if present,
       consumes to EOL and must come last. */
    while (1) {
        size_t ws_start = p->pos;
        skip_inline_ws(p);
        bool had_ws = p->pos > ws_start;
        char c = peek(p);
        char *raw = NULL;
        dms_comment_kind tkind = DMS_COMMENT_LINE;
        bool is_line = false;
        if (c == '#' && !starts_with(p, "###")) {
            if (!had_ws) return set_err(p, "expected whitespace before '#' comment");
            raw = read_line_comment_to_eol(p);
            tkind = DMS_COMMENT_LINE;
            is_line = true;
        } else if (c == '/' && starts_with(p, "//")) {
            if (!had_ws) return set_err(p, "expected whitespace before '//' comment");
            raw = read_line_comment_to_eol(p);
            tkind = DMS_COMMENT_LINE;
            is_line = true;
        } else if (c == '/' && starts_with(p, "/*")) {
            raw = read_c_block_comment(p);
            if (!raw) return 0;
            tkind = DMS_COMMENT_BLOCK;
        } else {
            break;
        }
        if (p->lite) {
            free(raw);
        } else {
            dms_attached_comment ac;
            ac.content = raw;
            ac.kind = tkind;
            ac.position = DMS_COMMENT_TRAILING;
            ac.path = path_clone(&p->path, &ac.path_len);
            attached_push(&p->comments, ac);
        }
        if (is_line) break; /* line comment consumes to EOL */
    }
    char c2 = peek(p);
    if (c2 == 0) return 1;
    if (c2 == '\n') { p->pos++; advance_line(p); return 1; }
    if (c2 == '\r' && starts_with(p, "\r\n")) { p->pos += 2; advance_line(p); return 1; }
    return set_err(p, "unexpected character '%c' after value", c2);
}

/* ========================================================================
 *                         encode emitter (SPEC §encode)
 * ======================================================================*/

typedef struct {
    const dms_breadcrumb_seg *path;
    size_t path_len;
    const dms_attached_comment *ac;   /* used for comment entries */
    const dms_original_literal *lit;  /* used for original-form entries */
} emit_entry;

typedef struct {
    buf out;
    /* Sorted indices into doc->comments for O(log n) path lookup. */
    const dms_document *doc;
    size_t *comments_sorted;  /* sorted index array; length == doc->num_comments */
    size_t *forms_sorted;     /* sorted index array; length == doc->num_original_forms */
    /* Single shared, growable breadcrumb buffer reused across the entire
       walk — mirrors the recursive call stack (push on entry, implicit
       pop on return). Replaces the per-kvpair malloc/memcpy/free that
       used to dominate emit cost on wide configs. */
    dms_breadcrumb_seg *path_buf;
    size_t path_buf_cap;
    /* Lite mode (canonical-form emit) — drops comments and consults no
       original-form records, even when present in `doc`. Mirrors the
       Rust DmsEmitter::lite field. SPEC §encode. */
    bool lite;
} emitter;

/* ---- path comparison ---- */

static int cmp_breadcrumb_seg(const dms_breadcrumb_seg *a, const dms_breadcrumb_seg *b) {
    /* Order: keys before indices, then lex/numerical within category.
       Any total ordering works so long as equal paths group together. */
    if (a->is_index != b->is_index) {
        return a->is_index ? 1 : -1;
    }
    if (a->is_index) {
        if (a->idx < b->idx) return -1;
        if (a->idx > b->idx) return 1;
        return 0;
    }
    return strcmp(a->key, b->key);
}

static int cmp_path(const dms_breadcrumb_seg *a, size_t al,
                    const dms_breadcrumb_seg *b, size_t bl) {
    size_t n = al < bl ? al : bl;
    for (size_t i = 0; i < n; i++) {
        int c = cmp_breadcrumb_seg(&a[i], &b[i]);
        if (c != 0) return c;
    }
    if (al < bl) return -1;
    if (al > bl) return 1;
    return 0;
}

/* ---- sort helpers (stable merge sort over indices). Comments and
        forms can reach 30k+ entries on real configs; the previous
        insertion-sort fallback was O(n²) and dominated `encode` cost
        on the comment-heavy bench fixture. Merge sort keeps the
        stability the leading-comment ordering / modifier args rely
        on (qsort is not guaranteed stable per C99). ---- */

typedef struct {
    const dms_document *doc;
    int is_form;     /* 0 = comments, 1 = forms */
} sort_ctx;

static int compare_idx(sort_ctx ctx, size_t ia, size_t ib) {
    if (ctx.is_form) {
        const dms_original_form_entry *a = &ctx.doc->original_forms[ia];
        const dms_original_form_entry *b = &ctx.doc->original_forms[ib];
        return cmp_path(a->path, a->path_len, b->path, b->path_len);
    } else {
        const dms_attached_comment *a = &ctx.doc->comments[ia];
        const dms_attached_comment *b = &ctx.doc->comments[ib];
        return cmp_path(a->path, a->path_len, b->path, b->path_len);
    }
}

/* Stable bottom-up merge sort over the index array. Stability matters
   for leading-comment ordering and for multiple-modifier args: entries
   with equal paths must keep their original insertion order. */
static void sort_indices(size_t *arr, size_t n, sort_ctx ctx) {
    if (n < 2) return;
    /* Insertion-sort fallback for small inputs avoids the buffer alloc
       cost. Threshold of 16 matches typical libc quadsort/timsort. */
    if (n < 16) {
        for (size_t i = 1; i < n; i++) {
            size_t cur = arr[i];
            size_t j = i;
            while (j > 0 && compare_idx(ctx, arr[j - 1], cur) > 0) {
                arr[j] = arr[j - 1];
                j--;
            }
            arr[j] = cur;
        }
        return;
    }
    size_t *tmp = (size_t *)malloc(n * sizeof(size_t));
    if (!tmp) {
        /* OOM fallback: degrade to insertion sort. Slow but correct. */
        for (size_t i = 1; i < n; i++) {
            size_t cur = arr[i];
            size_t j = i;
            while (j > 0 && compare_idx(ctx, arr[j - 1], cur) > 0) {
                arr[j] = arr[j - 1];
                j--;
            }
            arr[j] = cur;
        }
        return;
    }
    /* Bottom-up merge: width doubles each pass. Stable because we
       break ties by taking the left run first. */
    for (size_t width = 1; width < n; width *= 2) {
        for (size_t i = 0; i < n; i += 2 * width) {
            size_t left = i;
            size_t mid  = (i + width < n) ? i + width : n;
            size_t right = (i + 2 * width < n) ? i + 2 * width : n;
            size_t l = left, r = mid, k = left;
            while (l < mid && r < right) {
                /* `<= 0` keeps the left run first on tie → stable. */
                if (compare_idx(ctx, arr[l], arr[r]) <= 0) tmp[k++] = arr[l++];
                else                                       tmp[k++] = arr[r++];
            }
            while (l < mid)   tmp[k++] = arr[l++];
            while (r < right) tmp[k++] = arr[r++];
        }
        /* Copy this pass's output back into arr for the next round. */
        for (size_t i = 0; i < n; i++) arr[i] = tmp[i];
    }
    free(tmp);
}

/* Return the index of the first entry in sorted-array whose path
   equals `(path, path_len)`, or SIZE_MAX when none. */
static size_t find_first_match(const emitter *e, int is_form,
                               const dms_breadcrumb_seg *path, size_t path_len)
{
    size_t *arr;
    size_t n;
    if (is_form) { arr = e->forms_sorted; n = e->doc->num_original_forms; }
    else          { arr = e->comments_sorted; n = e->doc->num_comments; }
    /* In lite mode (or when there's nothing of this kind) `arr` is
       NULL — short-circuit so the binary search doesn't dereference it. */
    if (arr == NULL) return (size_t)-1;
    size_t lo = 0, hi = n;
    while (lo < hi) {
        size_t mid = lo + (hi - lo) / 2;
        const dms_breadcrumb_seg *mp;
        size_t ml;
        if (is_form) {
            mp = e->doc->original_forms[arr[mid]].path;
            ml = e->doc->original_forms[arr[mid]].path_len;
        } else {
            mp = e->doc->comments[arr[mid]].path;
            ml = e->doc->comments[arr[mid]].path_len;
        }
        int c = cmp_path(mp, ml, path, path_len);
        if (c < 0) lo = mid + 1;
        else hi = mid;
    }
    if (lo < n) {
        const dms_breadcrumb_seg *mp;
        size_t ml;
        if (is_form) {
            mp = e->doc->original_forms[arr[lo]].path;
            ml = e->doc->original_forms[arr[lo]].path_len;
        } else {
            mp = e->doc->comments[arr[lo]].path;
            ml = e->doc->comments[arr[lo]].path_len;
        }
        if (cmp_path(mp, ml, path, path_len) == 0) return lo;
    }
    return (size_t)-1;
}

/* ---- emitter basics ---- */

static void emit_push(emitter *e, const char *s) { buf_push_str(&e->out, s, strlen(s)); }
static void emit_push_ch(emitter *e, char c) { buf_push(&e->out, c); }
static void emit_push_n(emitter *e, const char *s, size_t n) { buf_push_str(&e->out, s, n); }

static void emit_indent(emitter *e, size_t indent) {
    for (size_t i = 0; i < indent; i++) emit_push(e, "  ");
}

/* Shortest-decimal float formatting (as used by encoder.c's tagged JSON). */
static void emit_shortest_float(emitter *e, double v) {
    if (v != v) { emit_push(e, "nan"); return; }
    if (v > 1e308 || v < -1e308 || v == INFINITY || v == -INFINITY) {
        /* Use isinf-equivalent */
    }
    /* Rust ryu produces shortest "round-trip" form. We approximate with
       increasing precision until round-trip succeeds. */
    if (v == v && (v > 1e308 || v < -1e308)) {
        /* isinf fallback — compared against IEEE infinities */
    }
    /* Direct isinf via <math.h>: but we avoid the macro to match
       encoder.c's style. Use *trip* via p test. */
    /* nan/inf handled below (no std macros to avoid conflicts). */
    {
        double inf = INFINITY;
        if (v == inf) { emit_push(e, "inf"); return; }
        if (v == -inf) { emit_push(e, "-inf"); return; }
    }
    char buf64[64];
    int found = 0;
    for (int p = 1; p <= 17; p++) {
        snprintf(buf64, sizeof buf64, "%.*g", p, v);
        double r = atof(buf64);
        if (r == v) { found = 1; break; }
    }
    if (!found) snprintf(buf64, sizeof buf64, "%.17g", v);
    /* Normalize exponent form: "1e+10" -> "1e10"; "1e-05" -> "1e-5". */
    char norm[64];
    char *src = buf64;
    char *dst = norm;
    while (*src) {
        if (*src == 'e') {
            *dst++ = *src++;
            if (*src == '+') src++;
            if (*src == '-') *dst++ = *src++;
            while (*src == '0' && src[1] != 0) src++;
            while (*src) *dst++ = *src++;
            break;
        }
        *dst++ = *src++;
    }
    *dst = 0;
    if (!strchr(norm, '.') && !strchr(norm, 'e') && !strchr(norm, 'n') && !strchr(norm, 'i')) {
        size_t ln = strlen(norm);
        norm[ln] = '.'; norm[ln+1] = '0'; norm[ln+2] = 0;
    }
    emit_push(e, norm);
}

/* ---- key / string formatting helpers ---- */

static bool key_is_bare(const char *k) {
    if (!k || !*k) return false;
    for (const unsigned char *q = (const unsigned char *)k; *q; ) {
        if (*q < 0x80) {
            if (!is_bare_key_char_ascii(*q)) return false;
            q++;
        } else {
            size_t clen;
            int cp = utf8_decode((const char *)q, strlen((const char *)q), &clen);
            if (cp < 0 || !is_bare_key_char_cp(cp)) return false;
            q += clen;
        }
    }
    return true;
}

static void emit_escape_basic(emitter *e, const char *s) {
    for (const unsigned char *q = (const unsigned char *)s; *q; q++) {
        unsigned char c = *q;
        if (c == '\\') emit_push(e, "\\\\");
        else if (c == '"') emit_push(e, "\\\"");
        else if (c == '\n') emit_push(e, "\\n");
        else if (c == '\r') emit_push(e, "\\r");
        else if (c == '\t') emit_push(e, "\\t");
        else if (c == '\b') emit_push(e, "\\b");
        else if (c == '\f') emit_push(e, "\\f");
        else if (c < 0x20) {
            char tmp[8];
            snprintf(tmp, sizeof tmp, "\\u%04X", c);
            emit_push(e, tmp);
        } else {
            emit_push_ch(e, (char)c);
        }
    }
}

static void emit_format_key(emitter *e, const char *k) {
    if (key_is_bare(k)) {
        emit_push(e, k);
        return;
    }
    bool has_sq = strchr(k, '\'') != NULL;
    bool has_nl = strchr(k, '\n') != NULL || strchr(k, '\r') != NULL;
    if (!has_sq && !has_nl) {
        emit_push_ch(e, '\'');
        emit_push(e, k);
        emit_push_ch(e, '\'');
    } else {
        emit_push_ch(e, '"');
        emit_escape_basic(e, k);
        emit_push_ch(e, '"');
    }
}

/* ---- forward decls ---- */

static void emit_document_body(emitter *e);
static void emit_table_block(emitter *e, const dms_table *t,
                             const dms_breadcrumb_seg *path, size_t path_len,
                             size_t indent);
static void emit_list_block(emitter *e, const dms_list *l,
                            const dms_breadcrumb_seg *path, size_t path_len,
                            size_t indent);
static void emit_value_inline(emitter *e, const dms_value *v,
                              const dms_breadcrumb_seg *path, size_t path_len);
static void emit_integer(emitter *e, int64_t n,
                         const dms_breadcrumb_seg *path, size_t path_len);
static void emit_string(emitter *e, const char *s,
                        const dms_breadcrumb_seg *path, size_t path_len);
static void emit_heredoc(emitter *e, const char *body,
                         dms_heredoc_flavor flavor, const char *label,
                         const dms_heredoc_modifier_call *mods, size_t nmods);
static void emit_modifier_arg(emitter *e, const dms_value *v);
static void emit_comment_line(emitter *e, const dms_attached_comment *ac, size_t indent);
static void emit_trailing_for(emitter *e, const dms_breadcrumb_seg *path, size_t path_len);
static void emit_floating_for(emitter *e, const dms_breadcrumb_seg *path, size_t path_len, size_t indent);
static void emit_leading_for(emitter *e, const dms_breadcrumb_seg *path, size_t path_len, size_t indent);
static bool has_trailing_for(const emitter *e, const dms_breadcrumb_seg *path, size_t path_len);
static bool is_flow_safe(const emitter *e, const dms_value *v,
                         const dms_breadcrumb_seg *path, size_t path_len);
static const dms_original_literal *find_form(const emitter *e,
                                             const dms_breadcrumb_seg *path, size_t path_len);

/* Build + sort index arrays. In lite mode, both lookup arrays are
   left NULL so every `find_first_match` short-circuits — comments are
   dropped, integer base / string flavor fall back to canonical form. */
static void emitter_init(emitter *e, const dms_document *doc, bool lite) {
    buf_init(&e->out);
    buf_ensure(&e->out, 64 * 1024);  /* pre-size: skip realloc cascade on typical-sized configs */
    e->doc = doc;
    e->comments_sorted = NULL;
    e->forms_sorted = NULL;
    e->path_buf = NULL;
    e->path_buf_cap = 0;
    e->lite = lite;
    if (lite) return;
    if (doc->num_comments > 0) {
        e->comments_sorted = (size_t *)malloc(doc->num_comments * sizeof(size_t));
        for (size_t i = 0; i < doc->num_comments; i++) e->comments_sorted[i] = i;
        sort_ctx ctx; ctx.doc = doc; ctx.is_form = 0;
        sort_indices(e->comments_sorted, doc->num_comments, ctx);
    }
    if (doc->num_original_forms > 0) {
        e->forms_sorted = (size_t *)malloc(doc->num_original_forms * sizeof(size_t));
        for (size_t i = 0; i < doc->num_original_forms; i++) e->forms_sorted[i] = i;
        sort_ctx ctx; ctx.doc = doc; ctx.is_form = 1;
        sort_indices(e->forms_sorted, doc->num_original_forms, ctx);
    }
}

static void emitter_free(emitter *e) {
    free(e->comments_sorted);
    free(e->forms_sorted);
    free(e->path_buf);
}

/* Grow the shared breadcrumb buffer to fit at least `need` segments.
   Used by emit_table_block / emit_list_block / emit_value_inline so they
   no longer malloc/free a fresh path per kvpair. */
static void path_ensure(emitter *e, size_t need) {
    if (need <= e->path_buf_cap) return;
    size_t newcap = e->path_buf_cap ? e->path_buf_cap * 2 : 16;
    while (newcap < need) newcap *= 2;
    e->path_buf = (dms_breadcrumb_seg *)xrealloc(e->path_buf, newcap * sizeof(dms_breadcrumb_seg));
    e->path_buf_cap = newcap;
}

/* Look up the first OriginalLiteral whose path equals (path, path_len). */
static const dms_original_literal *find_form(const emitter *e,
                                             const dms_breadcrumb_seg *path, size_t path_len) {
    size_t idx = find_first_match(e, 1, path, path_len);
    if (idx == (size_t)-1) return NULL;
    size_t src_idx = e->forms_sorted[idx];
    return &e->doc->original_forms[src_idx].lit;
}

/* ---- comment helpers ---- */

static bool has_trailing_for(const emitter *e, const dms_breadcrumb_seg *path, size_t path_len) {
    size_t first = find_first_match(e, 0, path, path_len);
    if (first == (size_t)-1) return false;
    for (size_t i = first; i < e->doc->num_comments; i++) {
        const dms_attached_comment *ac = &e->doc->comments[e->comments_sorted[i]];
        if (cmp_path(ac->path, ac->path_len, path, path_len) != 0) break;
        if (ac->position == DMS_COMMENT_TRAILING) return true;
    }
    return false;
}

static void emit_leading_for(emitter *e, const dms_breadcrumb_seg *path, size_t path_len, size_t indent) {
    size_t first = find_first_match(e, 0, path, path_len);
    if (first == (size_t)-1) return;
    for (size_t i = first; i < e->doc->num_comments; i++) {
        const dms_attached_comment *ac = &e->doc->comments[e->comments_sorted[i]];
        if (cmp_path(ac->path, ac->path_len, path, path_len) != 0) break;
        if (ac->position == DMS_COMMENT_LEADING) {
            emit_comment_line(e, ac, indent);
        }
    }
}

static void emit_trailing_for(emitter *e, const dms_breadcrumb_seg *path, size_t path_len) {
    size_t first = find_first_match(e, 0, path, path_len);
    if (first == (size_t)-1) return;
    bool first_emit = true;
    for (size_t i = first; i < e->doc->num_comments; i++) {
        const dms_attached_comment *ac = &e->doc->comments[e->comments_sorted[i]];
        if (cmp_path(ac->path, ac->path_len, path, path_len) != 0) break;
        if (ac->position == DMS_COMMENT_TRAILING) {
            emit_push(e, first_emit ? "  " : " ");
            first_emit = false;
            emit_push(e, ac->content);
        }
    }
}

static void emit_inner_for(emitter *e, const dms_breadcrumb_seg *path, size_t path_len) {
    size_t first = find_first_match(e, 0, path, path_len);
    if (first == (size_t)-1) return;
    for (size_t i = first; i < e->doc->num_comments; i++) {
        const dms_attached_comment *ac = &e->doc->comments[e->comments_sorted[i]];
        if (cmp_path(ac->path, ac->path_len, path, path_len) != 0) break;
        if (ac->position == DMS_COMMENT_INNER) {
            emit_push(e, ac->content);
            emit_push_ch(e, ' ');
        }
    }
}

static bool has_inner_for(const emitter *e, const dms_breadcrumb_seg *path, size_t path_len) {
    size_t first = find_first_match(e, 0, path, path_len);
    if (first == (size_t)-1) return false;
    for (size_t i = first; i < e->doc->num_comments; i++) {
        const dms_attached_comment *ac = &e->doc->comments[e->comments_sorted[i]];
        if (cmp_path(ac->path, ac->path_len, path, path_len) != 0) break;
        if (ac->position == DMS_COMMENT_INNER) return true;
    }
    return false;
}

static void emit_floating_for(emitter *e, const dms_breadcrumb_seg *path, size_t path_len, size_t indent) {
    size_t first = find_first_match(e, 0, path, path_len);
    if (first == (size_t)-1) return;
    for (size_t i = first; i < e->doc->num_comments; i++) {
        const dms_attached_comment *ac = &e->doc->comments[e->comments_sorted[i]];
        if (cmp_path(ac->path, ac->path_len, path, path_len) != 0) break;
        if (ac->position == DMS_COMMENT_FLOATING) {
            emit_comment_line(e, ac, indent);
        }
    }
}

static void emit_comment_line(emitter *e, const dms_attached_comment *ac, size_t indent) {
    const char *text = ac->content;
    if (!strchr(text, '\n')) {
        emit_indent(e, indent);
        emit_push(e, text);
        emit_push_ch(e, '\n');
        return;
    }
    /* Multi-line block comment: only the first line gets re-indented;
       the rest preserve stored indentation verbatim. */
    bool first = true;
    const char *q = text;
    while (1) {
        const char *nl = strchr(q, '\n');
        size_t llen = nl ? (size_t)(nl - q) : strlen(q);
        if (!first) emit_push_ch(e, '\n');
        if (first) {
            emit_indent(e, indent);
            first = false;
        }
        emit_push_n(e, q, llen);
        if (!nl) break;
        q = nl + 1;
    }
    emit_push_ch(e, '\n');
}

/* ---- flow-safe predicate ---- */

static bool path_is_descendant(const dms_breadcrumb_seg *child, size_t cl,
                               const dms_breadcrumb_seg *parent, size_t pl) {
    if (cl <= pl) return false;
    for (size_t i = 0; i < pl; i++) {
        if (cmp_breadcrumb_seg(&child[i], &parent[i]) != 0) return false;
    }
    return true;
}

static bool is_flow_safe(const emitter *e, const dms_value *v,
                         const dms_breadcrumb_seg *path, size_t path_len) {
    /* Any descendant with a comment → unsafe. Skipped in lite mode
       where comments are dropped on output. */
    if (!e->lite) {
        for (size_t i = 0; i < e->doc->num_comments; i++) {
            const dms_attached_comment *ac = &e->doc->comments[i];
            if (path_is_descendant(ac->path, ac->path_len, path, path_len)) return false;
        }
    }
    switch (v->type) {
    case DMS_STRING: {
        const dms_original_literal *lit = find_form(e, path, path_len);
        if (lit && lit->is_string_form && lit->string_form
            && lit->string_form->kind == DMS_STRING_HEREDOC) {
            return false;
        }
        return true;
    }
    case DMS_LIST:
        for (size_t i = 0; i < v->u.l.len; i++) {
            dms_breadcrumb_seg *sub = (dms_breadcrumb_seg *)malloc((path_len + 1) * sizeof(dms_breadcrumb_seg));
            for (size_t j = 0; j < path_len; j++) sub[j] = path[j];
            sub[path_len].is_index = 1;
            sub[path_len].key = NULL;
            sub[path_len].idx = i;
            bool ok = is_flow_safe(e, v->u.l.items[i], sub, path_len + 1);
            free(sub);
            if (!ok) return false;
        }
        return true;
    case DMS_TABLE:
        for (size_t i = 0; i < v->u.t.len; i++) {
            dms_breadcrumb_seg *sub = (dms_breadcrumb_seg *)malloc((path_len + 1) * sizeof(dms_breadcrumb_seg));
            for (size_t j = 0; j < path_len; j++) sub[j] = path[j];
            sub[path_len].is_index = 0;
            sub[path_len].key = v->u.t.items[i].key;
            sub[path_len].idx = 0;
            bool ok = is_flow_safe(e, v->u.t.items[i].value, sub, path_len + 1);
            free(sub);
            if (!ok) return false;
        }
        return true;
    default:
        return true;
    }
}

/* ---- value emission ---- */

static void emit_integer(emitter *e, int64_t n,
                         const dms_breadcrumb_seg *path, size_t path_len) {
    const dms_original_literal *lit = find_form(e, path, path_len);
    if (lit && !lit->is_string_form && lit->integer_lit) {
        emit_push(e, lit->integer_lit);
        return;
    }
    char buf32[32];
    snprintf(buf32, sizeof buf32, "%lld", (long long)n);
    emit_push(e, buf32);
}

static void emit_string(emitter *e, const char *s,
                        const dms_breadcrumb_seg *path, size_t path_len) {
    const dms_original_literal *lit = find_form(e, path, path_len);
    dms_string_kind kind = DMS_STRING_BASIC;
    dms_string_form *sf = NULL;
    if (lit && lit->is_string_form && lit->string_form) {
        sf = lit->string_form;
        kind = sf->kind;
    }
    switch (kind) {
    case DMS_STRING_BASIC:
        emit_push_ch(e, '"');
        emit_escape_basic(e, s);
        emit_push_ch(e, '"');
        return;
    case DMS_STRING_LITERAL:
        emit_push_ch(e, '\'');
        emit_push(e, s);
        emit_push_ch(e, '\'');
        return;
    case DMS_STRING_HEREDOC: {
        /* If any modifier is `_fold_paragraphs`, pre-expand each `\n` to
           `\n\n` so round-trip re-applies don't merge separate lines. */
        bool has_fold = false;
        for (size_t i = 0; i < sf->num_modifiers; i++) {
            if (strcmp(sf->modifiers[i].name, "_fold_paragraphs") == 0) {
                has_fold = true; break;
            }
        }
        char *body_owned = NULL;
        const char *body;
        if (has_fold) {
            /* Replace each \n with \n\n. */
            size_t nln = 0;
            for (const char *q = s; *q; q++) if (*q == '\n') nln++;
            size_t ln = strlen(s);
            body_owned = (char *)malloc(ln + nln + 1);
            char *dst = body_owned;
            for (const char *q = s; *q; q++) {
                *dst++ = *q;
                if (*q == '\n') *dst++ = '\n';
            }
            *dst = 0;
            body = body_owned;
        } else {
            body = s;
        }
        emit_heredoc(e, body, sf->heredoc_flavor, sf->label, sf->modifiers, sf->num_modifiers);
        free(body_owned);
        return;
    }
    }
}

static void emit_heredoc(emitter *e, const char *body,
                         dms_heredoc_flavor flavor, const char *label,
                         const dms_heredoc_modifier_call *mods, size_t nmods) {
    /* Determine current line's leading-space count by scanning from the
       last newline in the output. The caller has emitted up to and
       including the ": " / "+ " prefix, so this tells us the kvpair's
       indent. */
    size_t kv_indent_spaces;
    {
        size_t i = e->out.len;
        while (i > 0 && e->out.data[i - 1] != '\n') i--;
        size_t k = i;
        size_t n = 0;
        while (k < e->out.len && e->out.data[k] == ' ') { n++; k++; }
        kv_indent_spaces = n;
    }
    size_t body_indent_n = kv_indent_spaces + 2;  /* 2-space indent */
    /* Opener */
    emit_push(e, flavor == DMS_HEREDOC_BASIC_TRIPLE ? "\"\"\"" : "'''");
    if (label) emit_push(e, label);
    for (size_t i = 0; i < nmods; i++) {
        emit_push_ch(e, ' ');
        emit_push(e, mods[i].name);
        emit_push_ch(e, '(');
        for (size_t j = 0; j < mods[i].num_args; j++) {
            if (j > 0) emit_push(e, ", ");
            emit_modifier_arg(e, mods[i].args[j]);
        }
        emit_push_ch(e, ')');
    }
    emit_push_ch(e, '\n');
    /* Body */
    if (*body) {
        const char *q = body;
        while (1) {
            const char *nl = strchr(q, '\n');
            size_t llen = nl ? (size_t)(nl - q) : strlen(q);
            if (llen == 0) {
                emit_push_ch(e, '\n');
            } else {
                for (size_t si = 0; si < body_indent_n; si++) emit_push_ch(e, ' ');
                emit_push_n(e, q, llen);
                emit_push_ch(e, '\n');
            }
            if (!nl) break;
            q = nl + 1;
        }
    }
    /* Terminator (indented, same column as body) */
    for (size_t si = 0; si < body_indent_n; si++) emit_push_ch(e, ' ');
    if (label) {
        emit_push(e, label);
    } else {
        emit_push(e, flavor == DMS_HEREDOC_BASIC_TRIPLE ? "\"\"\"" : "'''");
    }
    /* Caller appends trailing/newline. */
}

static void emit_modifier_arg(emitter *e, const dms_value *v) {
    char buf32[64];
    switch (v->type) {
    case DMS_BOOL:
        emit_push(e, v->u.b ? "true" : "false");
        return;
    case DMS_INTEGER:
        snprintf(buf32, sizeof buf32, "%lld", (long long)v->u.i);
        emit_push(e, buf32);
        return;
    case DMS_FLOAT:
        emit_shortest_float(e, v->u.f);
        return;
    case DMS_STRING:
        emit_push_ch(e, '"');
        emit_escape_basic(e, v->u.s);
        emit_push_ch(e, '"');
        return;
    case DMS_OFFSET_DT:
    case DMS_LOCAL_DT:
    case DMS_LOCAL_DATE:
    case DMS_LOCAL_TIME:
        emit_push(e, v->u.s);
        return;
    case DMS_LIST:
        emit_push(e, "[]");
        return;
    case DMS_TABLE:
        emit_push(e, "{}");
        return;
    }
}

static void emit_value_inline(emitter *e, const dms_value *v,
                              const dms_breadcrumb_seg *path, size_t path_len) {
    switch (v->type) {
    case DMS_BOOL:
        emit_push(e, v->u.b ? "true" : "false");
        return;
    case DMS_INTEGER:
        emit_integer(e, v->u.i, path, path_len);
        return;
    case DMS_FLOAT:
        emit_shortest_float(e, v->u.f);
        return;
    case DMS_STRING:
        emit_string(e, v->u.s, path, path_len);
        return;
    case DMS_OFFSET_DT:
    case DMS_LOCAL_DT:
    case DMS_LOCAL_DATE:
    case DMS_LOCAL_TIME:
        emit_push(e, v->u.s);
        return;
    case DMS_LIST:
        if (v->u.l.len == 0) { emit_push(e, "[]"); return; }
        emit_push_ch(e, '[');
        {
            /* Same shared-path-buf trick as emit_table_block. */
            bool is_recursive = (path == e->path_buf);
            path_ensure(e, path_len + 1);
            if (!is_recursive) {
                for (size_t j = 0; j < path_len; j++) e->path_buf[j] = path[j];
            }
            for (size_t i = 0; i < v->u.l.len; i++) {
                if (i > 0) emit_push(e, ", ");
                e->path_buf[path_len].is_index = 1;
                e->path_buf[path_len].key = NULL;
                e->path_buf[path_len].idx = i;
                emit_value_inline(e, v->u.l.items[i], e->path_buf, path_len + 1);
            }
        }
        emit_push_ch(e, ']');
        return;
    case DMS_TABLE:
        if (v->u.t.len == 0) { emit_push(e, "{}"); return; }
        emit_push_ch(e, '{');
        {
            bool is_recursive = (path == e->path_buf);
            path_ensure(e, path_len + 1);
            if (!is_recursive) {
                for (size_t j = 0; j < path_len; j++) e->path_buf[j] = path[j];
            }
            for (size_t i = 0; i < v->u.t.len; i++) {
                if (i > 0) emit_push(e, ", ");
                emit_format_key(e, v->u.t.items[i].key);
                emit_push(e, ": ");
                e->path_buf[path_len].is_index = 0;
                e->path_buf[path_len].key = v->u.t.items[i].key;
                e->path_buf[path_len].idx = 0;
                emit_value_inline(e, v->u.t.items[i].value, e->path_buf, path_len + 1);
            }
        }
        emit_push_ch(e, '}');
        return;
    }
}

static void emit_table_block(emitter *e, const dms_table *t,
                             const dms_breadcrumb_seg *path, size_t path_len,
                             size_t indent) {
    /* Copy externally-passed path into the shared path_buf once. Recursive
       calls already pass e->path_buf so this becomes a no-op for them.
       Detection must happen BEFORE path_ensure (which may move e->path_buf). */
    bool is_recursive = (path == e->path_buf);
    path_ensure(e, path_len + 1);
    if (!is_recursive) {
        for (size_t j = 0; j < path_len; j++) e->path_buf[j] = path[j];
    }
    for (size_t i = 0; i < t->len; i++) {
        const char *k = t->items[i].key;
        const dms_value *v = t->items[i].value;
        e->path_buf[path_len].is_index = 0;
        e->path_buf[path_len].key = (char *)k;  /* const-safe: cmp only reads */
        e->path_buf[path_len].idx = 0;
        emit_leading_for(e, e->path_buf, path_len + 1, indent);
        bool is_nonempty_table = (v->type == DMS_TABLE && v->u.t.len > 0);
        bool is_nonempty_list = (v->type == DMS_LIST && v->u.l.len > 0);
        bool can_block = is_nonempty_table || is_nonempty_list;
        bool has_trailing = has_trailing_for(e, e->path_buf, path_len + 1);
        bool has_inner = has_inner_for(e, e->path_buf, path_len + 1);
        bool needs_block = can_block && !(has_trailing && is_flow_safe(e, v, e->path_buf, path_len + 1));
        emit_indent(e, indent);
        emit_format_key(e, k);
        emit_push_ch(e, ':');
        if (needs_block) {
            if (has_inner) {
                emit_push_ch(e, ' ');
                emit_inner_for(e, e->path_buf, path_len + 1);
                /* trim trailing space left by emit_inner_for */
                if (e->out.len > 0 && e->out.data[e->out.len - 1] == ' ') {
                    e->out.len--;
                    e->out.data[e->out.len] = '\0';
                }
            }
            emit_push_ch(e, '\n');
            if (v->type == DMS_TABLE) emit_table_block(e, &v->u.t, e->path_buf, path_len + 1, indent + 1);
            else emit_list_block(e, &v->u.l, e->path_buf, path_len + 1, indent + 1);
        } else {
            emit_push_ch(e, ' ');
            emit_inner_for(e, e->path_buf, path_len + 1);
            emit_value_inline(e, v, e->path_buf, path_len + 1);
            emit_trailing_for(e, e->path_buf, path_len + 1);
            emit_push_ch(e, '\n');
        }
    }
    emit_floating_for(e, e->path_buf, path_len, indent);
}

static void emit_list_block(emitter *e, const dms_list *l,
                            const dms_breadcrumb_seg *path, size_t path_len,
                            size_t indent) {
    /* Same shared-path-buf trick as emit_table_block — see comment there. */
    bool is_recursive = (path == e->path_buf);
    path_ensure(e, path_len + 1);
    if (!is_recursive) {
        for (size_t j = 0; j < path_len; j++) e->path_buf[j] = path[j];
    }
    for (size_t i = 0; i < l->len; i++) {
        const dms_value *v = l->items[i];
        e->path_buf[path_len].is_index = 1;
        e->path_buf[path_len].key = NULL;
        e->path_buf[path_len].idx = i;
        emit_leading_for(e, e->path_buf, path_len + 1, indent);
        emit_indent(e, indent);
        emit_push_ch(e, '+');
        bool has_inner = has_inner_for(e, e->path_buf, path_len + 1);
        if (v->type == DMS_TABLE && v->u.t.len > 0) {
            if (has_inner) {
                emit_push_ch(e, ' ');
                emit_inner_for(e, e->path_buf, path_len + 1);
                if (e->out.len > 0 && e->out.data[e->out.len - 1] == ' ') {
                    e->out.len--;
                    e->out.data[e->out.len] = '\0';
                }
            }
            emit_trailing_for(e, e->path_buf, path_len + 1);
            emit_push_ch(e, '\n');
            emit_table_block(e, &v->u.t, e->path_buf, path_len + 1, indent + 1);
        } else if (v->type == DMS_LIST && v->u.l.len > 0) {
            if (has_inner) {
                emit_push_ch(e, ' ');
                emit_inner_for(e, e->path_buf, path_len + 1);
                if (e->out.len > 0 && e->out.data[e->out.len - 1] == ' ') {
                    e->out.len--;
                    e->out.data[e->out.len] = '\0';
                }
            }
            emit_trailing_for(e, e->path_buf, path_len + 1);
            emit_push_ch(e, '\n');
            emit_list_block(e, &v->u.l, e->path_buf, path_len + 1, indent + 1);
        } else {
            emit_push_ch(e, ' ');
            emit_inner_for(e, e->path_buf, path_len + 1);
            emit_value_inline(e, v, e->path_buf, path_len + 1);
            emit_trailing_for(e, e->path_buf, path_len + 1);
            emit_push_ch(e, '\n');
        }
    }
    emit_floating_for(e, e->path_buf, path_len, indent);
}

static void emit_document_body(emitter *e) {
    /* Front matter: emit `+++\n...\n+++\n` when meta is non-NULL or any
       comment is attached under `__fm__`. */
    bool fm_present = (e->doc->meta != NULL);
    bool has_fm_comments = false;
    /* In lite mode, comments are dropped — only `meta` itself drives
       the front-matter block decision. */
    if (!e->lite) {
        for (size_t i = 0; i < e->doc->num_comments; i++) {
            const dms_attached_comment *ac = &e->doc->comments[i];
            if (ac->path_len > 0 && !ac->path[0].is_index
                && ac->path[0].key && strcmp(ac->path[0].key, "__fm__") == 0) {
                has_fm_comments = true;
                break;
            }
        }
    }
    if (fm_present || has_fm_comments) {
        emit_push(e, "+++\n");
        dms_breadcrumb_seg fm_seg;
        fm_seg.is_index = 0;
        fm_seg.key = (char *)"__fm__";
        fm_seg.idx = 0;
        if (e->doc->meta) {
            emit_table_block(e, e->doc->meta, &fm_seg, 1, 0);
        } else {
            emit_floating_for(e, &fm_seg, 1, 0);
        }
        emit_push(e, "+++\n\n");
    }
    /* Body */
    const dms_value *body = e->doc->body;
    if (body->type == DMS_TABLE) {
        emit_table_block(e, &body->u.t, NULL, 0, 0);
    } else if (body->type == DMS_LIST) {
        emit_list_block(e, &body->u.l, NULL, 0, 0);
    } else {
        emit_leading_for(e, NULL, 0, 0);
        emit_value_inline(e, body, NULL, 0);
        emit_trailing_for(e, NULL, 0);
        emit_push_ch(e, '\n');
        emit_floating_for(e, NULL, 0, 0);
    }
}

/* SPEC §"Unordered tables": full-mode round-trip refuses any document
   whose body contains an unordered table (iteration order is arbitrary
   so emit cannot be byte-stable). Mirrors `contains_unordered_table` in
   the Rust reference. */
static bool dms_value_contains_unordered(const dms_value *v) {
    if (!v) return false;
    switch (v->type) {
        case DMS_TABLE:
            if (v->u.t.unordered) return true;
            for (size_t i = 0; i < v->u.t.len; i++) {
                if (dms_value_contains_unordered(v->u.t.items[i].value)) return true;
            }
            return false;
        case DMS_LIST:
            for (size_t i = 0; i < v->u.l.len; i++) {
                if (dms_value_contains_unordered(v->u.l.items[i])) return true;
            }
            return false;
        default:
            return false;
    }
}

char *dms_encode(const dms_document *doc, dms_encode_error *err) {
    if (err) { err->code = DMS_ENCODE_OK; err->message[0] = 0; }
    if (doc && dms_value_contains_unordered(doc->body)) {
        if (err) {
            err->code = DMS_ENCODE_UNORDERED_IN_FULL_MODE;
            snprintf(err->message, sizeof err->message,
                     "dms_encode: full-mode round-trip refuses Document "
                     "with unordered table; unordered tables have arbitrary "
                     "iteration order — use dms_encode_lite instead. "
                     "(SPEC §\"Unordered tables\")");
        }
        return NULL;
    }
    emitter e;
    emitter_init(&e, doc, false);
    emit_document_body(&e);
    emitter_free(&e);
    if (!e.out.data) return xstrdup("");
    return e.out.data;
}

/* Lite-mode emit — canonical form. Comments and original_forms are
   ignored (left untouched in the input doc). Mirrors `encode_lite` in
   the Rust reference. */
char *dms_encode_lite(const dms_document *doc) {
    emitter e;
    emitter_init(&e, doc, true);
    emit_document_body(&e);
    emitter_free(&e);
    if (!e.out.data) return xstrdup("");
    return e.out.data;
}

/* ---------- deprecated thin aliases (pre-v0.14 names) ---------- */
#if defined(__GNUC__) || defined(__clang__)
#  pragma GCC diagnostic push
#  pragma GCC diagnostic ignored "-Wdeprecated-declarations"
#endif

char *dms_to_dms(const dms_document *doc) {
    /* Pre-v0.14 callers don't pass an error param. Preserve the old
       abort-on-bad-input behaviour: print the message dms_encode
       would have set, then abort — same crash signature pre-rename. */
    dms_encode_error err;
    char *out = dms_encode(doc, &err);
    if (!out && err.code != DMS_ENCODE_OK) {
        fprintf(stderr, "%s\n", err.message);
        abort();
    }
    return out;
}

char *dms_to_dms_lite(const dms_document *doc) {
    return dms_encode_lite(doc);
}

#if defined(__GNUC__) || defined(__clang__)
#  pragma GCC diagnostic pop
#endif
