#
# PriorityQueue.pm
#

# Author:  matthias beebe
# Date :  June 2008
#
#
package AI::Pathfinding::SMAstar::PriorityQueue;


use Tree::AVL;
use AI::Pathfinding::SMAstar::Path;
use AI::Pathfinding::SMAstar::TreeOfQueues;
use Carp;
use strict;



##################################################
# PriorityQueue constructor 
##################################################
sub new {
    my $invocant = shift;
    my $class   = ref($invocant) || $invocant;
    my $self = { 
        _hash_of_trees_ref    => {},
	
	_cost_min_max_tree   => Tree::AVL->new( fcompare => \&fp_compare,  # floating-point compare
						fget_key => sub { $_[0] },
						fget_data => sub { $_[0] },),

	f_depth        => \&AI::Pathfinding::SMAstar::Path::depth,
	f_fcost        => \&AI::Pathfinding::SMAstar::Path::fcost,
	f_avl_compare  => \&AI::Pathfinding::SMAstar::Path::compare_by_depth,
	f_avl_get_key  => \&AI::Pathfinding::SMAstar::Path::depth,
	f_avl_get_data => \&AI::Pathfinding::SMAstar::Path::get_data,

	_size                 => 0,

	@_,    # attribute override
    };
    return bless $self, $class;
}

################################################
# accessors
################################################

sub hash_of_trees {
    my $self = shift;
    if (@_) { $self->{_hash_of_trees_ref} = shift }
    return $self->{_hash_of_trees_ref};
}

sub size {
    my $self = shift;
    if (@_) { $self->{_size} = shift }
    return $self->{_size};    
}



################################################
##
## other methods       
##
################################################

sub insert {
    my ($self, $pobj) = @_;

    my $cost_hash_ref = $self->{_hash_of_trees_ref};
    my $cost_hash_key_func = $self->{f_fcost};

    my $cost_min_max_tree = $self->{_cost_min_max_tree};

    my $depth_func = $self->{f_depth};
    
    my $avl_compare_func = $self->{f_avl_compare};
    my $avl_get_key_func = $self->{f_avl_get_key};
    my $avl_get_data_func = $self->{f_avl_get_data};

    my $cost_key = $pobj->$cost_hash_key_func();
    my $data = $pobj->$avl_get_data_func();

    
    # inserting pobj with key: $cost_key, data: $data    
    if(!$cost_hash_ref->{$cost_key}){
	# no tree for this depth yet, so create one.
	my $avltree = AI::Pathfinding::SMAstar::TreeOfQueues->new(
	    f_avl_compare => $avl_compare_func,
	    f_obj_get_key => $avl_get_key_func,
	    f_obj_get_data => $avl_get_data_func,
	    );
       
	$avltree->insert($pobj);	
	$cost_hash_ref->{$cost_key} = \$avltree;
	# insert the cost_key in the cost tree
	$cost_min_max_tree->insert($cost_key);
    }
    else{
    # there is already a tree at $cost_key, so inserting there	
	my $avltree = $cost_hash_ref->{$cost_key};
	$$avltree->insert($pobj);	
    }    
    $self->{_size} = $self->{_size} + 1;
    my $antecedent = $pobj->{_antecedent};
    if($antecedent){
	$antecedent->{_descendants_on_queue} = $antecedent->{_descendants_on_queue} + 1;
    }
    $pobj->is_on_queue(1);
}


sub print_trees_in_order
{
     my ($self) = @_;

     my $cost_hash_ref = $self->{_hash_of_trees_ref};
               
     for my $cost_key (keys %$cost_hash_ref){
	 if(!$cost_hash_ref->{$cost_key}){
	     # no tree for this depth.	     
	     #print "no tree at key $depth_key\n";
	 }
	 else{
	     #print "contents of tree with depth $depth_key\n";	     
	     my $avltree = $cost_hash_ref->{$cost_key};	     
	     $$avltree->print();
	 }	 
     }      
}


#-----------------------------------
# get_list
#
# return a list of all objects in queue
#
#-----------------------------------
sub get_list
{
     my ($self) = @_;

     my $cost_hash_ref = $self->{_hash_of_trees_ref};
          
     my @list;
     
     for my $cost_key (keys %$cost_hash_ref){
	 if($cost_hash_ref->{$cost_key}){
	     my $avltree = $cost_hash_ref->{$cost_key};	     
	     push(@list, $$avltree->get_list());
	 }	 
     }     
     return @list;
}


