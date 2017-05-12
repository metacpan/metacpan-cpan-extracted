package AI::Pathfinding::SMAstar;

use 5.006000;
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use AI::Pathfinding::SMAstar ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);

our $VERSION = '0.07';

use AI::Pathfinding::SMAstar::PriorityQueue;
use AI::Pathfinding::SMAstar::Path;
use Scalar::Util;
use Carp;

my $DEBUG = 0;


##################################################
# SMAstar constructor 
##################################################
sub new {
    my $invocant = shift;
    my $class   = ref($invocant) || $invocant;
    my $self = { 
     
	_priority_queue => AI::Pathfinding::SMAstar::PriorityQueue->new(),
	_state_eval_func => undef,	
	_state_goal_p_func => undef,
	_state_num_successors_func => undef,
	_state_successors_iterator => undef,
	_show_prog_func => undef,
	_state_get_data_func => undef,


	@_, # attribute override
    };
    return bless $self, $class;
}


sub state_eval_func {
    my $self = shift;
    if (@_) { $self->{_state_eval_func} = shift }
    return $self->{_state_eval_func};
}

sub state_goal_p_func {
    my $self = shift;
    if (@_) { $self->{_state_goal_p_func} = shift }
    return $self->{_state_goal_p_func};    
}

sub state_num_successors_func {
    my $self = shift;
    if (@_) { $self->{_state_num_successors_func} = shift }
    return $self->{_state_num_successors_func};    
}

sub state_successors_iterator {
    my $self = shift;
    if (@_) { $self->{_state_successors_iterator} = shift }
    return $self->{_state_successors_iterator};    
}

sub state_get_data_func {
    my $self = shift;
    if (@_) { $self->{_state_get_data_func} = shift }
    return $self->{_state_get_data_func};    
}

sub show_prog_func {
    my $self = shift;
    if (@_) { $self->{_show_prog_func} = shift }
    return $self->{_show_prog_func};    
}



###################################################################
#
# Add a state from which to begin the search.   There can 
# be multiple start-states.
#
###################################################################
sub add_start_state
{
    my ($self, $state) = @_;


    my $state_eval_func = $self->{_state_eval_func};
    my $state_goal_p_func = $self->{_state_goal_p_func};
    my $state_num_successors_func = $self->{_state_num_successors_func},
    my $state_successors_iterator = $self->{_state_successors_iterator},
    my $state_get_data_func = $self->{_state_get_data_func};
    
    # make sure required functions have been defined
    if(!defined($state_eval_func)){
	croak "SMAstar:  evaluation function is not defined\n";
    }
    if(!defined($state_goal_p_func)){
	croak "SMAstar:  goal function is not defined\n";
    }
    if(!defined($state_num_successors_func)){
	croak "SMAstar:  num successors function is not defined\n";
    }
   if(!defined($state_successors_iterator)){
	croak "SMAstar:  successor iterator is not defined\n";
    }

    # create a path object from this state
    my $state_obj = AI::Pathfinding::SMAstar::Path->new(
	_state           => $state,
	_eval_func      => $state_eval_func,
	_goal_p_func    => $state_goal_p_func,
	_num_successors_func => $state_num_successors_func,
	_successors_iterator => $state_successors_iterator,
	_get_data_func  => $state_get_data_func,
	);
    
    
    my $fcost = AI::Pathfinding::SMAstar::Path::fcost($state_obj);
    # check if the fcost of this node looks OK (is numeric)
    unless(Scalar::Util::looks_like_number($fcost)){
	croak "Error:  f-cost of state is not numeric.  Cannot add state to queue.\n";	
    }
    $state_obj->f_cost($fcost);

    # check if the num_successors function returns a number
    my $num_successors = $state_obj->get_num_successors();
    unless(Scalar::Util::looks_like_number($num_successors)){
	croak "Error:  Number of state successors is not numeric.  Cannot add state to queue.\n";	
    }

    # test out the iterator function to make sure it returns
    #  an object of the correct type
    my $classname = ref($state);
    my $test_successor_iterator = $state_obj->{_successors_iterator}->($state);
    my $test_successor = $test_successor_iterator->($state);
    my $succ_classname = ref($test_successor);

    unless($succ_classname eq $classname){
	croak "Error:  Successor iterator method of object $classname does " .
	    "not return an object of type $classname.\n";	
    }

    
    # add this node to the queue
    $self->{_priority_queue}->insert($state_obj);
 
}

