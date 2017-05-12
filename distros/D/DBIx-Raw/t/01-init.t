#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;
use lib './t';
use dbixtest;

plan tests => 5;

use_ok( 'DBIx::Raw' ) || print "Bail out!\n";

my $db;
isa_ok($db = DBIx::Raw->new(dsn => dsn(), user => user(), password => password()), 'DBIx::Raw');

is($db->dsn, dsn());
is($db->user, user());
is($db->password, password());
