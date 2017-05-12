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
         unconnected_determination_strategy => sub {
            my ($v) = $_[1] =~ m/(\d+)$/;
            return "SQLite$v"
         },
         unconnected_options => {
            bar => sub { 2 },
         },
         connected_options => {
            baz => sub { 3 },
         },
      },
      { name => 'SQLite1', parents => ['SQLite'] },
      { name => 'SQLite2', parents => ['SQLite'] },
   ]
);

$d->add_driver({ name => 'SQLite3', parents => ['SQLite'] });

is($d->get(undef, 'dbi:SQLite:db1', '_introspector_driver'), 'SQLite1');
ok(exception { $d->get(undef, 'dbi:SQLite:db1', 'foo') }, 'unknown option throws');
$d->replace_driver({
   name => 'SQLite1',
   parents => ['SQLite'],
   unconnected_options => {
      foo => sub { 'bar' },
   },
});
is($d->get(undef, 'dbi:SQLite:db1', 'foo'), 'bar');
is($d->get(undef, 'dbi:SQLite:db2', '_introspector_driver'), 'SQLite2');
is($d->get(undef, 'dbi:SQLite:db2', 'bar'), 2, 'oo dispatch');
subtest 'dbh fallback' => sub {
   my $dbh;
   my $get_dbh = sub { $dbh };
   my $connect = sub { $dbh = DBI->connect('dbi:SQLite::memory:') };
   # ok(exception { warn $d->get($get_dbh, 'dbi:SQLite:db2', 'baz') }, 'throws');
   is($d->get($get_dbh, 'dbi:SQLite:db2', 'baz', {
      dbh_fallback_connect => $connect,
   }), 3, 'dbh fallback');
};

done_testing;