###################################################################
#
# start the SMAstar search process
#
###################################################################
sub start_search
{
    my ($self, 
	$log_function,
	$str_function,
	$max_states_in_queue,
	$max_cost,
	) = @_;

    if(!defined($str_function)){
	croak "SMAstar start_search:  str_function is not defined.\n";
    }

    sma_star_tree_search(\($self->{_priority_queue}), 
                         \&AI::Pathfinding::SMAstar::Path::is_goal, 
                         \&AI::Pathfinding::SMAstar::Path::get_descendants_iterator_smastar,
                         \&AI::Pathfinding::SMAstar::Path::fcost,
			 \&AI::Pathfinding::SMAstar::Path::backup_fvals,
			 $log_function,
			 $str_function,
			 \&AI::Pathfinding::SMAstar::Path::progress,
                         $self->{_show_prog_func},
			 $max_states_in_queue,
                         $max_cost,
	);
}



#################################################################
#
#  SMAstar search
#  Memory-bounded A* search
#
#
#################################################################
sub sma_star_tree_search
{
   
    my ($priority_queue,
	$goal_p,
	$successors_func,
	$eval_func,
	$backup_func,
	$log_function, # debug string func;  represent state object as a string.
	$str_function,
	$prog_function,
	$show_prog_func,
	$max_states_in_queue,
	$max_cost,
	) = @_;
    
    my $iteration = 0;
    my $num_states_in_queue = $$priority_queue->size();
    my $max_extra_states_in_queue = $max_states_in_queue;
    $max_states_in_queue = $num_states_in_queue + $max_extra_states_in_queue;    
    my $max_depth = ($max_states_in_queue - $num_states_in_queue);

    my $best; # the best candidate for expansion


    
    if($$priority_queue->is_empty() || !$$priority_queue){
	return;
    }
    else{
	my $num_successors = 0;
	
	# loop over the elements in the priority queue
	while(!$$priority_queue->is_empty()){
	    
	    # determine the current size of the queue
	    my $num_states_in_queue = $$priority_queue->{_size};
	    # get the best candidate for expansion from the queue
	    $best = $$priority_queue->deepest_lowest_cost_leaf_dont_remove();
    
	    #------------------------------------------------------
	    if(!$DEBUG){
		my $str = $log_function->($best);		 
		$show_prog_func->($iteration, $num_states_in_queue, $str);		    
	    }
	    else{	
		my $str = $log_function->($best);
		print "best is: " . $str_function->($best) . ", cost: " . $best->{_f_cost}  . "\n";
	    }
	    #------------------------------------------------------


	    if($best->$goal_p()) {			
		# goal achieved! iteration: $iteration, number of 
		# states in queue: $num_states_in_queue.
		return $best; 
	    }
	    elsif($best->{_f_cost} >= $max_cost){
		croak "\n\nSearch unsuccessful.  max_cost reached (cost:  $max_cost).\n";
	    }
	    else{	    
		my $successors_iterator = $best->$successors_func();		
		my $succ = $successors_iterator->();
			
		if($succ){
		    # if succ is at max depth and is not a goal node, set succ->fcost to infinity 
		    if($succ->depth() >= $max_depth && !$succ->$goal_p() ){                       
			$succ->{_f_cost} = $max_cost;                                                    
		    }                                                                             
		    else{                 
			# calling eval for comparison, and maintaining pathmax property		
			$succ->{_f_cost} = max($eval_func->($succ), $eval_func->($best));	
			my $descendant_index = $succ->{_descendant_index};
			$best->{_descendant_fcosts}->[$descendant_index] = $succ->{_f_cost};
		    }           
		}

		# determine if $best is completed, and if so backup values
		if($best->is_completed()){


		    # remove from queue first, back up fvals, then insert back on queue. 
		    # this way, it gets placed in its rightful place on the queue.		    
		    my $fval_before_backup = $best->{_f_cost};
		   
		    # STEPS:
		    # 1) remove best and all antecedents from queue, but only if they are 
		    #    going to be altered by backing-up fvals.    This is because 
		    #    removing and re-inserting in queue changes temporal ordering,
		    #    and we don't want to do that unless the node will be
		    #    placed in a new cost-bucket/tree.
		    # 2) then backup fvals
		    # 3) then re-insert best and all antecedents back on queue.


		    # Check if need for backup fvals		    
		    $best->check_need_fval_change();
		   
		    my $cmp_func = sub {
			my ($str) = @_;			
			return sub{
			    my ($obj) = @_;
			    my $obj_path_str = $str_function->($obj);
			    if($obj_path_str eq $str){
				return 1;
			    }
			    else{ 
				return 0; 
			    }	    
			}
		    };

		    my $antecedent = $best->{_antecedent};
		    my %was_on_queue;
		    my $i = 0;

		    # Now remove the offending nodes from queue, if any
		    if($best->need_fval_change()){
			
			# remove best from the queue
			$best = $$priority_queue->deepest_lowest_cost_leaf();  
		    
			while($antecedent){
			    my $path_str = $str_function->($antecedent);	
			    
			    if($antecedent->is_on_queue() && $antecedent->need_fval_change()){
				$was_on_queue{$i} = 1;
				$$priority_queue->remove($antecedent, $cmp_func->($path_str));  	
			    }
			    $antecedent = $antecedent->{_antecedent};
			    $i++;
			}
		    }
		    
	
		    #   Backup fvals
		    if($best->need_fval_change()){
			$best->$backup_func();			
		    }

		    
		    # Put everything back on the queue
		    if($best->need_fval_change()){
			$$priority_queue->insert($best);
			my $antecedent = $best->{_antecedent};
			my $i = 0;
			while($antecedent){
			    if($was_on_queue{$i} && $antecedent->need_fval_change()){  
                                # the antecedent needed fval change too.
				$$priority_queue->insert($antecedent);
			    }
			    if($antecedent->need_fval_change()){
				# set need_fval_change back to 0, so it will not be automatically  seen as 
				# needing changed in the future.  This is important, since we do not want
				# to remove an element from the queue *unless* we need to change the fcost. 
				# This is because when we remove it from the queue and re-insert it, it
				# loses its seniority in the queue (it becomes the newest node at its cost 
				# and depth) and will not be removed at the right time when searching for
				# deepest_lowest_cost_leafs or shallowest_highest_cost_leafs.
				$antecedent->{_need_fcost_change} = 0;
			    }

			    $antecedent = $antecedent->{_antecedent};
			    $i++;			    
			}
			# Again, set need_fval_change back to 0, so it will not be automatically 
			# seen as needing changed in the future.
			$best->{_need_fcost_change} = 0;
		    }
		}


		#
		# If best's descendants are all in memory, mark best as completed.
                #
		if($best->all_in_memory()) { 
		    
		    if(!($best->is_completed())){
			$best->is_completed(1);
		    }

		    my $cmp_func = sub {
			my ($str) = @_;			
			return sub{
			    my ($obj) = @_;
			    my $obj_str = $str_function->($obj);
			    if($obj_str eq $str){
				return 1;
			    }
			    else{ 
				return 0; 
			    }	    
			}
		    };			   
		    
		    my $best_str = $str_function->($best);

		    # If best is not a root node
		    if($best->{_depth} != 0){
			# descendant index is the unique index indicating which descendant
			# this node is of its antecedent.
			my $descendant_index = $best->{_descendant_index};
			my $antecedent = $best->{_antecedent};
			$$priority_queue->remove($best, $cmp_func->($best_str)); 
			if($antecedent){
			    $antecedent->{_descendants_produced}->[$descendant_index] = 0;			   
			}
		    }
		}
		
	        # there are no more successors of $best
		if(!$succ){ 
		    next;
		}

		my $antecedent;
		my @antecedents_that_need_to_be_inserted;

		# If the maximum number of states in the queue has been reached,
		# we need to remove the shallowest-highest-cost leaf to make room 
		# for more nodes.   That means we have to make sure that the antecedent
		# produces this descendant again at some point in the future if needed.
		if($num_states_in_queue > $max_states_in_queue){
		    my $shcl_obj = $$priority_queue->shallowest_highest_cost_leaf($best, $succ, $str_function);	

		    if(!$shcl_obj){
			croak "Error while pruning queue:   shallowest-highest-cost-leaf was null\n";	
		    }
		    $antecedent = $shcl_obj->{_antecedent};
		    if($antecedent){		
			my $antecedent_successors = \$antecedent->{_descendants_list};

			$antecedent->remember_forgotten_nodes_fcost($shcl_obj);
			$antecedent->{_forgotten_nodes_num} = $antecedent->{_forgotten_nodes_num} + 1;
			my $descendant_index = $shcl_obj->{_descendant_index};
		        # record the index of this descendant in the forgotten_nodes list
			$antecedent->{_forgotten_nodes_offsets}->{$descendant_index} = 1;			
			# flag the antecedent as not having this descendant in the queue
			$antecedent->{_descendants_produced}->[$descendant_index] = 0;
			$antecedent->{_descendant_fcosts}->[$descendant_index] = -1;		
			# flag the ancestor node as having deleted a descendant
			$antecedent->descendants_deleted(1);
			# update the number of descendants this node has in memory
			$antecedent->{_num_successors_in_mem} = $antecedent->{_num_successors_in_mem} - 1;				     
			# update the total number of nodes in the queue.
			$num_states_in_queue--;
			
		    }
		} # end if (num_states_on_queue > max_states)

		# if there is a successor to $best, insert it in the priority queue.
		if($succ){
		    $$priority_queue->insert($succ);
		    $best->{_num_successors_in_mem} = $best->{_num_successors_in_mem} + 1;
		}
		else{
		    croak "Error:  no successor to insert\n";
		}
	    }
	}
	continue {
	    $iteration++;
	}

	print "\n\nreturning unsuccessfully.   iteration: $iteration\n";	
	return;
    }
}    




