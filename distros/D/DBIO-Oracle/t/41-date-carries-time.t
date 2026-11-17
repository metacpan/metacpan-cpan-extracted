use strict;
use warnings;
use Test::More;

BEGIN {
  eval { require DateTime; require DateTime::Format::Oracle; 1 }
    or plan skip_all => "DateTime::Format::Oracle not installed: $@";
}

use DBIO::Test::Schema;
use DBIO::Oracle::Storage;

# A DATE holds a date and a time of day: a date column keeps the time it is
# read and written with and is not read at noon as a calendar day. Offline: a
# storage of the declared driver, built from a dbi:Oracle: DSN, never connects.

local $ENV{NLS_DATE_FORMAT} = 'YYYY-MM-DD HH24:MI:SS';

ok( DBIO::Oracle::Storage->datetime_date_carries_time,
  'the storage says that its DATE carries a time of day' );

my $schema = DBIO::Test::Schema->clone;
$schema->storage_type('+DBIO::Oracle::Storage');
$schema = $schema->connect('dbi:Oracle:orcl');

my $row = $schema->resultset('Event')->new_result({});
$row->store_column( starts_at => '2026-10-25 20:21:50' );
my $dt = $row->starts_at;

isa_ok( $dt, 'DateTime', 'a date column' );
is( $dt->ymd . ' ' . $dt->hms, '2026-10-25 20:21:50', 'keeps the time of day it was read with' );

$row->starts_at( DateTime->new( year => 2026, month => 3, day => 4, hour => 5, minute => 6, second => 7 ) );
is( $row->get_column('starts_at'), '2026-03-04 05:06:07', 'and is written with its time of day' );

done_testing;
