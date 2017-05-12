#!perl
#######  Test File for Data::Walk::Print  #######

use Test::Most tests => 252;
use Test::Moose;
use Capture::Tiny 0.12 qw( 
	capture_stdout 
);
use MooseX::ShortCut::BuildInstance 0.008;
use lib	
		'../../../lib',
		'../../lib',
		'../../../../Log-Shiras/lib',
		;
#~ use Log::Shiras::Unhide qw( :InternalExtracteD :InternalExtracteDDispatcH :InternalExtracteDPrinT );
#~ use Data::Walk::Extracted::Dispatch;# To unhide debug
use Data::Walk::Extracted;
use Data::Walk::Print;

my  ( 
			$first_ref, $second_ref, $newclass, $gutenberg, 
			$test_inst, $capture, $wait, $x, @answer,
);
my 			$test_case = 1;
my 			@class_attributes = qw(
				sorted_nodes
				skipped_nodes
				skip_level
				skip_node_tests
				change_array_size
				fixed_primary
			);
my  		@class_methods = qw(
				new
				has_sorted_nodes
				has_skipped_nodes
				has_skip_level
				has_skip_node_tests
				has_change_array_size
				has_fixed_primary
				get_sorted_nodes
				get_skipped_nodes
				get_skip_level
				get_skip_node_tests
				get_change_array_size
				get_fixed_primary
				set_sorted_nodes
				set_skipped_nodes
				set_skip_level
				set_skip_node_tests
				set_change_array_size
				set_fixed_primary
				clear_sorted_nodes
				clear_skipped_nodes
				clear_skip_level
				clear_skip_node_tests
				clear_change_array_size
				clear_fixed_primary
				add_sorted_nodes
				check_sorted_node
				remove_sorted_node
				add_skipped_nodes
				check_skipped_node
				remove_skipped_node
				add_skip_node_test
			);
my  		@instance_attributes = qw(
				sorted_nodes
				skipped_nodes
				skip_level
				skip_node_tests
				change_array_size
				fixed_primary
				match_highlighting
			);
my  		@instance_methods = qw(
				has_sorted_nodes
				has_skipped_nodes
				has_skip_level
				has_skip_node_tests
				has_change_array_size
				has_fixed_primary
				get_sorted_nodes
				get_skipped_nodes
				get_skip_level
				get_skip_node_tests
				get_change_array_size
				get_fixed_primary
				set_sorted_nodes
				set_skipped_nodes
				set_skip_level
				set_skip_node_tests
				set_change_array_size
				set_fixed_primary
				clear_sorted_nodes
				clear_skipped_nodes
				clear_skip_level
				clear_skip_node_tests
				clear_change_array_size
				clear_fixed_primary
				add_sorted_nodes
				check_sorted_node
				remove_sorted_node
				add_skipped_nodes
				check_skipped_node
				remove_skipped_node
				add_skip_node_test
				print_data
				set_match_highlighting
				get_match_highlighting
				has_match_highlighting
				clear_match_highlighting
			);
