#
# Queue.pm
#
# Implementation of a queue based on a binary tree
# A tree structure is used rather than a heap to allow 
# infrequent, but necessary, arbitrary access to elements 
# in the middle of the queue in log(n) time
# 
# This is primarily necessary to facilitat the SMAstar 
# path-finding algorithm.
#
#
# Author:  matthias beebe
# Date :  June 2008
#
#
package AI::Pathfinding::SMAstar::AVLQueue;

use Tree::AVL;
use AI::Pathfinding::SMAstar::PairObj;
use Carp;
use strict;



##################################################
#  AVLQueue constructor 
##################################################
sub new {
    my $invocant = shift;
    my $class   = ref($invocant) || $invocant;
    my $self = {
	_key         => undef, # for comparisons with other queues, etc.

	_avltree         => Tree::AVL->new(fcompare => \&AI::Pathfinding::SMAstar::AVLQueue::compare_obj_counters,
					   fget_key => \&AI::Pathfinding::SMAstar::AVLQueue::obj_counter,
					   fget_data => \&AI::Pathfinding::SMAstar::AVLQueue::obj_value),
	
	_counter     => 0,
	
	_obj_counts_tree => Tree::AVL->new(fcompare => \&AI::Pathfinding::SMAstar::PairObj::compare_keys_numeric,
					   fget_key => \&AI::Pathfinding::SMAstar::PairObj::key,
					   fget_data => \&AI::Pathfinding::SMAstar::PairObj::val),
		
        @_,    # Override previous attributes
    };
    return bless $self, $class;
}



##############################################
# accessor
##############################################

sub key
{
    my $self = shift;
    if (@_) { $self->{_key} = shift }
    return $self->{_key};	
}





#############################################################################
#
# other methods
#
#############################################################################


sub get_keys_iterator
{
    my ($self) = @_;
    return $self->{_obj_counts_tree}->get_keys_iterator();
}



sub compare_obj_counters{
    my ($obj, $arg_obj) = @_;

     if ($arg_obj){
	my $arg_key = $arg_obj->{_queue_counter};
	my $key = $obj->{_queue_counter};
	
	if($arg_key > $key){
	    return(-1);
	}
	elsif($arg_key == $key){
	    return(0);
	}
	elsif($arg_key < $key){
	    return(1);
	}	
    }
    else{
	croak "AVLQueue::compare_obj_counters: error: null argument object\n";
    }
}


sub obj_counter{
    my ($obj) = @_;
    return $obj->{_queue_counter};
}

sub obj_value{
    my ($obj) = @_;
    return $obj->{_value};
}



sub compare {
    my ($self, $arg_obj) = @_;

    if ($arg_obj){
	my $arg_key = $arg_obj->{_key};
	my $key = $self->{_key};
	
	if($arg_key > $key){
	    return(-1);
	}
	elsif($arg_key == $key){
	    return(0);
	}
	elsif($arg_key < $key){
	    return(1);
	}	
    }
    else{
	croak "AVLQueue::compare error: null argument object\n";
    }
}

sub lookup {    
    my ($self, $obj) = @_;        
    my $found_obj = $self->{_avltree}->lookup_obj($obj);

    if(!$found_obj){
	croak "AVLQueue::lookup:  did not find obj in queue\n";
	return;
    }    
    return $found_obj;
}

sub lookup_by_key {    
    my ($self, $key) = @_;    
    my $pair =  AI::Pathfinding::SMAstar::PairObj->new(
	_queue_counter => $key,
	);	       
    my $found_obj = $self->{_avltree}->lookup_obj($pair);

    if(!$found_obj){
	croak "AVLQueue::lookup:  did not find obj in queue\n";
	return;
    }    
    return $found_obj;
}


sub remove {
    my ($self, $obj, $compare_func) = @_;
    my $found_obj;
    
    $found_obj = $self->{_avltree}->remove($obj);

    if(!$found_obj){
	croak "AVLQueue::remove:  did not find obj in queue\n";
	return;
    }
    
    my $count = $found_obj->{_queue_counter};
   

    my $pairobj = AI::Pathfinding::SMAstar::PairObj->new(_key => $count,
			       _value => $count);
    $self->{_obj_counts_tree}->remove($pairobj);

    return $found_obj;
}



sub is_empty
{
    my ($self) = @_; 
    
    if($self->{_avltree}->is_empty()){
	return 1;
    }
    return 0;    
}


sub insert
{
    my ($self,
	$obj) = @_;
        
    my $count = $self->{_counter};

    $obj->{_queue_counter} = $count;       
    $self->{_avltree}->insert($obj);
    


    my $pairobj = AI::Pathfinding::SMAstar::PairObj->new(_key => $count,
			       _value => $count);
    $self->{_obj_counts_tree}->insert($pairobj);

    $self->{_counter} = $self->{_counter} + 1;

    
    return;
}


sub pop_top
{
    my ($self) = @_;
   
    my $top = $self->{_avltree}->pop_smallest();
    my $count = $top->{_queue_counter};
  

    my $pairobj = AI::Pathfinding::SMAstar::PairObj->new(_key => $count,
			       _value => $count);
    $self->{_obj_counts_tree}->remove($pairobj);


    return $top;
}



sub top
{
    my ($self) = @_;
    
    my $top = $self->{_avltree}->smallest();
    return $top;
    

}


sub get_list{
    my ($self) = @_;
    return $self->{_avltree}->get_list();
}


sub get_size{
    my ($self) = @_;
    my $avltree = $self->{_avltree};
    my $size = $avltree->get_size();    
    return $size;
}


sub print{
    my ($self, $delim) = @_;
    my @tree_elts = $self->{_avltree}->get_list(); 
    
    foreach my $obj (@tree_elts){
	print $obj->{_start_word} . ", " . $obj->{_phrase} . ", " . $obj->{_queue_counter} . "\n";
	
    }

     print "\n\nobj_counts_tree:\n";
    $self->{_obj_counts_tree}->print("*");



    my $iterator = $self->{_obj_counts_tree}->get_keys_iterator();
    print "\n\niterator keys:\n";
    while(defined(my $key = $iterator->())){
	print "iterator key: $key\n";
    }
    

}




1;
