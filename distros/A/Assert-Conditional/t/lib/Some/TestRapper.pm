package 
    Some::TestRapper;

use Moose;
use Assert::Conditional qw(:all);

has data => (
    isa         => "Str",
    is          => "rw",
    predicate   => "my_data",
    clearer     => "clear_data",
);  

sub their_data {
    assert_public_method;
    my($self) = @_; 
    return $self->my_data ? 1 : 0;
}   

sub our_data {
    assert_protected_method;
    my($self) = @_; 
    return $self->my_data ? 1 : 0;
}

around my_data => sub {
    my($next, $self, @args) = @_; 
    assert_private_method;
    $self->$next(@args);
};  

before my_data => sub {
    my($self, @args) = @_; 
    assert_private_method;
};  

around my_data => sub {
    my($next, $self, @args) = @_; 
    assert_private_method;
    $self->$next(@args);
};  

after my_data => sub {
    my($self, @args);
    assert_private_method;
};   

1;