my			$answer_ref = [
				'',#qr/The composed class passed to 'new' does not have either a 'before_method' or an 'after_method' the Role 'Data::Walk::Print' will be added/,
				[
					"undef,",
				],
				[
					"'Test String',",
				],
				[
					"[", "\t'Test String',", "],",
				],
				[
					"{", "\tTestString => 1,", "},",
				],
				[
					"{", "\tTestString => 'value',", "},",
				],
				[
					"{", "\tHelping => [", "\t\t{", "\t\t\tMyKey => {", "\t\t\t\tMiddleKey => {",
					"\t\t\t\t\tLowerKey1 => 'lvalue1',", "\t\t\t\t\tLowerKey2 => {", 
					"\t\t\t\t\t\tBottomKey1 => 12345,", "\t\t\t\t\t\tBottomKey2 => [", 
					"\t\t\t\t\t\t\t'bavalue2',", "\t\t\t\t\t\t\t'bavalue1',", 
					"\t\t\t\t\t\t\t'bavalue3',", "\t\t\t\t\t\t],", 
					"\t\t\t\t\t},", "\t\t\t\t},", "\t\t\t},","\t\t\tSomelevel => {", 
					"\t\t\t\tSublevel => \'levelvalue\',", "\t\t\t},", "\t\t},", "\t],",
					"\tParsing => {", "\t\tHashRef => {", "\t\t\tLOGGER => {",
					"\t\t\t\trun => 'INFO',", "\t\t\t},", "\t\t},", "\t},",
					"\tSomeotherkey => 'value',", "},"
				],
				[
					"{", '\tHelping => ARRAY\(0x.{5,25}\),', 
					"\tParsing => \{", "\t\tHashRef => \{", "\t\t\tLOGGER => \{",
					"\t\t\t\trun => 'INFO',", "\t\t\t},", "\t\t},", "\t},",
					"\tSomeotherkey => 'value',", "},"
				],
				[
					"{#<--- Ref Type Match", "\tHelping => [#<--- Hash Key Match - Ref Type Match",
					"\t\t{#<--- Position Exists - Ref Type Mismatch", 
					"\t\t\tMyKey => {#<--- Hash Key Mismatch - Ref Type Mismatch", 
					"\t\t\t\tMiddleKey => {#<--- Hash Key Mismatch - Ref Type Mismatch", 
					"\t\t\t\t\tLowerKey1 => 'lvalue1',#<--- Hash Key Mismatch - Scalar Value Does NOT Match", 
					"\t\t\t\t\tLowerKey2 => {#<--- Hash Key Mismatch - Ref Type Mismatch", 
					"\t\t\t\t\t\tBottomKey1 => 12345,#<--- Hash Key Mismatch - Scalar Value Does NOT Match", 
					"\t\t\t\t\t\tBottomKey2 => [#<--- Hash Key Mismatch - Ref Type Mismatch", 
					"\t\t\t\t\t\t\t'bavalue2',#<--- No Matching Position - Scalar Value Does NOT Match", 
					"\t\t\t\t\t\t\t'bavalue1',#<--- No Matching Position - Scalar Value Does NOT Match", 
					"\t\t\t\t\t\t\t'bavalue3',#<--- No Matching Position - Scalar Value Does NOT Match", 
					"\t\t\t\t\t\t],", "\t\t\t\t\t},", "\t\t\t\t},", "\t\t\t},", 
					"\t\t\tSomelevel => {#<--- Hash Key Mismatch - Ref Type Mismatch", 
					"\t\t\t\tSublevel => 'levelvalue',#<--- Hash Key Mismatch - Scalar Value Does NOT Match", 
					"\t\t\t},", "\t\t},", "\t],", "\tParsing => {#<--- Hash Key Match - Ref Type Mismatch", 
					"\t\tHashRef => {#<--- Hash Key Mismatch - Ref Type Mismatch", 
					"\t\t\tLOGGER => {#<--- Hash Key Mismatch - Ref Type Mismatch", 
					"\t\t\t\trun => 'INFO',#<--- Hash Key Mismatch - Scalar Value Does NOT Match", 
					"\t\t\t},", "\t\t},", "\t},", 
					"\tSomeotherkey => 'value',#<--- Hash Key Match - Scalar Value Matches", 
					"},", 
				],
				[
					"{", "\tHelping => [", "\t\t{", "\t\t\tMyKey => {", "\t\t\t\tMiddleKey => {", 
					"\t\t\t\t\tLowerKey1 => 'lvalue1',", "\t\t\t\t\tLowerKey2 => {", 
					"\t\t\t\t\t\tBottomKey1 => 12345,", "\t\t\t\t\t\tBottomKey2 => [", 
					"\t\t\t\t\t\t\t'bavalue2',", "\t\t\t\t\t\t\t'bavalue1',", "\t\t\t\t\t\t\t'bavalue3',", 
					"\t\t\t\t\t\t],", "\t\t\t\t\t},", "\t\t\t\t},", "\t\t\t},", "\t\t\tSomelevel => {", 
					"\t\t\t\tSublevel => 'levelvalue',", "\t\t\t},", "\t\t},", "\t],", "\tParsing => {", 
					"\t\tHashRef => {", "\t\t\tLOGGER => {", "\t\t\t\trun => 'INFO',", "\t\t\t},", "\t\t},", 
					"\t},", "\tSomeotherkey => 'value',", "},",
				],
				[
					"{#<--- Ref Type Match", "\tHelping => [#<--- Hash Key Match - Ref Type Match",
					"\t\t'Somelevel',#<--- Position Exists - Scalar Value Matches",
					"\t\t{#<--- Position Exists - Ref Type Match",
					"\t\t\tMyKey => {#<--- Hash Key Match - Ref Type Match",
					"\t\t\t\tMiddleKey => {#<--- Hash Key Match - Ref Type Match",
					"\t\t\t\t\tLowerKey1 => 'lvalue1',#<--- Hash Key Match - Scalar Value Matches",
					"\t\t\t\t\tLowerKey2 => {#<--- Hash Key Match - Ref Type Match",
					"\t\t\t\t\t\tBottomKey1 => 12345,#<--- Hash Key Match - Scalar Value Does NOT Match",
					"\t\t\t\t\t\tBottomKey2 => [#<--- Hash Key Match - Ref Type Match",
					"\t\t\t\t\t\t\t'bavalue1',#<--- Position Exists - Scalar Value Matches",
					"\t\t\t\t\t\t\t'bavalue2',#<--- Position Exists - Scalar Value Does NOT Match",
					"\t\t\t\t\t\t\t'bavalue3',#<--- No Matching Position - Scalar Value Does NOT Match",
					"\t\t\t\t\t\t],", "\t\t\t\t\t},", "\t\t\t\t},", "\t\t\t},", "\t\t},", "\t],",
					"\tParsing => {#<--- Hash Key Mismatch - Ref Type Mismatch",
					"\t\tHashRef => {#<--- Hash Key Mismatch - Ref Type Mismatch",
					"\t\t\tLOGGER => {#<--- Hash Key Mismatch - Ref Type Mismatch",
					"\t\t\t\trun => 'INFO',#<--- Hash Key Mismatch - Scalar Value Does NOT Match",
					"\t\t\t},", "\t\t},", "\t},",
					"\tSomeotherkey => 'value',#<--- Hash Key Match - Scalar Value Matches",
					"},",
				],
				[
					"{", "\tMyArray => [", "\t\tundef,", "\t\tundef,", "\t\t'ValueFive',", "\t],", "},",
				],
			];
