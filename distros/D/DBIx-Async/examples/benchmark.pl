#!/usr/bin/env perl
use strict;
use warnings;
use IO::Async::Loop;
use DBIx::Async;
use Future::Utils qw(repeat);
use Benchmark qw(:hireswallclock cmpthese);
use DBI;

use constant MAX_COUNT => 2000;
use constant DEBUG => 0;

my $dsn = 'dbi:SQLite:dbname=:memory:';

cmpthese -5, {
	'DBIx::Async' => sub {
		my $loop = IO::Async::Loop->new;
		$loop->add(my $dbh = DBIx::Async->connect(
			$dsn,
			'',
			'', {
				AutoCommit => 1,
				RaiseError => 1,
			}
		));

		Future->needs_all(
			$dbh->do(q{PRAGMA journal_mode=WAL}),
			$dbh->do(q{PRAGMA wal_autocheckpoint=0}),
			$dbh->do(q{PRAGMA synchronous=NORMAL}),

			# Clean up if this isn't our first run
			$dbh->do(q{drop table if exists tmp}),
		)

		# We start with a simple table definition
		->then(sub { $dbh->do(q{create table tmp(id serial, content text)}) })
		# ... put some values in it
		->then(sub { $dbh->begin_work })
		->then(sub {
			my $count = 0;
			Future->needs_all(
				map {
					$dbh->do(q{insert into tmp(content) values (?)}, undef, 'value ' . $_);
				} 0..MAX_COUNT-1
			)
		})
		->then(sub { $dbh->commit })

		# ... and then read them back
		->then(sub {
			my $sth = $dbh->prepare(q{select * from tmp order by id});
			$sth->execute
			->then(sub {
				my %seen;
				$sth->iterate(
					fetchrow_hashref => sub {
						my $row = shift;
						my ($id) = $row->{content} =~ /^value (\d+)$/ or die 'invalid entry found';
						die "Too many values for $id" if $seen{$id}++;
					}
				)->on_done(sub {
					my $id = 0;
					for (sort { $a <=> $b } keys %seen) {
						die "Wrong ID found: $_, expecting $id" unless $id++ eq $_;
					}
				});
			})
		})->on_fail(sub {
			warn "Failure: @_\n"
		})->get;
	},
	'DBD::SQLite' => sub {
		my $dbh = DBI->connect(
			$dsn,
			'',
			'', {
				AutoCommit => 1,
				RaiseError => 1,
			}
		);

			$dbh->do(q{PRAGMA journal_mode=WAL});
			$dbh->do(q{PRAGMA wal_autocheckpoint=0});
			$dbh->do(q{PRAGMA synchronous=NORMAL});
		if(0) {
			$dbh->sqlite_commit_hook(sub {
				warn "Manual checkpoint...\n" if DEBUG;
				my $sth = $dbh->prepare(q{PRAGMA wal_checkpoint(FULL)});
				$sth->execute;
				while(my $row = $sth->fetchrow_arrayref) {
					warn "Checkpoint result: @$row\n" if DEBUG;
				}
				warn "Done\n" if DEBUG;
				0
			});
		}

		$dbh->do(q{drop table if exists tmp});
		$dbh->do(q{create table tmp(id serial, content text)});
		# $dbh->do(q{create table tmp(id integer primary key autoincrement, content text)});
		$dbh->begin_work;
		my $count = 0;
		do {
			$dbh->do(q{insert into tmp(content) values (?)}, undef, 'value ' . $count);
		} while(++$count < MAX_COUNT);
		$dbh->commit;

		my $sth = $dbh->prepare(q{select * from tmp order by id});
		$sth->execute;
		my %seen;
		while(my $row = $sth->fetchrow_hashref) {
			my ($id) = $row->{content} =~ /^value (\d+)$/ or die 'incorrect value found';
			die "Too many values for $id" if $seen{$id}++;
		}
		my $id = 0;
		for (sort { $a <=> $b } keys %seen) {
			die "Wrong ID found: $_, expecting $id" unless $id++ eq $_;
		}
		$dbh->disconnect;
	},
};

