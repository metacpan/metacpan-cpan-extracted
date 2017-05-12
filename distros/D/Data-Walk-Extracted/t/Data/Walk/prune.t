#! C:/Perl/bin/perl
#######  Test File for Data::Walk::Prune  #######
BEGIN{
	#~ $ENV{ Smart_Comments } = '### #### #####';
}
use Test::Most tests => 27;
use Test::Moose;
use MooseX::ShortCut::BuildInstance 0.008 qw( build_instance );
use lib	
		'../../../lib',
		'../../lib',
		'../../../../Log-Shiras/lib',
		;
#~ use Log::Shiras::Unhide qw( :InternalExtracteD :InternalExtracteDDispatcH :InternalExtracteDPrunE );
#~ use Data::Walk::Extracted::Dispatch;# To unhide debug
use Data::Walk::Extracted 0.026;
use Data::Walk::Prune 0.026;

my  ( $wait, $newclass, $edward_scissorhands, $treeref, $sliceref, $answerref );

my  		@attributes = qw(
				prune_memory
			);

my  		@methods = qw(
				new
				prune_data
				set_prune_memory
				get_prune_memory
				has_prune_memory
				clear_prune_memory
				get_pruned_positions
				has_pruned_positions
				number_of_cuts
			);
    
# basic questions
lives_ok{
			$edward_scissorhands = 	build_instance(
										package => 'Barber',
										superclasses => ['Data::Walk::Extracted',],
										roles =>[ 'Data::Walk::Prune',],
									);
}                                       "Prep a new Prune instance";
does_ok		$edward_scissorhands, 'Data::Walk::Prune',
										"Check that 'with_traits' added the 'Data::Walk::Prune' Role to the instance";
map{ 
has_attribute_ok
			$edward_scissorhands, $_,	"Check that the new instance has the -$_- attribute"
} 			@attributes;
map{
can_ok		$edward_scissorhands, $_
}			@methods;

#Run the hard questions
lives_ok{   
			$treeref = {
				Someotherkey    => 'value',
				Parsing         =>{
					HashRef =>{
						LOGGER =>{
							run => 'INFO',
						},
					},
				},
				Helping =>[
					'Somelevel',
					{
						MyKey =>{
							MiddleKey =>{
								LowerKey1 => 'lvalue1',
								LowerKey2 => {
									BottomKey1 => 'bvalue1',
									BottomKey2 => 'bvalue2',
								},
							},
						},
					},
				],
			};
}										'Build the $tree_ref for testing';
lives_ok{   
			$answerref =  {
				Parsing         =>{
					HashRef =>{
						LOGGER =>{
							run => 'INFO',
						},
					},
				},
				Helping =>[
					'Somelevel',
					{
						MyKey =>{
							MiddleKey =>{
								LowerKey1 => 'lvalue1',
								LowerKey2 => {
									BottomKey1 => 'bvalue1',
									BottomKey2 => 'bvalue2',
								},
							},
						},
					},
				],
			};
}										'Build the $answer_ref for testing';
is_deeply	$edward_scissorhands->prune_data(
                slice_ref 	=> { Someotherkey => {} }, 
                tree_ref	=> $treeref,
            ),
            $answerref,                 'Test pruning a top level key';
lives_ok{   
			$sliceref =  {
				Helping =>[
					'',
					{
						MyKey =>{
							MiddleKey =>{
								LowerKey2 => {},
							},
						},
					},
				],
			};
}										'build a $slice_ref for testing';
lives_ok{   
			$answerref =  {
				Parsing         =>{
					HashRef =>{
						LOGGER =>{
							run => 'INFO',
						},
					},
				},
				Helping =>[
					'Somelevel',
					{
						MyKey =>{
							MiddleKey =>{
								LowerKey1 => 'lvalue1',
							},
						},
					},
				],
			};
}										'... change the $answer_ref for testing';
is_deeply	$edward_scissorhands->prune_data(
                tree_ref    => $treeref, 
                slice_ref   => $sliceref
            ), 
            $answerref,					'Test pruning a low level key (through an arrayref level)';
#~ exit 1;
ok			$edward_scissorhands->set_change_array_size( 1 ),
										'Turn on splice removal of array elements';
lives_ok{   
			$sliceref =  {
				Helping =>[
					'Somelevel',
					{
						MyKey =>{
							MiddleKey =>{
								LowerKey1 => [],
							},
						},
					},
				],
			};
}										'... change the $slice_ref for testing';
lives_ok{   
			$answerref =  {
				Parsing =>{
					HashRef =>{
						LOGGER =>{
							run => 'INFO',
						},
					},
				},
				Helping =>[
					'Somelevel',
					{
						MyKey =>{
							MiddleKey =>{
							},
						},
					},
				],
			};
}										'... change the $answer_ref for testing';
ok 			$edward_scissorhands->set_prune_memory( 1 ),	
										'Turn on prune rememberance';
is_deeply	$edward_scissorhands->prune_data(
                tree_ref    => $treeref, 
                slice_ref   => $sliceref,
            ), 
            $answerref,					'Test pruning (by splice) an array element';
lives_ok{   
			$sliceref =  {
				Helping =>[
					undef,
					{
						MyKey =>{
							MiddleKey =>{
								LowerKey1 => {},
							},
						},
					},
				],
			};
}										'... change the $slice_ref for testing';
ok 			$edward_scissorhands->has_pruned_positions,
										'See if any slices were remembered';
is 			$edward_scissorhands->number_of_cuts, 1,
										'Count the number of cuts';
is_deeply	$edward_scissorhands->get_pruned_positions, 
			[ $sliceref ],				'Check that the expected prune branch is available';
done_testing;
explain 								"...Test Done";