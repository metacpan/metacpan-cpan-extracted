#!perl

use strict;
use warnings;

use POSIX qw(:errno_h);
use Test::More tests => 2 + 4 + 3 + 3;

use lib 't';
require 'testdb.pl';
our $dbh;

use_ok('DBIx::Path');

my $root=DBIx::Path->new(dbh => $dbh, table => 'dbix_path_test');
isa_ok($root, 'DBIx::Path', 'Constructor return');
  
GOOD1: {
	my $set_ret=$root->set('lib', 10);
	ok($set_ret,                   "set('lib', 10) returned something");
	isa_ok($set_ret, 'DBIx::Path', '   ');
	
	my $get_ret=$root->get('lib');
	ok($get_ret,                   "get('lib') returned something");
	isa_ok($get_ret, 'DBIx::Path', '   ');
	
	for (qw(pid id name)) {
		is($set_ret->$_(), $get_ret->$_(), "${_}s match");
	}
}

GOOD2: {
	my $set_ret=$root->set('lib', 11);
    ok($set_ret,                   "re-set('lib', 11) returned something");
	isa_ok($set_ret, 'DBIx::Path', '   ');
	is($root->get('lib')->id, 11, "get('lib') registers change");
}
