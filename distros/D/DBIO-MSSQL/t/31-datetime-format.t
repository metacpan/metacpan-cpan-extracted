use strict;
use warnings;

use Test::More;

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
    $F->format_datetime($dt), '2024-08-21 14:36:48.080',
    'datetime round-trips'
  );
}

# smalldatetime channel (minute precision, no fractional seconds)
{
  my $dt = $F->parse_smalldatetime('2024-08-21 14:36:00');
  isa_ok $dt, 'DateTime', 'parse_smalldatetime result';
  is(
    $F->format_smalldatetime($dt), '2024-08-21 14:36:00',
    'smalldatetime round-trips'
  );
}

# Sybase variant: asymmetric (ISO_strict in, plain datetime out)
{
  my $G = 'DBIO::MSSQL::Storage::Sybase::DateTime::Format';
  my $dt = $G->parse_datetime('2024-08-21T14:36:48.080Z');
  isa_ok $dt, 'DateTime', 'sybase parse_datetime result';
  is(
    $G->format_datetime($dt), '2024-08-21 14:36:48.080',
    'sybase datetime: ISO in, plain out'
  );
}

done_testing;
