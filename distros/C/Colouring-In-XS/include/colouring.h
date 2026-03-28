/*
 * colouring.h - Pure C colour math library (header-only, C89 compatible)
 *
 * No Perl/XS dependencies. All functions are static.
 *
 * Usage from XS:
 *     #define COLOURING_FATAL(msg) croak("%s", (msg))
 *     #include "colouring.h"
 *
 * Usage from plain C:
 *     #include "colouring.h"
 *     // COLOURING_FATAL defaults to fprintf+abort
 */

#ifndef COLOURING_H
#define COLOURING_H

#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include <math.h>

/* ── Error handling ────────────────────────────────────────────── */

#ifndef COLOURING_FATAL
#define COLOURING_FATAL(msg) do { fprintf(stderr, "colouring: %s\n", (msg)); abort(); } while(0)
#endif

/* ── Structs ───────────────────────────────────────────────────── */

typedef struct {
    double r;   /* 0-255 */
    double g;
    double b;
    double a;   /* 0.0-1.0 */
} colouring_rgba_t;

typedef struct {
    int    h;   /* 0-360 */
    double s;   /* 0.0-1.0 */
    double l;   /* 0.0-1.0 */
    double a;   /* 0.0-1.0 */
} colouring_hsl_t;

typedef struct {
    double h;   /* 0-360 */
    double s;   /* 0.0-1.0 */
    double v;   /* 0.0-1.0 */
} colouring_hsv_t;

/* ── Scalar utilities ──────────────────────────────────────────── */

static double colouring_min(double a, double b) {
    return a < b ? a : b;
}

static double colouring_max(double a, double b) {
    return a > b ? a : b;
}

static double colouring_clamp(double val, double upper) {
    return colouring_min(colouring_max(val, 0), upper);
}

static double colouring_round(double val, int dp) {
    double factor = pow(10.0, dp);
    return floor(val * factor + 0.5) / factor;
}

static double colouring_depercent(const char *str) {
    return atof(str) / 100.0;
}

/* Format 0.0-1.0 as "NN%". buf must be >= 8 bytes. */
static void colouring_percent_buf(double num, char *buf, size_t bufsz) {
    snprintf(buf, bufsz, "%.0f%%", num * 100.0);
}

/* ── Hex parsing ───────────────────────────────────────────────── */

static int colouring_hex2int(const char *hex) {
    int val = 0;
    while (*hex) {
        int byte = *hex++;
        if (byte >= '0' && byte <= '9')      byte = byte - '0';
        else if (byte >= 'a' && byte <= 'f') byte = byte - 'a' + 10;
        else if (byte >= 'A' && byte <= 'F') byte = byte - 'A' + 10;
        else { COLOURING_FATAL("Invalid hex character"); return 0; }
        val = (val << 4) | (byte & 0xF);
    }
    return val;
}

static colouring_rgba_t colouring_hex2rgb(const char *hex) {
    colouring_rgba_t c;
    int l;
    c.a = 1.0;

    /* skip leading '#' if present */
    if (hex[0] == '#') hex++;
    l = (int)strlen(hex);

    if (l == 3) {
        char h[3];
        h[2] = '\0';
        h[0] = hex[0]; h[1] = hex[0]; c.r = colouring_hex2int(h);
        h[0] = hex[1]; h[1] = hex[1]; c.g = colouring_hex2int(h);
        h[0] = hex[2]; h[1] = hex[2]; c.b = colouring_hex2int(h);
    } else if (l == 6) {
        char h[3];
        h[2] = '\0';
        h[0] = hex[0]; h[1] = hex[1]; c.r = colouring_hex2int(h);
        h[0] = hex[2]; h[1] = hex[3]; c.g = colouring_hex2int(h);
        h[0] = hex[4]; h[1] = hex[5]; c.b = colouring_hex2int(h);
    } else {
        COLOURING_FATAL("hex length must be 3 or 6");
        c.r = c.g = c.b = 0;
    }
    return c;
}

/* ── Number parsing from colour strings ────────────────────────── */

