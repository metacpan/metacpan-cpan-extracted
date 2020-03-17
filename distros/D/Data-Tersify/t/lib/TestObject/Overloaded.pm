package TestObject::Overloaded;

use strict;
use warnings;
no warnings 'uninitialized';

# Deliberately not using a method name like "to_string", "stringify"
# or anything here to make sure that the code is actually looking at the
# overloaded nature of the object.
use overload '""' => sub {
    my ($self) = @_;

    # Grrr, can't use $self->{param} // 'nothing' because that doesn't work
    # on archaic Perls like 5.8.9.
    my $param = $self->{param};
    if (!defined $param) {
        $param = 'nothing';
    }
    return "An object which was passed $param";
};

sub new {
    my $package = shift || __PACKAGE__;
    my $self = bless { param => shift } => $package;
    return $self;
}

1;
