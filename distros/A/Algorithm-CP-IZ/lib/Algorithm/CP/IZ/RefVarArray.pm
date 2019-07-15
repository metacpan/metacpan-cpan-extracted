#####################################################
# Helper classes
#####################################################

package Algorithm::CP::IZ::RefVarArray;
use strict;
use warnings;

sub new {
    my $class = shift;
    my $array = shift;

    my $ptr = Algorithm::CP::IZ::alloc_var_array([map { $$_ } @$array]);
    bless \$ptr, $class;
}

sub ptr {
    my $self = shift;
    return $$self;
}

sub DESTROY {
    my $self = shift;
    Algorithm::CP::IZ::free_array($$self);
}

1;
