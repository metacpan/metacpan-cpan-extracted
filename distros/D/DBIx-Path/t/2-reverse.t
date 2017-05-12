#!perl

use strict;
use warnings;

use POSIX qw(:errno_h);
use Test::More tests => 2 + 4*3;

use lib 't';
require 'testdb.pl';
our $dbh;

use_ok('DBIx::Path');

my $root=DBIx::Path->new(dbh => $dbh, table => 'dbix_path_test');
isa_ok($root, 'DBIx::Path', 'Constructor return');

GOOD: {  
	my @teston=(
		[qw(usr)         ],
		[qw(usr bin)     ],
		[qw(usr bin perl)],
    );
    for my $test (@teston) {
        my $node=$root->resolve(@$test);
		isa_ok($node, 'DBIx::Path', "resolve(@$test) return");
		my @ret=$node->reverse();
        is(scalar @ret, 1, "node->reverse returned 1 result");
        is(ref $ret[0], 'ARRAY', "    an arrayref");
        is_deeply($ret[0], $test, "    and it looks like what it should");
	}
}
