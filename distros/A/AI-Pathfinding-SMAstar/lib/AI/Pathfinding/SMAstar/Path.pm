#
# Representation of a path, used in the SMAstar pathfinding algorithm.
#
# Author:  matthias beebe
# Date :  June 2008
#
#

package AI::Pathfinding::SMAstar::Path;

use strict;

BEGIN {
    use Exporter ();
    @Path::ISA         = qw(Exporter);
    @Path::EXPORT      = qw();
    @Path::EXPORT_OK   = qw($d);

  }

use vars qw($d $max_forgotten_nodes);  # used to debug destroy method for accounting purposes
$d = 0;
$max_forgotten_nodes = 0;


##################################################
# Path constructor 
##################################################
sub new {
    my $invocant = shift;
    my $class   = ref($invocant) || $invocant;
    my $self = {
	
	_state                    => undef,  # node in the search space
	_eval_func               => undef,
	_goal_p_func             => undef,
	_num_successors_func     => undef,
	_successors_iterator     => undef,
	_get_data_func           => undef,

	###########################################
	#
	#   path stuff
	#
	###########################################	
	_antecedent              => undef,  # pointer to the antecedent of this obj
	_f_cost                  => undef,  # g + h where g = cost so far, h = estimated cost to goal.

	_forgotten_node_fcosts   => [],     # array to store fcosts of forgotten nodes
	_forgotten_nodes_num     => 0,

	_forgotten_nodes_offsets => {},

	_depth                   => 0,     # depth used for memory-bounded search
	_descendants_produced    => [],
	_descendant_index        => undef,	
	_descendant_fcosts       => [],
	_descendants_on_queue    => 0,

	_descendands_deleted     => 0,
	_is_completed            => 0,
	_num_successors          => undef,
	_num_successors_in_mem   => 0,
	_is_on_queue             => 0,
	_iterator_index          => 0,      # to remember index of iterator for descendants
	_need_fcost_change       => 0,      # boolean

	@_,    # attribute override
    };

    return bless $self, $class;
        
}

##############################################
# accessors
##############################################

sub state{
    my $self = shift;
    if (@_) { $self->{_state} = shift }
    return $self->{_state};
}

sub antecedent{
    my $self = shift;
    if (@_) { $self->{_antecedent} = shift }
    return $self->{_antecedent};
}

sub f_cost{
    my $self = shift;
    if (@_) { $self->{_f_cost} = shift }
    return  $self->{_f_cost};
}

sub depth{
    my $self = shift;
    if (@_) { $self->{_depth} = shift }
    return  $self->{_depth};
}

sub is_completed{
    my $self = shift;
    if (@_) { $self->{_is_completed} = shift }
    return  $self->{_is_completed};
}

sub is_on_queue{
    my $self = shift;
    if (@_) { $self->{_is_on_queue} = shift }
    return  $self->{_is_on_queue};
}

sub descendants_deleted{
    my $self = shift;
    if (@_) { $self->{_descendants_deleted} = shift }
    return  $self->{_descendants_deleted};
}

sub need_fval_change{
    my $self = shift;
    if (@_) { $self->{_need_fcost_change} = shift }
    return  $self->{_need_fcost_change};
}




# new version 8
sub remember_forgotten_nodes_fcost
{
    my ($self, $node) = @_;      

    my $fcost = $node->{_f_cost};
    my $index = $node->{_descendant_index};

    $self->{_forgotten_node_fcosts}->[$index] = $fcost;
    
    return;
}






#----------------------------------------------------------------------------
# evaluation function f(n) = g(n) + h(n) where 
#
# g(n) = cost of path through this node
# h(n) = distance from this node to goal (optimistic)
#
# used for A* search.
#
sub fcost
{    
    my ($self) = @_;
    
    my $fcost = $self->{_f_cost};
    if(defined($fcost)){	    
	return $fcost;
    }

    my $eval_func = $self->{_eval_func};
    my $result =  $eval_func->($self->{_state});
    $self->{_f_cost} = $result;

    return $result;
}





sub is_goal
{
    my ($self) = @_;
      
    my $goal_p_func = $self->{_goal_p_func};
    my $result =  $goal_p_func->($self->{_state});

    return $result;
}



sub get_num_successors
{
    my ($self) = @_;
      
    my $num_successors_func = $self->{_num_successors_func};
    my $result =  $num_successors_func->($self->{_state});

    return $result;    
}


sub get_successors_iterator
{
    my ($self) = @_;
      
    my $successors_iterator = $self->{_successors_iterator};

    my $iterator = $successors_iterator->($self->{_state});
    
    return $iterator;    
}


    
    

