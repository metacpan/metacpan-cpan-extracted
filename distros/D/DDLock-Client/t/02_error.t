#!/usr/bin/perl -w

use strict;
use warnings;
use Test::More;
use DDLock::Client;

unless (eval { require Error }) {
    plan skip_all => 'Test require Error';
} 
plan tests => 4;

my $cl = DDLock::Client->new( servers => [ 'localhost' ] );
ok($cl, "Got a client object");

eval {
    my $lock = $cl->trylock('test');
    throw Error::Simple("test error");
    #throw My::Error::Test("test error");
    $lock->release;
};
ok $@, "got an error";
isa_ok $@, 'Error::Simple';

my $lock = $cl->trylock('test');
ok $lock, "able to lock test again";

# vim: filetype=perl
