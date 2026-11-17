use strict;
use warnings;
use Test::More;

use DateTime;
use DBIO::Test::Schema;
use DBIO::DB2::Storage;

# OFFLINE. A `time` column with inflate_datetime goes through parse_time /
# format_time of the storage's datetime parser (core: DBIO::InflateColumn::DateTime).
# DateTime::Format::DB2 0.06 has a parse_time that dies on every value
# ("year is a required parameter"), so the driver's parser must carry its own pair:
# the same time of day back, on 1970-01-01, floating; written as HH:MM:SS, which
# Db2 takes for TIME.

my $schema = DBIO::Test::Schema->clone;
$schema->storage_type('+DBIO::DB2::Storage');
$schema = $schema->connect('dbi:DB2:DATABASE=nonexistent', 'u', 'p');
my $parser = $schema->storage->datetime_parser;

my $dt = $parser->parse_time('15:14:15');
is $dt->ymd, '1970-01-01', 'a time of day stands on 1970-01-01';
is $dt->hms, '15:14:15', 'the time of day is read back';
ok $dt->time_zone->is_floating, 'floating';

is $parser->format_time(DateTime->new(year => 2026, month => 10, day => 25,
  hour => 15, minute => 14, second => 15, nanosecond => 123456000)),
  '15:14:15', 'written as HH:MM:SS, whatever the date and fraction';

# a TIMESTAMP and a DATE keep reading as before
is $parser->parse_datetime('2026-10-25 15:14:15.123456')->nanosecond, 123456000, 'timestamp unchanged';
is $parser->parse_date('2026-10-25')->ymd, '2026-10-25', 'date unchanged';

done_testing;