sub max
{
    my ($n1, $n2) = @_;
    return ($n1 > $n2 ? $n1 : $n2);
}


sub fp_compare {
    my ($a, $b, $dp) = @_;
    my $a_seq = sprintf("%.${dp}g", $a);
    my $b_seq = sprintf("%.${dp}g", $b);
    
    

    if($a_seq eq $b_seq){
	return 0;
    }
    elsif($a_seq lt $b_seq){
	return -1;
    }
    else{ 
	return 1;
    }
}





1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

AI::Pathfinding::SMAstar - Simplified Memory-bounded A* Search


=head1 SYNOPSIS

 use AI::Pathfinding::SMAstar;
  

=head2 EXAMPLE

 ##################################################################
 #
 # This example uses a hypothetical object called FrontierObj, and
 # shows the functions that the FrontierObj class must feature in 
 # order to perform a path-search in a solution space populated by 
 # FrontierObj objects.
 #
 ##################################################################
 
 my $smastar = AI::Pathfinding::SMAstar->new(
        # evaluates f(n) = g(n) + h(n), returns a number
    	_state_eval_func           => \&FrontierObj::evaluate,

        # when called on a node, returns 1 if it is a goal
	_state_goal_p_func         => \&FrontierObj::goal_test,

        # must return the number of successors of a node
        _state_num_successors_func => \&FrontierObj::get_num_successors,      

        # must return *one* successor at a time
        _state_successors_iterator => \&FrontierObj::get_successors_iterator,   

        # can be any suitable string representation 
        _state_get_data_func       => \&FrontierObj::string_representation,  

        # gets called once per iteration, useful for showing algorithm progress
        _show_prog_func            => \&FrontierObj::progress_callback,      
    );

 # You can start the search from multiple start-states.
 # Add the initial states to the smastar object before starting the search.
 foreach my $frontierObj (@start_states){
    $smastar->add_start_state($frontierObj);
 }

 
 #
 # Start the search.  If successful, $frontierGoalPath will contain the
 # goal path.   The optimal path to the goal node will be encoded in the
 # ancestry of the goal path.   $frontierGoalPath->antecedent() contains
 # the goal path's parent path, and so forth back to the start path, which
 # contains only the start state.
 #
 # $frontierGoalPath->state() contains the goal FrontierObj itself.
 #
 my $frontierGoalPath = $smastar->start_search(
    \&log_function,       # returns a string used for logging progress
    \&str_function,       # returns a string used to *uniquely* identify a node 
    $max_states_in_queue, # indicate the maximum states allowed in memory
    $MAX_COST,            # indicate the maximum cost allowed in search
    );



