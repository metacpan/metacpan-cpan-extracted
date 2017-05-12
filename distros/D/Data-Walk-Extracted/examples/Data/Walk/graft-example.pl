#!perl
use lib '../lib', 'lib';
use Data::Walk::Extracted;
use Data::Walk::Graft;
use Data::Walk::Print;
use MooseX::ShortCut::BuildInstance qw( build_instance );

my  $gardener = build_instance( 
		package => 'Jordan::Porter',
		superclasses =>['Data::Walk::Extracted'],
		roles =>[qw( Data::Walk::Graft Data::Walk::Clone Data::Walk::Print )],
		sorted_nodes =>{
			HASH => 1,
		},# For demonstration consistency
		#Until Data::Walk::Extracted and ::Graft support these types
		#(watch Data-Walk-Extracted on github)
		skipped_nodes =>{ 
			OBJECT => 1,
			CODEREF => 1,
		},
		graft_memory => 1,
	);
my  $tree_ref = {
        Helping =>{
            KeyTwo => 'A New Value',
            KeyThree => 'Another Value',
            OtherKey => 'Something',
        },
        MyArray =>[
            'ValueOne',
            'ValueTwo',
            'ValueThree',
        ],
    };
$gardener->graft_data(
    scion_ref =>{
        Helping =>{
            OtherKey => 'Otherthing',
        },
        MyArray =>[
            'IGNORE',
            {
                What => 'Chicken_Butt!',
            },
            'IGNORE',
            'IGNORE',
            'ValueFive',
        ],
    }, 
    tree_ref  => $tree_ref,
);
$gardener->print_data( $tree_ref );
print "Now a list of -" . $gardener->number_of_scions . "- grafted positions\n";
$gardener->print_data( $gardener->get_grafted_positions );