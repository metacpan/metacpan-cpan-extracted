#!/usr/bin/env perl
use strict;
use warnings;

use Test::More;
use Test::Fatal;

use Database::Async::SQLite;

my $dbh = new_ok('Database::Async::SQLite' => [ ':memory:' ]);
is($dbh->filename, ':memory:', 'database filename was correct');
ok($dbh->eventfd(), 'have eventfd');

is(exception {
	isa_ok($dbh->prepare(q{create table demo (id int)}), 'Database::Async::SQLite::STH');
}, undef, 'can prepare a statement');

is(exception {
	my $sth = $dbh->prepare(q{create table demo (id int)});
	$sth->step;
}, undef, 'can ->step that statement');

is(exception {
	my $sth = $dbh->prepare(q{insert into demo (id) values (3), (4), (5), (6)});
	$sth->step;
}, undef, 'can ->step our insert');

is(exception {
	my $sth = $dbh->prepare(q{select * from demo});
	$sth->step;
	$sth->step;
	$sth->step;
	$sth->step;
}, undef, 'can ->step our select');

done_testing;