In the example above, a hypothetical object, C<FrontierObj>, is used to
represent a state, or I<node> in your search space.   To use SMA* search to
find a shortest path from a starting node to a goal in your search space, you must
define what a I<node> is, in your search space (or I<point>, or I<state>).

A common example used for informed search methods, and one that is used in Russell's
original paper, is optimal puzzle solving, such as solving an 8 or 15-tile puzzle
in the least number of moves.   If trying to solve such a puzzle, a I<node> in the
search space could be defined as a  configuration of that puzzle (a paricular
ordering of the tiles).

There is an example provided in the /t directory of this module's distribution,
where SMA* is applied to the problem of finding the shortest palindrome that
contains a minimum number of letters specified, over a given list of words.

Once you have a definition and representation of a node in your search space, SMA*
search requires the following functions to work:


=over


=item *

B<State evaluation function> (C<_state_eval_func above>)

This function must return the cost of this node in the search space.   In all
forms of A* search, this means the cost paid to arrive at this node along a
path, plus the estimated cost of going from this node to a goal state:

I<f(x) = g(n) + h(n)>

This function must be I<positive> and I<monotonic>, meaning that the path to a
successor node must be at least as expensive overall when compared to the path
to that node's antecedent.   So if the nodes along a particular path are
labeled:  1 -> 2 -> 3, it must be at least as expensive to arrive at node 3 as
it is to arrive at node 2.   This amounts to the evaluation of the following
assignment B<[1]> when calculating the cost of a successor of node I<x>:

