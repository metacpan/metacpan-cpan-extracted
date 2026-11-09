use strict;
use warnings;

use Test::More;
use lib 't/lib';
use SybaseFakeDBH;

use DBIO ();
use DBIO::Schema;
use DBIO::Storage::Composed;
use DBIO::Sybase::Storage;
use DBIO::Sybase::Storage::ASE;

# OFFLINE (karr k78; the model is dbio-mssql k37, t/62-adapt-access-path.t).
# The placeholder decision -- DBIO::Sybase::Storage::ASE::
# _adapt_to_placeholder_support: auto_cast on, or the NoBindVars class -- fell
# on the declared base only. A schema that pins storage_type to
# +DBIO::Sybase::Storage::ASE (the way k59 names for connection parameters
# without a DSN, and t/10 and t/20 use) went through
# core's declared branch, whose hook returned at once: the storage stayed the
# plain ASE class without auto_cast, on a connection that needed one or the
# other.
#
# Claim: a storage pinned to the ASE class, with or without layers over it,
# is, after its first use, of the same class and has the same auto_cast as the
# declared base on the same connection -- for each client library. It takes
# the decision once, on one connection (the hook does not connect a second
# time), and the writer storage ASE's _init makes of it does not take it
# again: auto_cast is copied from its parent. A pinned NoBindVars class and a
# private subclass stay what they are.
#
# Not decided here, as for the declared base: under FreeTDS auto_cast is not
# switched on across the board. CAST(? AS ..) dies on a FreeTDS connection
# that takes typeless placeholders (Msg 12828, measured live in k72); the
# decision is the declared base's own and asks the connection, so the pinned
# class gets exactly its answer -- auto_cast on only where the declared base
# would turn it on.
#
# DBI->connect is replaced; nothing connects. t/62-component-rebless-live.t
# holds the same comparison against a real ASE.

SybaseFakeDBH::install();
$ENV{DBIO_SYBASE_FREETDS_NOWARN} = 1;

my $BASE = 'DBIO::Sybase::Storage';
my $ASE  = 'DBIO::Sybase::Storage::ASE';
my $DSN  = 'dbi:Sybase:host=ase.example;port=5000;database=app';

my $OPEN_CLIENT = $SybaseFakeDBH::OPEN_CLIENT;
my $FREETDS     = $SybaseFakeDBH::FREETDS;

{ package T::K78::Layer; sub k78_layer { 'layer' } }
{ package T::K78::Private; use base 'DBIO::Sybase::Storage::ASE'; use mro 'c3'; }

my $count = 0;
sub schema_class {
  my $class = 'T::K78::Schema' . ++$count;
  { no strict 'refs'; @{"${class}::ISA"} = ('DBIO::Schema') }
  return $class;
}

sub declared  { my $c = schema_class(); $c->load_components('Sybase'); $c }
sub pinned_to { my $c = schema_class(); $c->storage_type("+$_[0]"); $c }

my @KEEP;
sub connected_storage {
  my ($class, %opt) = @_;
  $class->register_storage_layer('T::K78::Layer') if $opt{layered};
  my $schema = $class->connect($DSN, 'sa', 's3cret');
  push @KEEP, $schema;
  return $schema->storage;
}

sub probed { scalar grep { /\?/ } @SybaseFakeDBH::DONE }

sub auto_cast_of { ( $_[0]->can('auto_cast') && $_[0]->auto_cast ) ? 1 : 0 }

