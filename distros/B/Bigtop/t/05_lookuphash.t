use strict;

use Test::More tests => 1;

use Bigtop::Parser;

my $bigtop_string = <<"EO_Bigtop";
config {
    base_dir  `.`;
    SQL       Postgres {}
    HttpdConf Gantry   {}
}
app Apps::Checkbook {
    author `Phil Crow`;
    sequence payeepayor_seq {}
    table payeepayor {
        field id    { is int, primary_key, auto; }
    }
}
EO_Bigtop

Bigtop::Parser->add_valid_keywords( 'app',   { keyword => 'author' } );
Bigtop::Parser->add_valid_keywords(
    'field',
    { keyword => 'is' },
    { keyword => 'update_with' },
);

my $tree         = Bigtop::Parser->parse_string($bigtop_string);
my $correct_lookup = {
    tables => {
        payeepayor => {
            fields => {
                id => {
                    is => {
                        args => bless(
                            [ 'int', 'primary_key', 'auto' ],
                        'arg_list' )
                    },
                    __IDENT__ => 'ident_2',
                },
            },
            __IDENT__ => 'ident_3',
        },
    },
    app_statements => {
        author => bless( [ 'Phil Crow' ], 'arg_lst' ),
    },
    sequences => {
        payeepayor_seq => 'ident_1'
    }
};

is_deeply( $tree->{application}{lookup}, $correct_lookup, 'lookup hash' );

# use Data::Dumper; warn Dumper( $tree->{application}{lookup} );

# use Data::Dumper; warn Dumper( $tree );