sub is_empty
{
    my ($self) = @_;
    
    my $cost_hash_ref = $self->{_hash_of_trees_ref};
    my @cost_keys = (keys %$cost_hash_ref);
    
    if(!@cost_keys){
	return 1;
    }
    else{
	return 0;
    }
}


sub remove
{
    my ($self, $obj, $cmp_func) = @_;

    my $cost_hash_ref = $self->{_hash_of_trees_ref};
    my @cost_keys = (keys %$cost_hash_ref);
    

    my $cost_min_max_tree = $self->{_cost_min_max_tree};
    
    
    my $avl_get_data_func = $self->{f_avl_get_data};
    my $cost_hash_key_func = $self->{f_fcost};
    my $depth_func = $self->{f_depth};
    

    my $cost_key = $obj->$cost_hash_key_func();
    my $data = $obj->$avl_get_data_func();
    
    if(!$cost_hash_ref->{$cost_key}){
	# no tree for this cost_key 	
	return;
    }
    else{
	# found the tree at $cost_key, trying to remove obj from there
	
	my $avltree = $cost_hash_ref->{$cost_key};
	$$avltree->remove($obj, $cmp_func);	

	# if tree is empty, remove it from hash
	if($$avltree->is_empty()){
	    delete $cost_hash_ref->{$cost_key}; 
	    $cost_min_max_tree->remove($cost_key);
	}	
	$self->{_size} = $self->{_size} - 1;
    }    
    my $antecedent = $obj->{_antecedent};
    if($antecedent){
	$antecedent->{_descendants_on_queue} = $antecedent->{_descendants_on_queue} - 1;
    }

    $obj->is_on_queue(0);
    return;
}

sub deepest_lowest_cost_leaf 
{
    my ($self) = @_;
   
    my $cost_hash_ref = $self->{_hash_of_trees_ref};
    my @cost_keys = (keys %$cost_hash_ref);

 
    my $cost_min_max_tree = $self->{_cost_min_max_tree};

    if(!@cost_keys){
	# queue is empty
	return;
    }

    # get the lowest cost from cost_keys  
    my $lowest_cost_key = $cost_min_max_tree->smallest();
    if(!$lowest_cost_key){
	croak "deepest_lowest_cost_leaf: object not found in min-max heap\n";	
    }    
 
    
    if(!$cost_hash_ref->{$lowest_cost_key}){
	# no tree for this cost.	     
	return;
    }
    else{
	my $avltree = $cost_hash_ref->{$lowest_cost_key};
	my $obj = $$avltree->pop_largest_oldest();  # get the deepest one
	my $antecedent = $obj->{_antecedent};
	
	# if tree is empty, remove it from hash and heap.
	if($$avltree->is_empty()){
	    #tree is empty, removing key $lowest_cost_key	    
	    delete $cost_hash_ref->{$lowest_cost_key}; 
	    $cost_min_max_tree->pop_smallest();
	}		

	if($antecedent){
	    $antecedent->{_descendants_on_queue} = $antecedent->{_descendants_on_queue} - 1;
	}
	
	$obj->is_on_queue(0);
	$self->{_size} = $self->{_size} - 1;
	return $obj;   
    }
}

sub deepest_lowest_cost_leaf_dont_remove
{
    my ($self) = @_;
    
    my $avl_compare_func = $self->{f_avl_compare};
    my $avl_get_key_func = $self->{f_avl_get_key};
    my $avl_get_data_func = $self->{f_avl_get_data};
    
    my $cost_hash_ref = $self->{_hash_of_trees_ref};
    my @cost_keys = (keys %$cost_hash_ref);



    my $cost_min_max_tree = $self->{_cost_min_max_tree};

    if(!@cost_keys){
	# queue is empty
	return;
    }

    # get the lowest cost from @cost_keys 
    my $lowest_cost_key = $cost_min_max_tree->smallest();
    if(!$lowest_cost_key){
	croak "deepest_lowest_cost_leaf_dont_remove: object not found in min-max heap\n";
    }
    
    # obtaining object from lowest-cost tree at cost:  $lowest_cost_key\n";
    if(!$cost_hash_ref->{$lowest_cost_key}){
	# no tree for this cost.	     
	return;
    }
    else{
	my $avltree = $cost_hash_ref->{$lowest_cost_key};
        # found tree at key $lowest_cost_key.

	my $obj = $$avltree->largest_oldest();  # get the deepest one	
	my $cost_key = $obj->$avl_get_key_func();
	my $data = $obj->$avl_get_data_func();
	return $obj;   
    }
}


