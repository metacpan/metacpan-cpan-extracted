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

my $row = $resultset->create(
    {
        id     => 1,
        dt     => $now,
        dt_utc => $now,
    }
);

$row->discard_changes;

my $parser = $schema->storage->datetime_parser;

for my $col_name (qw{ dt dt_utc }) {
    my $val = $row->$col_name;
    my $info = $row->column_info($col_name);
    isa_ok( $val, 'DateTime', "$col_name column" );
    is( $val,                  $now . '',         '  DateTime corect' );
    is( $val->time_zone->name, 'America/Chicago', '  time zone correct' );

    my $raw_str;
    $schema->storage->dbh_do(
        sub {
            my ( $storage, $dbh ) = @_;
            my $vals =
              $dbh->selectcol_arrayref("SELECT $col_name FROM tz WHERE id = 1");
            $raw_str = $vals->[0];
        }
    );

    # all datetime values should be stored as UTC
    my $expected_dt = $parser->format_datetime($now_utc);

    is( $raw_str, $expected_dt, "$col_name column raw value correct" )
      or diag "database datetime: $raw_str";
}

my $dt_null;
is( exception { $dt_null = $row->dt_null }, undef, 'retrieving null datetime succeeds' );
is( $dt_null, undef, '  and is undef' );

# resilience -- what happens if time zone is null while datetime is not?
my $null_row = $resultset->create(
    {
        id      => 2,
        dt      => $now,    # unused, but not nullable
        dt_utc  => $now,    # unused, but not nullable
        dt_null => $now,
    }
);

# null out time zone behind the scenes
$schema->storage->dbh->do('UPDATE tz SET tz_null = NULL');

# force reselect
$null_row->discard_changes;

warning_like { $dt_null = $null_row->dt_null } qr/dt_null had null timezone/, "retrieving with null timezone gives warning";

my $no_tz_resultset = $schema->resultset('Tz')->search( { id => 1 }, { columns => [ 'id', 'dt' ] } );

my $no_tz_row = $no_tz_resultset->first;

like( exception { $no_tz_row->dt }, qr/\bdt\b.*\btz\b/,
"retrieving without timezone throws error" );

done_testing;
