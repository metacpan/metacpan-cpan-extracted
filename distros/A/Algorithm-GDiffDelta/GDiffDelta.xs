/* Algorithm::GDiffDelta implementation.
 *
 * Copyright (C) 2003 Davide Libenzi (code derived from libxdiff)
 * Copyright 2004, Geoff Richards
 *
 *  This library is free software; you can redistribute it and/or
 *  modify it under the terms of the GNU Lesser General Public
 *  License as published by the Free Software Foundation; either
 *  version 2.1 of the License, or (at your option) any later version.
 *
 *  This library is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 *  Lesser General Public License for more details.
 *
 *  You should have received a copy of the GNU Lesser General Public
 *  License along with this library; if not, write to the Free Software
 *  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
 */

#ifdef __cplusplus
extern "C" {
#endif
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#ifdef __cplusplus
}
#endif

#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <errno.h>

#undef assert
#include <assert.h>

#define QEF_BUFSZ 8192

#if 0
#define QEF_DEBUG_IO
#endif


#include "util.c"


static void
careful_fread (void *ptr, size_t size, SV *f, const char *from)
{
#ifdef QEF_DEBUG_IO
    fprintf(stderr, "read from %p (%s): %u bytes ->%p\n", (void *) f, from,
            (unsigned int) size, ptr);
#endif

    if (sv_isobject(f)) {
        I32 n;
        SV *ret, *buf;
        STRLEN len;
        char *str;

        dSP;
        ENTER;
        SAVETMPS;
        PUSHMARK(SP);
        XPUSHs(f);
        /* TODO - possibly use newSVpvn_share to avoid the memcpy
         * and extra allocation for buf? */
        XPUSHs(sv_2mortal(buf = newSVpvn("", 0)));
        XPUSHs(sv_2mortal(newSVuv(size)));
        PUTBACK;
        n = call_method("read", G_SCALAR);
        assert(n == 0 || n == 1);
        SPAGAIN;
        ret = n ? POPs : &PL_sv_undef;
        if (!SvOK(ret))
            croak("error reading from %s: %s", from,
                  SvPV_nolen(get_sv("!", FALSE)));
        if (SvUV(ret) != size)
            croak("%s ends unexpectedly", from);
        if (!SvPOK(buf) || SvCUR(buf) != size)
            croak("'read' method left buffer badly set up", from);
        str = SvPV(buf, len);
        assert(len == size);
        memcpy(ptr, str, size);
        PUTBACK;
        FREETMPS;
        LEAVE;
    }
    else {
        int r = PerlIO_read(IoIFP(sv_2io(f)), ptr, size);
        if (r < 0)
            croak("error reading from %s: %s", from, strerror(errno));
        else if ((size_t) r != size)
            croak("%s ends unexpectedly", from);
    }
}

static void
careful_fwrite (const void *ptr, size_t size, SV *f, const char *to)
{
    I32 n;
    SV *ret;

#ifdef QEF_DEBUG_IO
    fprintf(stderr, "write to %p (%s): %u bytes <-%p\n", (void *) f, to,
            (unsigned int) size, ptr);
#endif

    if (sv_isobject(f)) {
        dSP;
        ENTER;
        SAVETMPS;
        PUSHMARK(SP);
        XPUSHs(f);
        XPUSHs(sv_2mortal(newSVpvn(ptr, size)));
        XPUSHs(sv_2mortal(newSVuv(size)));
        PUTBACK;
        n = call_method("write", G_SCALAR);
        assert(n == 0 || n == 1);
        SPAGAIN;
        ret = n ? POPs : &PL_sv_no;
        n = SvTRUE(ret);
        PUTBACK;
        FREETMPS;
        LEAVE;
        if (!n)
            croak("error writing to %s: %s", to,
                  SvPV_nolen(get_sv("!", FALSE)));
    }
    else {
        if ((size_t) PerlIO_write(IoIFP(sv_2io(f)), ptr, size) != size)
            croak("error writing to %s: %s", to, strerror(errno));
    }
}