### <where> - easy questions
map{ 
has_attribute_ok
			'Data::Walk::Extracted', $_,
										"Check that Data::Walk::Extracted has the -$_- attribute"
} 			@class_attributes;
map{
can_ok		'Data::Walk::Extracted', $_,
} 			@class_methods;

### <where> - harder questions
lives_ok{
			$gutenberg = 	build_instance(
								package => 'Print::Shop',
								superclasses => ['Data::Walk::Extracted'],
								roles => ['Data::Walk::Print'],
								sorted_nodes =>{
									HASH => 1, #To ensure test passes
								},
								match_highlighting => 0,
							);
}										"Prep a new Print instance";
map{
has_attribute_ok 
			$gutenberg, $_,				"Check that the new class has the -$_- attribute"
} 			@instance_attributes;
map can_ok( 
			$gutenberg, $_,
), 			@instance_methods;

### <where> 'hardest questions
ok			$capture = capture_stdout{ 
				$gutenberg->print_data( print_ref => undef, ); 
			},							'Test sending -undef- as a simple case for test case: ' . $test_case;
			$x = 0;
			@answer = split "\n", $capture;
### <where> - checking the answers for test: $test_case
map{
is			$answer[$x], $_, 			'Test matching line -' . (1 + $x++) . "- of the output for test: $test_case";
}			@{$answer_ref->[$test_case]};
			$test_case++;
ok			$capture = capture_stdout{ 
				$gutenberg->print_data( print_ref => 'Test String', ); 
			},							'Test sending a string as a simple case for test case: ' . $test_case;
			$x = 0;
			@answer = split "\n", $capture;
### <where> - checking the answers for test: $test_case
map{
is			$answer[$x], $_, 			'Test matching line -' . (1 + $x++) . "- of the output for test: $test_case";
}			@{$answer_ref->[$test_case]};
			$test_case++;
