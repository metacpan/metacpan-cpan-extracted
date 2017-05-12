#!/usr/bin/env perl
use strict;
use warnings;
use feature qw(say);

use IO::Async::Loop;
use DBIx::Async;

my $loop = IO::Async::Loop->new;
say 'Connecting to db';
$loop->add(my $dbh = DBIx::Async->connect(
	'dbi:SQLite:dbname=:memory:',
	'',
	'', {
		AutoCommit => 1,
		RaiseError => 1,
	}
));

# Clean up if this isn't our first run
$dbh->do(q{DROP TABLE IF EXISTS tmp})

# We start with a simple table definition
->then(sub { $dbh->do(q{CREATE TABLE tmp(id integer primary key autoincrement, content text)}) })
# ... put some values in it
->then(sub { $dbh->do(q{INSERT INTO tmp(content) VALUES ('some text'), ('other text') , ('more data')}) })
# ... and then read them back
->then(sub {
	say "Retrieving data...";
	my $sth = $dbh->prepare(q{SELECT * FROM tmp});
	$sth->execute;
	$sth->iterate(
		fetchrow_hashref => sub {
			my $row = shift;
			say "Row: " . join(',', %$row);
		}
	);
})->on_done(sub {
	say "Query complete";
})->on_fail(sub {
	warn "Failure: @_\n"
})->get;

