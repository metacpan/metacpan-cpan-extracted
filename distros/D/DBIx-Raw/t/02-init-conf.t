#!perl
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;
use lib './t';
use dbixtest;
use Cwd 'abs_path';

plan tests => 5;

use_ok( 'DBIx::Raw' ) || print "Bail out!\n";

my $db;
my $abs_path = abs_path('t/dbix_conf.yaml');
isa_ok($db = DBIx::Raw->new(conf => $abs_path), 'DBIx::Raw');

is($db->dsn, dsn());
is($db->user, user());
is($db->password, password());
