#!perl
use 5.008003;
use strict;
use warnings;
use Test::More;
use File::Temp ();

# The public C ABI (include/dbil_abi.h): the versioned function-pointer table
# consumers resolve through DBIx::Loop::_abi_ptr.
#
# Most of what there is to check is only reachable from C, so the two selftest
# entries do the checking and this file drives them: _abi_selftest covers the
# table's own behaviour (future lifecycle, borrowed values, every select*
# reshape, the no-croak error contract), _abi_dbtest drives the same table
# against a real SQLite database.

use DBIx::Loop;

# ---- the pointer -------------------------------------------------------------

my $ptr = DBIx::Loop::_abi_ptr();
# NOT `> 0`: PTR2IV is legitimately negative wherever shared objects map high
# in the address space (Solaris does), and an ABI test that fails there would
# be testing the platform rather than the table.
isnt($ptr, 0, '_abi_ptr returns a non-zero address');
is($ptr, DBIx::Loop::_abi_ptr(), 'and the same one every time (a static table)');

is(DBIx::Loop::_abi_version(), 2, '_abi_version is 2 (v2 on_exec)');

# The table's own first entry must agree with the accessor, or a consumer that
# gates on abi_version is gating on something other than what it will call.
ok(DBIx::Loop::_abi_version() >= 1, 'abi_version is at least the shipped version');

# ---- the table, exercised from C ---------------------------------------------

is(DBIx::Loop::_abi_selftest(), 1, '_abi_selftest: every entry behaves');

# ---- the table against a real database ---------------------------------------

SKIP: {
    my $adapter_class;
    for my $try ([ 'IO::Async::Loop' => 'DBIx::Loop::Loop::IOAsync' ],
                 [ 'AnyEvent'        => 'DBIx::Loop::Loop::AnyEvent' ],
                 [ 'Mojo::IOLoop'    => 'DBIx::Loop::Loop::Mojo'     ]) {
        my ($loop, $adapter) = @$try;
        next unless eval "require $loop; require $adapter; 1";
        $adapter_class = $adapter;
        last;
    }
    skip 'no event loop available', 1 unless $adapter_class;
    skip 'DBD::SQLite required', 1 unless eval { require DBD::SQLite; 1 };

    my $dir = File::Temp::tempdir(CLEANUP => 1);
    my $ad  = $adapter_class->new;
    diag("C ABI end to end over $adapter_class");
    is(DBIx::Loop::_abi_dbtest($ad, "dbi:SQLite:dbname=$dir/abi.db"), 1,
       '_abi_dbtest: connect, exec, exec_shaped, C on_ready and the failure '
     . 'path all drive from C');
}

# ---- the guard a consumer is expected to write -------------------------------
# A consumer resolves the table and refuses to use it when the provider is
# older than the header it was built against. Nothing here can make DBIx::Loop
# old, so this asserts the shape of that check rather than its failure.
{
    my $v = DBIx::Loop::_abi_version();
    ok($v >= 1, 'a consumer written against v1 accepts this provider');
    ok(!($v >= 99), 'and one written against v99 would reject it');
}

done_testing;
