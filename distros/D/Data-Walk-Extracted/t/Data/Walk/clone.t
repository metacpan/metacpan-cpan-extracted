#!perl
#######  Test File for Data::Walk::Clone  #######
use Test::Most tests => 47;
use Test::Moose;
use MooseX::ShortCut::BuildInstance 0.008 qw( build_instance );
use lib	
		'../../../lib',
		'../../lib',
		'../../../../Log-Shiras/lib',
		;
#~ use Log::Shiras::Unhide qw( :InternalExtracteD :InternalExtracteDDispatcH :InternalExtracteDClonE );
#~ use Data::Walk::Extracted::Dispatch;# To unhide debug
use Data::Walk::Extracted;
use Data::Walk::Clone;

my  ( 
			$victor_frankenstein, 
			$donor_ref, 
			$test_ref, 
			$dolly_ref, 
			$masha_ref, 
			$little_nicky_ref,
			$injaz_ref,
			$test_instance,
);

my  		@attributes = qw(
				should_clone
			);

my  		@methods = qw(
				new
				deep_clone
				set_should_clone
				get_should_clone
				has_should_clone
				clear_should_clone
			);
    
# basic questions
lives_ok{
			$victor_frankenstein = build_instance( 
				package => 'Clone::Factory',
				superclasses => ['Data::Walk::Extracted',],
				roles =>['Data::Walk::Clone',],
			);
}										"Prep a new cloner instance";
does_ok		$victor_frankenstein, 'Data::Walk::Clone',
										"Check that 'with_traits' added the 'Data::Walk::Clone' Role to the instance";
map has_attribute_ok( 
			$victor_frankenstein, 
			$_,							"Check that Data::Walk::Clone has the -$_- attribute"
), 			@attributes;
map can_ok($victor_frankenstein, $_ ), @methods;
#Run the hard questions
lives_ok{   
			$donor_ref = {
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
}										'Build the $donor_ref for testing';
lives_ok{   
			$test_ref ={
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
}										'Build the $test_ref for testing';
lives_ok{
			$dolly_ref = $victor_frankenstein->deep_clone(
				donor_ref => $donor_ref,
			) 
}										'Test cloning the donor ref';
is_deeply	$dolly_ref, $test_ref,		'See if the $test_ref matches the clone deeply';
is_deeply	$dolly_ref, $donor_ref,		'See if the $donor_ref matches the clone deeply';
isnt 		$dolly_ref, $test_ref,		'... but it should not match a test ref at the top level';
isnt 		$dolly_ref, $donor_ref,		'... and it should not match the donor ref at the top level';
ok 			$victor_frankenstein->add_skip_node_test( 
				[ 'HASH', 'LowerKey2', 'ALL',   'ALL' ] 
			),							'Add a skip test to see if partial deep cloning will work';
lives_ok{
			$masha_ref = $victor_frankenstein->deep_clone(
				donor_ref => $donor_ref,
			)
}										'Test cloning the donor ref with a skip called out';
isnt		$masha_ref, $donor_ref,		'It should not match the doner ref at the top level';
is_deeply	$masha_ref, $donor_ref,		'Confirm that the new clone matches deeply';
#~ $wait = <>;
isnt 		$masha_ref, $donor_ref,		'... and the new clone does not match the donor ref at the top level';
is			$masha_ref->{Helping}->[1]->{MyKey}->{MiddleKey}->{LowerKey2}, 
			$donor_ref->{Helping}->[1]->{MyKey}->{MiddleKey}->{LowerKey2},
										'... but it should match at the skip level';
isnt		$masha_ref->{Helping}->[1]->{MyKey}->{MiddleKey}, 
			$donor_ref->{Helping}->[1]->{MyKey}->{MiddleKey},
										'... and it should not match one level up from the skip level';
lives_ok{ 	$victor_frankenstein->clear_skip_node_tests }
										'clear the skip test to ensure it is possible';
lives_ok{
			$little_nicky_ref = $victor_frankenstein->deep_clone(
				$donor_ref,
			)
}										'Test cloning the donor ref without a skip called out (again) and sending the donor without a key';
isnt		$little_nicky_ref, $donor_ref,	
										'It should not match the doner ref at the top level';
is_deeply 	$little_nicky_ref, $donor_ref,	
										'Confirm that the new clone matches deeply';
isnt		$little_nicky_ref, $donor_ref,	
										'... and the new clone does not match the donor ref at the string pointer';
isnt		$little_nicky_ref->{Helping}->[1]->{MyKey}->{MiddleKey}->{LowerKey2}, 
			$donor_ref->{Helping}->[1]->{MyKey}->{MiddleKey}->{LowerKey2},
										'... and it should not match at the (old) skip level';
ok 			$victor_frankenstein->set_skip_level( 3 ),
										'Add a clone level boundary to see if bounded deep cloning will work';
lives_ok{
			$injaz_ref = $victor_frankenstein->deep_clone(
				donor_ref 	=> $donor_ref,
				skip_level	=> 4,
			)
}										'Test cloning the donor ref with a boundary called out (as a one time method change)';
is_deeply	$injaz_ref, $donor_ref,		'Confirm that the new clone matches deeply';
isnt 		$injaz_ref, $donor_ref,		'... and the new clone does not match the donor ref at the top level';
is			$injaz_ref->{Helping}->[1]->{MyKey}, 
			$donor_ref->{Helping}->[1]->{MyKey},
										'... but it should match at the boundary level';
isnt		$injaz_ref->{Helping}->[1], $donor_ref->{Helping}->[1],
										'... and it should not match one level up from the boundary level';
lives_ok{
			$injaz_ref = $victor_frankenstein->deep_clone(
				donor_ref 	=> $donor_ref,
			)
}										'Re-Test cloning the donor ref with a boundary called out (prior to the one time change)';
is_deeply	$injaz_ref, $donor_ref,		'Confirm that the new clone matches deeply';
isnt 		$injaz_ref, $donor_ref,		'... and the new clone does not match the donor ref at the top level';
is			$injaz_ref->{Helping}->[1], 
			$donor_ref->{Helping}->[1],
										'... but it should match at the boundary level';
isnt		$injaz_ref->{Helping},
			$donor_ref->{Helping},		'... and it should not match one level up from the boundary level';
lives_ok{ 	$victor_frankenstein->clear_skip_level }
										'clear the boundary to ensure it is possible';
lives_ok{
			$donor_ref = {
				test =>{
					empty_hash => {},
					empty_array => [],
				},
			};
}										'Build a data ref to test the empty reference bug';
lives_ok{
			$injaz_ref = $victor_frankenstein->deep_clone(
				$donor_ref,
			)
}										'Test cloning the empty reference bug test donor ref';
is_deeply	$injaz_ref, $donor_ref,		'Confirm that the new clone matches deeply';
lives_ok{
			$test_instance = bless {}, 'TestClass';
			$donor_ref = {
				test =>[
					$test_instance,
				],
};
}										'Build a data ref to test the array bounce issue';
lives_ok{
			$injaz_ref = $victor_frankenstein->deep_clone(
				donor_ref =>$donor_ref,
				skip_node_tests => [ [ 'ARRAY', 'ANY', 'ANY', 'ANY', ], ],
			)
}										'Test cloning the array bounce issue test donor ref';
is			$injaz_ref->{test}->[0], 
			$donor_ref->{test}->[0],	'Confirm that the clone bounced at the correct point';
explain 								"... Test Done\n";
done_testing;