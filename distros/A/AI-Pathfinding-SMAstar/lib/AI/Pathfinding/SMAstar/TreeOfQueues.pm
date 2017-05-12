#
# TreeOfQueues.pm
#
# An implementation of a binary tree of queues.
# This is a way to solve the problem of duplicate elements within
# a tree.  We want to remove elements from the tree in time oldest-first
# order.   In order to do this, a queue is located at each node in 
# the tree.   The queue contains objects with duplicate
# tree-keys.
#
# Author:  matthias beebe
# Date :  June 2008
#
#
package AI::Pathfinding::SMAstar::TreeOfQueues;
use strict;
use Tree::AVL;
use AI::Pathfinding::SMAstar::AVLQueue;


##################################################
# TreeOfQueues constructor 
##################################################
sub new {
    my $invocant = shift;
    my $class   = ref($invocant) || $invocant;
    my $self = {
	f_avl_compare => undef,
	f_obj_get_key  => undef,
	f_obj_get_data => undef,
	_avl_tree   => Tree::AVL->new(fcompare => \&AI::Pathfinding::SMAstar::AVLQueue::compare,
				      fget_key => \&AI::Pathfinding::SMAstar::AVLQueue::key,
				      fget_data => \&AI::Pathfinding::SMAstar::AVLQueue::key),
        @_, # attribute override
    };

    return bless $self, $class;
}


sub insert{
    my ($self, $obj) = @_;

    # check to see if there is a Queue in the tree with the key of obj.
    # if not, create one and insert
    my $fget_key = $self->{f_obj_get_key};
    my $avl_compare = $self->{f_avl_compare};
    my $key = $obj->$fget_key();
    my $queue = AI::Pathfinding::SMAstar::AVLQueue->new(_key => $key);

    my $found_queue = $self->{_avl_tree}->lookup_obj($queue);

    if(!$found_queue){
	$self->{_avl_tree}->insert($queue); # insert queue, with no duplicates	
	$queue->insert($obj); # insert object onto new queue
    }
    else { # found a queue here.  insert obj
	$found_queue->insert($obj);
    }
}


sub remove{
    my ($self, $obj, $cmp_func) = @_;

    # check to see if there is a Queue in the tree with the key of obj.
    # if not, create one and insert
    my $fget_key = $self->{f_obj_get_key};
    my $avl_compare = $self->{f_avl_compare};
    my $key = $obj->$fget_key();
    my $queue = AI::Pathfinding::SMAstar::AVLQueue->new(_key => $key);
    my $avltree = \$self->{_avl_tree};
    my $found_queue = $self->{_avl_tree}->lookup_obj($queue);



    if(!$found_queue){
#	print "TreeOfQueues::remove: did not find queue with key $key\n";
#	$self->{_avl_tree}->print();
    }
    else { # found a queue here.  remove obj
	#print "TreeOfQueues::remove: found queue, removing obj using $cmp_func\n";
	$found_queue->remove($obj, $cmp_func);
	if($found_queue->is_empty()){
	    #print "TreeOfQueues::remove: found queue is now empty, removing queue from tree\n";
	    $$avltree->remove($found_queue);	    
	}	
    }    
}

sub largest_oldest{
    my ($self) = @_;    
    my $avltree = \$self->{_avl_tree};

#    $$avltree->print("-");

    # get the avl tree with the largest key
    my $queue = $$avltree->largest();
    if($queue){
	my $key = $queue->key();
	my $obj = $queue->top();      
    	return $obj;
    }
    else{
	return;
    }
}


sub pop_largest_oldest{
    my ($self) = @_;    
    my $avltree = \$self->{_avl_tree};
    
#    $$avltree->print("*");
    
    # get the avl tree with the largest key
    my $queue = $$avltree->largest();
    if($queue){
	my $key = $queue->key();
	my $obj = $queue->pop_top();
	
	if($queue->is_empty()){
	    $$avltree->remove($queue);	    
	}	
	return $obj;
    }
    else{
	return;
    }
}

sub smallest_oldest{
    my ($self) = @_;    
    my $avltree = \$self->{_avl_tree};

#    $$avltree->print("-");

    # get the avl tree with the largest key
    my $queue = $$avltree->smallest();
    if($queue){
	my $key = $queue->key();
	my $obj = $queue->top();	
	return $obj;
    }
    else{
	return;
    }
}