static void
careful_fseek_whence (SV *f, Off_t offset, const char *from, int whence)
{
    assert(whence == SEEK_SET || whence == SEEK_CUR || whence == SEEK_END);
#ifdef QEF_DEBUG_IO
    fprintf(stderr, "seek %p (%s): %s %u\n", (void *) f, from,
            (whence == SEEK_SET ? "SEEK_SET" :
             whence == SEEK_CUR ? "SEEK_CUR" : "SEEK_END"),
            (unsigned int) offset);
#endif

    if (sv_isobject(f)) {
        I32 n;
        SV *ret;

        dSP;
        ENTER;
        SAVETMPS;
        PUSHMARK(SP);
        XPUSHs(f);
        XPUSHs(sv_2mortal(newSVuv(offset)));
        XPUSHs(sv_2mortal(newSVuv(whence)));
        PUTBACK;
        n = call_method("seek", G_SCALAR);
        assert(n == 0 || n == 1);
        SPAGAIN;
        ret = n ? POPs : &PL_sv_undef;
        n = SvTRUE(ret);
        PUTBACK;
        FREETMPS;
        LEAVE;
        if (!n)
            croak("error seeking in %s: %s", from,
                  SvPV_nolen(get_sv("!", FALSE)));
    }
    else {
        if (PerlIO_seek(IoIFP(sv_2io(f)), offset, whence))
            croak("error seeking in %s: %s", from, strerror(errno));
    }
}

QEF_INLINE static void
careful_fseek (SV *f, Off_t offset, const char *from)
{
    careful_fseek_whence(f, offset, from, SEEK_SET);
}

static Off_t
careful_ftell (SV *f, const char *from)
{
    Off_t offset;

    if (sv_isobject(f)) {
        I32 n;
        SV *ret;

        dSP;
        ENTER;
        SAVETMPS;
        PUSHMARK(SP);
        XPUSHs(f);
        PUTBACK;
        n = call_method("tell", G_SCALAR);
        assert(n == 0 || n == 1);
        SPAGAIN;
        offset = (Off_t) -1;
        if (n) {
            ret = POPs;
            if (SvOK(ret))
                offset = SvUV(ret);
        }
        PUTBACK;
        FREETMPS;
        LEAVE;
        if (offset == (Off_t) -1)
            croak("error getting position in %s: %s", from,
                  SvPV_nolen(get_sv("!", FALSE)));
    }
    else {
        offset = PerlIO_tell(IoIFP(sv_2io(f)));
        if (offset == (Off_t) -1)
            croak("error getting position in %s: %s", from, strerror(errno));
    }

    return offset;
}

QEF_INLINE static size_t
read_ubyte (SV *f)
{
    unsigned char buf;
    careful_fread(&buf, 1, f, "delta");
    return buf;
}

QEF_INLINE static size_t
read_ushort (SV *f)
{
    unsigned char buf[2];
    careful_fread(buf, 2, f, "delta");
    return buf[0] * 0x100 + buf[1];
}

QEF_INLINE static size_t
read_int (SV *f)
{
    unsigned char buf[4];
    careful_fread(buf, 4, f, "delta");
    if (buf[0] >= 0x7F)
        croak("delta contains negative int value");
    return buf[0] * 0x1000000 + buf[1] * 0x10000 +
           buf[2] * 0x100 + buf[3];
}

/* The buffer is supplied by the parent so that we can avoid allocating
 * it on the stack every time this is called, even though that probably
 * wouldn't be very expensive in most implementations.  */
static void
copy_data (SV *in, SV *out, size_t num_bytes, unsigned char *buf,
           const char *from, const char *to)
{
    assert(buf);

    while (num_bytes >= QEF_BUFSZ) {
        careful_fread(buf, QEF_BUFSZ, in, from);
        careful_fwrite(buf, QEF_BUFSZ, out, to);
        num_bytes -= QEF_BUFSZ;
    }

    careful_fread(buf, num_bytes, in, from);
    careful_fwrite(buf, num_bytes, out, to);
}

/* Work out the size of the file by seeking to the end.  */
static Off_t
file_size (SV *f, const char *from)
{
    careful_fseek_whence(f, 0, from, SEEK_END);
    return careful_ftell(f, from);
}


/* largest prime smaller than 65536 */
#define QEF_BASE 65521L

/* NMAX is the largest n such that 255n(n+1)/2 + (n+1)(BASE-1) <= 2^32-1 */
#define QEF_NMAX 5552

