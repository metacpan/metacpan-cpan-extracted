use strict;
use warnings;

use Test::Most;

use constant MODULE => 'Config::App';

BEGIN { use_ok(MODULE); }

my ( $obj, $conf );

ok( $obj = MODULE->new( 'config/merge.yaml', 1 ), MODULE . '->new( "merge.yaml", 1 )' );

lives_ok(
    sub {
        $conf = $obj->conf({
            logs => {
                outputs => [
                    {
                        File => {
                            name      => 'develop.log',
                            min_level => 'debug',
                        },
                    },
                    {
                        File => {
                            name      => 'errors.log',
                            min_level => 'error',
                        },
                    },
                ],
            },
        });
    },
    MODULE . '->conf({...})',
);

is_deeply(
    $conf->{logs},
    {
        outputs => [
            {
                File => {
                    min_level => 'debug',
                    name      => 'develop.log',
                },
            },
            {
                File => {
                    min_level => 'error',
                    name      => 'errors.log',
                },
            },
        ],
    },
    'Merged conf data is correct',
);

done_testing;