I<f(successor) = max(f(x), g(successor) + h(successor))>  

NOTE: Monotonicity is ensured in this implementation of SMA*, so even if your
function is not monotonic (which is possible, even given an admissible 
heuristic), SMA* will assign the antecedent node's cost to a successor if
that successor's I<g+h> amounts to less than the antecedent's f-cost.


=item *

B<State goal function> (C<_state_goal_p_func> above)

Goal predicate function.  This function must return 1 if the object argument is a
goal node, or 0 otherwise.


=item *

B<State number of successors function> (C<_state_num_successors_func> above)

This function must return the number of successors of the argument object/node, 
i.e. all nodes that are reachable from this node via a single operation.


=item *

B<State successors iterator> (C<_state_iterator> above)

This function must return a I<handle to a function> that produces the next
successor of the argument object, i.e. it must return an iterator function that
produces the successors of this node *one* at a time.    This is necessary
to maintain the memory-bounded constraint of SMA* search.


=item *

B<State get-data function> (C<_state_get_data_func> above)

This function returns a string representation of this node.


=item *

B<State show-progress function> (C<_show_prog_func> above)

This is a callback function for displaying the progress of the search.
It can be an empty callback if you do not need this output.


=item *

B<log string function> (C<log_function> above)

This is an arbitrary string used for logging.    It also gets passed to
the show-progress function above.


