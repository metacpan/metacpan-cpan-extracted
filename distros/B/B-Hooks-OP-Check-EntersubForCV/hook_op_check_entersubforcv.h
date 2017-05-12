#ifndef __HOOK_OP_CHECK_ENTERSUBFORCV_H__
#define __HOOK_OP_CHECK_ENTERSUBFORCV_H__

#include "perl.h"
#include "hook_op_check.h"

START_EXTERN_C

typedef OP *(*hook_op_check_entersubforcv_cb) (pTHX_ OP *, CV *, void *);
hook_op_check_id hook_op_check_entersubforcv (CV *cv, hook_op_check_entersubforcv_cb cb, void *user_data);
void *hook_op_check_entersubforcv_remove (hook_op_check_id id);

END_EXTERN_C

#endif
