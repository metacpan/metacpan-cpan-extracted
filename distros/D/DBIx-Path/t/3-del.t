#!perl

use strict;
use warnings;

use POSIX qw(:errno_h);
use Test::More tests => 2 + 4 + 3;

use lib 't';
require 'testdb.pl';
our $dbh;

use_ok('DBIx::Path');

my $root=DBIx::Path->new(dbh => $dbh, table => 'dbix_path_test');
isa_ok($root, 'DBIx::Path', 'Constructor return');
  
GOOD: {
	isa_ok($root->get('tmp'), 'DBIx::Path', 'Sanity check--all is right in the world');
	my $del_ret=$root->del('tmp');
	ok($del_ret, "del('tmp') thinks it worked");
    my $get_ret=$root->get('tmp');
    is($get_ret, undef, "...and it was right.");
    is($! + 0, ENOENT, "    Proper error return from get()");
    undef $!;
}

BAD: {
	is($root->get('lost+found'), undef, 'Sanity check again');
    undef $!;
	ok(!$root->del('lost+found'), "del('lost+found') fails, as it should");
    is($! + 0, ENOENT, '    $! is ENOENT');
}