for my $client (
  [ 'Open Client, placeholders',
    $OPEN_CLIENT, 1, 1, 1, $ASE, 0 ],
  [ 'Open Client, no placeholder without a type',
    $OPEN_CLIENT, 1, 1, 0, $ASE, 1 ],
  [ 'Open Client, no dynamic SQL',
    $OPEN_CLIENT, 0, 1, 1, "${ASE}::NoBindVars", 0 ],
  [ 'FreeTDS, placeholders',
    $FREETDS, 1, 1, 1, "${ASE}::FreeTDS", 0 ],
  [ 'FreeTDS, no placeholder without a type',
    $FREETDS, 1, 1, 0, "${ASE}::FreeTDS", 1 ],
  [ 'FreeTDS, no placeholders',
    $FREETDS, 1, 0, 0, "${ASE}::NoBindVars::FreeTDS", 0 ],
) {
  (my $name, local $SybaseFakeDBH::OC_VERSION, local $SybaseFakeDBH::DYNAMIC,
    local $SybaseFakeDBH::PLACEHOLDERS, local $SybaseFakeDBH::TYPELESS,
    my $expect, my $auto_cast) = @$client;

  # the declared base on this connection: the measure
  SybaseFakeDBH::reset_records();
  my $reference = connected_storage(declared());
  $reference->ensure_connected;
  my $logins = @SybaseFakeDBH::CONNECTS;
  my $reference_writer = $reference->_writer_storage;
  SybaseFakeDBH::reset_records();
  $reference_writer->ensure_connected;
  my $writer_logins = @SybaseFakeDBH::CONNECTS;
  my $writer_probes = probed();

  is ref $reference, $expect, "$name: (the declared base becomes $expect)";
  is auto_cast_of($reference), $auto_cast, '... (auto_cast ' . ( $auto_cast ? 'on' : 'off' ) . ')';

  for my $layered (0, 1) {
    my $what = $layered ? 'pinned to the ASE class, with a layer' : 'pinned to the ASE class';

    SybaseFakeDBH::reset_records();
    my $storage = connected_storage(pinned_to($ASE), layered => $layered);
    is ref( $storage ) =~ /^\Q$ASE\E\z/ || $layered ? 1 : 0, 1,
      "$name, $what: (before the first use it is the ASE class)";
    $storage->ensure_connected;

    # Under FreeTDS _init builds its trait class over the base of a layered
    # storage's composition and composes the layers over it again (karr k77,
    # t/59): the class is <expect> with ::FreeTDS appended, and core knows it.
    (my $below = $expect) =~ s/::FreeTDS\z//;
    my $freetds = $expect =~ /::FreeTDS\z/;

    ok $storage->isa($below), "$name, $what: the first use gives $below"
      or diag 'it is a ' . ref $storage;
    ok $storage->isa('DBIO::Sybase::Storage::FreeTDS'), '... with the FreeTDS class'
      if $freetds;
    if ($layered) {
      my $composition = DBIO::Storage::Composed->composition_of(ref $storage);
      is $composition && $composition->{base}, $expect,
        '... with the layer composed over it';
      is eval { $storage->k78_layer }, 'layer', '... and the layer answers';
    }
    else {
      is ref $storage, $expect, '... exactly the class the declared base ends in';
    }
    is auto_cast_of($storage), $auto_cast, '... with the declared base\'s auto_cast';
    is scalar @SybaseFakeDBH::CONNECTS, $logins,
      '... on as many logins as the declared base takes (no second connect)';
    ok !@SybaseFakeDBH::ASKED, '... and the server is not asked what it is';

    # the writer storage: made by _init of the class, copies auto_cast, decides nothing
    my $writer = $storage->_writer_storage;
    is ref $writer, ref $storage, '... its writer storage is of the same class';
    SybaseFakeDBH::reset_records();
    $writer->ensure_connected;
    is auto_cast_of($writer), $auto_cast, '... and has the auto_cast of its parent';
    is ref $writer, ref $storage, '... connecting it leaves its class alone';
    is probed(), $writer_probes,
      '... and probes the placeholders as often as the declared base\'s writer does';
    is scalar @SybaseFakeDBH::CONNECTS, $writer_logins,
      '... on as many logins as the declared base\'s writer';
  }
}

# Pinned NoBindVars and a private subclass: where they were put.
for my $pin (
  [ "${ASE}::NoBindVars", 'the NoBindVars class' ],
  [ 'T::K78::Private',    'a private subclass of the ASE class' ],
) {
  my ($class, $what) = @$pin;
  local $SybaseFakeDBH::DYNAMIC = 0;    # a connection that asks for NoBindVars

  SybaseFakeDBH::reset_records();
  my $storage = connected_storage(pinned_to($class));
  $storage->ensure_connected;

  is ref $storage, $class, "pinned to $what: the storage stays what it is";
  is auto_cast_of($storage), 0, '... and auto_cast stays off';
}

