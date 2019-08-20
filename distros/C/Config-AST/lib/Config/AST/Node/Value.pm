package Config::AST::Node::Value;
use parent 'Config::AST::Node';
use strict;
use warnings;

=head1 NAME

Config::AST::Node::Value - simple statement node

=head1 DESCRIPTION

Implements a simple statement node. Simple statement is always associated
with a value, hence the class name.    

=cut    

sub new {
    my $class = shift;
    local %_ = @_;
    my $v = delete $_{value};
    my $self = $class->SUPER::new(%_);
    $self->value($v);
    return $self;
}

=head1 METHODS

=head2 $node->value

Returns the value associated with the statement.

If value is a code reference, it is invoked without arguments, and its
return is used as value.    
    
If the value is a reference to a list or hash, the return depends on the
context. In scalar context, the reference itself is returned. In list
context, the array or hash is returned.

=cut    

sub value {
    my ($self, $val) = @_;

    if (defined($val)) {
	$self->{_value} = $val;
	return; # Avoid evaluatig value too early
    } else {
	$val = $self->{_value};
    }
    
    if (ref($val) eq 'CODE') {
	$val = &$val;
    }

    if (wantarray) {
	if (ref($val) eq 'ARRAY') {
	    return @$val
	} elsif (ref($val) eq 'HASH') {
	    return %$val
        }
    }
    
    return $val;
}

=head2 bool = $node->is_leaf

Returns false.

=cut    
    
sub is_leaf { 1 };

=head2 $s = $node->as_string

Returns the node value, converted to string.

=cut    

sub as_string {
    my $self = shift;
    return $self->value
}

=head1 SEE ALSO

B<Config::AST>,    
B<Config::AST::Node>.

=cut    

1;
