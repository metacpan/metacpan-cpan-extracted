use Data::AnyXfer::Test::Kit;
use Data::AnyXfer::Elastic::DSL;
use DateTime;

use constant DSL => 'Data::AnyXfer::Elastic::DSL';


for ( tests() ) {

    my $method   = $_->{method};
    my @input    = @{ $_->{in} };
    my $expected = $_->{expected};

    # use DDP;
    # p DSL->$method(@input);
    is_deeply DSL->$method(@input), $expected, "${method} clause okay";

}


note 'Other methods';

ok DSL->format_datetime, 'default date time returned';

is                                         #
    DSL->format_datetime('2015-10-10'),    #
    '2015-10-10 23:59:59',                 #
    'string date time returned';           #

my $dt = DateTime->new( year => 1964, month => 10, day => 16 );

is                                           #
    DSL->format_datetime($dt),               #
    '1964-10-16 00:00:00',                   #
    'DateTime object date time returned';    #

$dt = DateTime->new(
    year   => 1989,
    month  => 11,
    day    => 9,
    hour   => 20,
    minute => 15
);

is                                                     #
    DSL->format_datetime($dt),                         #
    '1989-11-09 20:15:00',                             #
    'HH::Core::DateTime object date time returned';    #

done_testing;


sub tests {
    return (

        {   method   => 'exists',
            in       => ['location'],
            expected => { exists => { field => 'location' } },
        },

        {   method => 'geo_bounding_box',
            in     => [
                'location',
                top_left     => { lat => 50, lon => 0 },
                bottom_right => { lat => 49, lon => -0.1 }
            ],
            expected => {
                geo_bounding_box => {
                    location => {
                        top_left     => { lat => 50, lon => 0 },
                        bottom_right => { lat => 49, lon => -0.1 }
                    }
                }
            }
        },

        {   method => 'geo_distance',
            in     => [
                'pin.location',
                distance => '100km',
                lat      => 40,
                lon      => -70
            ],
            expected => {
                geo_distance => {
                    distance       => '100km',
                    'pin.location' => { lat => 40, lon => -70 }
                }
            },
        },

        {   method => 'geo_polygon',
            in     => [
                'location',
                points => [ [ -70, 40 ], [ -80, 30 ], [ -90, 20 ] ],
            ],
            expected => {
                geo_polygon => {
                    location => {
                        points => [ [ -70, 40 ], [ -80, 30 ], [ -90, 20 ] ],
                    }
                },
            },
        },

        {   method   => 'term',
            in       => [ 'fruit', value => 'orange', boost => 2.0 ],
            expected => { term => { fruit => 'orange', boost => 2.0 } },
        },

        {   method   => 'terms',
            in       => [ 'fruit', values => ['apples'], _cache => 1 ],
            expected => { terms => { fruit => ['apples'], _cache => 1, } },
        },

        {   method   => 'range',
            in       => [ 'age', gte => 16, lte => 25, ],
            expected => { range => { age => { gte => 16, lte => 25 } } },
        },

        {   method   => 'match',
            in       => [ 'postcode', query => 'E14 E15', operator => 'or' ],
            expected => {
                match => {
                    postcode => {
                        query    => 'E14 E15',
                        operator => 'or'
                    }
                }
            },
        },

        {   method => 'match_phrase',
            in     => [ 'street_name', 'Clerkenwell Lane' ],
            expected =>
                { match_phrase => { street_name => 'Clerkenwell Lane' }, },
        },

        {   method   => 'missing',
            in       => ['author'],
            expected => { bool => { must_not => { exists => { field => 'author' } } } },
        },
        {   method   => 'regexp',
            in       => [ 'author', value => 'Geor[A-z]?', _cache => 1 ],
            expected => {
                regexp => { author => { value => 'Geor[A-z]?', _cache => 1 } }
            },
        },

    );
}
