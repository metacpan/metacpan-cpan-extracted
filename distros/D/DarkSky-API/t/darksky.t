use Test::More tests => 6;

use strict;
use warnings;
use DarkSky::API;
use Test::MockModule;

my $lat  = 43.6667;
my $long = -79.4167;
my $time = 1373241600;

my $forecast;

{
    my $mock = Test::MockModule->new('DarkSky::API');
    $mock->mock(
        "new" => sub {
            return {
                'latitude'  => $lat,
                'longitude' => $long,
                'currently' => { 'time' => $time, 'summary' => 'something' },
                'daily'  => { 'data' => 1 },
                'hourly' => { 'data' => 1 },
            };
        }
    );

    $forecast = DarkSky::API->new(
        key       => 'something',
        longitude => $long,
        latitude  => $lat,
        'time'    => $time
    );
}

is( sprintf( "%.4f", $forecast->{latitude} ),  $lat );
is( sprintf( "%.4f", $forecast->{longitude} ), $long );
is( $forecast->{currently}->{'time'}, $time );
ok( exists( $forecast->{daily}->{data} ) );
ok( exists( $forecast->{hourly}->{data} ) );
ok( exists( $forecast->{currently}->{summary} ) );
