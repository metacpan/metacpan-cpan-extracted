#!perl

use strict;
use warnings;

use Test::More tests => 3;

use lib 't';
require 'testdb.pl';
our $dbh;

use_ok('DBIx::Path');

my $root=DBIx::Path->new(dbh => $dbh, table => 'dbix_path_test');
ok($root, 'Constructor returned something');
isa_ok($root, 'DBIx::Path', '   ');
  
