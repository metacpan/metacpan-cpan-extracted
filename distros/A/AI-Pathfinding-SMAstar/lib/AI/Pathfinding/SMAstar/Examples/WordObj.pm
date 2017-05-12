package AI::Pathfinding::SMAstar::Examples::WordObj;
use strict;

##################################################
## the object constructor (simplistic version)  ##
##################################################
sub new {
    my $invocant = shift;
    my $class   = ref($invocant) || $invocant;
    my $self = {
        _word  => undef,      
        @_,                 # Override previous attributes
    };
    return bless $self, $class;
}

##############################################
## methods to access per-object data        ##
##                                          ##
## With args, they set the value.  Without  ##
## any, they only retrieve it/them.         ##
##############################################
sub word {
    my $self = shift;
    if (@_) { $self->{_word} = shift }
    return $self->{_word};
}



# compare
#
# usage:  $word_obj->compare($other_word_obj)
#
# Accepts another WordObj object as an argument.
# Returns 1 if greater than argument, 0 if equal, and -1 if 
# less than argument
sub compare{
    my ($self,$arg_wordobj) = @_;
    
    my $arg_word = $arg_wordobj->{_word};
    my $word = $self->{_word};
    
    if($arg_word gt $word){
	return -1;
    }
    elsif($arg_word eq $word){
	return 0;
    }
    return 1;	    
}


# compare_up_to
#
# usage:  $word_obj->compare_up_to($other_word_obj)
#
# Accepts another WordObj object as an argument.
# Returns 1 if greater than argument, 0 if $other_word_obj 
# is a substring of $word_obj
# that appears at the beginning of $word_obj 
# and -1 if less than argument $other_word_obj
sub compare_up_to{
    my $self = shift;
    if (@_){
	my $arg_wordobj = shift;
	my $arg_word = $arg_wordobj->{_word};
	my $word = $self->{_word};
       	
	# perl's index function works like: index($string, $substr);
	if(index($word, $arg_word) == 0){
	    return(0);
	}
	elsif($arg_word gt $word){
	    return(-1);
	}       
	elsif($arg_word lt $word){
	    return(1);
	}	
    }    
}


# compare_up_to
#
# usage:  $word_obj->compare_down_to($other_word_obj)
#
# Returns 0 if $word_obj is a substring of 
# $other_word_obj, that appears at the beginning
# of $other_word_obj.
#
sub compare_down_to{
    my $self = shift;
    if (@_){
	my $arg_wordobj = shift;
	my $arg_word = $arg_wordobj->{_word};
	my $word = $self->{_word};
	
	# perl's index function works like: index($string, $substr);
	if(index($arg_word, $word) == 0){
	    return(0);
	}
	elsif($arg_word gt $word){
	    return(-1);
	}       
	elsif($arg_word lt $word){
	    return(1);
	}	
    }    
}






1;  # so the require or use succeeds

