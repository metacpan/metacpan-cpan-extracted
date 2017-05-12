#ifndef __HOOK_OP_PPADDR_H__
#define __HOOK_OP_PPADDR_H__

#include "perl.h"

START_EXTERN_C

typedef OP *(*hook_op_ppaddr_cb_t) (pTHX_ OP *, void *user_data);
void hook_op_ppaddr (OP *op, hook_op_ppaddr_cb_t cb, void *user_data);
void hook_op_ppaddr_around (OP *op, hook_op_ppaddr_cb_t before, hook_op_ppaddr_cb_t after, void *user_data);

END_EXTERN_C

#endif
