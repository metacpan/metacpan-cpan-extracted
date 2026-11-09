use strict;
use warnings;
use Test::More;

use DBIO::Oracle::Storage ();

# karr k56. The ISO date and timestamp formats of datetime_setup
# (NLS_DATE_FORMAT, NLS_TIMESTAMP_FORMAT, NLS_TIMESTAMP_TZ_FORMAT) are the
# default of every connection of this driver, set when the connection is made,
# without an on_connect_call of the application.
#
# CLAIM: before, a connection that did not ask for 'datetime_setup' read dates
# and timestamps in the server's NLS format (19-OCT-26 04.15.31.601359 AM); and
# a default that is not set on every connection (the pool connections of an
# async storage included) would leave some of them in that format. After: the
# alter session statements are issued for every new connection, whether or not
# the application names the call, and asking for it as well is harmless.

# --- offline: the statements, on the sync path and on the pool path ---------

{
  package T77::Storage;
  use base 'DBIO::Oracle::Storage';
  my @sql;
  sub sql_seen { [ @sql ] }
  sub reset_sql { @sql = () }
  sub _do_query { push @sql, $_[1]; return }
}

my $storage = T77::Storage->new(undef);
local @ENV{qw(NLS_DATE_FORMAT NLS_TIMESTAMP_FORMAT NLS_TIMESTAMP_TZ_FORMAT)};
delete @ENV{qw(NLS_DATE_FORMAT NLS_TIMESTAMP_FORMAT NLS_TIMESTAMP_TZ_FORMAT)};

$storage->_apply_connection_schema;
is_deeply $storage->sql_seen, [
  q{alter session set nls_date_format = 'YYYY-MM-DD HH24:MI:SS'},
  q{alter session set nls_timestamp_format = 'YYYY-MM-DD HH24:MI:SS.FF'},
  q{alter session set nls_timestamp_tz_format='YYYY-MM-DD HH24:MI:SS.FF TZHTZM'},
], 'every connection sets the three ISO formats, with no on_connect_call given';

is $ENV{NLS_TIMESTAMP_FORMAT}, 'YYYY-MM-DD HH24:MI:SS.FF',
  '... and the format is in the environment, which is what DateTime::Format::Oracle parses with';

$storage->reset_sql;
delete $ENV{NLS_DATE_FORMAT};
{
  local $ENV{NLS_DATE_FORMAT} = 'DD-MON-YY';
  $storage->_apply_connection_schema;
  like $storage->sql_seen->[0], qr/nls_date_format = 'DD-MON-YY'/,
    'a NLS_DATE_FORMAT the environment names is the one used, as before';
}

$storage->reset_sql;
$storage->connect_call_datetime_setup;
$storage->connect_call_datetime_setup;
is scalar(@{ $storage->sql_seen }), 6,
  'asking for datetime_setup as well just sets the same formats again';

# --- live: a connection without on_connect_call ----------------------------

my @live = @ENV{qw(DBIO_TEST_ORA_DSN DBIO_TEST_ORA_USER DBIO_TEST_ORA_PASS)};
SKIP: {
  skip 'Set $ENV{DBIO_TEST_ORA_DSN}, _USER and _PASS (and have DBD::Oracle) for the live half', 5
    unless length($live[0] // '') and eval { require DBD::Oracle; 1 };

  {
    package T77::Live;
    use base 'DBIO::Schema';
    __PACKAGE__->load_components('Oracle');
  }
  # the environment of the other test files must not decide this one
  delete @ENV{qw(NLS_DATE_FORMAT NLS_TIMESTAMP_FORMAT NLS_TIMESTAMP_TZ_FORMAT)};

  my $schema = T77::Live->connect(@live, { AutoCommit => 1, RaiseError => 1, PrintError => 0 });
  my $dbh = $schema->storage->dbh;
  my ($date, $ts, $tstz) = $dbh->selectrow_array(
    q{SELECT SYSDATE, SYSTIMESTAMP, SYSTIMESTAMP FROM dual});
  like $date, qr/\A\d{4}-\d\d-\d\d \d\d:\d\d:\d\d\z/,
    'a connection without on_connect_call reads a DATE as YYYY-MM-DD HH24:MI:SS';
  like $ts, qr/\A\d{4}-\d\d-\d\d \d\d:\d\d:\d\d\.\d+/,
    '... a TIMESTAMP as YYYY-MM-DD HH24:MI:SS.FF';
  like $tstz, qr/\A\d{4}-\d\d-\d\d \d\d:\d\d:\d\d\.\d+ [+-]\d{4}\z/,
    '... a TIMESTAMP WITH TIME ZONE with the zone as TZHTZM';

  # and the explicit call, which older applications still make, is harmless
  my $both = T77::Live->connect(@live, { AutoCommit => 1, RaiseError => 1, PrintError => 0 },
    { on_connect_call => 'datetime_setup' });
  like scalar $both->storage->dbh->selectrow_array(q{SELECT SYSDATE FROM dual}),
    qr/\A\d{4}-\d\d-\d\d /, 'asking for datetime_setup as well gives the same format';

  $schema->storage->disconnect;
  $both->storage->disconnect;
  pass 'disconnected';
}

done_testing;