ok			$capture = capture_stdout{ 
				$gutenberg->print_data( print_ref =>[ 'Test String', ] ); 
			},							'Test sending a simple array with one level for test case: ' . $test_case;
			$x = 0;
			@answer = split "\n", $capture;
### <where> - checking the answers for test: $test_case
map{
is			$answer[$x], $_, 			'Test matching line -' . (1 + $x++) . "- of the output for test: $test_case";
}			@{$answer_ref->[$test_case]};
			$test_case++;
ok			$capture = capture_stdout{ 
				$gutenberg->print_data( print_ref =>{ TestString => 1, } ); 
			},							'Test sending a simple hash with one level, one key, and numeric value for test case: ' . $test_case;
			$x = 0;
			@answer = split "\n", $capture;
### <where> - checking the answers for test: $test_case
map{
is			$answer[$x], $_, 			'Test matching line -' . (1 + $x++) . "- of the output for test: $test_case";
}			@{$answer_ref->[$test_case]};
			$test_case++;
ok			$capture = capture_stdout{ 
				$gutenberg->print_data( print_ref =>{ TestString => 'value', } ); 
			},							'Test sending a simple hash with one level, one key, and string value  for test case: ' . $test_case;
			$x = 0;
			@answer = split "\n", $capture;
### <where> - checking the answers for test: $test_case
map{
is			$answer[$x], $_, 			'Test matching line -' . (1 + $x++) . "- of the output for test: $test_case";
}			@{$answer_ref->[$test_case]};
			$test_case++;
lives_ok{   
			$first_ref = {
				Someotherkey => 'value',
				Parsing =>{
					HashRef =>{
						LOGGER =>{
							run => 'INFO',
						},
					},
				},
				Helping =>[
					{
						Somelevel =>{
							Sublevel => 'levelvalue',
						},
						MyKey =>{
							MiddleKey =>{
								LowerKey1 => 'lvalue1',
								LowerKey2 => {
									BottomKey1 => 12345,
									BottomKey2 =>[
										'bavalue2',
										'bavalue1',
										'bavalue3',
									],
								},
							},
						},
					},
				],
			};
}                                        'Build the $first_ref for testing';
#### $first_ref
ok			$capture = capture_stdout{ 
				$gutenberg->print_data( print_ref => $first_ref, ) 
			},							'Test sending the data structure for test case: ' . $test_case;
			$x = 0;
			@answer = split "\n", $capture;
### <where> - checking the answers for test: $test_case
map{
is			$answer[$x], $_, 			'Test matching line -' . (1 + $x++) . "- of the output for test: $test_case";
}			@{$answer_ref->[$test_case]};
			$test_case++;
ok			$gutenberg->add_skipped_nodes( ARRAY => 1, ),
										"... set 'skip = yes' for future parsed ARRAY refs (test case: $test_case)";
lives_ok{
			$capture = capture_stdout{ 
				$gutenberg->print_data( print_ref => $first_ref, ); 
			}
}										'Test running the same array with the ARRAY nodes set for skipping (capturing the output)';
			$x = 0;
			@answer = split "\n", $capture;