#define QEF_DO1(buf, i)  { s1 += buf[i]; s2 += s1; }
#define QEF_DO2(buf, i)  QEF_DO1(buf, i); QEF_DO1(buf, i + 1);
#define QEF_DO4(buf, i)  QEF_DO2(buf, i); QEF_DO2(buf, i + 2);
#define QEF_DO8(buf, i)  QEF_DO4(buf, i); QEF_DO4(buf, i + 4);
#define QEF_DO16(buf)    QEF_DO8(buf, 0); QEF_DO8(buf, 8);

static U32
adler32(U32 adler, const unsigned char *buf, size_t len)
{
    int k;
    U32 s1 = adler & 0xffff;
    U32 s2 = (adler >> 16) & 0xffff;

    assert(buf);

    while (len > 0) {
        k = len < QEF_NMAX ? len : QEF_NMAX;
        len -= k;
        while (k >= 16) {
            QEF_DO16(buf);
            buf += 16;
            k -= 16;
        }
        if (k != 0)
            do {
                s1 += *buf++;
                s2 += s1;
            } while (--k);
        s1 %= QEF_BASE;
        s2 %= QEF_BASE;
    }

    return (s2 << 16) | s1;
}

static U32
adler32_file (SV *f, U32 adler, Off_t offset, Off_t size, const char *from)
{
    unsigned char buf[QEF_BUFSZ];
    Off_t chunk_sz;

    careful_fseek(f, offset, from);

    while (size > 0) {
        chunk_sz = QEF_MIN(QEF_BUFSZ, size);
        careful_fread(buf, chunk_sz, f, from);
        adler = adler32(adler, buf, chunk_sz);
        size -= chunk_sz;
    }

    return adler;
}


static void
prepare_bdfile (SV *orig, Off_t orig_size, QefBDFile *bdf)
{
    unsigned int fphbits;
    Off_t hsize, offset;
    U32 i;
    QefBDRecord *brec;
    QefBDRecord **fphash;

    fphbits = hashbits(orig_size / QEF_BLK_SIZE + 1);
    hsize = (Off_t) 1 << fphbits;
    New(0, fphash, hsize, QefBDRecord *);
    for (i = 0; i < hsize; ++i)
        fphash[i] = 0;

    qef_cha_init(&bdf->cha, sizeof(QefBDRecord), hsize / 4 + 1);

    if (orig_size == 0)
        bdf->size = 0;
    else {
        offset = 0;
        bdf->size = orig_size;

        /* Start by looking at the last (possibly incomplete) block */
        if ((offset = (orig_size / QEF_BLK_SIZE) * QEF_BLK_SIZE) == orig_size)
            offset -= QEF_BLK_SIZE;

        while (1) {
            brec = qef_cha_alloc(&bdf->cha);

            brec->fp = adler32_file(orig, 0, offset,
                                    QEF_MIN(QEF_BLK_SIZE, orig_size - offset),
                                    "original");
            brec->offset = offset;

            i = QEF_HASHLONG(brec->fp, fphbits);
            brec->next = fphash[i];
            fphash[i] = brec;

            if (offset < QEF_BLK_SIZE)
                break;
            offset -= QEF_BLK_SIZE;
        }
        assert(offset == 0);
    }

    bdf->fphbits = fphbits;
    bdf->fphash = fphash;
}

/* Output a GDIFF DATA operation.  */
static void
data_op (SV *changed, SV *delta, Off_t offset, Off_t size, unsigned char *buf)
{
    size_t headsz = 0;

    assert(size > 0);
    assert(size <= QEF_INT_MAX);
    assert(buf);

    if (size <= 246)
        buf[headsz++] = size;
    else if (size <= QEF_USHORT_MAX) {
        buf[headsz++] = 247;
        QEF_BE16_PUT(buf, headsz, size);
    }
    else {
        buf[headsz++] = 248;
        QEF_BE32_PUT(buf, headsz, size);
    }

    /* Write the opcode and size argument (if any).  */
    careful_fwrite(buf, headsz, delta, "delta");

    /* Copy the actual data to be inserted into the delta.  */
    careful_fseek(changed, offset, "changed file");
    copy_data(changed, delta, size, buf, "changed file", "delta");
}

