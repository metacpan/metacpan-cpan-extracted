#!perl
use MooseX::ShortCut::BuildInstance qw( build_instance );
use lib '../lib';
use Data::Walk::Extracted;
use Data::Walk::Prune;
use Data::Walk::Print;

my  $edward_scissorhands = build_instance( 
		package => 'Edward::Scissorhands',
		superclasses =>['Data::Walk::Extracted'],
		roles =>[qw( Data::Walk::Print Data::Walk::Prune )],
		change_array_size => 1, #Default
    );
my  $firstref = {
        Helping => [
            'Somelevel',
            {
                MyKey => {
                    MiddleKey => {
                        LowerKey1 => 'low_value1',
                        LowerKey2 => {
                            BottomKey1 => 'bvalue1',
                            BottomKey2 => 'bvalue2',
                        },
                    },
                },
            },
        ],
    };
my	$result = $edward_scissorhands->prune_data(
        tree_ref    => $firstref, 
        slice_ref   => {
            Helping => [
				undef,
                {
                    MyKey => {
                        MiddleKey => {
                            LowerKey1 => {},
                        },
                    },
                },
            ],
        },
    );
$edward_scissorhands->print_data( $result );