/* Parse numeric values from strings like "rgb(255,0,128)" or "hsl(120,50%,50%)".
   Writes up to max_out doubles, returns count written. */
static int colouring_parse_numbers(const char *str, double *out, int max_out) {
    int count = 0;
    char temp[32];
    int ti = 0;
    int i;
    int len = (int)strlen(str);

    for (i = 0; i < len; i++) {
        if ((str[i] >= '0' && str[i] <= '9') || str[i] == '.') {
            if (ti < 31) temp[ti++] = str[i];
        } else if (ti > 0) {
            temp[ti] = '\0';
            if (count < max_out) {
                out[count++] = atof(temp);
            }
            ti = 0;
        }
    }
    /* flush trailing number */
    if (ti > 0 && count < max_out) {
        temp[ti] = '\0';
        out[count++] = atof(temp);
    }
    return count;
}

/* ── HSL helper ────────────────────────────────────────────────── */

static double colouring__hue(double h, double m1, double m2) {
    h = h < 0 ? h + 1 : h > 1 ? h - 1 : h;
    if (h * 6.0 < 1.0) return m1 + (m2 - m1) * h * 6.0;
    if (h * 2.0 < 1.0) return m2;
    if (h * 3.0 < 2.0) return m1 + (m2 - m1) * ((2.0 / 3.0) - h) * 6.0;
    return m1;
}

/* ── Colour space conversions ──────────────────────────────────── */

static colouring_rgba_t colouring_hsl2rgb(double h, double s, double l, double a) {
    colouring_rgba_t c;
    double m2, m1;
    int hi = (int)h;

    h = (hi % 360) / 360.0;
    if (s > 1 || l > 1) {
        s = s / 100.0;
        l = l / 100.0;
    }
    m2 = l <= 0.5 ? l * (s + 1) : l + s - l * s;
    m1 = l * 2 - m2;

    c.r = (int)(colouring_clamp(colouring__hue(h + (1.0 / 3.0), m1, m2), 1) * 255);
    c.g = (int)(colouring_clamp(colouring__hue(h, m1, m2), 1) * 255);
    c.b = (int)(colouring_clamp(colouring__hue(h - (1.0 / 3.0), m1, m2), 1) * 255);
    c.a = a;
    return c;
}

static colouring_hsl_t colouring_rgb2hsl(double r, double g, double b, double a) {
    colouring_hsl_t hsl;
    double rn = r / 255.0;
    double gn = g / 255.0;
    double bn = b / 255.0;
    double mx = colouring_max(colouring_max(rn, gn), bn);
    double mn = colouring_min(colouring_min(rn, gn), bn);
    double d  = mx - mn;
    double h  = 0;
    double s  = 0;
    double l  = (mx + mn) / 2.0;

    if (mx != mn) {
        s = l > 0.5 ? (d / (2.0 - mx - mn)) : (d / (mx + mn));
        if (mx == rn)
            h = (gn - bn) / d + (gn < bn ? 6 : 0);
        else if (mx == gn)
            h = (bn - rn) / d + 2;
        else
            h = (rn - gn) / d + 4;
        h = h / 6.0;
    }

    hsl.h = (int)(h * 360);
    hsl.s = s;
    hsl.l = l;
    hsl.a = a;
    return hsl;
}

static colouring_hsv_t colouring_rgb2hsv(double r, double g, double b) {
    colouring_hsv_t hsv;
    double rn = r / 255.0;
    double gn = g / 255.0;
    double bn = b / 255.0;
    double mx = colouring_max(colouring_max(rn, gn), bn);
    double mn = colouring_min(colouring_min(rn, gn), bn);
    double d  = mx - mn;
    double h  = 0;

    hsv.s = (mx == 0) ? 0 : d / mx;
    hsv.v = mx;

    if (mx != mn) {
        if (mx == rn)
            h = (gn - bn) / d + (gn < bn ? 6 : 0);
        else if (mx == gn)
            h = (bn - rn) / d + 2;
        else
            h = (rn - gn) / d + 4;
        h = h / 6.0;
    }

    hsv.h = h * 360.0;
    return hsv;
}

