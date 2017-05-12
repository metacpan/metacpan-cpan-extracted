/*
 * $Id: tea.h,v 1.25 2001/05/21 17:32:59 ams Exp $
 * Copyright 2001 Abhijit Menon-Sen <ams@wiw.org>
 */

#include <stdlib.h>
#include "platform.h"

#ifndef _TEA_H_
#define _TEA_H_

struct tea {
    int rounds;
    uint32_t key[4];
};

struct tea *tea_setup(unsigned char *key, int rounds);
void tea_free(struct tea *self);
void tea_crypt(struct tea *self,
               unsigned char *input, unsigned char *output,
               int decrypt);

#endif
