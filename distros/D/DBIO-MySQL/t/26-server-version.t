use strict;
use warnings;

use Test::More;

use DBIO::MySQL::Storage;
use DBIO::MySQL::Storage::MariaDB;

# karr #28 -- where the driver gets its idea of the server version from.
#
# Everything here is string logic and therefore fully offline: the only thing
# a real server contributes is the string itself, and both shapes it comes in
# were measured against real servers on 2026-07-25 (MySQL 8.0.46 and MariaDB
# 11.8.8, reached through DBD::MariaDB):
#
#   get_info(SQL_DBMS_VER)   SELECT VERSION()
#   08.00.4600               8.0.46
#   11.08.0800               11.8.8-MariaDB-ubu2404
#
# The packed get_info form is what core's normaliser chokes on -- it stops at
# the first dotted component above 999 -- and it carries no product name, so
# both the version gate and the MariaDB check were reading a server that does
# not exist. The fake handle below serves both strings, so a test can pin what
# each of the two routes answers.

{
  package VerTest::DBH;

  sub new {
    my ($class, %args) = @_;
    return bless { %args, queries => [] }, $class;
  }

  sub selectrow_array {
    my ($self, $sql) = @_;
    push @{ $self->{queries} }, $sql;
    return () unless defined $self->{version};
    return ($self->{version});
  }

  sub get_info {
    my ($self, $type) = @_;
    push @{ $self->{queries} }, "get_info($type)";
    return $self->{get_info};
  }
}

{
  # The two storage classes, with the connection stubbed out. Nothing else is
  # overridden: _server_info, its caching and its normaliser are core's own.
  package VerTest::MySQL;
  use base 'DBIO::MySQL::Storage';
  use mro 'c3';
  sub ensure_connected { 1 }
  sub _get_dbh { $_[0]->{__dbh} }

  package VerTest::MariaDB;
  use base 'DBIO::MySQL::Storage::MariaDB';
  use mro 'c3';
  sub ensure_connected { 1 }
  sub _get_dbh { $_[0]->{__dbh} }
}

# A fresh storage per case: _server_info caches on the handle, which is the
# point of asking the server only once.
sub storage {
  my ($class, %server) = @_;
  my $storage = $class->new;
  $storage->{__dbh} = VerTest::DBH->new(%server);
  return $storage;
}

# --- the two servers that were actually measured -------------------------

{
  my $s = storage('VerTest::MySQL',
    version => '8.0.46', get_info => '08.00.4600');

  is $s->_server_info->{dbms_version}, '8.0.46',
    'the version comes from SELECT VERSION(), not from get_info';
  is $s->_server_info->{normalized_dbms_version}, '8.000046',
    'so MySQL 8.0.46 normalizes to the version it really is';
  is $s->_is_mariadb, 0, 'and is not mistaken for a MariaDB';
  is $s->_upsert_row_alias, 'new',
    'the >= 8.0.20 row alias is used on a server that has it (karr #28)';

  is_deeply $s->{__dbh}{queries}, ['SELECT VERSION()'],
    'one query, and get_info is not consulted at all';
}

{
  my $s = storage('VerTest::MariaDB',
    version => '11.8.8-MariaDB-ubu2404', get_info => '11.08.0800');

  is $s->_server_info->{normalized_dbms_version}, '11.008008',
    'MariaDB 11.8.8 normalizes to 11.8.8';
  is $s->_is_mariadb, 1, 'and the product name in the string identifies it';
  is $s->_upsert_row_alias, undef,
    'so it keeps VALUES(col) -- MariaDB never grew the row alias';
}

# --- what the inherited get_info route answers, and why it is not used ----

# The fallback is reached when the server does not answer SELECT VERSION().
# It is also, verbatim, the behaviour this override exists to replace, so
# these two cases pin the bug rather than merely the fix.

{
  my $s = storage('VerTest::MySQL',
    version => undef, get_info => '08.00.4600');

  is $s->_server_info->{dbms_version}, '08.00.4600',
    'without SELECT VERSION() the inherited get_info route still answers';
  is $s->_server_info->{normalized_dbms_version}, '8.000000',
    'and the packed form collapses to 8.0.0 -- core stops at the part above 999';
  is $s->_upsert_row_alias, undef,
    'which is how a MySQL 8.0.46 ended up emitting the deprecated VALUES() form';
}

{
  my $s = storage('VerTest::MySQL',
    version => undef, get_info => '11.08.0800');

  is $s->_is_mariadb, 0,
    'the packed form carries no product name, so MariaDB is not recognised';
  is $s->_upsert_row_alias, 'new',
    'and 11.008800 sails past the 8.0.20 gate -- the AS new that MariaDB '
  . 'answers with a syntax error';
}

# --- the version gate itself ----------------------------------------------

my @gate = (
  [ '5.7.44',                        undef, 'MySQL 5.7: no row alias' ],
  [ '8.0.19',                        undef, 'MySQL 8.0.19: still VALUES(col)' ],
  [ '8.0.20',                        'new', 'MySQL 8.0.20: the row alias exists' ],
  [ '8.4.0',                         'new', 'MySQL 8.4' ],
  [ '10.11.6-MariaDB-1:10.11.6+maria~ubu2204', undef, 'MariaDB 10.11' ],
  [ '11.8.8-MariaDB-ubu2404',        undef, 'MariaDB 11.8' ],
);

for my $case (@gate) {
  my ($version, $expected, $name) = @$case;
  my $s = storage('VerTest::MySQL', version => $version);
  is $s->_upsert_row_alias, $expected, $name;
}

# --- the product is a fact about the server, not about the DBD ------------

# DBD::MariaDB talks to MySQL servers and DBD::mysql talks to MariaDB ones, so
# the storage class the connection landed in cannot answer which engine is at
# the other end. Both of these are live configurations: the first is how the
# live suite reaches the MySQL pod (DBD::MariaDB is the only MySQL-capable DBD
# installed), the second is a MariaDB server under a schema that loaded the
# plain MySQL component, which keeps DBIO::MySQL::Storage because the schema
# declares its driver, so it does not reach the MariaDB subclass.

{
  my $s = storage('VerTest::MariaDB',
    version => '8.0.46', get_info => '08.00.4600');

  is $s->_is_mariadb, 0,
    'the MariaDB storage class does not make the server a MariaDB';
  is $s->_upsert_row_alias, 'new',
    'and a MySQL 8.0.46 reached through DBD::MariaDB gets the row alias';
}

{
  my $s = storage('VerTest::MySQL', version => '11.8.8-MariaDB-ubu2404');

  is $s->_is_mariadb, 1,
    'a MariaDB server reached through the plain MySQL storage is recognised';
  is $s->_upsert_row_alias, undef,
    'so it gets VALUES(col) instead of SQL its parser rejects';
}

done_testing;