=item *

B<str_function> (C<str_function> above)

This function returns a *unique* string representation of this node.
Uniqueness is required for SMA* to work properly.


=item *

B<max states allowed in memory> (C<max_states_in_queue> above)

An integer indicating the maximum number of expanded nodes to hold in
memory at any given time.


=item *

B<maximum cost> (C<MAX_COST> above)

An integer indicating the maximum cost, beyond which nodes will not
be expanded.





=back



=head1 DESCRIPTION


=head2 Overview

Simplified Memory-bounded A* search (or SMA* search) addresses some of the
limitations of conventional A* search, by bounding the amount of space required
to perform a shortest-path search.   This module is an implementation of
SMA*, which was first introduced by Stuart Russell in 1992.   SMA* is a simpler,
more efficient variation of the original MA* search introduced by P. Chakrabarti
et al. in 1989 (see references below).



=head2 Motivation and Comparison to A* Search


=head3 A* search

A* Search is an I<optimal> and I<complete> algorithm for computing a sequence of
operations leading from a system's start-state (node) to a specified goal.
In this context, I<optimal> means that A* search will return the shortest
(or cheapest) possible sequence of operations (path) leading to the goal,
and I<complete> means that A* will always find a path to 
the goal if such a path exists.

In general, A* search works using a calculated cost function on each node along a
path, in addition to an I<admissible> heuristic estimating the distance from 
that node to the goal.  The cost is calculated as:

I<f(n) = g(n) + h(n)>

Where:


=over

=item *

I<n> is a state (node) along a path

=item *

I<g(n)> is the total cost of the path leading up to I<n> 

=item *

I<h(n)> is the heuristic function, or estimated cost of the path from I<n>
to the goal node.

=back


For a given admissible heuristic function, it can be shown that A* search
is I<optimally efficient>, meaning that,  in its calculation of the shortest
path, it expands fewer nodes in the search space than any other algorithm.

To be admissible, the heuristic I<h(n)> can never over-estimate the distance
from the node to the goal.   Note that if the heuristic I<h(n)> is set to
zero, A* search reduces to I<Branch and Bound> search.  If the cost-so-far
I<g(n)> is set to zero, A* reduces to I<Greedy Best-first> search (which is
neither complete nor optimal).   If both I<g(n)> and I<h(n)> are set to zero,
the search becomes I<Breadth-first>, which is complete and optimal, but not
optimally efficient.

The space complexity of A* search is bounded by an exponential of the
branching factor of the search-space, by the length of the longest path
examined during the search.   This is can be a problem particularly if the
branching factor is large, because the algorithm may run out of memory.


=head3 SMA* Search

Like A* search, SMA* search is an optimal and complete algorithm for finding
a least-cost path.   Unlike A*, SMA* will not run out of memory, I<unless the size
of the shortest path exceeds the amount of space in available memory>.

SMA* addresses the possibility of running out of memory 
by pruning the portion of the search-space that is being examined.  It relies on 
the I<pathmax>, or I<monotonicity> constraint on I<f(n)> to remove the shallowest 
of the highest-cost nodes from the search queue when there is no memory left to 
expand new nodes.  It records the best costs of the pruned nodes within their 
antecedent nodes to ensure that crucial information about the search space is 
not lost.   To facilitate this mechanism, the search queue is best maintained 
as a search-tree of search-trees ordered by cost and depth, respectively.

=head4 Nothing is for free

