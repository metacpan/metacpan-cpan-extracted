use Test2::V0;
use Config::App;

my ( $obj, $conf );
ok( $obj = Config::App->new( 'config/merge.yaml', 1 ), 'Config::App->new( "merge.yaml", 1 )' );

ok(
    lives {
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
    'Config::App->conf({...})',
) or note $@;

is(
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