# A storage pinned to the ASE class meets the server's answer (karr k94).
# The declared base reports a server that DBD::Sybase found to be Microsoft SQL
# Server through core's _driver_mismatch (t/59, section 4); the pinned ASE
# class took the placeholder decision and nothing else, so the same server went
# unreported there. Claim: the pinned class reports it the same way -- a
# warning, an error under driver_strict, silence under driver_warnings(0) --
# and does it BEFORE the placeholder decision, so a refused connection has not
# been probed. The writer storage (its parent decided), a pinned NoBindVars
# class and a private subclass go through unchanged. Against ASE nothing is
# said.
{
  my $MISMATCH = qr/Driver mismatch for declared storage class \Q$ASE\E: the server answers as Microsoft SQL Server/;
  local $SybaseFakeDBH::SERVER_VERSION =
    'Microsoft SQL Server 2022 (RTM) - 16.0.1000.6 (X64) Oct  8 2022 Copyright (C) 2022 Microsoft Corporation';

  my $warnings_of = sub {
    my $code = shift;
    my @w;
    local $SIG{__WARN__} = sub { push @w, @_ };
    $code->();
    return @w;
  };

  for my $layered (0, 1) {
    my $what = $layered ? 'pinned to the ASE class, with a layer' : 'pinned to the ASE class';

    SybaseFakeDBH::reset_records();
    my $storage = connected_storage(pinned_to($ASE), layered => $layered);
    my @w = $warnings_of->(sub { $storage->ensure_connected });
    is scalar @w, 1, "$what, server is Microsoft SQL Server: one warning";
    like $w[0], $MISMATCH, '... a driver mismatch naming the pinned class and the product';
    unlike $w[0], qr/ase\.example|s3cret/, '... and nothing of the connect info';
    ok !@SybaseFakeDBH::ASKED, '... known from the login, the server is not asked';
    ok !$storage->isa('DBIO::MSSQL::Storage'), '... and the storage is no storage of the other product';

    # the writer storage decides nothing and says nothing
    my $writer = $storage->_writer_storage;
    SybaseFakeDBH::reset_records();
    @w = $warnings_of->(sub { $writer->ensure_connected });
    is scalar @w, 0, '... its writer storage (the parent decided) does not report it again';
  }

  {
    SybaseFakeDBH::reset_records();
    my $class   = pinned_to($ASE);
    my $schema  = $class->connect($DSN, 'sa', 's3cret');
    push @KEEP, $schema;
    $schema->driver_strict(1);
    my $storage = $schema->storage;
    my $err = eval { $storage->ensure_connected; 1 } ? '' : "$@";
    like $err, qr/$MISMATCH.*driver_strict/s, 'with driver_strict the pinned class throws';
    is scalar( grep { /\?/ } @SybaseFakeDBH::DONE ), 0,
      '... before the placeholder decision: nothing was probed';
  }

  {
    my $class   = pinned_to($ASE);
    my $schema  = $class->connect($DSN, 'sa', 's3cret');
    push @KEEP, $schema;
    $schema->driver_warnings(0);
    my @w = $warnings_of->(sub { $schema->storage->ensure_connected });
    is_deeply \@w, [], 'with driver_warnings off nothing is said';
    is ref $schema->storage, $ASE, '... and the storage is the ASE class all the same';
  }

  for my $pin (
    [ "${ASE}::NoBindVars", 'the NoBindVars class' ],
    [ 'T::K78::Private',    'a private subclass of the ASE class' ],
  ) {
    my ($class, $what) = @$pin;
    local $SybaseFakeDBH::DYNAMIC = 0;
    my $storage = connected_storage(pinned_to($class));
    my @w = $warnings_of->(sub { $storage->ensure_connected });
    is_deeply \@w, [], "pinned to $what: passed through unchanged, nothing reported";
  }
}

{
  SybaseFakeDBH::reset_records();
  my $storage = connected_storage(pinned_to($ASE));
  my @w;
  { local $SIG{__WARN__} = sub { push @w, @_ }; $storage->ensure_connected; }
  is_deeply \@w, [], 'pinned to the ASE class on an ASE server: nothing is reported';
}

done_testing;
