#!perl
BEGIN
{
    use strict;
    use warnings;
    use lib './lib';
    use open ':std' => ':utf8';
    use vars qw( $DEBUG $dt_class );
    use utf8;
    use version;
    use Test::More;
    use DBD::SQLite;
    if( version->parse( $DBD::SQLite::sqlite_version ) < version->parse( '3.6.19' ) )
    {
        plan skip_all => 'SQLite driver version 3.6.19 or higher is required. You have version ' . $DBD::SQLite::sqlite_version;
    }
    elsif( $^O eq 'openbsd' && ( $^V >= v5.12.0 && $^V <= v5.12.5 ) )
    {
        plan skip_all => 'Weird memory bug out of my control on OpenBSD for v5.12.0 to 5';
    }

    # NOTE: We support both DateTime::Lite (preferred for speed) and DateTime.
    # If neither is installed, the tests are skipped. This avoids a circular dependency
    # between DateTime::Locale::FromCLDR and DateTime::Lite.
    if( eval{ require DateTime::Lite; 1 } )
    {
        $dt_class = 'DateTime::Lite';
    }
    elsif( eval{ require DateTime; 1 } )
    {
        $dt_class = 'DateTime';
    }
    else
    {
        plan skip_all => 'Neither DateTime::Lite nor DateTime is installed; cannot run interval diff tests';
    }
    our $DEBUG = exists( $ENV{AUTHOR_TESTING} ) ? $ENV{AUTHOR_TESTING} : 0;
};

BEGIN
{
    use_ok( 'DateTime::Locale::FromCLDR' ) || BAIL_OUT( 'Unable to load DateTime::Locale::FromCLDR' );
};

use strict;
use warnings;
use utf8;

my $locale = DateTime::Locale::FromCLDR->new( 'en' );
isa_ok( $locale, 'DateTime::Locale::FromCLDR' );

my $year = $dt_class->now->year;
my( $dt1, $dt2, $diff );

# NOTE: Different era
diag( "Testing different eras" ) if( $DEBUG );
$dt1 = $dt_class->new(
    year => -1,
    month => 1,
    day => 1,
    hour => 0,
    minute => 0,
    second => 0,
    time_zone => 'floating',
);
$dt2 = $dt_class->new(
    year => $year,
    month => 1,
    day => 1,
    hour => 0,
    minute => 0,
    second => 0,
    time_zone => 'floating',
);
diag( "Comparing ", $dt1->iso8601, " and ", $dt2->iso8601 ) if( $DEBUG );
$diff = $locale->interval_greatest_diff( $dt1, $dt2 );
BAIL_OUT( $locale->error ) if( !defined( $diff ) && $locale->error );
diag( "Greatest difference is: '${diff}'" ) if( $DEBUG );
is( $diff, 'G', 'G' );

# NOTE: Different years
diag( "Testing different years" ) if( $DEBUG );
$dt1 = $dt_class->new(
    year => $year,
    month => 1,
    day => 1,
    hour => 0,
    minute => 0,
    second => 0,
    time_zone => 'floating',
);
$dt2 = $dt_class->new(
    year => ( $year + 1 ),
    month => 1,
    day => 1,
    hour => 0,
    minute => 0,
    second => 0,
    time_zone => 'floating',
);
diag( "Comparing ", $dt1->iso8601, " and ", $dt2->iso8601 ) if( $DEBUG );
$diff = $locale->interval_greatest_diff( $dt1, $dt2 );
BAIL_OUT( $locale->error ) if( !defined( $diff ) && $locale->error );
diag( "Greatest difference is: '${diff}'" ) if( $DEBUG );
is( $diff, 'y', 'y' );

# NOTE: Different months
diag( "Testing different months" ) if( $DEBUG );
$dt1 = $dt_class->new(
    year => $year,
    month => 1,
    day => 1,
    hour => 0,
    minute => 0,
    second => 0,
    time_zone => 'floating',
);
$dt2 = $dt_class->new(
    year => $year,
    month => 2,
    day => 2,
    hour => 0,
    minute => 0,
    second => 0,
    time_zone => 'floating',
);
diag( "Comparing ", $dt1->iso8601, " and ", $dt2->iso8601 ) if( $DEBUG );
$diff = $locale->interval_greatest_diff( $dt1, $dt2 );
BAIL_OUT( $locale->error ) if( !defined( $diff ) && $locale->error );
diag( "Greatest difference is: '${diff}'" ) if( $DEBUG );
is( $diff, 'M', 'M' );