/* ── Colour manipulation ───────────────────────────────────────── */

static colouring_rgba_t colouring_lighten(double r, double g, double b, double a,
                                           double amount, int relative) {
    colouring_hsl_t hsl = colouring_rgb2hsl(r, g, b, a);
    if (relative) {
        /* Original C code: double l = hsl.l || 1.; -- C logical OR
           always yields 1 when hsl.l is nonzero, 1 when zero.
           So relative lighten behaves same as absolute. */
        hsl.l = hsl.l + colouring_clamp(amount, 1);
    } else {
        hsl.l = hsl.l + colouring_clamp(amount, 1);
    }
    return colouring_hsl2rgb(hsl.h, hsl.s, hsl.l, hsl.a);
}

static colouring_rgba_t colouring_darken(double r, double g, double b, double a,
                                          double amount, int relative) {
    colouring_hsl_t hsl = colouring_rgb2hsl(r, g, b, a);
    if (relative) {
        hsl.l = hsl.l - colouring_clamp(hsl.l * amount, 1);
    } else {
        hsl.l = hsl.l - colouring_clamp(amount, 1);
    }
    return colouring_hsl2rgb(hsl.h, hsl.s, hsl.l, hsl.a);
}

static colouring_rgba_t colouring_fade(double r, double g, double b, double a,
                                        double amount) {
    colouring_hsl_t hsl = colouring_rgb2hsl(r, g, b, a);
    hsl.a = amount;
    return colouring_hsl2rgb(hsl.h, hsl.s, hsl.l, hsl.a);
}

static colouring_rgba_t colouring_fadeout(double r, double g, double b, double a,
                                           double amount, int relative) {
    colouring_hsl_t hsl = colouring_rgb2hsl(r, g, b, a);
    hsl.a -= colouring_clamp(relative ? hsl.a * amount : amount, 1);
    return colouring_hsl2rgb(hsl.h, hsl.s, hsl.l, hsl.a);
}

static colouring_rgba_t colouring_fadein(double r, double g, double b, double a,
                                          double amount, int relative) {
    colouring_hsl_t hsl = colouring_rgb2hsl(r, g, b, a);
    hsl.a += colouring_clamp(relative ? hsl.a * amount : amount, 1);
    hsl.a = colouring_clamp(hsl.a, 1);
    return colouring_hsl2rgb(hsl.h, hsl.s, hsl.l, hsl.a);
}

static colouring_rgba_t colouring_saturate(double r, double g, double b, double a,
                                            double amount, int relative) {
    colouring_hsl_t hsl = colouring_rgb2hsl(r, g, b, a);
    hsl.s += colouring_clamp(relative ? hsl.s * amount : amount, 1);
    return colouring_hsl2rgb(hsl.h, hsl.s, hsl.l, hsl.a);
}

static colouring_rgba_t colouring_desaturate(double r, double g, double b, double a,
                                              double amount, int relative) {
    colouring_hsl_t hsl = colouring_rgb2hsl(r, g, b, a);
    hsl.s -= colouring_clamp(relative ? hsl.s * amount : amount, 1);
    return colouring_hsl2rgb(hsl.h, hsl.s, hsl.l, hsl.a);
}

static colouring_rgba_t colouring_greyscale(double r, double g, double b, double a) {
    colouring_hsl_t hsl = colouring_rgb2hsl(r, g, b, a);
    hsl.s -= 1.0;
    return colouring_hsl2rgb(hsl.h, hsl.s, hsl.l, hsl.a);
}

static colouring_rgba_t colouring_mix(colouring_rgba_t c1, colouring_rgba_t c2,
                                       int weight) {
    colouring_rgba_t out;
    double w = weight / 100.0;
    double a = c1.a - c2.a;
    double w1, w2;

    w = (w * 2) - 1;
    w1 = (((w * a == -1) ? w : (w + a) / (1 + w * a)) + 1) / 2.0;
    w2 = 1 - w1;

    out.r = (c1.r * w1) + (c2.r * w2);
    out.g = (c1.g * w1) + (c2.g * w2);
    out.b = (c1.b * w1) + (c2.b * w2);
    out.a = (c1.a * w) + (c2.a * (1 - w));
    return out;
}

