use strict;
use warnings;

use Test::More;

use DBI;
use DBIO::Schema;
use DBIO::Sybase::Storage;
use DBIO::Sybase::Storage::ASE;
use DBIO::AccessBroker::Static;

# OFFLINE (karr k63; the defect was karr k60). This driver puts two things into
# the DSN after the connect info is set:
#
#   ;maxConnect=256  DBIO::Sybase::Storage::_set_max_connect, called from
#                    DBIO::Sybase::Storage::ASE::_init for every ASE storage
#                    -- the main one, its writer storage, its bulk storage. It
#                    then reconnects, so the session it leaves is one opened
#                    with that DSN;
#   ;bulkLogin=1     DBIO::Sybase::Storage::ASE::_init, for the bulk storage
#                    alone: the login that may use the bulk-copy API.
#
# With an AccessBroker core's _connect rebuilds the DSN from the broker's
# answer for EVERY connect, so what was appended to the stored copy would be
# gone before DBI->connect is called. The driver therefore adds both parts in
# DBIO::Sybase::Storage::_finish_connect_dsn (core's seam, asked for the DSN
# of every connect), for a DSN string and a broker alike (karr k60).
#
# So nothing here looks at _dbi_connect_info. DBI->connect is replaced by a
# recorder, and every assertion is about the DSN that arrived there:
#
#   1. the connect _set_max_connect makes carries maxConnect=256 -- on the
#      main storage, the writer storage and the bulk storage;
#   2. the bulk storage never connects without bulkLogin=1;
#   3. both still hold after disconnect + ensure_connected.
#
# These are asserted without a broker (the control: they pass) and with a
# DBIO::AccessBroker::Static, in both shapes it has: a dbname that is a whole
# DSN, and { dbname, host, port } built through _connect_params_dsn.
#
# Nothing of the driver is stubbed: _adapt_to_access_path, _init,
# _using_freetds and _set_max_connect run as they are. The handle DBI->connect
# returns answers what they ask a server -- syb_oc_version (an OpenClient
# string: under FreeTDS there is no bulk storage, see t/22-ase-bulk-freetds.t),
# syb_dynamic_supported and the placeholder probes.
#
# Two schemas, because the storage has to become an ASE storage for any of
# this to run, and each declares the driver, as a schema has to (core ADR
# 0067, karr k90). T::Component::Schema loads the Sybase component: its
# storage is DBIO::Sybase::Storage at connect and becomes
# DBIO::Sybase::Storage::ASE at the first use, without asking the server
# (karr k64, held in t/59-component-rebless.t). T::ASE::Schema pins the ASE
# class, as t/10-sybase.t pins NoBindVars.
#
# Whether a server honours maxConnect or bulkLogin is not provable offline and
# is not claimed here.

{
  package T::Component::Schema;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('Sybase');
}

{
  package T::ASE::Schema;
  use base 'DBIO::Schema';
  __PACKAGE__->storage_type('+DBIO::Sybase::Storage::ASE');
}

{
  package T::FakeDBH;

  sub new {
    return bless {
      Active                => 1,
      AutoCommit            => 1,
      RaiseError            => 1,
      PrintError            => 0,
      Driver                => { Name => 'Sybase' },
      syb_oc_version        => 'Sybase Client-Library/16.0/P/x86_64/Linux',
      syb_dynamic_supported => 1,
    }, shift;
  }

  sub FETCH      { $_[0]{$_[1]} }
  sub do         { 1 }
  sub disconnect { $_[0]{Active} = 0; 1 }

  # sp_server_info @attribute_id=1, as ASE answers it
  sub selectrow_arrayref { [ 1, 'DBMS_NAME', 'SQL Server' ] }
}

my $ASE = 'DBIO::Sybase::Storage::ASE';
my $DSN = 'dbi:Sybase:host=ase.example;port=5000;database=app';

sub broker {
  return DBIO::AccessBroker::Static->new(
    username => 'sa',
    password => 's3cret',
    @_,
  );
}

