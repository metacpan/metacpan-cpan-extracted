/*
 * $Id: gost.h,v 1.00 2001/05/13 14:11:35 ams Exp $
 * Copyright 2001 Abhijit Menon-Sen <ams@wiw.org>
 */

#include <stdlib.h>
#include "platform.h"

#ifndef _GOST_H_
#define _GOST_H_

struct gost {
    uint32_t K[8];              /* 8 round subkeys  */
    unsigned char S[4][256];    /* 4 8*8 S-boxes    */
};

struct gost *gost_setup(unsigned char *key);
void gost_free(struct gost *self);
void gost_sboxes(struct gost *self, unsigned char S[8][16]);
void gost_crypt(struct gost *self,
                unsigned char *input, unsigned char *output,
                int decrypt);

#endif