static colouring_rgba_t colouring_tint(colouring_rgba_t c, int weight) {
    colouring_rgba_t white;
    white.r = 255; white.g = 255; white.b = 255; white.a = 1.0;
    return colouring_mix(white, c, weight);
}

static colouring_rgba_t colouring_shade(colouring_rgba_t c, int weight) {
    colouring_rgba_t black;
    black.r = 0; black.g = 0; black.b = 0; black.a = 1.0;
    return colouring_mix(black, c, weight);
}

/* ── Formatting ────────────────────────────────────────────────── */

static void colouring_fmt_hex(colouring_rgba_t c, char *buf, size_t bufsz,
                               int force_long) {
    int r = (int)c.r, g = (int)c.g, b = (int)c.b;
    snprintf(buf, bufsz, "#%02x%02x%02x", r, g, b);
    if (!force_long) {
        /* shorten "#aabbcc" to "#abc" if possible */
        if (buf[1] == buf[2] && buf[3] == buf[4] && buf[5] == buf[6]) {
            buf[2] = buf[3];
            buf[3] = buf[5];
            buf[4] = '\0';
        }
    }
}

static void colouring_fmt_rgb(colouring_rgba_t c, char *buf, size_t bufsz) {
    snprintf(buf, bufsz, "rgb(%d,%d,%d)", (int)c.r, (int)c.g, (int)c.b);
}

static void colouring_fmt_rgba(colouring_rgba_t c, char *buf, size_t bufsz) {
    snprintf(buf, bufsz, "rgba(%d,%d,%d,%.2g)", (int)c.r, (int)c.g, (int)c.b, c.a);
}

static void colouring_fmt_hsl(colouring_hsl_t hsl, char *buf, size_t bufsz) {
    char ps[8], pl[8];
    colouring_percent_buf(hsl.s, ps, sizeof(ps));
    colouring_percent_buf(hsl.l, pl, sizeof(pl));
    snprintf(buf, bufsz, "hsl(%d,%s,%s)", hsl.h, ps, pl);
}

static void colouring_fmt_hsv(colouring_hsv_t hsv, char *buf, size_t bufsz) {
    char ps[8], pv[8];
    colouring_percent_buf(hsv.s, ps, sizeof(ps));
    colouring_percent_buf(hsv.v, pv, sizeof(pv));
    snprintf(buf, bufsz, "hsv(%.0f,%s,%s)", hsv.h, ps, pv);
}

static void colouring_fmt_term(colouring_rgba_t c, char *buf, size_t bufsz) {
    snprintf(buf, bufsz, "r%dg%db%d", (int)c.r, (int)c.g, (int)c.b);
}

static void colouring_fmt_on_term(colouring_rgba_t c, char *buf, size_t bufsz) {
    snprintf(buf, bufsz, "on_r%dg%db%d", (int)c.r, (int)c.g, (int)c.b);
}

/* ── Colour string conversion (dispatch) ──────────────────────── */

/* Parse any supported colour string into RGBA.
   Returns 1 on success, 0 on failure. */
static int colouring_parse(const char *str, colouring_rgba_t *out) {
    if (str[0] == '#') {
        *out = colouring_hex2rgb(str);
        return 1;
    } else if (str[0] == 'r' && str[1] == 'g' && str[2] == 'b') {
        double nums[4];
        int n = colouring_parse_numbers(str, nums, 4);
        if (n < 3) return 0;
        out->r = nums[0];
        out->g = nums[1];
        out->b = nums[2];
        out->a = n >= 4 ? nums[3] : 1.0;
        return 1;
    } else if (str[0] == 'h' && str[1] == 's' && str[2] == 'l') {
        double nums[4];
        int n = colouring_parse_numbers(str, nums, 4);
        if (n < 3) return 0;
        *out = colouring_hsl2rgb(nums[0], nums[1], nums[2],
                                  n >= 4 ? nums[3] : 1.0);
        return 1;
    }
    return 0;
}

#endif /* COLOURING_H */
