use strict;
use warnings;

use Test::More;
use lib 't/lib';
use MssqlServerLanguage ();   # DBIO_TEST_SERVER_LANGUAGE; this test sets its own language per session
use DBI;
use DateTime;
use DBIO::Optional::Dependencies ();
use DBIO::Schema;

# LIVE. SQL Server reads 'YYYY-MM-DD hh:mm:ss' of a DATETIME/SMALLDATETIME by
# the DATEFORMAT of the session: SET LANGUAGE German or French brings dmy, and
# 2026-10-05 became 2026-05-10, 2026-10-25 failed with Msg 242. DBIO writes
# 'YYYYMMDD hh:mm:ss[.mmm]', which no DATEFORMAT or language changes, and
# leaves the session as the user made it. What this file holds, per access
# path and per session setting (SET LANGUAGE German, SET LANGUAGE French,
# SET DATEFORMAT dmy): create, update and read back give the DateTime that
# was written, and the server holds the same year, month and day (asked in
# the same session, in numbers).

my %ENV_PREFIX = (
  'DBD::Sybase' => 'DBIO_TEST_MSSQL',
  'DBD::ODBC'   => 'DBIO_TEST_MSSQL_ODBC',
);

my %WAY;
for my $dbd (keys %ENV_PREFIX) {
  my ($dsn, $user, $pass) = @ENV{ map { "$ENV_PREFIX{$dbd}_$_" } qw/DSN USER PASS/ };
  $WAY{$dbd} = [ $dsn, $user, $pass ] if $dsn and defined $user and defined $pass;
}

plan skip_all => 'Set $ENV{DBIO_TEST_MSSQL_DSN} or '
  . '$ENV{DBIO_TEST_MSSQL_ODBC_DSN}, with _USER and _PASS, to run this test'
  unless %WAY;

