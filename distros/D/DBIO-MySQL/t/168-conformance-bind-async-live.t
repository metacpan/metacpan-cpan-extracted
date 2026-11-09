use strict;
use warnings;
use Test::More;

plan skip_all => 'Set DBIO_TEST_MYSQL_DSN, _USER and _PASS to run this test'
  unless $ENV{DBIO_TEST_MYSQL_DSN} && $ENV{DBIO_TEST_MYSQL_USER};

BEGIN {
  eval {
    require IO::Async::Loop;
    require Future::IO::Impl::IOAsync;
    Future::IO::Impl::IOAsync->import;
    require DBIO::MySQL::Storage::Async;
    1;
  } or plan skip_all =>
    'DBIO::Async, IO::Async and Future::IO::Impl::IOAsync required for the future_io transport';
}

use Time::HiRes ();

# LIVE test for karr k121 (core ADR 0060, decision 7): the shared Bind case
# table over the future_io transport. Every operation a case performs on data
# (create, find, count, update, populate) is issued through the *_async API on
# a pooled connection and waited for in its seam; the install, namespace and
# cleanup seams stay on the blocking owner connection.
#
# WHY IT MATTERS. The pool connections of the transport are their own DBD
# handles. What the synchronous storage does for a value on its way out (a
# BLOB bound as binary, 8-bit text bound as characters under DBD::mysql) and
# for a session (STRICT_ALL_TABLES) has to hold there too, or the async path
# cuts and rewrites what the synchronous one stores whole or refuses. Run it
# once against MySQL and once against MariaDB.

{
  package DBIO::MySQL::Test::Conformance::Async;
  use base 'DBIO::MySQL::Test::Conformance';

  my $loop = IO::Async::Loop->new;

  sub conformance_connect_attributes { return (async => 'future_io', pool_size => 2) }

  sub _wait {
    my ($class, $f) = @_;
    my $deadline = Time::HiRes::time() + 60;
    until ($f->is_ready) {
      die "conformance: a Future did not settle in 60 seconds\n"
        if Time::HiRes::time() > $deadline;
      $loop->loop_once(0.05);
    }
    return $f->get;
  }

  sub conformance_create {
    my ($class, $schema, $source, $values) = @_;
    my $row = $class->_wait($schema->resultset($source)->create_async({ %{ $values || {} } }));
    $class->_wait($row->discard_changes_async);
    return { $row->get_columns };
  }

  sub conformance_find {
    my ($class, $schema, $source, $cond) = @_;
    my $row = $class->_wait($schema->resultset($source)->search($cond || {})->first_async);
    return undef unless $row;
    return { $row->get_columns };
  }

  sub conformance_count {
    my ($class, $schema, $source, $cond) = @_;
    return $class->_wait($schema->resultset($source)->search($cond || {})->count_async);
  }

  sub conformance_update {
    my ($class, $schema, $source, $cond, $set) = @_;
    # no ResultSet::update_async: the storage's, as the ResultSet's update calls it
    my $rs = $schema->resultset($source)->search($cond || {});
    return $class->_wait($schema->storage->update_async(
      $rs->result_source, $set, $rs->_resolved_attrs->{where} || {}));
  }

  sub conformance_delete {
    my ($class, $schema, $source, $cond) = @_;
    my $rs = $schema->resultset($source)->search($cond || {});
    return $class->_wait($schema->storage->delete_async(
      $rs->result_source, $rs->_resolved_attrs->{where} || {}));
  }

  # no populate_async: the rows go in one by one through the transport
  sub conformance_populate {
    my ($class, $schema, $source, $rows) = @_;
    $class->_wait($schema->resultset($source)->create_async({ %$_ })) for @$rows;
    return;
  }
}

local $SIG{ALRM} = sub { BAIL_OUT('t/168 timed out') };
alarm 600;

DBIO::MySQL::Test::Conformance::Async->run('Bind');

done_testing;
