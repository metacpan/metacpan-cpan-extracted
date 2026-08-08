MODULE = DBIx::Loop        PACKAGE = DBIx::Loop

# Public C ABI entry point (dbil_abi.h / dbil_abi_impl.h): a DBI-style
# versioned function-pointer table for XS consumers (Punk::Model::DBIx::Loop,
# ...). Resolved at runtime - call_pv("DBIx::Loop::_abi_ptr"), INT2PTR, check
# abi_version.

IV
_abi_ptr()
    CODE:
        RETVAL = PTR2IV(&dbil_abi_table);
    OUTPUT:
        RETVAL

# Resolve and exercise the whole table from C: future lifecycle (done, fail,
# on_ready including the already-settled case, double-settle no-op, borrowed
# values), is_future against things that are not futures, every select*
# reshape, and connect's no-croak error contract. 1 = every check passed.
IV
_abi_selftest()
    CODE:
        RETVAL = dbil_abi_selftest(aTHX);
    OUTPUT:
        RETVAL

# The table's version, for tests and for a consumer that would rather ask
# than dereference the pointer itself.
IV
_abi_version()
    CODE:
        RETVAL = dbil_abi_table.abi_version;
    OUTPUT:
        RETVAL

# Drive the table against a real database: connect, exec, exec_shaped with and
# without binds, a C on_ready that fires when the rows land, and the failure
# path - all in C, with only the await going back through Perl. 1 = passed.
IV
_abi_dbtest(adapter, dsn)
        SV *adapter
        SV *dsn
    CODE:
        RETVAL = dbil_abi_dbtest(aTHX_ adapter, dsn);
    OUTPUT:
        RETVAL
