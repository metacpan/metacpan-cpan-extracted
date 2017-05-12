/* Algorithm::GDiffDelta utility code.
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

#ifndef QEFGDIFF_INCLUDE_UTIL_H_
#define QEFGDIFF_INCLUDE_UTIL_H_

#include <limits.h>


#ifdef __GNUC__
#define QEF_INLINE __inline__
#else
#define QEF_INLINE /* not inlining */
#endif


#define QEF_MIN(a, b) ((a) < (b) ? (a) : (b))

#define GR_PRIME 0x9e370001UL

/* Return a 'b' bit hash of 'v' as a U32 value.  */
#define QEF_HASHLONG(v, b) (((U32)(v) * GR_PRIME) >> \
                            ((CHAR_BIT * sizeof(U32)) - (b)))

/* In libxdiff this is configurable, but it uses 16 as the value in the
 * test program and as the minimum allowable value, so we'll hard code
 * that for now.  */
#define QEF_BLK_SIZE 16

/* The minimum size required by a COPY operation (opcode 249).  */
#define QEF_COPY_MIN (1 + 2 + 1)

/* The maximum size required by a COPY operation (opcode 255).  */
#define QEF_COPY_MAX (1 + 8 + 4)

/* Maximum value of a GDIFF ubyte (unsigned 8 bit value).  */
#define QEF_UBYTE_MAX 0xFFUL

/* Maximum value of a GDIFF ushort (unsigned 16 bit value).  */
#define QEF_USHORT_MAX 0xFFFFUL

/* Maximum value of a GDIFF int (signed 32 bit value).  */
#define QEF_INT_MAX 0x7FFFFFFFUL

/* Copy a number into a buffer in big-endian format, using a counter as an
 * index into the buffer and moving it along the right number of bytes.  */
#define QEF_BE16_PUT(buf, idx, num) \
    do { \
        buf[idx++] = ((num) >> 8) & 0xFF; \
        buf[idx++] = (num) & 0xFF; \
    } while (0)
#define QEF_BE32_PUT(buf, idx, num) \
    do { \
        buf[idx++] = ((num) >> 24) & 0xFF; \
        buf[idx++] = ((num) >> 16) & 0xFF; \
        buf[idx++] = ((num) >> 8) & 0xFF; \
        buf[idx++] = (num) & 0xFF; \
    } while (0)


/* Data structures for the hashes of the original file.  */
struct QefChaNode {
    struct QefChaNode *next;
    long icurr;
};
typedef struct QefChaNode QefChaNode;

struct QefChaStore {
    QefChaNode *head, *tail;
    long isize, nsize;
    QefChaNode *ancur;
    QefChaNode *sncur;
    long scurr;
};
typedef struct QefChaStore QefChaStore;

struct QefBDRecord
{
    struct QefBDRecord *next;
    U32 fp;
    Off_t offset;
};
typedef struct QefBDRecord QefBDRecord;

struct QefBDFile
{
    Off_t size;
    QefChaStore cha;
    unsigned int fphbits;
    QefBDRecord **fphash;
};
typedef struct QefBDFile QefBDFile;


#endif  /* QEFGDIFF_INCLUDE_UTIL_H_ */

/* vi:set ts=4 sw=4 expandtab: */
