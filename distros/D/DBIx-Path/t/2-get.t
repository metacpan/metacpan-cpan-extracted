#!perl

use strict;
use warnings;

use POSIX qw(:errno_h);
use Test::More tests => 2 + 4*4 + 2 + 4*3;

use lib 't';
require 'testdb.pl';
our $dbh;

use_ok('DBIx::Path');

my $root=DBIx::Path->new(dbh => $dbh, table => 'dbix_path_test');
isa_ok($root, 'DBIx::Path', 'Constructor return');

GOOD1: {  
	my $id=1;
	for (qw(usr var tmp home)) {
		my $node=$root->get($_);
		ok($node,                     "get('$_') gives something");
		isa_ok($node, 'DBIx::Path',   '   ');
		is(eval { $node->name }, $_,  '        with the right name');
		is(eval { $node->id }, $id++, '        and the right ID');
	}
}

GOOD2: {
	my $p=$root;
	my $pname='root';
	my $pid=0;
	for (qw(usr bin perl)) {
		my $node=$p->get($_);
		ok($node,                      "descending tests - get('$_') in $pname gives something");
		isa_ok($node, 'DBIx::Path',    '   ');
		is(eval { $node->name }, $_,   '        with the right name');
		is(eval { $node->pid  }, $pid, '        and the right parent ID');
		$p=$node;
		$pname="'".$node->name."'";
		$pid=$node->id;
	}
}

BAD: {
    my $node=$root->get('lost+found');
    is($node, undef, "get('lost+found') returns undef");
    is($!+0, ENOENT, '    And sets $! to ENOENT');
}
