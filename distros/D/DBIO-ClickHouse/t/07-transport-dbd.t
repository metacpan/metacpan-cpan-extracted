use strict;
use warnings;

use Test::More;

# Both MySQL-wire DBDs must reach the same storage. ADR 0001 says the transport
# is the MySQL wire protocol over DBD::MariaDB *or* DBD::mysql, and that the
# storage is pinned explicitly because a ClickHouse DSN is indistinguishable
# from a MySQL one. Those two statements only hold together if the pin is truly
# DSN-independent: naming the other DBD in the DSN must not change which class
# ends up driving the connection.
#
# This is not decoration. The same claim was untested in dbio-firebird and was
# false there (dbio-firebird k20): a second DBD in the DSN fell through to a
# generic storage, which is a silent downgrade -- the schema keeps working,
# just without any of the driver's semantics. Here it would mean losing every
# ClickHouse decision at once (no-transaction policy, mutation UPDATE/DELETE,
# backtick quoting, refusal of the SQL::Translator MySQL producer), and the
# failure would not surface as an error, but as MySQL DDL and a lying
# transaction API.
#
# This is also what made karr k15's verification possible: DBD::MariaDB cannot
# connect to a stock ClickHouse server at all (it issues SET
# character_set_server on connect, which ClickHouse rejects with
# UNKNOWN_SETTING), so DBD::mysql -- verified live against a stock server in
# karr k15 -- is the transport of record. The pin holds for it exactly as for
# DBD::MariaDB.
#
# Offline by construction: ->connect() is lazy, so no DBI handle is created and
# neither DBD needs to be installed. The last assertion pins that.

use DBIO::ClickHouse::Test::Schema;
use DBIO::ClickHouse::Storage;

my %DSN = (
  'DBD::MariaDB' => 'dbi:MariaDB:database=default;host=127.0.0.1;port=9004',
  'DBD::mysql'   => 'dbi:mysql:database=default;host=127.0.0.1;port=9004',
);

for my $dbd (sort keys %DSN) {
  my $schema = DBIO::ClickHouse::Test::Schema->connect($DSN{$dbd}, '', '');

  isa_ok $schema->storage, 'DBIO::ClickHouse::Storage',
    "a $dbd DSN gets the ClickHouse storage";

  # Not just an isa: the generic base would pass an isa_ok on a subclass-less
  # storage too. What must not happen is falling back to DBIO::Storage::DBI
  # itself, or to core's DSN-driven MySQL storage.
  is ref($schema->storage), 'DBIO::ClickHouse::Storage',
    "... exactly, not a generic or MySQL storage reblessed from the $dbd DSN";

  is $schema->storage->sql_quote_char, '`',
    "... carrying the ClickHouse backtick quoting with a $dbd DSN";

  is $schema->storage->sql_maker_class, 'DBIO::ClickHouse::SQLMaker',
    "... and the ClickHouse SQLMaker with a $dbd DSN";

  ok !$schema->storage->connected,
    "... without having connected -- a $dbd DSN is inert until used";
}

# The shortcut is the other documented way in (`use DBIO Schema => -ch`), and it
# pins by class attribute rather than by load_components. Same question for it.
{
  package MyTest::Transport::Schema;
  use DBIO 'Schema', -ch;
}

my $short = MyTest::Transport::Schema->connect($DSN{'DBD::mysql'}, '', '');
is ref($short->storage), 'DBIO::ClickHouse::Storage',
  'the -ch shortcut pins the same storage for a DBD::mysql DSN';

# --- the pinned storage takes both DBDs as its own access path ---------------
#
# Everything above samples the storage right after ->connect, and that is only
# half of "which class ends up driving": driver determination is lazy, and since
# core ADR 0059 it is the moment core holds the DSN's DBD against its driver
# registry. Core has DBD::mysql and DBD::MariaDB registered for the MySQL
# storages, and reads "the storage inherits the class its DBD is registered
# for" as the declaration that a DBD belongs to a driver. This storage
# deliberately does not inherit them (ADR 0002), so the only two transports it
# has (ADR 0001) were reported as a "Driver mismatch" on every connect -- a
# warning per connection by default, and a refusal to work at all for a schema
# that set driver_strict(1), which is exactly the schema that asked for the
# check to be taken seriously (karr k35).
#
# So the claim is in two halves, and the second matters as much as the first:
# the two MySQL-wire DBDs are accepted in silence, and a DBD that really belongs
# to another driver is still reported. An exception widened to "never report
# anything" would keep the first half green and must turn the second red.
#
# _determine_driver is called directly because it is what the first real use of
# the storage would trigger, minus the connection: nothing here needs a server
# or an installed DBD, and the assertions say so.

