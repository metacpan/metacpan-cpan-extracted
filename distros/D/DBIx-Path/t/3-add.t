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
  
GOOD: {
	my $add_ret=$root->add('lib', 10);
	ok($add_ret,                   "add('lib', 10) returned something");
	isa_ok($add_ret, 'DBIx::Path', '   ');
	
	my $get_ret=$root->get('lib');
	ok($get_ret,                   "get('lib') returned something");
	isa_ok($get_ret, 'DBIx::Path', '   ');
	
	for (qw(pid id name)) {
		is($add_ret->$_(), $get_ret->$_(), "${_}s match");
	}
}

BAD: {
	my $add_ret=$root->add('lib', 11);
	is($add_ret, undef, "re-add('lib', 11) fails");
    is($! + 0, EEXIST, '    and sets $! to EEXIST');
	is($root->get('lib')->id, 10, "get('lib') unaffected");
}
