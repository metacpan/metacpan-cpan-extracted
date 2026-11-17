use strict;
use warnings;

use Test::More;
use DateTime;

# Offline coverage for the DateTime format classes (no DB needed). These
# subclass DBIO::Storage::DateTimeFormat; this pins the round-trip behaviour
# that core's InflateColumn::DateTime relies on.

use DBIO::MSSQL::Storage::DateTime::Format;
use DBIO::MSSQL::Storage::Sybase::DateTime::Format;

my $F = 'DBIO::MSSQL::Storage::DateTime::Format';

# datetime channel (symmetric, 3-digit fractional seconds)
{
  my $dt = $F->parse_datetime('2024-08-21 14:36:48.080');
  isa_ok $dt, 'DateTime', 'parse_datetime result';
  is $dt->ymd, '2024-08-21', 'datetime date parts';
  is $dt->hms, '14:36:48',   'datetime time parts';
  is(
    $F->format_datetime($dt), '20240821 14:36:48.080',
    'datetime is written as YYYYMMDD (DATEFORMAT independent)'
  );
}

# smalldatetime channel (minute precision, no fractional seconds)
{
  my $dt = $F->parse_smalldatetime('2024-08-21 14:36:00');
  isa_ok $dt, 'DateTime', 'parse_smalldatetime result';
  is(
    $F->format_smalldatetime($dt), '20240821 14:36:00',
    'smalldatetime is written as YYYYMMDD (DATEFORMAT independent)'
  );
}

# date channel: DBD::ODBC reads YYYY-MM-DD, writes YYYYMMDD
{
  my $dt = $F->parse_date('2026-10-25');
  isa_ok $dt, 'DateTime', 'parse_date result';
  is $dt->ymd, '2026-10-25', 'date parts (day > 12)';
  is $F->parse_date('2026-10-05')->ymd, '2026-10-05', 'date parts (day <= 12)';
  is(
    $F->format_date($dt), '20261025',
    'date is written as YYYYMMDD (DATEFORMAT independent)'
  );
}

# Sybase variant: asymmetric (ISO_strict in, plain datetime out)
{
  my $G = 'DBIO::MSSQL::Storage::Sybase::DateTime::Format';
  my $dt = $G->parse_datetime('2024-08-21T14:36:48.080Z');
  isa_ok $dt, 'DateTime', 'sybase parse_datetime result';
  is(
    $G->format_datetime($dt), '20240821 14:36:48.080',
    'sybase datetime: ISO in, YYYYMMDD out'
  );
}

# Sybase date: ISO_strict hands a date over as a datetime at midnight
{
  my $G = 'DBIO::MSSQL::Storage::Sybase::DateTime::Format';
  my $dt = $G->parse_date('2026-10-25T00:00:00.000Z');
  isa_ok $dt, 'DateTime', 'sybase parse_date result';
  is $dt->ymd, '2026-10-25', 'sybase date parts (day > 12)';
  is $G->parse_date('2026-10-05T00:00:00.000Z')->ymd, '2026-10-05', 'sybase date parts (day <= 12)';
  is(
    $G->format_date($dt), '20261025',
    'sybase date: ISO in, YYYYMMDD out'
  );
}

# datetime2, datetimeoffset and time: a channel of their own each
{
  my $berlin = sub {
    my ($m, $d, $H) = @_;
    DateTime->new(year => 2026, month => $m, day => $d, hour => $H, minute => 14, second => 15,
      nanosecond => 123_456_700, time_zone => 'Europe/Berlin');
  };

  # DBD::ODBC: the text of the server, seven digits
  my $dt2 = $F->parse_datetime2('2026-10-25 13:14:15.1234567');
  is $dt2->nanosecond, 123_456_700, 'datetime2 keeps 100ns';
  is $F->format_datetime2($dt2), '20261025 13:14:15.1234567', 'datetime2 is written with seven digits, YYYYMMDD';
  is $F->parse_datetime2('2026-10-25 13:14:15')->nanosecond, 0, 'datetime2(0) has no fraction';
  is $F->parse_datetime2('2026-10-25 13:14:15.12')->nanosecond, 120_000_000, 'datetime2(2)';

  my $dto = $F->parse_datetimeoffset('2026-10-05 13:14:15.1234567 +02:00');
  is $dto->offset, 7200, 'datetimeoffset keeps its offset';
  is $dto->nanosecond, 123_456_700, 'datetimeoffset keeps 100ns';
  is $F->format_datetimeoffset($dto), '20261005 13:14:15.1234567 +02:00', 'datetimeoffset is written with its offset';
  is $F->format_datetimeoffset($berlin->(10, 5, 15)), '20261005 15:14:15.1234567 +02:00',
    'a value in an Olson zone writes the offset of that moment (summer)';
  is $F->format_datetimeoffset($berlin->(10, 25, 13)), '20261025 13:14:15.1234567 +01:00',
    'a value in an Olson zone writes the offset of that moment (winter)';
  is $F->parse_datetimeoffset('2026-10-25 13:14:15.1234567 -03:30')->offset, -12600, 'negative offset with minutes';
  is $F->format_datetimeoffset($F->parse_datetimeoffset('2026-10-25 13:14:15.1234567 -03:30')),
    '20261025 13:14:15.1234567 -03:30', 'negative offset is written back';

  my $tm = $F->parse_time('13:14:15.1234567');
  is $tm->nanosecond, 123_456_700, 'time keeps 100ns';
  is $F->format_time($tm), '13:14:15.1234567', 'time is written with seven digits';
  is $F->parse_time('13:14:15')->second, 15, 'time(0) has no fraction';

  # DBD::Sybase
  my $G = 'DBIO::MSSQL::Storage::Sybase::DateTime::Format';

  # TDS 7.3 and 7.4: the client library has cut the value to milliseconds
  is $G->parse_datetime2('2026-10-25T13:14:15.123Z')->nanosecond, 123_000_000, 'sybase datetime2 (TDS 7.3+): ISO_strict';
  is $G->format_datetime2($dt2), '20261025 13:14:15.1234567', 'sybase datetime2 is written with seven digits';
  my $u = $G->parse_datetimeoffset('2026-10-05T11:14:15.123Z');
  is $u->epoch, $dto->epoch, 'sybase datetimeoffset (TDS 7.3+): the instant, in UTC';
  is $u->offset, 0, 'sybase datetimeoffset (TDS 7.3+): the offset is gone before Perl sees it';
  is $G->format_datetimeoffset($dto), '20261005 13:14:15.1234567 +02:00', 'sybase datetimeoffset is written with its offset';
  my $t = $G->parse_time('2026-10-05T13:14:15.123Z');
  is $t->ymd . ' ' . $t->hms, '1970-01-01 13:14:15', 'sybase time (TDS 7.3+): the filler date is not the time';
  is $t->nanosecond, 123_000_000, 'sybase time (TDS 7.3+): milliseconds';
  is $G->format_time($tm), '13:14:15.1234567', 'sybase time is written with seven digits';

  # TDS 7.0 to 7.2: the full text of the server
  is $G->parse_datetime2('2026-10-25 13:14:15.1234567')->nanosecond, 123_456_700, 'sybase datetime2 (TDS <= 7.2): full text';
  is $G->parse_datetimeoffset('2026-10-05 13:14:15.1234567 +02:00')->offset, 7200, 'sybase datetimeoffset (TDS <= 7.2): offset';
  is $G->parse_time('13:14:15.1234567')->nanosecond, 123_456_700, 'sybase time (TDS <= 7.2): full text';
}

done_testing;