sub pop_smallest_oldest{
    my ($self) = @_;    
    my $avltree = \$self->{_avl_tree};
    
#   $$avltree->print("*");
    
    # get the avl tree with the largest key
    my $queue = $$avltree->smallest();
    if($queue){
	my $key = $queue->key();
	my $obj = $queue->pop_top();
	
	if($queue->is_empty()){
	    $$avltree->remove($queue);	    	    
	}
	return $obj;
    }
    else{
	return;
    }
}


sub pop_oldest_at{
    my ($self, $key) = @_;    
    my $avltree = \$self->{_avl_tree};
    
    my $queue_to_find = AI::Pathfinding::SMAstar::AVLQueue->new(_key => $key);

    my $queue = $$avltree->lookup_obj($queue_to_find);

    if($queue){
#	print "TreeOfQueues::pop_oldest_at: found queue with key: $key\n";	
	my $obj = $queue->pop_top();
	if($queue->is_empty()){
	    $$avltree->remove($queue);	    	    
	}
	return $obj;
    }
    else{
#	print "TreeOfQueues::pop_oldest_at: did not find queue with key: $key\n";
	return;
    }
}




sub oldest_at{
    my ($self, $key) = @_;    
    my $avltree = \$self->{_avl_tree};
    
    my $queue_to_find = AI::Pathfinding::SMAstar::AVLQueue->new(_key => $key);

    my $queue = $$avltree->lookup_obj($queue_to_find);

    if($queue){
#	print "TreeOfQueues::oldest_at: found queue with key: $key\n";	
	my $obj = $queue->top();
	return $obj;
    }
    else{
#	print "TreeOfQueues::oldest_at: did not find queue with key: $key\n";
	return;
    }
}


sub largest{
    my ($self) = @_;    
    my $avltree = \$self->{_avl_tree};
    
    return $$avltree->largest();    
}





sub get_queue{
    my ($self, $key) = @_;    
    my $avltree = \$self->{_avl_tree};
    
    my $queue_to_find = AI::Pathfinding::SMAstar::AVLQueue->new(_key => $key);

    my $queue = $$avltree->lookup_obj($queue_to_find);

    if($queue){
#	print "TreeOfQueues::get_queue: found queue with key: $key\n";	
	return $queue;
    }
    else{
#	print "TreeOfQueues::get_queue: did not find queue with key: $key\n";
	return;
    }
}





sub get_keys_iterator
{
    my ($self) = @_;
    my $avltree = \$self->{_avl_tree};    
    return $$avltree->get_keys_iterator();
}


sub get_keys
{
    my ($self) = @_;    
    my $avltree = \$self->{_avl_tree};
    
    return $$avltree->get_keys();
}


sub print{
    my ($self) = @_;  

    if($self->{_avl_tree}->is_empty()){
	print "tree is empty\n";
    }

    my $get_key_func = $self->{f_obj_get_key};
    my $get_data_func = $self->{f_obj_get_data};

    my @queue_list = $self->{_avl_tree}->get_list();

    foreach my $queue (@queue_list){
	#print "queue is $queue\n";

	my $queue_key = $queue->key();
	#print "queue key: $queue_key\n";
	
	my @objlist = $queue->get_list();

	if(!@objlist){
	    print "queue at key $queue_key is empty\n";
	}

	print "queue at key $queue_key:\n";
	foreach my $obj (@objlist){
	    my $key = $obj->$get_key_func;
	    my $word = $obj->$get_data_func;
	    
	    print " key: $key, data: $word\n";
	}
    }
}



sub is_empty{    
    my ($self) = @_;
    if($self->{_avl_tree}->is_empty()){
	return 1;
    }
    return 0;
}



sub get_size{
    my ($self) = @_;  
    
    my $size = 0;
    
    if($self->{_avl_tree}->is_empty()){
	return $size;
    }
    
    my @queue_list = $self->{_avl_tree}->get_list();
    
    foreach my $queue (@queue_list){
	$size = $size + $queue->get_size();
    }
    return $size;
}

sub get_list{
    my ($self) = @_;  

    my @objs;

    if($self->{_avl_tree}->is_empty()){
	return;
    }

    #$self->{_avl_tree}->print(">>>");

    my @queue_list = $self->{_avl_tree}->get_list();

    foreach my $queue (@queue_list){
	my $queue_key = $queue->key();	


	my @objlist = $queue->get_list();	

	#print "get_list: size of queue at key: $queue_key is:  " . @objlist . "\n";

	push(@objs, @objlist);		 
    }
    return @objs;
}




1;