if ($WAY{'DBD::Sybase'}) {
  if (not DBIO::Optional::Dependencies->req_ok_for('test_rdbms_mssql_sybase')) {
    diag 'DBD::Sybase is not looked at: test needs '
       . DBIO::Optional::Dependencies->req_missing_for('test_rdbms_mssql_sybase');
    delete $WAY{'DBD::Sybase'};
  }
  elsif (not eval { require DBIO::Sybase::Storage; 1 }) {
    die $@ unless $@ =~ m{\ACan't locate DBIO/Sybase/Storage\.pm };
    diag 'DBD::Sybase is not looked at: DBIO::Sybase is not installed';
    delete $WAY{'DBD::Sybase'};
  }
}

if ($WAY{'DBD::ODBC'}
    and not DBIO::Optional::Dependencies->req_ok_for('test_rdbms_mssql_odbc')) {
  diag 'DBD::ODBC is not looked at: test needs '
     . DBIO::Optional::Dependencies->req_missing_for('test_rdbms_mssql_odbc');
  delete $WAY{'DBD::ODBC'};
}

plan skip_all => 'Neither access path has what it needs installed' unless %WAY;
plan skip_all => 'Test needs ' . DBIO::Optional::Dependencies->req_missing_for('test_dt')
  unless DBIO::Optional::Dependencies->req_ok_for('test_dt');

my $EXPECTED_WARNING = qr/compiled against buggy FreeTDS version/;
local $SIG{__WARN__} = sub {
  warn $_[0] unless $_[0] =~ $EXPECTED_WARNING;
};

my $TABLE = 'dbio_t133_dt';

{
  package T::T133::Result::Stamp;
  use base 'DBIO::Core';
  __PACKAGE__->load_components('InflateColumn::DateTime');
  __PACKAGE__->table('dbio_t133_dt');
  __PACKAGE__->add_columns(
    id  => { data_type => 'integer', is_auto_increment => 1 },
    dt  => { data_type => 'datetime', is_nullable => 1 },
    sdt => { data_type => 'smalldatetime', is_nullable => 1 },
    # inflated like the others: the DBD hands a date over as 'YYYY-MM-DD'
    # (DBD::ODBC) or 'YYYY-MM-DDT00:00:00.000Z' (DBD::Sybase), DBIO writes 'YYYYMMDD'
    d   => { data_type => 'date', is_nullable => 1 },
  );
  __PACKAGE__->set_primary_key('id');
}

# datetime2(7), datetimeoffset(7) and time(7): each a channel of its own
# (parse_datetime2 / parse_datetimeoffset / parse_time), none inflates without
# being asked
{
  package T::T133::Result::Wide;
  use base 'DBIO::Core';
  __PACKAGE__->load_components('InflateColumn::DateTime');
  __PACKAGE__->table('dbio_t133_wide');
  __PACKAGE__->add_columns(
    id  => { data_type => 'integer', is_auto_increment => 1 },
    dt2 => { data_type => 'datetime2(7)',      is_nullable => 1, inflate_datetime => 1 },
    dto => { data_type => 'datetimeoffset(7)', is_nullable => 1, inflate_datetime => 1 },
    tm  => { data_type => 'time(7)',           is_nullable => 1, inflate_datetime => 1 },
  );
  __PACKAGE__->set_primary_key('id');
}

{
  package T::T133::Schema;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('MSSQL');
  __PACKAGE__->register_class(Stamp => 'T::T133::Result::Stamp');
  __PACKAGE__->register_class(Wide  => 'T::T133::Result::Wide');
}

my @SESSION = ('SET LANGUAGE German', 'SET LANGUAGE French', 'SET DATEFORMAT dmy');

# day <= 12 is the one that swaps, day > 12 the one that used to fail (Msg 242)
my @DAYS = (
  [ 2026, 10,  5, 13, 14, 15, 120_000_000 ],
  [ 2026, 10, 25, 13, 14, 15, 120_000_000 ],
);

sub dt_of {
  my ($y, $m, $d, $H, $M, $S, $ns, $trunc) = @_;
  return DateTime->new(
    year => $y, month => $m, day => $d,
    hour => $H, minute => $M, second => $trunc ? 0 : $S,
    nanosecond => $trunc ? 0 : $ns,
  );
}

for my $way (sort keys %WAY) {
  my ($dsn, $user, $pass) = @{ $WAY{$way} };

  # a plain handle makes and drops the table: no setting of the session
  # of the tests touches the DDL
  my $admin = DBI->connect($dsn, $user, $pass, { RaiseError => 1, PrintError => 0 });
  $admin->do("IF OBJECT_ID('$TABLE') IS NOT NULL DROP TABLE $TABLE");
  $admin->do("CREATE TABLE $TABLE (id INT IDENTITY PRIMARY KEY, dt DATETIME NULL, "
    . "sdt SMALLDATETIME NULL, d DATE NULL)");

  for my $set (@SESSION) {
    my $label = "$way, $set";

    my $schema = T::T133::Schema->connect($dsn, $user, $pass, {
      on_connect_do => [ $set ],
      ($way eq 'DBD::Sybase' ? (on_connect_call => 'datetime_setup') : ()),
    });
    $schema->storage->ensure_connected;
    $schema->storage->dbh_do(sub { $_[1]->do("DELETE FROM $TABLE") });

    my ($df) = $schema->storage->dbh_do(
      sub { $_[1]->selectrow_array('SELECT date_format FROM sys.dm_exec_sessions WHERE session_id = @@SPID') }
    );
    is $df, 'dmy', "$label: the session reads dates day-month-year";

    for my $day (@DAYS) {
      my $name = "$label, day $day->[2]";
      my $dt  = dt_of(@$day);
      my $sdt = dt_of(@$day, 1);
      my $d   = dt_of(@$day[0..2], 0, 0, 0, 0);

      my $row = eval {
        $schema->resultset('Stamp')->create({ dt => $dt, sdt => $sdt, d => $d });
      };
      ok $row, "$name: create" or do { diag $@; next };

      my $got = $schema->resultset('Stamp')->find($row->id);
      is $got->dt . '',  $dt . '',  "$name: datetime reads back as written";
      is $got->sdt . '', $sdt . '', "$name: smalldatetime reads back as written";
      isa_ok $got->d, 'DateTime', "$name: date is inflated";
      is $got->d->ymd, $d->ymd, "$name: date reads back as written";
      is $got->dt->nanosecond, 120_000_000, "$name: datetime keeps its milliseconds";

      my @server = $schema->storage->dbh_do(sub {
        $_[1]->selectrow_array(
          "SELECT YEAR(dt), MONTH(dt), DAY(dt), YEAR(sdt), MONTH(sdt), DAY(sdt), "
          . "YEAR(d), MONTH(d), DAY(d) FROM $TABLE WHERE id = ?", undef, $row->id
        );
      });
      is_deeply \@server, [ ($day->[0], $day->[1], $day->[2]) x 3 ],
        "$name: the server holds that year, month and day";

      # update to the other day of the pair, then read again
      my $other = $day->[2] == 5 ? 25 : 5;
      my $dt2  = dt_of($day->[0], $day->[1], $other, 8, 9, 10, 40_000_000);
      my $sdt2 = dt_of($day->[0], $day->[1], $other, 8, 9, 10, 0, 1);
      eval { $got->update({ dt => $dt2, sdt => $sdt2, d => $dt2->clone->truncate(to => 'day') }); 1 } or diag "$name: update died: $@";
      my $again = $schema->resultset('Stamp')->find($row->id);
      is $again->dt . '',  $dt2 . '',  "$name: update, datetime reads back";
      is $again->sdt . '', $sdt2 . '', "$name: update, smalldatetime reads back";
      is $again->d->ymd, $dt2->ymd, "$name: update, date reads back";
      my @s2 = $schema->storage->dbh_do(sub {
        $_[1]->selectrow_array(
          "SELECT MONTH(dt), DAY(dt), MONTH(sdt), DAY(sdt), MONTH(d), DAY(d) FROM $TABLE WHERE id = ?",
          undef, $row->id
        );
      });
      is_deeply \@s2, [ ($day->[1], $other) x 3 ], "$name: update, the server holds that month and day";
    }

    $schema->storage->disconnect;
  }

  $admin->do("DROP TABLE $TABLE");

  # ---- datetime2(7), datetimeoffset(7), time(7) ----
  # What the DBD hands over decides what comes back. DBD::ODBC: the full
  # string of the server. DBD::Sybase over TDS 7.3 and 7.4: the client library
  # has converted the value to its datetime before ISO_strict writes it down,
  # milliseconds only, a datetimeoffset as the UTC instant, a time with a
  # filler date; over TDS 7.2 and below the full text. Writing is exact in all
  # cases, and the server is asked in numbers.
  my $WIDE = 'dbio_t133_wide';
  $admin->do("IF OBJECT_ID('$WIDE') IS NOT NULL DROP TABLE $WIDE");
  $admin->do("CREATE TABLE $WIDE (id INT IDENTITY PRIMARY KEY, dt2 DATETIME2(7) NULL, "
    . "dto DATETIMEOFFSET(7) NULL, tm TIME(7) NULL)");

  # is the read of this DBD cut to milliseconds (and the offset converted)?
  my $lossy = 0;
  if ($way eq 'DBD::Sybase') {
    $admin->syb_date_fmt('ISO_strict') if $admin->can('syb_date_fmt');
    my ($raw) = $admin->selectrow_array("SELECT CAST('2026-10-25T13:14:15.1234567' AS DATETIME2(7))");
    $lossy = $raw =~ /\.\d{3}Z\z/ ? 1 : 0;
    diag "$way: datetime2 read as '$raw'" . ($lossy ? ' (client library: milliseconds, UTC)' : ' (full text)');
  }

  my @WSESSION = ('SET LANGUAGE us_english', @SESSION);
  # [ y, m, d, H, M, S, ns, zone ]: Europe/Berlin is +01:00 on the 25th of
  # October 2026 (the DST change happens that night) and +02:00 on the 5th
  my @WIDE = (
    [ 2026, 10,  5, 15, 14, 15, 123_456_700, 'Europe/Berlin', 7200 ],
    [ 2026, 10, 25, 13, 14, 15, 123_456_700, 'Europe/Berlin', 3600 ],
  );

  for my $set (@WSESSION) {
    my $label = "$way, $set";
    my $schema = T::T133::Schema->connect($dsn, $user, $pass, {
      on_connect_do => [ $set ],
      ($way eq 'DBD::Sybase' ? (on_connect_call => 'datetime_setup') : ()),
    });
    $schema->storage->ensure_connected;
    $schema->storage->dbh_do(sub { $_[1]->do("DELETE FROM $WIDE") });

    for my $w (@WIDE) {
      my ($y, $m, $d, $H, $M, $S, $ns, $zone, $off) = @$w;
      my $name = "$label, day $d";
      my $dt2 = DateTime->new(year => $y, month => $m, day => $d, hour => $H,
        minute => $M, second => $S, nanosecond => $ns);
      my $dto = DateTime->new(year => $y, month => $m, day => $d, hour => $H,
        minute => $M, second => $S, nanosecond => $ns, time_zone => $zone);
      my $tm  = DateTime->new(year => 1970, month => 1, day => 1, hour => $H,
        minute => $M, second => $S, nanosecond => $ns);

      my $row = eval { $schema->resultset('Wide')->create({ dt2 => $dt2, dto => $dto, tm => $tm }) };
      ok $row, "$name: create" or do { diag $@; next };

      my @server = $schema->storage->dbh_do(sub {
        $_[1]->selectrow_array(
          "SELECT DATEPART(year, dt2), DATEPART(month, dt2), DATEPART(day, dt2), DATEPART(hour, dt2), "
          . "DATEPART(nanosecond, dt2), "
          . "DATEPART(year, dto), DATEPART(month, dto), DATEPART(day, dto), DATEPART(hour, dto), "
          . "DATEPART(nanosecond, dto), DATEPART(TZoffset, dto), "
          . "DATEPART(hour, tm), DATEPART(minute, tm), DATEPART(second, tm), DATEPART(nanosecond, tm) "
          . "FROM $WIDE WHERE id = ?", undef, $row->id
        );
      });
      is_deeply \@server, [
        $y, $m, $d, $H, $ns,
        $y, $m, $d, $H, $ns, $off / 60,
        $H, $M, $S, $ns,
      ], "$name: the server holds year, month, day, hour, 100ns and offset of what was written";

      my $got = $schema->resultset('Wide')->find($row->id);
      my $full = $lossy ? $ns - $ns % 1_000_000 : $ns;   # ms only, truncated
      is $got->dt2->ymd . ' ' . $got->dt2->hms, sprintf('%04d-%02d-%02d %02d:%02d:%02d', $y, $m, $d, $H, $M, $S),
        "$name: datetime2 reads back";
      is $got->dt2->nanosecond, $full, "$name: datetime2 nanoseconds" . ($lossy ? ' (client library: milliseconds)' : '');
      is $got->tm->hms, sprintf('%02d:%02d:%02d', $H, $M, $S), "$name: time reads back";
      is $got->tm->nanosecond, $full, "$name: time nanoseconds" . ($lossy ? ' (client library: milliseconds)' : '');
      is $got->tm->ymd, '1970-01-01', "$name: time stands on 1970-01-01";
      is $got->dto->epoch, $dto->epoch, "$name: datetimeoffset is the same instant";
      is $got->dto->nanosecond, $full, "$name: datetimeoffset nanoseconds" . ($lossy ? ' (client library: milliseconds)' : '');
      if ($lossy) {
        is $got->dto->offset, 0, "$name: datetimeoffset comes back in UTC (client library converts it)";
      }
      else {
        is $got->dto->offset, $off, "$name: datetimeoffset comes back with its offset";
      }
    }
    $schema->storage->disconnect;
  }

  $admin->do("DROP TABLE $WIDE");
  $admin->disconnect;
}

done_testing;