/* Output a GDIFF COPY operation.  */
static void
copy_op (SV *delta, Off_t offset, Off_t size)
{
    unsigned char buf[QEF_COPY_MAX];
    size_t headsz = 0;

    assert(size > 0);

    if (offset <= QEF_USHORT_MAX) {
        if (size <= QEF_UBYTE_MAX) {
            buf[headsz++] = 249;
            QEF_BE16_PUT(buf, headsz, offset);
            buf[headsz++] = size;
        }
        else if (size <= QEF_USHORT_MAX) {
            buf[headsz++] = 250;
            QEF_BE16_PUT(buf, headsz, offset);
            QEF_BE16_PUT(buf, headsz, size);
        }
        else if (size <= QEF_INT_MAX) {
            buf[headsz++] = 251;
            QEF_BE16_PUT(buf, headsz, offset);
            QEF_BE32_PUT(buf, headsz, size);
        }
        else {
            /* TODO - break copy ops for bigger than 2Gb into smaller ones */
            assert(0);
        }
    }
    else if (offset <= QEF_INT_MAX) {
        if (size <= QEF_UBYTE_MAX) {
            buf[headsz++] = 252;
            QEF_BE32_PUT(buf, headsz, offset);
            buf[headsz++] = size;
        }
        else if (size <= QEF_USHORT_MAX) {
            buf[headsz++] = 253;
            QEF_BE32_PUT(buf, headsz, offset);
            QEF_BE16_PUT(buf, headsz, size);
        }
        else if (size <= QEF_INT_MAX) {
            buf[headsz++] = 254;
            QEF_BE32_PUT(buf, headsz, offset);
            QEF_BE32_PUT(buf, headsz, size);
        }
        else {
            /* TODO - break copy ops for bigger than 2Gb into smaller ones */
            assert(0);
        }
    }
    else {
        /* TODO - allow 64bit offsets */
        assert(0);
    }

    /* Write the opcode and arguments.  */
    careful_fwrite(buf, headsz, delta, "delta");
}

static void
do_delta (SV *orig, SV *changed, SV *delta)
{
    U32 fp;
    Off_t orig_size, changed_size, changed_offset;
    Off_t rsize, msize, newmsize;
    Off_t off1, off2, moff, newmoff;
    QefBDFile bdf;
    QefBDRecord *brec;
    unsigned char insbuf[QEF_BUFSZ], buf1[QEF_BUFSZ], buf2[QEF_BUFSZ];
    size_t pos, sz1, sz2, minsz;
    Off_t ins_offset, ins_size;
    int stop;

    changed_size = file_size(changed, "changed file");
    if (changed_size == 0)
        return;
    orig_size = file_size(orig, "original");

    prepare_bdfile(orig, orig_size, &bdf);

    ins_size = 0;
    changed_offset = 0;
    while (changed_offset < changed_size) {
        rsize = QEF_MIN(QEF_BLK_SIZE, changed_size - changed_offset);
        fp = adler32_file(changed, 0, changed_offset, rsize, "changed file");

        brec = bdf.fphash[QEF_HASHLONG(fp, bdf.fphbits)];
        for (msize = 0; brec; brec = brec->next) {
            if (brec->fp == fp) {
                off1 = brec->offset;
                off2 = changed_offset;
                newmsize = 0;
                newmoff = off1;
                stop = 0;
                while (!stop) {
                    sz1 = QEF_MIN(QEF_BUFSZ, orig_size - off1);
                    sz2 = QEF_MIN(QEF_BUFSZ, changed_size - off2);
                    minsz = QEF_MIN(sz1, sz2);
                    if (minsz == 0)
                        break;
                    /* TODO - is there a better way to buffer these? */
                    careful_fseek(orig, off1, "original");
                    careful_fread(buf1, minsz, orig, "original");
                    careful_fseek(changed, off2, "changed file");
                    careful_fread(buf2, minsz, changed, "changed file");
                    for (pos = 0; pos < minsz; ++pos) {
                        if (buf1[pos] != buf2[pos]) {
                            stop = 1;
                            break;
                        }
                    }
                    newmsize += pos;
                    off1 += minsz;
                    off2 += minsz;
                }

                if (newmsize > msize) {
                    moff = newmoff;
                    msize = newmsize;
                }
            }
        }

        if (msize < QEF_COPY_MIN) {
            if (!ins_size)
                ins_offset = changed_offset;
            ++ins_size;
            ++changed_offset;
            if (ins_size == QEF_INT_MAX) {
                data_op(changed, delta, ins_offset, ins_size, insbuf);
                ins_size = 0;
            }
        }
        else {
            if (ins_size) {
                data_op(changed, delta, ins_offset, ins_size, insbuf);
                ins_size = 0;
            }

            copy_op(delta, moff, msize);
            changed_offset += msize;
        }
    }

    if (ins_size) {
        data_op(changed, delta, ins_offset, ins_size, insbuf);
        ins_size = 0;
    }
}