The pruning of the search queue allows SMA* search to utilize all available
memory for search without any danger of overflow.   It can, however, make
SMA* search significantly slower than a theoretical unbounded-memory search,
due to the extra bookkeeping it must do, and because nodes may need to be
re-expanded (the overall number of node expansions may increase).  
In this way there is a trade-off between time and space.

It can be shown that of the memory-bounded variations of A* search, such MA*, IDA*, 
Iterative Expansion, etc., SMA* search expands the least number of nodes on average.
However, for certain classes of problems, guaranteeing optimality can be costly.   
This is particularly true in solution spaces where:


=over

=item *

the branching factor of the search space is large

=item *

there are many equivalent optimal solutions (or shortest paths)

=back


For solution spaces with these characteristics, stochastic methods or
approximation algorithms such as I<Simulated Annealing> can provide a
massive reduction in time and space requirements, while introducing a
tunable probability of producing a sub-optimal solution.


=head1 METHODS


=head2 new()

  my $smastar = AI::Pathfinding::SMAstar->new();

Creates a new SMA* search object.


=head2 start_search()

  my $frontierGoalObj = $smastar->start_search(
    \&log_function,       # returns a string used for logging progress
    \&str_function,       # returns a string used to *uniquely* identify a node 
    $max_states_in_queue, # indicate the maximum states allowed in memory
    $MAX_COST,            # indicate the maximum cost allowed in search
    );

Initiates a memory-bounded search.  When calling this function, pass a handle to
a function for recording current status( C<log_function> above- this can be
an empty subroutine if you don't care), a function that returns a *unique* string
representing a node in the search-space (this *cannot* be an empty subroutine), a
maximum number of expanded states to store in the queue, and a maximum cost
value (beyond which the search will cease).


=head2 state_eval_func()

 $smastar->state_eval_func(\&FrontierObj::evaluate);

Set or get the handle to the function that returns the cost of the object 
argument (node) in the search space. 


=head2 state_goal_p_func()

 $smastar->state_goal_p_func(\&FrontierObj::goal_test);

Set/get the handle to the goal predicate function.   This is a function 
that returns 1 if the argument object is a goal node, or 0 otherwise.



=head2 state_num_successors_func()

 $smastar->state_num_successors_func(\&FrontierObj::get_num_successors);

Set/get the handle to the function that returns the number of successors 
of this the object argument (node).


=head2 state_successors_iterator()

 $smastar->state_successors_iterator(\&FrontierObj::get_successors_iterator);

Set/get the handle to the function that returns iterator that produces the 
next successor of this node.


=head2 state_get_data_func()

 $smastar->state_get_data_func(\&FrontierObj::string_representation);

Set/get the handle to the function that returns a string 
representation of this node.


=head2 show_prog_func()

 $smatar->show_prog_func(\&FrontierObj::progress_callback);

Sets/gets the callback function for displaying the progress of the search.
It can be an empty callback (sub{}) if you do not need this output.



=head2 DEPENDENCIES

 Tree::AVL
 Test::More


=head2 INCLUDED MODULES

 AI::Pathfinding::SMAstar
 AI::Pathfinding::SMAstar::Path
 AI::Pathfinding::SMAstar::PriorityQueue
 AI::Pathfinding::SMAstar::TreeOfQueues



=head2 EXPORT

None by default.



=head1 SEE ALSO

[1] Russell, Stuart. (1992) I<"Efficient Memory-bounded Search Methods."> 
Proceedings of the 10th European conference on Artificial intelligence, pp. 1-5 

[2] Chakrabarti, P. P., Ghose, S., Acharya, A., and de Sarkar, S. C. (1989)
I<"Heuristic search in restricted memory.">  Artificial Intelligence Journal, 
41, pp. 197-221.

=head1 AUTHOR

Matthias Beebe, E<lt>matthiasbeebe@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Matthias Beebe

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.


=cut