{
  # driver_strict is inherited class data. It goes on classes of this file's
  # own, never on the shared DBIO::ClickHouse::Test::Schema.
  package MyTest::Transport::StrictSchema;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('ClickHouse');
  __PACKAGE__->driver_strict(1);

  package MyTest::Transport::StrictShortcutSchema;
  use DBIO 'Schema', -ch;
  __PACKAGE__->driver_strict(1);
}

# Runs driver determination on the schema's storage and reports what came of
# it: the exception (or undef) and every warning.
sub determine_driver {
  my ($schema) = @_;

  my @warnings;
  local $SIG{__WARN__} = sub { push @warnings, @_ };

  my $error;
  eval { $schema->storage->_determine_driver; 1 } or $error = $@;

  return ($error, @warnings);
}

my %DECLARED = (
  'the component'    => 'DBIO::ClickHouse::Test::Schema',
  'the -ch shortcut' => 'MyTest::Transport::Schema',
);
my %STRICT = (
  'the component'    => 'MyTest::Transport::StrictSchema',
  'the -ch shortcut' => 'MyTest::Transport::StrictShortcutSchema',
);

ok !DBIO::ClickHouse::Test::Schema->driver_strict,
  'the shared fixture schema is not strict -- the default is what gets tested';

for my $way (sort keys %DECLARED) {
  for my $dbd (sort keys %DSN) {
    my $schema = $DECLARED{$way}->connect($DSN{$dbd}, '', '');
    my ($error, @warnings) = determine_driver($schema);

    is $error, undef,
      "driver determination lives for a $dbd DSN declared by $way";
    is_deeply \@warnings, [],
      "... and warns about nothing: $dbd is this driver's own transport";
    is ref($schema->storage), 'DBIO::ClickHouse::Storage',
      '... leaving exactly the declared storage in charge';
    ok !$schema->storage->connected,
      '... and it was decided from the DSN alone, without connecting';

    my $strict = $STRICT{$way}->connect($DSN{$dbd}, '', '');
    ($error, @warnings) = determine_driver($strict);

    is $error, undef,
      "... and a driver_strict(1) schema can use a $dbd DSN at all";
    is_deeply \@warnings, [], '... again in silence';
  }
}

# The other half. DBD::Pg is registered for another driver's storage and has
# nothing to do with ClickHouse, so pointing a ClickHouse schema at it is the
# mistake ADR 0059's report exists for. It need not be installed: core judges
# the name in the DSN.
my $FOREIGN_DSN = 'dbi:Pg:dbname=default;host=127.0.0.1;port=5432';

for my $way (sort keys %DECLARED) {
  my $schema = $DECLARED{$way}->connect($FOREIGN_DSN, '', '');
  my ($error, @warnings) = determine_driver($schema);

  is $error, undef,
    "a DBD::Pg DSN declared by $way is not an error by default";
  is scalar(@warnings), 1, '... but it is reported, once';
  like $warnings[0], qr/Driver mismatch/, '... as a driver mismatch';
  like $warnings[0], qr/\bDBIO::ClickHouse::Storage\b/,
    '... naming the declared storage class';
  like $warnings[0], qr/\bDBD::Pg\b/, '... and the DBD that is not its own';
  is ref($schema->storage), 'DBIO::ClickHouse::Storage',
    '... while the storage stays in its driver';

  my $strict = $STRICT{$way}->connect($FOREIGN_DSN, '', '');
  ($error, @warnings) = determine_driver($strict);

  like $error, qr/Driver mismatch.*\bDBIO::ClickHouse::Storage\b.*\bDBD::Pg\b/s,
    "... and with driver_strict(1) on a schema declared by $way it throws";
  ok !$strict->storage->connected, '... before anything connected';
}

# --- the behaviour above comes from core's documented declaration -------------
#
# The two halves above sample behaviour, and that is the claim: mysql and
# MariaDB accepted (also under driver_strict), a foreign DBD still reported.
# How the driver gets there is pinned separately (karr k38): through core's
# register_access_path_dbd, not by overriding core's private check method. A
# storage that redefines the check itself would keep every assertion above
# green and still depend on a private name.
{
  require B;
  my $glob = $DBIO::ClickHouse::Storage::{_check_access_path_dbd};
  ok !( $glob && defined *{$glob}{CODE} ),
    'the storage defines no _check_access_path_dbd of its own';
  is(
    B::svref_2object(DBIO::ClickHouse::Storage->can('_check_access_path_dbd'))
      ->GV->STASH->NAME,
    'DBIO::Storage::DBI',
    "... the check that runs is core's",
  );
  ok( DBIO::ClickHouse::Storage->_access_path_dbd_declared($_),
    "$_ is declared as this storage's access path through core's API" )
    for qw( mysql MariaDB );
  ok !DBIO::ClickHouse::Storage->_access_path_dbd_declared('Pg'),
    '... and Pg is not';
}

done_testing;
