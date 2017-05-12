#! C:/Perl/bin/perl
#######  Test File for the joining of all Data::Walk::XXX modules  #######

use Test::Most tests => 68;
use Test::Moose;
use MooseX::ShortCut::BuildInstance 0.008 qw( build_instance );
use lib	
		'../../../lib',
		'../../lib';
use Data::Walk::Extracted::Dispatch 0.026;
use Data::Walk::Extracted 0.026;
use Data::Walk::Print 0.026;
use Data::Walk::Prune 0.026;
use Data::Walk::Clone 0.026;
use Data::Walk::Graft 0.026;

my  ( 
			$wait,
			$anonymous,
);

my  		@attributes = qw(
				sorted_nodes
				skipped_nodes
				skip_level
				skip_node_tests
				change_array_size
				fixed_primary
				match_highlighting
				prune_memory
				should_clone
				graft_memory
			);

my  		@methods = qw(
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
				prune_data
				set_prune_memory
				get_prune_memory
				has_prune_memory
				clear_prune_memory
				get_pruned_positions
				has_pruned_positions
				number_of_cuts
				deep_clone
				set_should_clone
				get_should_clone
				has_should_clone
				clear_should_clone
				graft_data
				has_graft_memory
				set_graft_memory
				get_graft_memory
				clear_graft_memory
				number_of_scions
				has_grafted_positions
				get_grafted_positions
			);
    
# basic questions
lives_ok{
			$anonymous =	build_instance(
								package => 'All::Included',
								superclasses => ['Data::Walk::Extracted',],
								roles => [
									'Data::Walk::Clone', 
									'Data::Walk::Print',
									'Data::Walk::Prune',
									'Data::Walk::Graft',
								],
							);
}										"Prep a new instance with all roles!";
map{
has_attribute_ok
			$anonymous, $_, 			"Check that $anonymous has the -$_- attribute"#the master instance 
} 			@attributes;
map{
can_ok		$anonymous, $_
}			@methods;
explain 								"...Test Done";
done_testing;