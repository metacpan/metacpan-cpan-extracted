#!perl
use strict;
use warnings;
use Test::More;

# Ensure a recent version of Test::Deep
my $min_tp = 0.089;
eval "use Test::Deep $min_tp";
plan skip_all => "Test::Deep $min_tp required"
    if $@;

use Config::Strict;
use Declare::Constraints::Simple -All;

my %default = (
    a1 => [],
    h1 => {},
    e  => 3,
    ch => { k1 => '-foo-' }
);
my $config = Config::Strict->new( {
        params => {
            Str      => 's',
            ArrayRef => [ qw( a1 a2 ) ],
            HashRef  => [ qw( h1 h2 ) ],
            Enum     => { 'e' => [ 1, 2, 3 ] },
            Anon => { 'ch' => OnHashKeys( 'k1' => Matches( qr/foo/ ) ), }
        },
        required => [ qw( a1 h1 e ch ) ],
        defaults => \%default
    }
);

# Deep data
cmp_bag( [ $config->get(keys %default) ], [ values %default ], 'get' );
cmp_deeply( { $config->param_hash }, \%default, 'param_hash' );
cmp_bag(
    [ $config->param_array ],
    [ map { [ $_ => $default{ $_ } ] } keys %default ],
    'param_array'
);
cmp_bag( [ $config->all_set_params ], [ keys %default ], 'all_sets' );

done_testing(4);