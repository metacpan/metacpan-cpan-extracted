use strict;
use warnings;

use Test::More;
use Test::Exception;
use Test::Warn;

use DBIO::Test;
use DBIO::Util 'sigwarn_silencer';

my ($dsn, $user, $pass) = @ENV{map { "DBIO_TEST_MYSQL_${_}" } qw/DSN USER PASS/};

plan skip_all => 'Set $ENV{DBIO_TEST_MYSQL_DSN}, _USER and _PASS to run this test'
  unless ($dsn && $user);

for my $mod (qw(DateTime DateTime::Format::MySQL DateTime::TimeZone DateTime::Locale)) {
  eval "require $mod" or plan skip_all => "Inflation tests need $mod";
}

DBIO::Test::Schema->load_classes({ 'DBIO::MySQL::Test' => ['EventTZ'] });
{
  local $SIG{__WARN__} = sigwarn_silencer( qr/extra \=\> .+? has been deprecated/ );
  DBIO::Test::Schema->load_classes({ 'DBIO::MySQL::Test' => ['EventTZDeprecated'] });
}

# Self-contained: build the single `event` table both EventTZ and
# EventTZDeprecated map to, then connect with no_deploy. Deploying the whole
# DBIO::Test::Schema is neither needed nor MySQL-deployable -- it carries
# result classes with non-MySQL constructs (e.g. ArtistGUID's
# uniqueidentifier auto-increment PK). This mirrors the PostgreSQL t/21
# pattern.
require DBI;
{
  my $bootstrap = DBI->connect($dsn, $user, $pass, {
    AutoCommit => 1,
    RaiseError => 1,
    PrintError => 0,
  });
  $bootstrap->do('DROP TABLE IF EXISTS event');
  $bootstrap->do(q{
    CREATE TABLE event (
      id         INTEGER   NOT NULL AUTO_INCREMENT,
      starts_at  DATE,
      created_on DATETIME,
      PRIMARY KEY (id)
    ) ENGINE=InnoDB
  });
  $bootstrap->disconnect;
}

# The test stores 0000-00-00 to exercise datetime_undef_if_invalid handling.
# With no_deploy, DBIO::Test::deploy_schema (which would call deploy_setup) never
# runs. deploy_setup only relaxes sql_mode on the handle live at deploy time, but
# the zero-date write below happens on whatever session DBIO opens for the writes
# (and survives reconnects). Wire the relaxation through on_connect_call so every
# (re)connect strips NO_ZERO_DATE / NO_ZERO_IN_DATE -- the session issuing the
# UPDATE is guaranteed to carry it. See DBIO::MySQL::Storage/connect_call_set_zero_date_permissive.
my $schema = DBIO::Test->init_schema(
  dsn          => $dsn,
  user         => $user,
  pass         => $pass,
  no_deploy    => 1,
  connect_opts => { on_connect_call => 'set_zero_date_permissive' },
);

# Test "timezone" parameter
foreach my $tbl (qw/EventTZ EventTZDeprecated/) {
  my $event_tz = $schema->resultset($tbl)->create({
      starts_at => DateTime->new(year=>2007, month=>12, day=>31, time_zone => "America/Chicago" ),
      created_on => DateTime->new(year=>2006, month=>1, day=>31,
          hour => 13, minute => 34, second => 56, time_zone => "America/New_York" ),
  });

  is ($event_tz->starts_at->day_name, "Montag", 'Locale de_DE loaded: day_name');
  is ($event_tz->starts_at->month_name, "Dezember", 'Locale de_DE loaded: month_name');
  is ($event_tz->created_on->day_name, "Tuesday", 'Default locale loaded: day_name');
  is ($event_tz->created_on->month_name, "January", 'Default locale loaded: month_name');

  my $starts_at = $event_tz->starts_at;
  is("$starts_at", '2007-12-31T00:00:00', 'Correct date/time using timezone');

  my $created_on = $event_tz->created_on;
  is("$created_on", '2006-01-31T12:34:56', 'Correct timestamp using timezone');
  is($event_tz->created_on->time_zone->name, "America/Chicago", "Correct timezone");

  my $loaded_event = $schema->resultset($tbl)->find( $event_tz->id );

  isa_ok($loaded_event->starts_at, 'DateTime', 'DateTime returned');
  $starts_at = $loaded_event->starts_at;
  is("$starts_at", '2007-12-31T00:00:00', 'Loaded correct date/time using timezone');
  is($starts_at->time_zone->name, 'America/Chicago', 'Correct timezone');

  isa_ok($loaded_event->created_on, 'DateTime', 'DateTime returned');
  $created_on = $loaded_event->created_on;
  is("$created_on", '2006-01-31T12:34:56', 'Loaded correct timestamp using timezone');
  is($created_on->time_zone->name, 'America/Chicago', 'Correct timezone');

  # Test floating timezone warning
  # We expect one warning
  SKIP: {
    skip "ENV{DBIO_FLOATING_TZ_OK} was set, skipping", 1 if $ENV{DBIO_FLOATING_TZ_OK};
    warnings_exist (
      sub {
        $schema->resultset($tbl)->create({
          starts_at => DateTime->new(year=>2007, month=>12, day=>31 ),
          created_on => DateTime->new(year=>2006, month=>1, day=>31, hour => 13, minute => 34, second => 56 ),
        });
      },
      qr/You're using a floating timezone, please see the documentation of DBIO::InflateColumn::DateTime for an explanation/,
      'Floating timezone warning'
    );
  };

  # This should fail to set
  my $prev_str = "$created_on";
  $loaded_event->update({ created_on => '0000-00-00' });
  is("$created_on", $prev_str, "Don't update invalid dates");
}

# Test invalid DT
my $invalid = $schema->resultset('EventTZ')->create({
  starts_at  => '0000-00-00',
  created_on => DateTime->now,
});

is( $invalid->get_column('starts_at'), '0000-00-00', "Invalid date stored" );
is( $invalid->starts_at, undef, "Inflate to undef" );

$invalid->created_on('0000-00-00');
$invalid->update;

throws_ok (
  sub { $invalid->created_on },
  qr/invalid date format/i,
  "Invalid date format exception"
);

# Hygiene: this test creates the `event` table (both EventTZ and
# EventTZDeprecated map to it). Drop it at END with a dedicated dbh -- the
# schema's own dbh may already be gone at process exit -- so the live
# database stays clean for downstream tests.
END {
  return unless $dsn;
  my $h = eval { DBI->connect($dsn, $user, $pass, { RaiseError => 0, PrintError => 0 }) };
  return unless $h;
  eval { $h->do('DROP TABLE IF EXISTS event') };
  $h->disconnect;
}

done_testing;
