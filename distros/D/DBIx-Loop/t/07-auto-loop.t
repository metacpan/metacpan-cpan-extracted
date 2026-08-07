#!perl
use 5.008003;
use strict;
use warnings;
use Test::More;

# loop => 'auto' adapts an already-loaded loop and croaks when none is loaded.

BEGIN {
    plan skip_all => 'DBD::SQLite required' unless eval { require DBD::SQLite; 1 };
}
use DBIx::Loop;

# nothing loaded yet -> croak
{
    my $err;
    eval { DBIx::Loop->connect("dbi:SQLite:dbname=:memory:", '', '', {}, loop => 'auto') }
        or $err = $@;
    like($err, qr/found no loaded event loop/, "auto with no loop loaded croaks");
}

SKIP: {
    skip 'IO::Async required', 2 unless eval { require IO::Async::Loop; 1 };
    my $db = DBIx::Loop->connect("dbi:SQLite:dbname=:memory:", '', '',
        { RaiseError => 1, PrintError => 0 }, loop => 'auto');
    isa_ok($db->loop, 'DBIx::Loop::Loop::IOAsync', 'auto picked the loaded IO::Async');
    my $f = $db->query("SELECT 1");
    $db->loop->await($f);
    ok($f->is_done, 'auto-adapted loop serves a query');
    $db->disconnect;
}

done_testing();