#-----------------------------------------------------------------------------------------------
#
# Check whether we need to backup the fvals for a node when it is completed (recursive)
# Sets flags throughout path object's lineage, indicating whether fvals need to be updated.
#
#-----------------------------------------------------------------------------------------------
sub check_need_fval_change
{
    my ($self, $descendant_fcost, $descendant_ind) = @_;
 

    my $descendant_index = $self->{_descendant_index};

    if(!$self->is_completed()){
        # node not completed. no need to update fcost.
	$self->need_fval_change(0);
	return;
    }

    my $fcost = $self->{_f_cost};
    my $least_fcost2 = 99;
       
    
    my $min = sub {	
	my ($n1, $n2) = @_;
	return ($n1 < $n2 ? $n1 : $n2);
    };

    if($self->{_forgotten_nodes_num} != 0){ 
	foreach my $ind (keys %{$self->{_forgotten_nodes_offsets}}){	  
	    my $cost = $self->{_forgotten_node_fcosts}->[$ind];	    
	    if($cost != -1 && $cost < $least_fcost2){
		$least_fcost2 = $cost;
	    }		    
	}
    }    
   
    my $j = 0;
    foreach my $fc (@{$self->{_descendant_fcosts}}){
	if(defined($descendant_ind) && $j != $descendant_ind){
	    if($fc != -1 && $fc < $least_fcost2){
		$least_fcost2 = $fc;
	    }
	}
	else{
	    # special case for index $j:  it is the caller's index.
	    if(defined($descendant_fcost)){	
		if($descendant_fcost < $least_fcost2) {
		    $least_fcost2 = $descendant_fcost;
		}
	    }
	    elsif($fc != -1 && $fc < $least_fcost2){
		$least_fcost2 = $fc;
	    }
	}	
	$j++;	
    }
    
    # if no successors, this node cannot lead to 
    # goal, so set fcost to infinity.
    if($self->{_num_successors} == 0){ 
	$least_fcost2 = 99;
    }
  
    if($least_fcost2 != $fcost){		
        # setting need_fcost_change to 1
	$self->need_fval_change(1);
	my $antecedent = $self->{_antecedent};
	
	# recurse on the antecedent
	if($antecedent){
	    $antecedent->check_need_fval_change($least_fcost2, $descendant_index);
	}	
    }
}





#-----------------------------------------------------------------------------------------------
#
# Backup the fvals for a node when it is completed.
#
#-----------------------------------------------------------------------------------------------
sub backup_fvals
{
    my ($self) = @_;
    
    while($self){
	
	if(!$self->is_completed()){
            # node not completed, return
	    return;
	}
	
	my $fcost = $self->{_f_cost};
	my $least_fcost = 99;

	my $min = sub {	
	    my ($n1, $n2) = @_;
	    return ($n1 < $n2 ? $n1 : $n2);
	};
	
	if($self->{_forgotten_nodes_num} != 0){ 
	    foreach my $ind (keys %{$self->{_forgotten_nodes_offsets}}){	  
		my $cost = $self->{_forgotten_node_fcosts}->[$ind];	    
		if($cost != -1 && $cost < $least_fcost){
		    $least_fcost = $cost;
		}		    
	    }
	}    

	foreach my $fc (@{$self->{_descendant_fcosts}}){
	    if($fc != -1 && $fc < $least_fcost){
		$least_fcost = $fc;
	    }
	}

	# if no successors, this node cannot lead to 
	# goal, so set fcost to infinity.
	if($self->{_num_successors} == 0){ 
	    $least_fcost = 99;
	}
	
	if($least_fcost != $fcost){		
        # changing fcost from $self->{_f_cost} to $least_fcost	    
	    $self->{_f_cost} = $least_fcost;
	    
	    my $antecedent = $self->{_antecedent};
	    if($antecedent){
		my $descendant_index = $self->{_descendant_index};
		$antecedent->{_descendant_fcosts}->[$descendant_index] = $least_fcost;
	    }	    
	}
	else{
            # not changing fcost. current fcost: $self->{_f_cost}, least_fcost: $least_fcost
	    last;
	}
	
	$self = $self->{_antecedent};
        	
    }  #end while
    
    return;
}






#
# return 1 if all descendants of this path are in
# memory, return 0 otherwise.
#
sub all_in_memory
{
    my ($self) = @_;
    my $is_completed = $self->is_completed();
    my $num_successors_in_mem = $self->{_num_successors_in_mem};
    my $num_successors = $self->{_num_successors};

    my $num_forgotten_fcosts = @{$self->{_forgotten_node_fcosts}};

    if($is_completed || $num_successors == 0){		
	if($num_successors == $num_successors_in_mem){
	    return 1;
	}
	return 0;	    
    }    
    return 0;    
}



#
# return 1 if *any* descendants are in memory
#
sub has_descendants_in_memory
{
    my ($self) = @_;

    my $num_descendants_on_queue = $self->{_descendants_on_queue};
  
    if($num_descendants_on_queue){
	return $num_descendants_on_queue;
    }
  
    return;
}