# The DSNs DBI->connect is handed while $code runs, in order.
sub dsns_connected (&) {
  my $code = shift;
  my @dsns;
  no warnings qw(redefine once);
  local *DBI::connect = sub { push @dsns, $_[1]; T::FakeDBH->new };
  $code->();
  return \@dsns;
}

sub reconnect {
  my $storage = shift;
  return dsns_connected { $storage->disconnect; $storage->ensure_connected };
}

# $dsn is $DSN with further parts appended, $part among them.
sub carries {
  my ($dsn, $part) = @_;
  return defined $dsn && $dsn =~ /\A\Q$DSN\E(?:;[^;]+)*;\Q$part\E(?:;|\z)/;
}

sub got { 'DBI->connect got: ' . (@{$_[0]} ? join(', ', @{$_[0]}) : 'no connect') }

# The last connect is the one the storage stays on.
sub last_connect_carries {
  my ($dsns, $part, $name) = @_;
  ok carries($dsns->[-1], $part), $name or diag got($dsns);
}

sub every_connect_carries {
  my ($dsns, $part, $name) = @_;
  ok @$dsns && !(grep { !carries($_, $part) } @$dsns), $name or diag got($dsns);
}

sub dsn_parts_reach_dbi_connect {
  my ($label, $storage) = @_;

  # The first connect determines the driver and runs _init, and with it
  # _set_max_connect.
  my $main = dsns_connected { $storage->ensure_connected };

  my ($writer, $bulk) = $storage->isa($ASE)
    ? ($storage->_writer_storage, $storage->_bulk_storage)
    : ();

  ok $writer && $bulk,
    "$label: the first connect leaves an ASE storage with a writer and a "
  . 'bulk storage' or return;

  {
    last_connect_carries $main, 'maxConnect=256',
      "$label: _set_max_connect leaves the storage on a connection made with "
    . 'maxConnect=256';

    last_connect_carries dsns_connected { $writer->ensure_connected },
      'maxConnect=256', "$label: ... and so the writer storage";

    my $bulk_dsns = dsns_connected { $bulk->ensure_connected };

    every_connect_carries $bulk_dsns, 'bulkLogin=1',
      "$label: the bulk storage connects with bulkLogin=1, every time";

    last_connect_carries $bulk_dsns, 'maxConnect=256',
      "$label: ... and stays on a connection made with maxConnect=256 too";

    # disconnect goes to the writer and the bulk storage as well
    last_connect_carries reconnect($storage), 'maxConnect=256',
      "$label: after disconnect, the reconnect still carries maxConnect=256";

    last_connect_carries reconnect($writer), 'maxConnect=256',
      "$label: ... and so does the writer storage's";

    $bulk_dsns = reconnect($bulk);

    every_connect_carries $bulk_dsns, 'bulkLogin=1',
      "$label: ... and the bulk storage's still carries bulkLogin=1";

    last_connect_carries $bulk_dsns, 'maxConnect=256',
      "$label: ... and maxConnect=256";
  }
}

# ------------------------------------------------- the control: a DSN string

dsn_parts_reach_dbi_connect(
  'DSN string, Sybase component',
  T::Component::Schema->connect($DSN, 'sa', 's3cret')->storage,
);

dsn_parts_reach_dbi_connect(
  'DSN string, ASE storage pinned',
  T::ASE::Schema->connect($DSN, 'sa', 's3cret')->storage,
);

# --------------------------------------------------------- through a broker

dsn_parts_reach_dbi_connect(
  'broker answering a whole DSN, Sybase component',
  T::Component::Schema->connect(broker(dbname => $DSN))->storage,
);

dsn_parts_reach_dbi_connect(
  'broker answering dbname, host and port, ASE storage pinned',
  T::ASE::Schema->connect(
    broker(dbname => 'app', host => 'ase.example', port => 5000)
  )->storage,
);

done_testing;
