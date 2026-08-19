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

# DBIx::Loop->on_exec(\&start, \&done): the same statement-observer registry
# the C ABI's on_exec writes to, reached from Perl - for a consumer that is
# not an XS module, which on the native backend has no other hook at all
# (there is no DBI statement handle for $dbh->{Callbacks} to hang off).
# Same contract, one Perl call per statement as the price. Public.
IV
on_exec(class, start, done = &PL_sv_undef)
        SV *class
        SV *start
        SV *done
    CODE:
        PERL_UNUSED_VAR(class);
        RETVAL = dbil_obs_add_perl(aTHX_ start, done);
    OUTPUT:
        RETVAL

# v2 on_exec, for t/13-observer.t. Registering a C callback is not something
# Perl can do, so the test drives these two instead.
IV
_abi_observer_install()
    CODE:
        RETVAL = dbil_obs_selftest_install(aTHX);
    OUTPUT:
        RETVAL

# (starts, dones, resolved, failed, nbind, is_query, sql) since load.
void
_abi_observer_state()
    PPCODE:
        EXTEND(SP, 7);
        mPUSHi(DBIL_OBS_ST_STARTS);
        mPUSHi(DBIL_OBS_ST_DONES);
        mPUSHi(DBIL_OBS_ST_OK);
        mPUSHi(DBIL_OBS_ST_ERR);
        mPUSHi(DBIL_OBS_ST_BIND);
        mPUSHi(DBIL_OBS_ST_QUERY);
        mPUSHp(DBIL_OBS_ST_SQL, strlen(DBIL_OBS_ST_SQL));

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
