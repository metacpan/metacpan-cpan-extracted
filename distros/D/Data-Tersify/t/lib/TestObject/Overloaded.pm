package TestObject::Overloaded;

use strict;
use warnings;
no warnings 'uninitialized';

# Deliberately not using a method name like "to_string", "stringify"
# or anything here to make sure that the code is actually looking at the
# overloaded nature of the object.
use overload '""' => sub {
    my ($self) = @_;

    return 'An object which was passed ' . ($self->{param} // 'nothing');
};

sub new {
    my $package = shift || __PACKAGE__;
    my $self = bless { param => shift } => $package;
    return $self;
}

1;