# Return the shallowest, highest-cost leaf
sub shallowest_highest_cost_leaf
{
    my ($self, $best, $succ, $str_function) = @_;
    
    my $cost_hash_ref = $self->{_hash_of_trees_ref};
    my @cost_keys = (keys %$cost_hash_ref);
 
    my $cost_min_max_tree = $self->{_cost_min_max_tree};
      
    my $obj;

    if(!@cost_keys){
	return;
    }

    my $compare_func = sub{
	my ($obj1, $obj2) = @_;
	my $obj1_str = $str_function->($obj1);
	my $obj2_str = $str_function->($obj2);	
	if($obj1_str eq $obj2_str){
	    return 1;
	}
	return 0;
    };
    
    my $cmp_func = sub {
	my ($phrase) = @_;			
	return sub{
	    my ($obj) = @_;
	    my $obj_phrase = $str_function->($obj);
	    if($obj_phrase eq $phrase){
		return 1;
	    }
	    else{ 
		return 0; 
	    }	    
	}
    };	

    # get the highest cost from @cost_keys
  
    my $highest_cost_key = $cost_min_max_tree->largest();
    if(!$highest_cost_key){
	croak "shallowest_highest_cost_leaf_dont_remove: object not found in min-max heap\n";
    }

    if(!$cost_hash_ref->{$highest_cost_key}){
	# no tree for this cost.	     
	croak "shallowest_highest_cost_leaf: no tree at key $highest_cost_key\n";
	return;
    }
    else{
	my $least_depth = 0;
	my $avltree;
	my $depth_keys_iterator;

	while(1){

	    while($least_depth == 0){
		$avltree = $cost_hash_ref->{$highest_cost_key};  #tree with highest cost
		
		# get the deepest queue in the tree
		# so we can use it to step backward to the smallest non-zero 
		# depth in the following loop
		my $queue_at_largest_depth = $$avltree->largest(); 
		$least_depth = $queue_at_largest_depth->key();
		$depth_keys_iterator = $$avltree->get_keys_iterator();
		

		# get lowest non-zero key of tree (smallest non-zero depth)
		while (defined(my $key = $depth_keys_iterator->())){
		    #########################################################################
		    #
		    # Does this need to be a non-zero depth element? yes. (example: test68.lst)
		    # 
		    #########################################################################		  
		    if($key != 0){
			$least_depth = $key;
			last;
		    }
		}

		# if no non-zero depths, find the next highest key and loop back
		my $next_highest_cost_key;
		if($least_depth == 0){
		    $next_highest_cost_key = next_largest_element(\@cost_keys, $highest_cost_key);
		    $highest_cost_key = $next_highest_cost_key;
		    if(!$highest_cost_key){
			print "no highest_cost_key found\n";
			exit;
		    }
		}
		else{ # least depth is non-zero, so it's good
		    last;
		}
		
	    }  # Now have a good highest_cost_key, with a tree that has a good non-zero key queue somewhere in it.
	    

	    my $queue = $$avltree->get_queue($least_depth);  # get the queue at least_depth	    

	    my $queue_keys_iterator = $queue->get_keys_iterator();
	    my $queue_key = $queue_keys_iterator->(); # burn the first value from the iterator since we're getting first object on next line.	    
	    $obj = $$avltree->oldest_at($least_depth); # get the shallowest one that is not at zero depth
	    
	    my $i = 1;

	    while($compare_func->($obj, $best) || $compare_func->($obj, $succ) || $obj->has_descendants_in_memory()){		
		
		if($queue_key = $queue_keys_iterator->()){					    
		    $obj = $queue->lookup_by_key($queue_key);		
	       
		}
		else{
		    # need a new least_depth.  check if there are any more queues with non-zero depth in this tree.
		    # if not, need a new highest_cost_key.
		    $obj = undef;

		    my $next_smallest = $depth_keys_iterator->();
		    if(!defined($next_smallest)){
			last;
		    }
		    else{
			$least_depth = $next_smallest;
			$queue = $$avltree->get_queue($least_depth);  # get the queue at least_depth		
			$queue_keys_iterator = $queue->get_keys_iterator();
			$queue_key = $queue_keys_iterator->(); # burn the first value from the iterator		
			$obj = $$avltree->oldest_at($least_depth); # get the shallowest one that is not at zero depth			
			$i = 1;		
			next;
		    }
		}
		
		$i++;
	    } # end while($compare_func->($obj, $best) || $compare_func->($obj, $succ) || $obj->has_descendants_in_memory())
	    	    
	    # done loop on last highest_cost_key.  if obj is not found, get another highest_cost_key, and loop back again.
	    if(!$obj){
		$least_depth = 0;
		$highest_cost_key = next_largest_element(\@cost_keys, $highest_cost_key);		
	    }
	    else{
		last;
	    }
	    
	} # end while(1)

	my $obj_str = $str_function->($obj);
	$$avltree->remove($obj, $cmp_func->($obj_str));

	if($obj){
	    $self->{_size} = $self->{_size} - 1;
	    
	    my $antecedent = $obj->{_antecedent};
	    if($antecedent){
		$antecedent->{_descendants_on_queue} = $antecedent->{_descendants_on_queue} - 1;
	    }
	    $obj->is_on_queue(0);
	    if($$avltree->is_empty()){
		delete $cost_hash_ref->{$highest_cost_key}; 
	

		$cost_min_max_tree->remove($highest_cost_key);
	    }		
	    return $obj;   
	}
	else{	
	    return;
	}
    }
}


