#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;
use DBIx::Introspector;
use DBI;

my $d = DBIx::Introspector->new(
   drivers => [ map DBIx::Introspector::Driver->new($_),
      {
         name => 'DBI',
         connected_determination_strategy => sub { $_[1]->{Driver}{Name} },
         unconnected_determination_strategy => sub {
            my $dsn = $_[1] || $ENV{DBI_DSN} || '';
            my ($driver) = $dsn =~ /dbi:([^:]+):/i;
            $driver ||= $ENV{DBI_DRIVER};
            return $driver
         },
      },
      {
         name => 'SQLite',
         parents => ['DBI'],
         connected_determination_strategy => sub {
            my ($v) = $_[1]->selectrow_array('SELECT "value" FROM "a"');
            return "SQLite$v"
         },
         connected_options => {
            bar => sub { 2 },
         },
         unconnected_options => {
            borg => sub { 'magic ham' },
         },
      },
      {
         name => 'SQLite1',
         parents => ['SQLite'],
         unconnected_options => { a => 1 },
      },
      {
         name => 'SQLite2',
         parents => ['SQLite'],
         unconnected_options => { a => 0 },
      },
   ]
);

$d->add_driver({ name => 'SQLite3', parents => ['SQLite'] });

my $dbh = DBI->connect('dbi:SQLite::memory:');
$dbh->do($_) for (
   'CREATE TABLE "a" ("value" NOT NULL)',
   'INSERT INTO "a" ("value") VALUES (1)',
);
is($d->get($dbh, 'dbi:SQLite::memory:', '_introspector_driver'), 'SQLite1');
is($d->get($dbh, 'dbi:SQLite::memory:', 'a'), 1, 'true bool');
ok(exception { $d->get($dbh, 'dbi:SQLite::memory:', 'foo') }, 'unknown option dies');;
$d->replace_driver({
   name => 'SQLite1',
   parents => ['SQLite'],
   connected_options => {
      foo => sub { 'bar' },
   },
});
is($d->get($dbh, 'dbi:SQLite::memory:', 'foo'), 'bar');
$dbh->do('UPDATE "a" SET "value" = 2');
is($d->get($dbh, 'dbi:SQLite::memory:', '_introspector_driver'), 'SQLite2');
is($d->get($dbh, 'dbi:SQLite::memory:', 'a'), 0, 'false bool');
is($d->get($dbh, 'dbi:SQLite::memory:', 'bar'), 2, 'oo dispatch');

is($d->get($dbh, 'dbi:SQLite::memory:', 'borg'), 'magic ham', 'working $dbh still dispatches to dsn');

done_testing;
