#!/usr/bin/perl -w

use strict;
use Test::More;

use DDLock::Client;

BEGIN { plan tests => 14 }

my $cl = DDLock::Client->new( servers => [ 'localhost' ] );
ok($cl, "Got a client object");

{
    my $lock = $cl->trylock('test_a');
    ok($lock, "Got a lock for 'test_a'");
}

{
    my $lock = $cl->trylock('test_a');
    ok($lock, "Got a lock for 'test_a' again.");
}

{
    my $lock = $cl->trylock('test_b');
    ok($lock, "Got a lock for 'test_b'");
    my $rv = $lock->release();
    ok($rv, "Lock release succeeded");
    $rv = eval { $lock->release() };
    ok ! $rv, "no return value";
    like $@, qr/ERR didnthave/, "release() die if it couldn't release";
    my $lock2 = $cl->trylock('test_b');
    ok($lock, "Got a lock for 'test_b' again");
}

{
    my $lock = $cl->trylock('test_c');
    ok($lock, "Got a lock for 'test_c'");
    my $lock2 = $cl->trylock('test_c');
    ok(!defined($lock2), "Got no lock for 'test_c' again without release");
    diag "Error was '$DDLock::Client::Error'";
}

{
    my $lock = $cl->trylock('test_d');
    ok $lock, "got lock test_d";
    $lock->DESTROY;

    my $lock2 = $cl->trylock('test_d');
    ok $lock2, "got lock test_d again";
}

{
    my $lock = $cl->trylock('test_e');
    my $lock2 = $cl->trylock('test_f');
    $lock2->{name} = "test_e";
    ok $lock2->release, "release e by hack";
    eval { $lock->release };
    like $@, qr/didnthave/, "got an error, because lock was stolen (SHOULDN'T happen)";
}

# vim: filetype=perl
