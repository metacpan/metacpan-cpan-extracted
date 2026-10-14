# The C ABI's Perl-visible ends: the table's address, its version, the
# selftest that walks it, and the version of the HAMT table this module
# resolved when it loaded.

MODULE = Context::Vars    PACKAGE = Context::Vars

# Unsigned, not IV: where the loader maps this object decides the sign bit, and
# a 32-bit perl above 0x7fffffff would hand back a negative from PTR2IV.
UV
_abi_ptr()
    CODE:
        RETVAL = PTR2UV(&CONTEXT_VARS_ABI);
    OUTPUT:
        RETVAL

IV
_abi_version()
    CODE:
        RETVAL = CONTEXT_VARS_ABI.abi_version;
    OUTPUT:
        RETVAL

# The number of the first check that did not hold, or 0; and an object for a
# context the checks built through the table, for the Perl side to read.
void
_abi_selftest()
    PPCODE:
    {
        int step = 0;
        SV *obj = context_vars_abi_selftest(aTHX_ &step);
        EXTEND(SP, 2);
        PUSHs(sv_2mortal(newSViv(step)));
        PUSHs(obj);
    }

# What HAMT's table said its version was when this module loaded. The module
# does not load without one, so this is never zero.
IV
_hamt_abi_version()
    CODE:
        RETVAL = CONTEXT_VARS_HAMT->abi_version;
    OUTPUT:
        RETVAL

# The version of HAMT's table this module was COMPILED against, which is the
# least it accepts.
IV
_hamt_abi_needed()
    CODE:
        RETVAL = HAMT_ABI_VERSION;
    OUTPUT:
        RETVAL
