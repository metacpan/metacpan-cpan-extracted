# ABSTRACT: The async mode of a broker-backed connection is given beside the broker
use strict;
use warnings;

use Test::More;
use Test::Exception;

use DBIO::Test;
use DBIO::Test::Storage;
use DBIO::Storage::Async;
use DBIO::AccessBroker::Static;

# OFFLINE (karr k240, ADR 0030 addendum 2026-09-27). Core read a connection's
# async mode only out of the broker's ANSWER: the 'async' attribute of a
# DBI-form answer (Vault's dbi_attrs). A broker answering a hash of connection
# parameters (Static) cannot put one there, and the connect call had no slot
# for it: connect($broker, { async => ... }) was not taken as broker form, so
# the broker object silently became the DSN and no broker was attached.
#
# What this file claims:
#   1. [ $broker, { async => $mode } ] is broker form: the broker is attached,
#      the mode is this connection's, and the DBI connect info is the broker's
#      answer alone -- a mode beside the broker is no DBI attribute;
#   2. the async backend is handed the broker alone, the form every backend
#      takes a broker in, when nothing but the mode stands beside it;
#   3. [ $broker ] and [ $broker, {} ] stay sync;
#   4. the connection itself beside the broker throws, naming it. (Until
#      karr k243 this claim was "any key but async beside the broker throws":
#      the backend was handed the broker alone, so another key would have
#      reached the sync connection only. k243 made the hash take the connect
#      options and hands the ones a backend applies to the backend --
#      t/access_broker/09-connect-options-beside-broker.t carries that claim.
#      What stays refused is what the broker answers: dsn, user, password,
#      dbh_maker, dbname, host, port.)
#   5. a DBI-form answer that carries async too must name the same mode; and
#      its pool_size -- the backend's pool size -- does not reach the owner's
#      DBI->connect when the mode was given beside the broker, on
#      connect_info and on the per-connect path (as karr k211 keeps it out
#      when the mode is an attribute).
#
# THE SUBSTITUTIONS: a fake driver storage (DBIO::Test::Storage registered for
# the DBD name 'FakeDBD') with a fake async mode whose backend records the
# connect info it was given; DBI->connect records its arguments.

{
  package T::FakeDriver::Storage;
  use base 'DBIO::Test::Storage';
  DBIO::Storage::DBI->register_driver(FakeDBD => __PACKAGE__);
}

{
  package T::RecordingBackend;
  use base 'DBIO::Storage::Async';
  sub new { my ($class, $schema) = @_; bless { schema => $schema }, $class }
  sub connect_info { my $self = shift; $self->{connect_info} = shift if @_; $self->{connect_info} }
  sub disconnect { 1 }
}

T::FakeDriver::Storage->register_async_mode(k240loop  => 'T::RecordingBackend');
T::FakeDriver::Storage->register_async_mode(k240other => 'T::RecordingBackend');

# A broker answering the DBI form, with attributes of its own.
{
  package T::DBIFormBroker;
  use base 'DBIO::AccessBroker';
  sub new { my ($class, %attrs) = @_; bless { attrs => \%attrs }, $class }
  sub connect_info_for {
    return [ 'dbi:FakeDBD:dbname=app', 'u', 'p', { %{ $_[0]{attrs} } } ];
  }
}

{
  package T::FakeDBH;
  sub new { bless { Active => 1, AutoCommit => 1, RaiseError => 1 }, shift }
  sub FETCH { $_[0]{$_[1]} }
}

my %DEFAULT_ATTRS = (
  AutoCommit         => 1,
  PrintError         => 0,
  RaiseError         => 1,
  ShowErrorStatement => 0,
);

sub static_broker {
  return DBIO::AccessBroker::Static->new(
    host => 'db.example', dbname => 'appdb', username => 'app', password => 's3cret',
  );
}

sub connect_with {
  my (@connect_info) = @_;
  my $schema = DBIO::Test->init_schema(
    no_connect   => 1,
    storage_type => '+T::FakeDriver::Storage',
  );
  return $schema->connection(@connect_info)->storage;
}

# ---------------------------------------------------------------------------
# 1 + 2. The mode beside a hash-answering broker.
# ---------------------------------------------------------------------------
{
  my $broker  = static_broker();
  my $storage = connect_with($broker, { async => 'k240loop' });

  is $storage->access_broker, $broker, 'the broker beside a mode is attached as the broker';
  is $storage->_async_mode, 'k240loop', 'the mode beside the broker is the connection mode';
  is_deeply $storage->_dbi_connect_info, [
    'dbi:FakeDBD:dbname=appdb;host=db.example', 'app', 's3cret', { %DEFAULT_ATTRS },
  ], "the DBI connect info is the broker's answer; the hash beside it adds nothing";

  my $backend = $storage->async;
  isa_ok $backend, 'T::RecordingBackend', 'the async backend of that mode';
  is_deeply $backend->connect_info, [ $broker ], 'the backend is handed the broker alone';
}

# ---------------------------------------------------------------------------
# 3. Without a mode: sync.
# ---------------------------------------------------------------------------
for my $case ([ 'alone' ], [ 'beside an empty hash', {} ]) {
  my ($label, @rest) = @$case;
  my $broker  = static_broker();
  my $storage = connect_with($broker, @rest);

  is $storage->access_broker, $broker, "a broker $label is attached";
  ok !defined $storage->_async_mode, "a broker $label connects sync";
}

# ---------------------------------------------------------------------------
# 4. The connection itself beside the broker throws.
# ---------------------------------------------------------------------------
throws_ok {
  connect_with(static_broker(), { async => 'k240loop', user => 'other', dbname => 'otherdb' });
} qr/the hash beside the broker takes connect options, not the connection itself: user, dbname/,
  'the connection itself beside the broker throws, naming it';

# ---------------------------------------------------------------------------
# 5. A DBI-form answer carrying async, or pool_size, too.
# ---------------------------------------------------------------------------
{
  my $storage = connect_with(T::DBIFormBroker->new(async => 'k240loop'), { async => 'k240loop' });
  is $storage->_async_mode, 'k240loop', 'the same mode beside the broker and in its answer is accepted';
}

throws_ok {
  connect_with(T::DBIFormBroker->new(async => 'k240other'), { async => 'k240loop' });
} qr/Two async modes for one connection: 'k240loop' beside the AccessBroker, 'k240other' in the broker's answer/,
  'two different modes throw, naming both';

{
  my $storage = connect_with(
    T::DBIFormBroker->new(pool_size => 3, pg_enable_utf8 => 1),
    { async => 'k240loop' },
  );

  is_deeply $storage->_dbi_connect_info->[3], { %DEFAULT_ATTRS, pg_enable_utf8 => 1 },
    "pool_size in the broker's answer stays out of an async owner's DBI attributes";

  my @connects;
  {
    no warnings qw(redefine once);
    require DBI;
    local *DBI::connect = sub { shift; push @connects, [@_]; T::FakeDBH->new };
    $storage->_connect;
  }
  is_deeply $connects[0][3], { %DEFAULT_ATTRS, pg_enable_utf8 => 1 },
    '... and out of DBI->connect on the per-connect path';
}

done_testing;
