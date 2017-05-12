use strict;
use Test::More;
use Test::Fatal;
use Test::Warn;

use DateTime;

use lib qw( t/lib );
use Test::Schema;

my $schema = Test::Schema->connect('dbi:SQLite:dbname=:memory:', '', '');
$schema->deploy;

my $resultset = $schema->resultset('Tz');

my $result_source = $resultset->result_source;

is( $result_source->column_info('dt')->{timezone},
    'UTC', 'timezone defaults to UTC' );

is( $result_source->column_info('dt_utc')->{timezone},
    'UTC', 'explicit UTC timezone correct' );

my $now = DateTime->now( time_zone => 'America/Chicago' );
my $now_utc = $now->clone->set_time_zone('UTC');

my $now_dt = $now->clone;
my $now_dt_utc = $now->clone;

$ENV{DBIC_IC_DT_WTZ_MODIFY_TZ} = 1;

my $row = $resultset->create(
    {
        id     => 1,
        dt     => $now_dt,
        dt_utc => $now_dt_utc,
    }
);

# since deflation has occured, time_zone should be UTC for both objects
is( $now_dt . '', $now_utc . '', 'dt column: DateTime correct' );
is( $now_dt->time_zone->name, 'UTC', 'dt column: time zone correct' );

is( $now_dt_utc . '', $now_utc . '', 'dt_utc column: DateTime correct' );
is( $now_dt_utc->time_zone->name, 'UTC', 'dt_utc column: time zone correct' );

done_testing;
