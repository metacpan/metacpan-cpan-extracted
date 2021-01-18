#####################################################
# Helper classes
#####################################################

package Algorithm::CP::IZ::RefIntArray;
use strict;
use warnings;

sub new {
    my $class = shift;
    my $array = shift;

    my $ptr = Algorithm::CP::IZ::alloc_int_array([map { $_+0 } @$array]);
    bless \$ptr, $class;
}

sub DESTROY {
    my $self = shift;
    Algorithm::CP::IZ::free_array($$self);
}

1;
