#####################################################
# Helper classes
#####################################################

package Algorithm::CP::IZ::RefVarArray;

sub new {
    my $class = shift;
    my $array = shift;

    my $ptr = Algorithm::CP::IZ::alloc_var_array([map { $_->{_ptr } } @$array]);
    bless \$ptr, $class;
}

sub DESTROY {
    my $self = shift;
    Algorithm::CP::IZ::free_array($$self);
}

1;