MODULE = Algorithm::GDiffDelta   PACKAGE = Algorithm::GDiffDelta   PREFIX = qefgdiff_

PROTOTYPES: DISABLE


U32
qefgdiff_gdiff_adler32 (U32 init, SV *s)
    PREINIT:
        STRLEN len;
        const unsigned char *buf;
    CODE:
        buf = (unsigned char *) SvPV(s, len);
        RETVAL = adler32(init, buf, len);
    OUTPUT:
        RETVAL


void
qefgdiff_gdiff_delta (SV *orig, SV *changed, SV *delta)
    CODE:
        careful_fwrite("\xD1\xFF\xD1\xFF\x04", 5, delta, "delta");
        do_delta(orig, changed, delta);
        careful_fwrite("\0", 1, delta, "delta");


void
qefgdiff_gdiff_apply (SV *orig, SV *delta, SV *output)
    PREINIT:
        unsigned char buf[QEF_BUFSZ];
        size_t r, s;
        int c;
    CODE:
        /* Check that GDIFF header and version number are valid. */
        careful_fread(buf, 5, delta, "delta");
        if (buf[0] != 0xD1 || buf[1] != 0xFF ||
            buf[2] != 0xD1 || buf[3] != 0xFF)
            croak("incorrect GDIFF header at start of delta");
        if (buf[4] != 4)
            croak("wrong version of GDIFF format (%d),"
                  " only version 4 understood", (int) buf[4]);

        while (1) {
            careful_fread(buf, 1, delta, "delta");
            c = buf[0];
            if (c == 0)
                return;
            else if (c <= 246) {
                careful_fread(buf, c, delta, "delta");
                careful_fwrite(buf, c, output, "output");
            }
            else {
                switch (c) {
                    case 247: /* ushort, <n> bytes - append <n> data bytes */
                        s = read_ushort(delta);
                        copy_data(delta, output, s, buf, "delta", "output");
                        break;
                    case 248: /* int, <n> bytes - append <n> data bytes */
                        s = read_int(delta);
                        copy_data(delta, output, s, buf, "delta", "output");
                        break;
                    case 249: /* ushort, ubyte - copy <position>, <length> */
                        r = read_ushort(delta);
                        s = read_ubyte(delta);
                        careful_fseek(orig, r, "original");
                        copy_data(orig, output, s, buf, "original", "output");
                        break;
                    case 250: /* ushort, ushort - copy <position>, <length> */
                        r = read_ushort(delta);
                        s = read_ushort(delta);
                        careful_fseek(orig, r, "original");
                        copy_data(orig, output, s, buf, "original", "output");
                        break;
                    case 251: /* ushort, int - copy <position>, <length> */
                        r = read_ushort(delta);
                        s = read_int(delta);
                        careful_fseek(orig, r, "original");
                        copy_data(orig, output, s, buf, "original", "output");
                        break;
                    case 252: /* int, ubyte - copy <position>, <length> */
                        r = read_int(delta);
                        s = read_ubyte(delta);
                        careful_fseek(orig, r, "original");
                        copy_data(orig, output, s, buf, "original", "output");
                        break;
                    case 253: /* int, ushort - copy <position>, <length> */
                        r = read_int(delta);
                        s = read_ushort(delta);
                        careful_fseek(orig, r, "original");
                        copy_data(orig, output, s, buf, "original", "output");
                        break;
                    case 254: /* int, int - copy <position>, <length> */
                        r = read_int(delta);
                        s = read_int(delta);
                        careful_fseek(orig, r, "original");
                        copy_data(orig, output, s, buf, "original", "output");
                        break;
                    case 255: /* long, int - copy <position>, <length> */
                        /* TODO - 64 seeking */
                        assert(0);
                        break;
                    default: assert(0);
                }
            }
        }

# vi:ts=4 sw=4 expandtab:
