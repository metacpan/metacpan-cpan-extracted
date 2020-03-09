package TestObject::Overloaded::JustImport;

# A test object that imports overload but doesn't actually overload any
# operators.

use strict;
use warnings;
no warnings 'uninitialized';

use overload;

sub new {
    my $package = shift || __PACKAGE__;
    my $self = bless { param => shift } => $package;
    return $self;
}

1;
