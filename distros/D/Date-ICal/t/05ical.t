use Test::More qw(no_plan);

BEGIN{use_ok('Date::ICal')}

# Testing object creation with ical string

my $acctest = Date::ICal->new( ical => "19920405T160708Z" );

is( $acctest->sec,    8,    "second accessor read is correct" );
is( $acctest->minute, 7,    "minute accessor read is correct" );
is( $acctest->hour,   16,   "hour accessor read is correct" );
is( $acctest->day,    5,    "day accessor read is correct" );
is( $acctest->month,  4,    "month accessor read is correct" );
is( $acctest->year,   1992, "year accessor read is correct" );

# extra-epoch dates?

my $preepoch = Date::ICal->new( ical => '18700523T164702Z' );
is( $preepoch->year,  1870, 'Pre-epoch year' );
is( $preepoch->month, 5,    'Pre-epoch month' );
is( $preepoch->sec,   2,    'Pre-epoch seconds' );

my $postepoch = Date::ICal->new( ical => '23481016T041612Z' );
is( $postepoch->year, 2348, "Post-epoch year" );
is( $postepoch->day,  16,   "Post-epoch day" );
is( $postepoch->hour, 04,   "Post-epoch hour" );


