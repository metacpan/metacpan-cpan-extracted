/*
   Copyright (c) 2008  Edwin Pratomo

   You may distribute under the terms of either the GNU General Public
   License or the Artistic License, as specified in the Perl README file,
   with the exception that it cannot be placed on a CD-ROM or similar media
   for commercial distribution without the prior approval of the author.

*/

#ifndef COOLEX_H
#define COOLEX_H
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

typedef struct {
    IV 	            n;
    IV              r;
    SV              *aryref;
    unsigned char   *b;             /* bitstring: array of bytes */
    int             state;          /* state 0 / 1 / 2 */
    int             x;
    int             y;
} COMBINATION;

COMBINATION* init_combination(IV n, IV r, AV *av);
void free_combination(COMBINATION *c);
/* coollex pseudo-coroutine */
bool coollex(COMBINATION *c);
void coollex_visit(COMBINATION *c, SV **p_items);

#endif
