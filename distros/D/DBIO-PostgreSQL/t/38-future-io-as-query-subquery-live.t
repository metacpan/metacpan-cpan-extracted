use strict;
use warnings;
use Test::More;

# LIVE parity (dbio-postgresql karr k132): a ResultSet with an as_query
# subquery carrying a literal bind -- in a WHERE ... IN, in a FROM and as a
# column -- gives the same rows and the same count over future_io as over the
# synchronous path. The cause was in the core (the maker hands a literal bind
# of a subquery on as [ \%attrs => $value ]; core karr k342 takes the pair
# apart before the transport), so this test pins the end-to-end result for
# this transport.

my ($dsn, $user, $pass) = @ENV{ map { "DBIO_TEST_PG_${_}" } qw/DSN USER PASS/ };

plan skip_all => 'Set $ENV{DBIO_TEST_PG_DSN}, _USER and _PASS to run this test'
  unless $dsn && $user;

BEGIN {
  eval {
    require IO::Async::Loop;
    require Future::IO::Impl::IOAsync;
    Future::IO::Impl::IOAsync->import;
    1;
  } or plan skip_all =>
    'Future::IO::Impl::IOAsync + IO::Async required for the live future_io roundtrip';
}

use Future::IO;
use DBIO::Test;

# DBIO::Test::Schema keeps no driver in its class: this file runs it on
# PostgreSQL (core ADR 0067).
DBIO::Test::Schema->storage_type('+DBIO::PostgreSQL::Storage');

eval { require DBIO::PostgreSQL::Storage::Async; 1 }
  or plan skip_all =>
    'DBIO::Async not installed (recommends only) -- future_io transport unavailable';

use FindBin;
use lib "$FindBin::Bin/lib";
use LiveServer;
LiveServer->require_server;

my $setup = DBIO::Test::Schema->connect($dsn, $user, $pass);
$setup->storage->dbh_do(sub {
  my (undef, $dbh) = @_;
  local $dbh->{Warn} = 0;
  $dbh->do('DROP TABLE IF EXISTS artist CASCADE');
  $dbh->do(<<'SQL');
CREATE TABLE artist (
    artistid  serial PRIMARY KEY
  , name      VARCHAR(100)
  , rank      INTEGER NOT NULL DEFAULT 13
  , charfield CHAR(10)
)
SQL
});
$setup->resultset('Artist')->populate([
  { name => 'a', rank => 1 }, { name => 'b', rank => 2 },
  { name => 'c', rank => 3 }, { name => 'd', rank => 4 },
]);

my $sync  = $setup;
my $async = DBIO::Test::Schema->connect($dsn, $user, $pass, { async => 'future_io' });

my %case = (
  where_in => sub {
    my ($s) = @_;
    my $sub = $s->resultset('Artist')->search({ rank => { '>' => 1 } },
      { columns => ['artistid'] });
    $s->resultset('Artist')->search({ artistid => { -in => $sub->as_query } },
      { order_by => 'artistid' });
  },
  from => sub {
    my ($s) = @_;
    my $sub = $s->resultset('Artist')->search({ rank => { '>' => 2 } },
      { columns => [qw(artistid name)] });
    $s->resultset('Artist')->search({}, {
      from     => [ { me => $sub->as_query } ],
      columns  => [qw(artistid name)],
      order_by => 'artistid',
    });
  },
);

for my $name (sort keys %case) {
  my @want = map { $_->name } $case{$name}->($sync)->all;
  my $want_count = $case{$name}->($sync)->count;
  ok @want, "$name: the synchronous path finds rows";

  my @got = eval { map { $_->name } $case{$name}->($async)->all_async->get };
  is $@, '', "$name: all_async does not die";
  is_deeply \@got, \@want, "$name: all_async gives the synchronous rows";

  my $got_count = eval { $case{$name}->($async)->count_async->get };
  is $@, '', "$name: count_async does not die";
  is $got_count, $want_count, "$name: count_async gives the synchronous count";
}

done_testing;
