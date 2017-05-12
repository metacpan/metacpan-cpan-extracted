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

#include "util.h"
#include <limits.h>


static unsigned int
hashbits (Off_t size)
{
    unsigned int val = 1, bits = 0;

    while (val < size && bits < CHAR_BIT * sizeof(Off_t)) {
        val <<= 1;
        ++bits;
    }

    return bits ? bits : 1;
}


static void
qef_cha_init (QefChaStore *cha, long isize, long icount)
{
    cha->head = cha->tail = 0;
    cha->isize = isize;
    cha->nsize = icount * isize;
    cha->ancur = cha->sncur = 0;
    cha->scurr = 0;
}


static void
qef_cha_free (QefChaStore *cha)
{
    QefChaNode *cur, *tmp;

    for (cur = cha->head; (tmp = cur) != 0;) {
        cur = cur->next;
        free(tmp);
    }
}


static void *
qef_cha_alloc (QefChaStore *cha)
{
    QefChaNode *ancur;
    void *data;

    if (!(ancur = cha->ancur) || ancur->icurr == cha->nsize) {
        if (!(ancur = (QefChaNode *) malloc(sizeof(QefChaNode) + cha->nsize)))
            assert(0);
        ancur->icurr = 0;
        ancur->next = 0;
        if (cha->tail)
            cha->tail->next = ancur;
        if (!cha->head)
            cha->head = ancur;
        cha->tail = ancur;
        cha->ancur = ancur;
    }

    data = (char *) ancur + sizeof(QefChaNode) + ancur->icurr;
    ancur->icurr += cha->isize;

    return data;
}

/* vi:set ts=4 sw=4 expandtab: */
