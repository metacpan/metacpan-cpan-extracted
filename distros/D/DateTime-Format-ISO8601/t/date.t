use strict;
use warnings;

use Test2::V0;

use DateTime::Format::ISO8601;

my $base_year  = 2000;
my $base_month = '01';
my $base_dt    = DateTime->new( year => $base_year, month => $base_month );
my $default_expect_date = '1985-04-12';

my @tests = (
    [qw( YYYYMMDD 19850412 )],
    [qw( YYYY-MM-DD 1985-04-12 )],
    [qw( YYYY-MM 1985-04 1985-04-01 )],
    [qw( YYYY 1985 1985-01-01 )],
    [qw( YY 19 1901-01-01 )],
    [qw( YYMMDD 850412 )],
    [qw( YY-MM-DD 85-04-12 )],
    [qw( -YYMM -8504 1985-04-01 )],
    [qw( -YY-MM -85-04 1985-04-01 )],
    [qw( -YY -85 1985-01-01 )],
    [ qw( --MM-DD --04-12 ), "${base_year}-04-12" ],
    [ qw( --MM --04 ),       "${base_year}-04-01" ],
    [ qw( ---DD ---12 ),     "${base_year}-${base_month}-12" ],
    [qw( +[YY]YYYYMMDD +0019850412 )],
    [qw( +[YY]YYYY-MM-DD +001985-04-12 )],
    [qw( +[YY]YYYY-MM +001985-04 1985-04-01 )],
    [qw( +[YY]YYYY +001985 1985-01-01 )],
    [qw( +[YY]YY +0019 1901-01-01 )],
    [qw( YYYYDDD 1985102 )],
    [qw( YYYY-DDD 1985-102 )],
    [qw( YYDDD 85102 )],
    [qw( YY-DDD 85-102 )],
    [qw( -DDD -103 2000-04-12 )],
    [qw( +[YY]YYYYDDD +001985102 )],
    [qw( +[YY]YYYY-DDD +001985-102 )],
    [qw( YYYYWwwD 1985W155 )],
    [qw( YYYY-Www-D 1985-W15-5 )],
    [qw( YYYYWww 1985W15 1985-04-08 )],
    [qw( YYYY-Www 1985-W15 1985-04-08 )],
    [qw( YYWwwD 85W155 )],
    [qw( YY-Www-D 85-W15-5 )],
    [qw( YYWww 85W15 1985-04-08 )],
    [qw( YY-Www 85-W15 1985-04-08 )],
    [qw( -YWwwD -5W155 2005-04-15 )],
    [qw( -Y-Www-D -5-W15-5 2005-04-15 )],
    [qw( -YWww -5W15 2005-04-11 )],
    [qw( -Y-Www -5-W15 2005-04-11 )],
    [qw( -WwwD -W155 2000-04-14 )],
    [qw( -Www-D -W15-5 2000-04-14 )],
    [qw( -W-D -W-5 2000-12-29 )],
    [qw( +[YY]YYYYWwwD +001985W155 )],
    [qw( +[YY]YYYY-Www-D +001985-W15-5 )],
    [qw( +[YY]YYYYWww +001985W15 1985-04-08 )],
    [qw( +[YY]YYYY-Www +001985-W15 1985-04-08 )],
);

subtest(
    'date formats with base_datetime' => sub {
        my $iso8601
            = DateTime::Format::ISO8601->new( base_datetime => $base_dt );
        for my $t (@tests) {
            my ( $format, $to_parse, $expect ) = @{$t};
            $expect ||= $default_expect_date;
            subtest(
                $format => sub {
                    is(
                        $iso8601->parse_datetime($to_parse)->ymd,
                        $expect,
                        "$to_parse = $expect",
                    );
                }
            );
        }
    }
);

subtest(
    'date formats without base_datetime' => sub {
        my $epoch
            = DateTime->new( year => 2000, month => 1, time_zone => 'UTC' )
            ->epoch;

        no warnings 'redefine';
        ## no critic (Variables::ProtectPrivateVars)
        local *DateTime::_core_time = sub {$epoch};

        my $iso8601 = DateTime::Format::ISO8601->new;
        for my $parser ( $iso8601, 'DateTime::Format::ISO8601' ) {
            my $st = 'parse with ' . ( ref $parser ? 'object' : 'class' );
            subtest(
                $st => sub {
                    for my $t (@tests) {
                        my ( $format, $to_parse, $expect ) = @{$t};
                        $expect ||= $default_expect_date;
                        subtest(
                            $format => sub {
                                is(
                                    $parser->parse_datetime($to_parse)->ymd,
                                    $expect,
                                    "$to_parse = $expect",
                                );
                            }
                        );
                    }
                }
            );
        }
    }
);

subtest(
    'ISO week of year parsing',
    sub {
        my $iso8601      = DateTime::Format::ISO8601->new;
        my %week_formats = (
            'YYYY-Www'   => q{YYYY'-W'ww},
            'YYYY-Www-D' => q{YYYY'-W'ww'-'c},
            'YYYYWww'    => q{YYYY'W'ww},
            'YYYYWwwD'   => q{YYYY'W'wwc},
        );

        # This makes sure we cover the entire last week of one year and one
        # more entire year.
        my $dt = DateTime->new( year => 1991, month => 12, day => 22 );

        # This tests many possible cases, visiting every week in each year at
        # least once.
        while ( $dt->year < 2000 ) {
            $dt->add( days => 3 );
            subtest(
                $dt->ymd,
                sub {
                    for my $iso_format ( sort keys %week_formats ) {
                        subtest(
                            $iso_format => sub {
                                my $expect;
                                if ( $iso_format =~ /d$/i ) {
                                    $expect = $dt->ymd;
                                }
                                else {
                                    $expect
                                        = $dt->clone->truncate( to => 'week' )
                                        ->ymd;
                                }

                                my $to_parse
                                    = $dt->format_cldr(
                                    $week_formats{$iso_format} );
                                is(
                                    $iso8601->parse_datetime($to_parse)->ymd,
                                    $expect,
                                    "$to_parse = $expect",
                                );
                            }
                        );
                    }
                }
            );

        }
    }
);

subtest(
    '1 digit year in 2015',
    sub {
        my $epoch
            = DateTime->new( year => 2015, month => 1, day => 1 )->epoch;
        no warnings 'redefine';
        ## no critic (Variables::ProtectPrivateVars)
        local *DateTime::_core_time = sub {$epoch};

        my $parser = DateTime::Format::ISO8601->new;
        my $dt     = $parser->parse_datetime('-6W155');
        is( $dt->ymd, '2016-04-15' );
    }
);

done_testing();
