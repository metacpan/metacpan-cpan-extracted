package AI::Pathfinding::SMAstar::PairObj;
use strict;

##################################################
# PairObj constructor
##################################################
sub new {
    my $invocant = shift;
    my $class   = ref($invocant) || $invocant;
    my $self = {
	_key    => undef,
        _value  => undef,      
        @_,  # Override previous attributes
    };
    return bless $self, $class;
}

##############################################
# accessors
##############################################
sub value {
    my $self = shift;
    if (@_) { $self->{_value} = shift }
    return $self->{_value};
}

sub val {
    my $self = shift;
    if (@_) { $self->{_value} = shift }
    return $self->{_value};
}

sub key {
    my $self = shift;
    if (@_) { $self->{_key} = shift }
    return $self->{_key};
}




# compare_vals
#
# usage:  $pair_obj->compare($other_pair_obj)
#
# Accepts another PairObj object as an argument.
# Returns 1 if greater than argument, 0 if equal, and -1 if 
# less than argument
sub compare_vals{
    my ($self,$arg_obj) = @_;
    
    my $arg_value = $arg_obj->{_value};
    my $value = $self->{_value};
    
    if($arg_value gt $value){
	return -1;
    }
    elsif($arg_value eq $value){
	return 0;
    }
    return 1;	    
}


# compare_keys
#
# usage:  $pair_obj->compare($other_pair_obj)
#
# Accepts another PairObj object as an argument.
# Returns 1 if greater than argument, 0 if equal, and -1 if 
# less than argument
sub compare_keys{
    my ($self,$arg_obj) = @_;
    
    my $arg_key = $arg_obj->{_key};
    my $key = $self->{_key};
    
    if($arg_key gt $key){
	return -1;
    }
    elsif($arg_key eq $key){
	return 0;
    }
    return 1;	    
}


sub compare_keys_numeric{
    my ($self,$arg_obj) = @_;
    
    my $arg_key = $arg_obj->{_key};
    my $key = $self->{_key};
    
    if($arg_key > $key){
	return -1;
    }
    elsif($self->fp_equal($arg_key, $key, 10)){
	return 0;
    }
    return 1;	    
}




sub fp_equal {
    my ($self, $A, $B, $dp) = @_;

    return sprintf("%.${dp}g", $A) eq sprintf("%.${dp}g", $B);
}




1;  # so the require or use succeeds

