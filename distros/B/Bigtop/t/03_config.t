use strict;

use Test::More tests => 1;

use Bigtop::Parser;

my $bigtop_string = <<"EO_Bigtop";
config {
    base_dir  `.`;
    SQL       Postgres {}
    SQL       MySQL    { no_gen 1; }
    HttpdConf Gantry   {}
}
app Apps::Checkbook {
    table payeepayor {
        field id    { is int, primary_key, auto; }
    }
}
EO_Bigtop

Bigtop::Parser->add_valid_keywords(
    'field',
    { keyword => 'is' },
    { keyword => 'update_with' },
);

my $conf         = Bigtop::Parser->parse_config_string($bigtop_string);
my $correct_conf = {
    base_dir                  => '.',
    'SQL'     => {
        __NAME__ => 'MySQL',
        no_gen => 1,
    },
    'HttpdConf' => {
        __NAME__ => 'Gantry',
    },
    '__STATEMENTS__' => [
        [ 'base_dir', '.' ],
        [ 'SQL', { __NAME__ => 'Postgres' }, ],
        [ 'SQL', { __NAME__ => 'MySQL',
                   no_gen => 1, }, ],
        [ 'HttpdConf', { __NAME__ => 'Gantry' }, ],
    ],
    '__BACKENDS__' => {
        HttpdConf => [
            {
                __NAME__ => 'Gantry',
            },
        ],
        SQL       => [
            {
                __NAME__ => 'Postgres',
            },
            {
                __NAME__ => 'MySQL',
                no_gen   => 1,
            },
        ],
    },
};

is_deeply( $conf, $correct_conf, 'config string parsed' );

# use Data::Dumper; warn Dumper( $conf );
# use Data::Dumper; warn Dumper( $tree );
