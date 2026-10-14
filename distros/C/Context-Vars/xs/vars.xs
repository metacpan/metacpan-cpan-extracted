# The variables: import, and the doors a test needs onto them.

MODULE = Context::Vars    PACKAGE = Context::Vars

# use Context::Vars qw($request_id $span);
#
# Each name becomes a scalar in the package the `use` is written in. The
# package is the one the calling statement was compiled in, which is where
# perl looks the name up.
void
import(klass, ...)
        SV *klass
    CODE:
    {
        HV *stash = CopSTASH(PL_curcop);
        I32 i;
        PERL_UNUSED_VAR(klass);
        if (!stash && items > 1)
            croak("Context::Vars: cannot tell which package to import into");
        for (i = 1; i < items; i++)
            context_vars_import_one(aTHX_ stash, ST(i));
    }

# True when the scalar is one of this module's variables.
int
_is_var(sv)
        SV *sv
    CODE:
        RETVAL = (SvROK(sv) && context_vars_var_mg(SvRV(sv))) ? 1 : 0;
    OUTPUT:
        RETVAL

# How many values `local` has displaced and not yet put back.
IV
_locals()
    CODE:
    {
        dMY_CXT;
        RETVAL = (IV)(av_len(MY_CXT.locals) + 1);
    }
    OUTPUT:
        RETVAL

# True once code outside any scope has assigned a variable.
int
_has_program()
    CODE:
    {
        dMY_CXT;
        RETVAL = MY_CXT.program ? 1 : 0;
    }
    OUTPUT:
        RETVAL