sub largest_element
{
    my ($array) = @_;
    
    if(!@$array){
	return;
    }
    else{
	my $i = 0;
	my $largest = $$array[$i];
	for($i = 1; $i < @$array; $i++)
	{
	    if($largest < $$array[$i]){
		$largest  = $$array[$i];
	    }
	}
	return $largest;
    }
}


sub next_largest_element
{
    my ($array, $val) = @_;
    
    if(!@$array){
	return;
    }
    else{
	my $i = 0;
	my $largest = -1;
	for($i = 0; $i < @$array; $i++)
	{
	    if($$array[$i] < $val && $largest < $$array[$i]){
		$largest  = $$array[$i];
	    }
	}

	if($largest != -1){
	    return $largest;
	}
	else{
	    return;
	}
    }
}



sub next_smallest_non_zero_element
{
    my ($array, $val) = @_;
    
    my $max = 2^32-1;

    if(!@$array){
	return;
    }
    else{
	my $i = 0;
	my $smallest = $max;
	for($i = 0; $i < @$array; $i++)
	{
	    if($$array[$i] > $val && $$array[$i] < $smallest){
		$smallest  = $$array[$i];
	    }
	}

	if($smallest != $max){
	    return $smallest;
	}
	else{
	    return;
	}
    }
}


sub smallest_element
{
    my ($array) = @_;
     if(!@$array){
	return;
     }
     else{
	my $i = 0;
	my $smallest = $$array[$i];
	for($i = 1; $i < @$array; $i++){
	    if($smallest > $$array[$i]){
		$smallest  = $$array[$i];
	    }
	}
	return $smallest;
    }
}



sub get_size{
    my ($self) = @_;       
    my $cost_hash_ref = $self->{_hash_of_trees_ref};    
    my $size = 0; 
    
    foreach my $key (keys %$cost_hash_ref){
	my $tree = $cost_hash_ref->{$key};
	my $tree_size = $$tree->get_size();
	$size += $tree_size;
    }
    return $size;
}



sub fp_compare
{
    my ($obj1, $obj2) = @_;
   
    if(fp_equal($obj1, $obj2, 10)){
	return 0;
    }
    if($obj1 < $obj2){	
	return -1;
    }
    return 1;
}

sub fp_equal {
    my ($A, $B, $dp) = @_;

    return sprintf("%.${dp}g", $A) eq sprintf("%.${dp}g", $B);
}















































































1;  # so the require or use succeeds