#-----------------------------------------------------------------------------
# Get descendants iterator function, for for SMA* search.  Returns one new
# node at a time.
#
# The SMA* algorithm must handle "forgotten" nodes.
#
# Generate the next descendant of a path object. Each descendant adds
# another node on the path that may lead to the goal.
#
#-----------------------------------------------------------------------------
sub get_descendants_iterator_smastar
{
    my ($self) = @_;
    
    my $depth = $self->{_depth};
    my $iterator;
    my $num_successors = 0;
    my $next_descendant;

    # if we haven't counted the number of successors yet,
    # count and record the number, so we only have to do
    # this once.
    if(!defined($self->{_num_successors})){

	$num_successors = $self->get_num_successors();

	$self->{_num_successors} = $num_successors;	

	$#{$self->{_descendants_produced}}  = $num_successors;
	$#{$self->{_descendant_fcosts}}     = $num_successors;
	$#{$self->{_forgotten_node_fcosts}} = $num_successors;

	for (my $i = 0;  $i <= $num_successors; $i++){
	    $self->{_descendants_produced}->[$i] = 0;
	    $self->{_descendant_fcosts}->[$i] = -1;
	    $self->{_forgotten_node_fcosts}->[$i] = -1;
	}
    }
    else{
	# if number of successors has already been recorded, update 
	# num_successors variable with stored value.
	$num_successors = $self->{_num_successors};	
    }
	
    return sub{	
	my $i = 0;
	
        # entering get_descendants_iterator_smastar() sub	
	$iterator = $self->get_successors_iterator();

	my $descendants_deleted = 0;
	my $descendants_found = 0;
	

	# loop over nodes returned by iterator
	while(my $next_state = $iterator->()){	

	    $next_descendant = AI::Pathfinding::SMAstar::Path->new(
		_state => $next_state,
		_eval_func => $self->{_eval_func},
		_goal_p_func => $self->{_goal_p_func},
		_get_data_func => $self->{_get_data_func},
		_num_successors_func => $self->{_num_successors_func},
		_successors_iterator => $self->{_successors_iterator},
		_antecedent => $self,	
		_depth => $depth + 1,				
		);

    		
	    my $start_word = $next_descendant->{_state}->{_start_word};
	    my $phrase = $next_descendant->{_state}->{_phrase};
	    
	    my $already_produced_p = $self->{_descendants_produced}->[$i] || ($self->{_descendant_fcosts}->[$i] != -1);
	    

	    if($already_produced_p){
		# have already produced this descendant
		$descendants_found++;
                # found descendant in tree\n";		

		if($i == $num_successors - 1 && $descendants_deleted){
		    # !!! resetting iterator index. descendants have been deleted. clearing forgotten_fcosts on next expansion.
		    $iterator = $self->get_successors_iterator();
		    $self->{_iterator_index} = 0;
		    $i = 0;		

                    # setting completed to 1 (true)
		    $self->is_completed(1);	    		    
		    next;
		}
		else{
		    $i++;
		}


		if($descendants_found == $num_successors){
                    # setting completed to 1.
		    $self->is_completed(1);
		}	

		$next_descendant = undef;  # found this one in list, so undef next descendant.
		
	    }
	    else{	    	
		# did not find descendant in descendant's list 

		if($i < $self->{_iterator_index} && $self->{_forgotten_nodes_num} != 0){
                    # did not find descendant in list, but may have already produced this 
		    # descendant since this node was created.
		    $i++;
		    $descendants_deleted++;
		    next;
		}		
                # did not find descendant in list, adding now.

				
		$next_descendant->{_descendant_index} = $i;
		$self->{_descendants_produced}->[$i] = 1;
                # new descendant's index is $i

		
		$self->{_iterator_index} = $i + 1;
		
		if($self->{_iterator_index} == $self->{_num_successors}){
		    $iterator = $self->get_successors_iterator();
		    $self->{_iterator_index} = 0;
		    $i = 0;
		    	

		    # node is completed, setting completed to 1\n";
		    $self->is_completed(1);
		}
		
		# break out of while() loop
		last;
	    }	 	   
	}


	if($i >= $num_successors - 1 && $descendants_deleted && $self->depth() == 0){
            # root node.  going to reset iterator index. descendants have been deleted.  Also, will be
            # clearing out forgotten_descendants fcost list, since those descendants will be re-generated anyway.
	    $iterator = $self->get_successors_iterator();
	    $self->{_iterator_index} = 0;
	    $i = 0;
	    	   
            # setting completed to 1
	    $self->is_completed(1);	    	  
	}
	
 	if($next_descendant){
	    
	    if($self->{_forgotten_node_fcosts}->[$next_descendant->{_descendant_index}] != -1){
		# erase the index of this node in the forgotten_nodes list
		$self->{_forgotten_node_fcosts}->[$next_descendant->{_descendant_index}] = -1;
		# decrement the number of forgotten nodes
		$self->{_forgotten_nodes_num} = $self->{_forgotten_nodes_num} - 1;
		delete $self->{_forgotten_nodes_offsets}->{$next_descendant->{_descendant_index}};
	    }

	}
	else{
            # no next successor found
	    $self->is_completed(1);
	}

	return $next_descendant;
    }     	
}



sub get_data
{
    my ($self) = @_;

    my $get_data_func = $self->{_get_data_func};
    my $data = $get_data_func->($self->{_state});
    
    return $data;
}



sub DESTROY
{
    my ($self) = @_;

    # antecedent is no longer pointing at this object, or else
    # DESTROY would not have been called.  
    if($self->{_antecedent}){
	delete $self->{_antecedent};
    }
}

































1;  # so the require or use succeeds

