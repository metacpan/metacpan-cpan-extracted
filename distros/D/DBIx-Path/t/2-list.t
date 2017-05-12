#!perl

use strict;
use warnings;

use POSIX qw(:errno_h);
use Test::More tests => 2 + 2*3 + 0;

use lib 't';
require 'testdb.pl';
our $dbh;

use_ok('DBIx::Path');

my $root=DBIx::Path->new(dbh => $dbh, table => 'dbix_path_test');
isa_ok($root, 'DBIx::Path', 'Constructor return');

my @tests=(
    { name => 'root', node => $root, ret => [qw(usr var tmp home)] },
	{ name => 'usr', node => $root->get('usr'), ret => [qw(bin local)] },
	{ name => 'tmp', node => $root->get('tmp'), ret => [] }
);

for my $test(@tests) {
	my @ret=$test->{node}->list();
	is(scalar @ret, scalar @{$test->{ret}}, "$test->{name}->list() returns the right number of children");
	is_deeply([map {$_->name} @ret], $test->{ret}, "    with the right names"); 
}

