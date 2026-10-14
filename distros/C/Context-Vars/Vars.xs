#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#define MY_CXT_KEY "Context::Vars::_guts" XS_VERSION

#include "hamt_abi.h"
#include "context_vars/context_vars_hamt.h"
#include "context_vars/context_vars_ctx.h"
#include "context_vars/context_vars_ctx_selftest.h"
#include "context_vars/context_vars_var.h"
#include "context_vars/context_vars_scope.h"
#include "context_vars/context_vars_faa.h"
#include "context_vars/context_vars_obj.h"

#include "context_vars_abi.h"
#include "context_vars/context_vars_abi_impl.h"

MODULE = Context::Vars    PACKAGE = Context::Vars

PROTOTYPES: DISABLE

BOOT:
{
    context_vars_hamt_resolve(aTHX);
    {
        MY_CXT_INIT;
        PERL_UNUSED_VAR(MY_CXT);
    }
    context_vars_ctx_init(aTHX);
    context_vars_scope_boot(aTHX);
    context_vars_faa_boot(aTHX);
}

void
CLONE(...)
    CODE:
    {
        MY_CXT_CLONE;
        PERL_UNUSED_VAR(MY_CXT);
        PERL_UNUSED_VAR(items);
        context_vars_ctx_init(aTHX);
    }

INCLUDE: xs/vars.xs
INCLUDE: xs/context.xs
INCLUDE: xs/abi.xs
INCLUDE: xs/test.xs
