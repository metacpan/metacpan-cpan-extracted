#!/usr/bin/env perl 
use strict;
use warnings;

use IO::Async::Loop;
use Ryu::Async;
use Database::Async::SQLite;

$loop->add(
	$_
) for
	(my $dbh = Database::Async::SQLite->new(db => ':memory:')),
	(my $ryu = Ryu::Async->new);

# Start off with some config - including our base table
(fmap0 {
	$dbh->do($_)
} foreach => [
	q{pragma mmap_size = 8388608},
	q{pragma auto_vacuum = 2},
	q{pragma automatic_index = on},
	q{pragma encoding = "UTF-8"},
	q{pragma foreign_keys = on},
	q{pragma journal_mode = memory},
	q{pragma recursive_triggers = on},
	q{pragma synchronous = off},
	q{create table demo (id integer primary key, key text, value text, last_updated datetime)},
])->get;

# Add some values
$dbh->txn(sub {
	my ($txn) = @_;
	$txn->prepare(
		q{insert into demo (key, value, last_updated) values (?, ?, 'now')}
	)->then(sub {
		my ($sth) = @_;
		$sth->sink(
			$ryu->from(
				[xyz => 123],
				[abc => 456],
				[def => 789]
			)
		)->completion
	})
})->get;

# Query some results
$dbh->prepare(
	q{select id, key, value, last_updated from demo}
)->then(sub {
	my ($sth) = @_;
	$sth->execute
		->results_hashref
		->take(2)
		->map(sub { $_->{id} . ' (' . $_->{key} . ')' })
		->each(sub {
			print "ID $_\n";
		})
		->completion
})->get;

# Run an integrity check
(fmap0 {
	$dbh->do($_)
} foreach => [
	q{pragma integrity_check},
	q{pragma foreign_key_check},
])->get;

