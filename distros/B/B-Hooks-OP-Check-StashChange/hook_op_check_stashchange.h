#ifndef __HOOK_OP_CHECK_STASHCHANGE_H__
#define __HOOK_OP_CHECK_STASHCHANGE_H__

#include "perl.h"
#include "hook_op_check.h"

typedef OP *(*hook_op_check_stashchange_cb) (pTHX_ OP *, const char *new_stash, const char *old_stash, void *);

UV hook_op_check_stashchange (hook_op_check_stashchange_cb cb, void *user_data);
void *hook_op_check_stashchange_remove (UV id);

#endif
