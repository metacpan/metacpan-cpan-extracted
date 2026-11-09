# ABSTRACT: DBIO->driver_for names the exact driver of a connection, DBIO->schema_for connects a schema with it
use strict;
use warnings;

use Test::More;
use Test::Exception;

use DBI ();
use DBIO;
use DBIO::Storage::DBI;

# OFFLINE (karr k308, ADR 0067). Where the driver is not known in advance --
# loading a schema from an existing database -- "which driver is this
# connection" is a function, not a schema object.
#
# What this file claims:
#   1. driver_for returns the name of the driver the connection's DBD is
#      registered for (register_driver): read off the DSN without connecting,
#      in the DBI form and as a hash's dsn; for a code reference (also a
#      hash's dbh_maker) off the DBD of the handle it returns. A DBD
#      registered for a subclass of a driver's storage names that driver.
#   2. It is the exact driver: the server is asked nothing.
#   3. A DBD that names no driver -- ODBC, one nothing is registered for --
#      throws, telling the caller to declare the driver; so does connect info
#      without a DSN driver part and a code reference that returns no handle.
#   4. schema_for returns a connected schema of DBIO::SchemaFor::<Driver>, a
#      DBIO::Schema subclass with that driver applied and no sources, built
#      once per driver; it connects lazily, and what driver_for refuses it
#      refuses before building a class.
#
# THE SUBSTITUTIONS: a fake driver DBIO::K308For, its storage classes defined
# here and registered for DBD names no DBD carries; DBI->connect records that
# it was asked and returns nothing; a fake handle whose every method dies.

my @CONNECTS;
{
  no warnings 'redefine';
  *DBI::connect = sub { push @CONNECTS, $_[1]; return undef };
}

{
  package DBIO::K308For::Storage;
  use base 'DBIO::Storage::DBI';
  use mro 'c3';
  DBIO::Storage::DBI->register_driver(K308For => __PACKAGE__);
  $INC{'DBIO/K308For/Storage.pm'} = __FILE__;
}
{
  package DBIO::K308For::Storage::Compat;
  use base 'DBIO::K308For::Storage';
  use mro 'c3';
  DBIO::Storage::DBI->register_driver(K308ForCompat => __PACKAGE__);
}

# A handle that answers {Driver}{Name} and nothing else: a method called on it
# is a question to the server.
{
  package T::K308For::DBH;
  our @ASKED;
  sub new { bless { Driver => { Name => $_[1] } }, $_[0] }
  our $AUTOLOAD;
  sub AUTOLOAD { push @ASKED, $AUTOLOAD; die "asked the server: $AUTOLOAD\n" }
  sub DESTROY {}
}

# --- 1 + 2. the driver -------------------------------------------------------
@CONNECTS = ();
is(DBIO->driver_for('dbi:K308For:db=t', 'u', 'p', { AutoCommit => 1 }), 'K308For',
  'a DSN names the driver its DBD is registered for');
is(DBIO->driver_for({ dsn => 'dbi:K308For:db=t', user => 'u' }), 'K308For',
  '... also as the dsn of a hash');
is(DBIO->driver_for('dbi:K308ForCompat:db=t'), 'K308For',
  "a DBD registered for a subclass of the driver's storage names that driver");
is scalar(@CONNECTS), 0, '... and nothing connects to find out';

{
  my $called = 0;
  my $code = sub { $called++; T::K308For::DBH->new('K308For') };
  local @T::K308For::DBH::ASKED;
  is(DBIO->driver_for($code), 'K308For',
    'a code reference names the driver of the DBD of the handle it returns');
  is $called, 1, '... it is called once for that';
  is_deeply \@T::K308For::DBH::ASKED, [], '... and the handle is asked nothing';
  is(DBIO->driver_for({ dbh_maker => $code }), 'K308For', '... also as a dbh_maker');
}

# --- 3. no driver ------------------------------------------------------------
for my $case (
  [ 'ODBC, which names no engine', [ 'dbi:ODBC:DSN=k308' ], qr/DBD::ODBC names no DBIO driver/ ],
  [ 'a DBD nothing is registered for', [ 'dbi:K308Nobody:db=t' ], qr/DBD::K308Nobody names no DBIO driver/ ],
  [ 'a code reference to a handle of such a DBD',
    [ sub { T::K308For::DBH->new('K308Nobody') } ], qr/DBD::K308Nobody names no DBIO driver/ ],
) {
  my ($what, $info, $error) = @$case;
  @CONNECTS = ();
  throws_ok { DBIO->driver_for(@$info) } $error, "$what: refused";
  isa_ok $@, 'DBIO::Exception', "$what: what is thrown";
  like "$@", qr/Declare the driver/, "$what: ... telling the caller to declare the driver";
  like "$@", qr/ADR 0067/, "$what: ... naming the decision";
  is scalar(@CONNECTS), 0, "$what: ... and nothing connects";
}

throws_ok { DBIO->driver_for('dbi::db=t') } qr/names no DBD/,
  'a DSN without a driver part is refused';
throws_ok { DBIO->driver_for(sub { undef }) } qr/returned no database handle/,
  'a code reference that returns no handle is refused';
throws_ok { DBIO->driver_for() } qr/takes connect info with a DSN or a code reference/,
  'no connect info is refused';
throws_ok { DBIO->driver_for({ user => 'u' }) } qr/takes connect info with a DSN or a code reference/,
  'a hash without dsn or dbh_maker is refused';

# --- 4. schema_for -----------------------------------------------------------
{
  @CONNECTS = ();
  my $schema = DBIO->schema_for('dbi:K308For:db=t', 'u', 'p');

  is ref($schema), 'DBIO::SchemaFor::K308For', 'schema_for: an object of DBIO::SchemaFor::<Driver>';
  isa_ok $schema, 'DBIO::Schema', 'schema_for: the schema';
  is(DBIO::SchemaFor::K308For->storage_type, '+DBIO::K308For::Storage',
    '... whose class has the driver applied');
  isa_ok $schema->storage, 'DBIO::K308For::Storage', '... connected through it';
  is_deeply [ $schema->sources ], [], '... with no sources';
  is scalar(@CONNECTS), 0, '... lazily: nothing connected yet';

  my $again = DBIO->schema_for('dbi:K308ForCompat:db=t');
  is ref($again), 'DBIO::SchemaFor::K308For', 'a second call for the same driver uses the same class';
  isnt $again, $schema, '... and returns a schema of its own';
}

{
  throws_ok { DBIO->schema_for('dbi:K308Nobody:db=t') } qr/names no DBIO driver/,
    'schema_for refuses what driver_for refuses';
  ok !DBIO::SchemaFor::K308Nobody->can('connect'), '... and builds no class for it';
}

done_testing;
