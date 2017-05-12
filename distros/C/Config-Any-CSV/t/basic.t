use strict;
use warnings;

use Test::More;
use Config::Any;

my $config = Config::Any->load_stems( { 
    stems => [ 't/example/example' ], use_ext => 1 
} );

# note explain $config;

is_deeply
    $config->[0]->{'t/example.csv'},
    $config->[0]->{'t/example.json'};

my $file = 't/args.csv';
my $csv = Config::Any->load_files( {
    files => [ $file ], 
    use_ext => 1, 
    driver_args => { 
        CSV => { 
            sep_char => ';', 
            allow_whitespace => 0,
            empty_is_undef => 1,
            with_key => 1,
        } 
    }
} );

is_deeply( $csv, [{
    $file => { 
        42 => {
            id => 42,
            bar => undef,
            doz => 'Hi',
        },
        23 => {
            id => 23,
            bar => ' Hello',
            doz => undef
        },
    },
}], "read $file with driver_args" );

done_testing;
