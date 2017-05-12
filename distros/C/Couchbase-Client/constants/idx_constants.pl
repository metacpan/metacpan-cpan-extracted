use PLCB_ConfUtil;

BEGIN {
    PLCB_ConfUtil::env_from_tmpflags();
}

use ExtUtils::H2PM;
module "Couchbase::Client::IDXConst";
use_export;


include "sys/types.h";
include "perl-couchbase.h";
include "perl-couchbase-async.h";

my @const_bases = qw(
    CTORIDX_SERVERS
    CTORIDX_USERNAME
    CTORIDX_PASSWORD
    CTORIDX_BUCKET
    CTORIDX_STOREFLAGS
    CTORIDX_MYFLAGS

    CTORIDX_COMP_THRESHOLD
    CTORIDX_COMP_METHODS

    CTORIDX_SERIALIZE_METHODS

    CTORIDX_TIMEOUT
    CTORIDX_NO_CONNECT

    RETIDX_VALUE
    RETIDX_ERRSTR
    RETIDX_CAS
    RETIDX_ERRNUM
);

constant("PLCB_$_", name => $_) for (@const_bases);

my @ctor_flags = qw(
    USE_COMPAT_FLAGS
    USE_COMPRESSION
    USE_STORABLE
    USE_CONVERT_UTF8
    NO_CONNECT
    DECONVERT
    DEREF_RVPV
);

constant("PLCBf_$_", name => "f$_") for (@ctor_flags);

my @async_bases = qw(
    CTORIDX_CBEVMOD
    CTORIDX_CBERR
    CTORIDX_CBTIMERMOD
    CTORIDX_CBWAITDONE
    CTORIDX_BLESS_EVENT
);

constant("PLCBA_$_", name => $_) for (@async_bases);

my @event_bases = qw(
    READ_EVENT
    WRITE_EVENT
);

constant("LIBCOUCHBASE_$_", name => "COUCHBASE_$_") for (@event_bases);

my @async_reqidx = qw(
    KEY
    VALUE
    EXP
    CAS
    ARITH_DELTA
    ARITH_INITIAL
    STAT_ARGS
);
constant("PLCBA_REQIDX_$_", name => "REQIDX_$_") for (@async_reqidx);

my @async_commands = qw(
    SET
    GET
    ADD
    REPLACE
    APPEND
    PREPEND
    REMOVE
    TOUCH
    ARITHMETIC
    STATS
    FLUSH
);
constant("PLCBA_CMD_$_") for (@async_commands);

my @async_reqtypes = qw(
    SINGLE
    MULTI
);
constant("PLCBA_REQTYPE_$_", name => "REQTYPE_$_") for (@async_reqtypes);


my @async_cbtypes = qw(
    COMPLETION
    INCREMENTAL
);
constant("PLCBA_CBTYPE_$_", name => "CBTYPE_$_") for @async_cbtypes;


my @evidx_constants = qw(
    FD
    DUPFH
    WATCHFLAGS
    STATEFLAGS
    OPAQUE
    PLDATA
);
constant("PLCBA_EVIDX_$_", name => "EVIDX_$_") for (@evidx_constants);

my @evactions = qw(
    WATCH
    UNWATCH
    SUSPEND
    RESUME
);

constant("PLCBA_EVACTION_$_", name => "EVACTION_$_") for (@evactions);

my @evstates = qw(
    INITIALIZED
    ACTIVE
    SUSPENDED
);
constant("PLCBA_EVSTATE_$_", name => "EVSTATE_$_") for (@evstates);


write_output($ARGV[0]);