# NOTE: Different days
diag( "Testing different days" ) if( $DEBUG );
$dt1 = $dt_class->new(
    year => $year,
    month => 1,
    day => 1,
    hour => 0,
    minute => 0,
    second => 0,
    time_zone => 'floating',
);
$dt2 = $dt_class->new(
    year => $year,
    month => 1,
    day => 2,
    hour => 0,
    minute => 0,
    second => 0,
    time_zone => 'floating',
);
diag( "Comparing ", $dt1->iso8601, " and ", $dt2->iso8601 ) if( $DEBUG );
$diff = $locale->interval_greatest_diff( $dt1, $dt2 );
BAIL_OUT( $locale->error ) if( !defined( $diff ) && $locale->error );
diag( "Greatest difference is: '${diff}'" ) if( $DEBUG );
is( $diff, 'd', 'd' );

# NOTE: morning vs afternoon
diag( "Testing AM/PM" ) if( $DEBUG );
$dt1 = $dt_class->new(
    year => $year,
    month => 1,
    day => 1,
    hour => 2,
    minute => 0,
    second => 0,
    time_zone => 'floating',
);
$dt2 = $dt_class->new(
    year => $year,
    month => 1,
    day => 1,
    hour => 14,
    minute => 0,
    second => 0,
    time_zone => 'floating',
);
diag( "Comparing ", $dt1->iso8601, " and ", $dt2->iso8601 ) if( $DEBUG );
$diff = $locale->interval_greatest_diff( $dt1, $dt2 );
BAIL_OUT( $locale->error ) if( !defined( $diff ) && $locale->error );
diag( "Greatest difference is: '${diff}'" ) if( $DEBUG );
is( $diff, 'a', 'a' );

$diff = $locale->interval_greatest_diff( $dt1, $dt2, day_period_first => 1 );
BAIL_OUT( $locale->error ) if( !defined( $diff ) && $locale->error );
diag( "Greatest difference is: '${diff}'" ) if( $DEBUG );
is( $diff, 'B', 'B' );

# NOTE: Different periods of the day
diag( "Testing different periods of the day" ) if( $DEBUG );
$dt1 = $dt_class->new(
    year => $year,
    month => 1,
    day => 1,
    hour => 2,
    minute => 0,
    second => 0,
    time_zone => 'floating',
);
$dt2 = $dt_class->new(
    year => $year,
    month => 1,
    day => 1,
    hour => 11,
    minute => 0,
    second => 0,
    time_zone => 'floating',
);
diag( "Comparing ", $dt1->iso8601, " and ", $dt2->iso8601 ) if( $DEBUG );
$diff = $locale->interval_greatest_diff( $dt1, $dt2 );
BAIL_OUT( $locale->error ) if( !defined( $diff ) && $locale->error );
diag( "Greatest difference is: '${diff}'" ) if( $DEBUG );
# is( $diff, 'B', 'B' );
is( $diff, 'h', 'h' );

# NOTE: Different hours
diag( "Testing different hours" ) if( $DEBUG );
$dt1 = $dt_class->new(
    year => $year,
    month => 1,
    day => 1,
    hour => 13,
    minute => 0,
    second => 0,
    time_zone => 'floating',
);
$dt2 = $dt_class->new(
    year => $year,
    month => 1,
    day => 1,
    hour => 17,
    minute => 0,
    second => 0,
    time_zone => 'floating',
);
diag( "Comparing ", $dt1->iso8601, " and ", $dt2->iso8601 ) if( $DEBUG );
$diff = $locale->interval_greatest_diff( $dt1, $dt2 );
BAIL_OUT( $locale->error ) if( !defined( $diff ) && $locale->error );
diag( "Greatest difference is: '${diff}'" ) if( $DEBUG );
is( $diff, 'h', 'h' );

# NOTE: Different minutes
diag( "Testing different minutes" ) if( $DEBUG );
$dt1 = $dt_class->new(
    year => $year,
    month => 1,
    day => 1,
    hour => 12,
    minute => 10,
    second => 0,
    time_zone => 'floating',
);
$dt2 = $dt_class->new(
    year => $year,
    month => 1,
    day => 1,
    hour => 12,
    minute => 20,
    second => 0,
    time_zone => 'floating',
);
diag( "Comparing ", $dt1->iso8601, " and ", $dt2->iso8601 ) if( $DEBUG );
$diff = $locale->interval_greatest_diff( $dt1, $dt2 );
BAIL_OUT( $locale->error ) if( !defined( $diff ) && $locale->error );
diag( "Greatest difference is: '${diff}'" ) if( $DEBUG );
is( $diff, 'm', 'm' );

done_testing();

__END__
