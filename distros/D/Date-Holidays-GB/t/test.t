# test.t

use utf8;
use Test::Most;
use Test::Fatal;

my $builder = Test::More->builder;
binmode $builder->output,         ":utf8";
binmode $builder->failure_output, ":utf8";
binmode $builder->todo_output,    ":utf8";

use Date::Holidays::GB qw( is_holiday holidays holidays_ymd );

open( my $fh, '<:encoding(utf-8)', 't/samples/2013-holidays' )
    or die "Can't open 2013-holidays: $!";

Date::Holidays::GB::set_holidays($fh);

subtest is_holiday => sub {

    my @tests = (
        { date => [ year => 2013, month => 1,  day => 3 ],  holiday => 0, },
        { date => [ year => 2013, month => 12, day => 25 ], holiday => 'Christmas Day', },
        {   date    => [ year => 2013, month => 12, day => 25 ],
            regions => [],
            holiday => 0,
        },
        {   date    => [ year => 2013, month => 11, day => 30 ],
            regions => ['EAW'],
            holiday => 0,
        },
        {   date    => [ year => 2013, month => 12, day => 2 ],
            regions => ['EAW'],
            holiday => 0,
        },
        {   date    => [ year => 2013, month => 12, day => 2 ],
            regions => ['SCT'],
            holiday => "St Andrew\x{2019}s Day (Scotland)",
        },
    );

    foreach my $test (@tests) {
        my $regions = $test->{regions};
        my %date    = @{ $test->{date} };
        my $string
            = sprintf( "%02d-%02d-%02d", $date{year}, $date{month}, $date{day} );

        my $regions_str = $regions ? join( ',', @{$regions} ) : '<none>';
        note $string . " - regions: $regions_str";

        if ( my $expected = $test->{holiday} ) {
            my $holiday;
            ok $holiday
                = is_holiday( $date{year}, $date{month}, $date{day}, $regions ),
                "is a holiday (using list)";
            is $holiday, $expected, "holiday name ok";

            ok $holiday = is_holiday( date => $string, regions => $regions ),
                "is a holiday (using 'date')";
            is $holiday, $expected, "holiday name ok";

            ok $holiday = is_holiday( %date, regions => $regions ),
                "is a holiday (using year/month/day arguments')";
            is $holiday, $expected, "holiday name ok";
        }
        else {
            ok !is_holiday( $date{year}, $date{month}, $date{day}, $regions ),
                "not a holiday (using list)";
            ok !is_holiday( date => $string, regions => $regions ),
                "not a holiday (using 'date')";
            ok !is_holiday( %date, regions => $regions ),
                "not a holiday (using year/month/day arguments')";
        }

    }
};

subtest holidays => sub {

    is_deeply holidays(2000), {}, "No data for year 2000 - outside range";
    is_deeply holidays(2030), {}, "No data for year 2030 - outside range";

#like exception { holidays(2000) }, qr/No holiday data for year 2000/, "dies ok outside date range";
#like exception { holidays(2030) }, qr/No holiday data for year 2030/, "dies ok outside date range";

    is_deeply holidays(2013),
        {
        "0101" => "New Year\x{2019}s Day",
        "0102" => "2nd January (Scotland)",
        "0318" => "St Patrick\x{2019}s Day (Northern Ireland)",
        "0329" => "Good Friday",
        "0401" => "Easter Monday (England & Wales, Northern Ireland)",
        "0506" => "Early May bank holiday",
        "0527" => "Spring bank holiday",
        "0712" => "Battle of the Boyne (Orangemen\x{2019}s Day) (Northern Ireland)",
        "0805" => "Summer bank holiday (Scotland)",
        "0826" => "Summer bank holiday (England & Wales, Northern Ireland)",
        "1202" => "St Andrew\x{2019}s Day (Scotland)",
        "1225" => "Christmas Day",
        "1226" => "Boxing Day"
        },
        "2013 holidays ok";

    is_deeply holidays_ymd(2013),
        {
        "2013-01-01" => "New Year\x{2019}s Day",
        "2013-01-02" => "2nd January (Scotland)",
        "2013-03-18" => "St Patrick\x{2019}s Day (Northern Ireland)",
        "2013-03-29" => "Good Friday",
        "2013-04-01" => "Easter Monday (England & Wales, Northern Ireland)",
        "2013-05-06" => "Early May bank holiday",
        "2013-05-27" => "Spring bank holiday",
        "2013-07-12" => "Battle of the Boyne (Orangemen\x{2019}s Day) (Northern Ireland)",
        "2013-08-05" => "Summer bank holiday (Scotland)",
        "2013-08-26" => "Summer bank holiday (England & Wales, Northern Ireland)",
        "2013-12-02" => "St Andrew\x{2019}s Day (Scotland)",
        "2013-12-25" => "Christmas Day",
        "2013-12-26" => "Boxing Day"
        },
        "2013 holidays_ymd ok";

    is_deeply holidays( year => 2013, regions => ['EAW'] ),
        {
        "0101" => "New Year\x{2019}s Day",
        "0329" => "Good Friday",
        "0401" => "Easter Monday (England & Wales)",
        "0506" => "Early May bank holiday",
        "0527" => "Spring bank holiday",
        "0826" => "Summer bank holiday (England & Wales)",
        "1225" => "Christmas Day",
        "1226" => "Boxing Day"
        },
        "got holidays for England & Wales, 2013";
};

done_testing();

