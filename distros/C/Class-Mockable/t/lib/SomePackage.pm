package SomePackage;

use base ParentPackage;

use Class::Mockable
    _returnvalue => 94,
    methods => {
        _wrapped_method           => 'wrapped_method',
        _wrapped_method_in_parent => 'wrapped_method_in_parent',
    };

sub get_returnvalue {
    my $class = shift;
    return _returnvalue();
}

sub wrapped_method {
    my $class = shift;
    return "wrapped method";
}

1;
