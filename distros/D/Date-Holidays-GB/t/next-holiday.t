use Test::Most;
use Test::Time;
use Date::Holidays::GB qw/ next_holiday /;

$Test::Time::time = 1581526134;

ok my $next_holiday = next_holiday(), "next_holiday returned truthy";

is_deeply $next_holiday,
    {
    EAW => {
        date => "2020-04-10",
        name => "Good Friday",
    },
    NIR => {
        date => "2020-03-17",
        name => "St Patrick\x{2019}s Day",
    },
    SCT => {
        date => "2020-04-10",
        name => "Good Friday",
    },
    all => {
        date => "2020-04-10",
        name => "Good Friday",
    },
    },
    "next holiday as expected";

# Set to Good Friday (i.e. the next holiday from above)
$Test::Time::time = 1586476800;

ok $next_holiday = next_holiday(), "next_holiday returned truthy";

is_deeply $next_holiday,
    {
    EAW => {
        date => "2020-04-13",
        name => "Easter Monday",
    },
    NIR => {
        date => "2020-04-13",
        name => "Easter Monday",
    },
    SCT => {
        date => "2020-05-08",
        name => "Early May bank holiday (VE day)",
    },
    all => {
        date => "2020-05-08",
        name => "Early May bank holiday (VE day)",
    },
    },
    "next holiday as expected";

subtest regions => sub {

    is_deeply next_holiday('EAW'),
        {
        EAW => {
            date => "2020-04-13",
            name => "Easter Monday",
        },
        },
        "next holiday for one region as expected";

    is_deeply next_holiday( 'EAW', 'NIR' ),
        {
        EAW => {
            date => "2020-04-13",
            name => "Easter Monday",
        },
        NIR => {
            date => "2020-04-13",
            name => "Easter Monday",
        },
        },
        "next holiday for multiple regions as expected";
};

done_testing;