### <where> - checking the answers for test: $test_case
map{
#~ explain		$answer[$x];
			s/(?<!\.)\{/\\\{/g;
#~ explain		$_;
like		$answer[$x], qr/$_/,			'Test matching line -' . (1 + $x++) . "- of the output for test: $test_case";
}			@{$answer_ref->[$test_case]};
			$test_case++;
lives_ok{ 
			$gutenberg->remove_skipped_node( 'ARRAY' ); 
}										"... set 'skip = NO' for future parsed ARRAY refs (test case: $test_case)";
lives_ok{   
			$second_ref = {
				Someotherkey => 'value',
				'Parsing' =>[
					HashRef =>{
						LOGGER =>{
							run => 'INFO',
						},
					},
				],
				Helping =>[
					[
						'Somelevel',
					],
					{
						MyKey =>{
							MiddleKey =>{
								LowerKey1 =>{
									Testkey1 => 'value1',
									Testkey2 => 'value2',
								},
								LowerKey2 => {
									BottomKey1 => '12354',
									BottomKey2 =>[
										'bavalue1',
										'bavalue3',
									],
								},
							},
						},
					},
				],
			};
}   									"Build a second ref for testing (test case $test_case)";
dies_ok{ 
			$gutenberg->print_data( data_ref => $first_ref, );
}										"Test sending the data with a bad key";
like		$@, qr/-print_ref- is a required key but was not found in the passed ref/,
										"Check that the code caught the wrong failure";
ok			$gutenberg->set_match_highlighting( 1 ),
										"Turn on match_highlighting for future testing";
lives_ok{
			$capture = capture_stdout{ $gutenberg->print_data( 
				print_ref => $first_ref,
				match_ref => $second_ref,
			); }
}                                       "Test the non matching state with a match ref sent";
			$x = 0;
			@answer = split "\n", $capture;
### <where> - checking the answers for test: $test_case
map{
is			$answer[$x], $_, 			'Test matching line -' . (1 + $x++) . "- of the output for test: $test_case";
}			@{$answer_ref->[$test_case]};
			$test_case++;
lives_ok{ 
			$gutenberg->set_match_highlighting( 0 ); 
}										"... set 'match_highlighting = NO' for future parsed refs (test case: $test_case)";
dies_ok{
			$gutenberg->print_data(
				bad_ref	=>  $first_ref,
				match_ref   =>  $second_ref,
			) 
}										"Send a bad reference with a new request to print";
like		$@, qr/-print_ref- is a required key but was not found in the passed ref/,
										"Test that the error message was found";
lives_ok{
			$capture = capture_stdout{ $gutenberg->print_data(
				print_ref	=>  $first_ref,
				match_ref   =>  $second_ref,
			) }
}                                      "Send the same request with the reference fixed";#~ $x = 0;
			$x = 0;
			@answer = split "\n", $capture;
### <where> - checking the answers for test: $test_case
map{
is			$answer[$x], $_, 			'Test matching line -' . (1 + $x++) . "- of the output for test: $test_case";
}			@{$answer_ref->[$test_case]};
			$test_case++;
lives_ok{
			$first_ref = {
				Someotherkey => 'value',
				Parsing => {
					HashRef => {
						LOGGER => {
							run => 'INFO',
						},
					},
				},
				Helping => [
					'Somelevel',
					{
						MyKey => {
							MiddleKey => {
								LowerKey1 => 'lvalue1',
								LowerKey2 => {
									BottomKey1 => 12345,
									BottomKey2 => [
										'bavalue1',
										'bavalue2',
										'bavalue3',
									],
								},
							},
						},
					},
				],
			};
			$second_ref = {
				Someotherkey => 'value',
				Helping => [
					'Somelevel',
					{
						MyKey => {
							MiddleKey => {
								LowerKey1 => 'lvalue1',
								LowerKey2 => {
									BottomKey2 => [
										'bavalue1',
										'bavalue3',
									],
									BottomKey1 => 12354,
								},
							},
						},
					},
				],
			};
}										"A bug fix text case for testing secondary value equivalence (test case $test_case)";
lives_ok{ 
			$gutenberg->set_match_highlighting( 1 ); 
}										"... set 'match_highlighting = YES' for future parsed refs (test case: $test_case)";
lives_ok{
			$capture = capture_stdout{ $gutenberg->print_data(
				print_ref	=>  $first_ref,
				match_ref   =>  $second_ref,
			) }
}										"Send the request to print_data";
			$x = 0;
			@answer = split "\n", $capture;
### <where> - checking the answers for test: $test_case
map{
is			$answer[$x], $_, 			'Test matching line -' . (1 + $x++) . "- of the output for test: $test_case";
}			@{$answer_ref->[$test_case]};
			$test_case++;
lives_ok{
			$capture = capture_stdout{ 
				$gutenberg->print_data(
					match_highlighting => 0,
					print_ref => {
						MyArray => [
							undef,
							undef,
							'ValueFive',
						],
					},
				) 
			}
}										"Text a bug fix case for arrays with undef positions using print_data";
			$x = 0;
			@answer = split "\n", $capture;
### <where> - checking the answers for test: $test_case
map{
is			$answer[$x], $_, 			'Test matching line -' . (1 + $x++) . "- of the output for test: $test_case";
}			@{$answer_ref->[$test_case]};
			$test_case++;
explain 								"...Test Done";
done_testing();