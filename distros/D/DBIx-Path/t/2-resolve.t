#!perl

use strict;
use warnings;

use POSIX qw(:errno_h);
use Test::More tests => 2 + 5*3 + 5*3;

use lib 't';
require 'testdb.pl';
our $dbh;

use_ok('DBIx::Path');

my $root=DBIx::Path->new(dbh => $dbh, table => 'dbix_path_test');
isa_ok($root, 'DBIx::Path', 'Constructor return');

GOOD: {  
	my @teston=(
		{ path => [qw(usr)         ], id => 1, pid => 0, name => 'usr' },
		{ path => [qw(usr bin)     ], id => 5, pid => 1, name => 'bin' },
		{ path => [qw(usr bin perl)], id => 7, pid => 5, name => 'perl' },
    );
    for my $test (@teston) {
        my $node=$root->resolve( @{$test->{path}} );
        ok($node,                   "resolve( qw( @{$test->{path}} ) ) returned something");
		isa_ok($node, 'DBIx::Path', '   ');
		for my $meth (qw(id pid name)) {
            is($node->$meth(), $test->{$meth}, "        \$node->$meth is '$test->{$meth}'");
		}
	}
}

BAD: {
    my @teston=(
		{ path => [qw(lost+found)]            , good => [qw()]   , bad => [qw(lost+found)]        , parent => 0 },
		{ path => [qw(usr lost+found)]        , good => [qw(usr)], bad => [qw(lost+found)]        , parent => 1 },
		{ path => [qw(usr lost+found 1097763)], good => [qw(usr)], bad => [qw(lost+found 1097763)], parent => 1 }
	);
    
    for my $test(@teston) {
        my $ret=$root->resolve( @{$test->{path}} );
		is($ret, undef,           "resolve( qw( @{$test->{path}} ) ) returned undef");
		is($!+0, ENOENT,          '    with $! set to ENOENT');
		no warnings 'once';
		is_deeply($test->{good}, \@DBIx::Path::RESOLVED, "    \@RESOLVED = qw( @{$test->{good}} )");
		is_deeply($test->{bad}, \@DBIx::Path::FAILED,    "    \@FAILED   = qw( @{$test->{bad}} )");
		is($test->{parent}, $DBIx::Path::PARENT->id,     "    \$PARENT->id = $test->{parent}");
	}
}
