#!perl -T

use strict;
use warnings;

use Test::More tests => 19;

use Data::Ovulation;

my $temperatures = [ qw/
36.5 36.1 36.1 36.2 36.2 36.2 36.3 36.2 36.2 36.1 36.3 36.4 36.2 36.4 36.4
36.4 36.4 36.5 36.7 36.7 36.6 36.6 36.7 36.8 36.6 36.7 36.8 36.8 36.8 36.7 36.9
36.9 36.8 36.8 36.7 36.8 36.9/ ];

my $ovul = Data::Ovulation->new;

# Ovulation: RULE 1
$ovul->temperatures( $temperatures );
my $data = $ovul->calculate;
is_deeply( $data->ovulation_days, [ qw/ 16 17 18 / ], "Ovulation: Rule #1 - Ovulation day" );
is_deeply( $data->fertile_days, [ qw/ 14 15 16 17 18 / ], "Ovulation: Rule #1 - Fertile days" );
is( $data->day_rise, 18, "Ovulation: Rule #1 - Rise of temperature day" );
is( $data->cover_temperature, 36.4, "Ovulation: Rule #1 - Cover temperature" );
is( $data->impregnation, 1, "Ovulation: Rule #1 - Possible impregnation" );
is( sprintf( "%2.1f", $data->min ), sprintf( "%2.1f", 36.1 ), "Ovulation: Rule #1 - Lowest temperature value" );
is( sprintf( "%2.1f", $data->max ), sprintf( "%2.1f", 36.9 ), "Ovulation: Rule #1 - Highest temperature value" );

# Ovulation: RULE 2
my $rule2_temps = [ qw/36.0 36.2 36.2 36.1 36.3 36.3 36.6 36.4 36.4 36.5/ ];
$ovul->temperatures( $rule2_temps );
$data = $ovul->calculate;
is( $data->day_rise, 7, "Ovulation: Rule #2 - Rise of temperature day" );
is_deeply( $data->ovulation_days, [ qw/ 5 6 7 / ], "Ovulation: Rule #2 - Ovulation day" );
is_deeply( $data->fertile_days, [ qw/ 3 4 5 6 7 / ], "Ovulation: Rule #1 - Fertile days" );
is( $data->cover_temperature, 36.3, "Ovulation: Rule #2 - Cover temperature" );
is( sprintf( "%2.1f", $data->min ), sprintf( "%2.1f", 36.0 ), "Ovulation: Rule #2 - Lowest temperature value" );
is( sprintf( "%2.1f", $data->max ), sprintf( "%2.1f", 36.6 ), "Ovulation: Rule #2 - Highest temperature value" );

# Ovulation: RULE 3
my $rule3_temps = [ qw/36.0 36.2 36.2 36.1 36.3 36.3 36.6 36.0 36.4 36.5/ ];
$ovul->temperatures( $rule3_temps );
$data = $ovul->calculate;
is( $data->day_rise, 7, "Ovulation: Rule #3 - Rise of temperature day" );
is_deeply( $data->ovulation_days, [ qw/ 5 6 7 / ], "Ovulation: Rule #3 - Ovulation day" );
is_deeply( $data->fertile_days, [ qw/ 3 4 5 6 7 / ], "Ovulation: Rule #3 - Fertile days" );
is( $data->cover_temperature, 36.3, "Ovulation: Rule #3 - Cover temperature" );
is( sprintf( "%2.1f", $data->min ), sprintf( "%2.1f", 36.0 ), "Ovulation: Rule #2 - Lowest temperature value" );
is( sprintf( "%2.1f", $data->max ), sprintf( "%2.1f", 36.6 ), "Ovulation: Rule #2 - Highest temperature value" );
