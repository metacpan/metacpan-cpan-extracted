package TestObject::Overloaded::OtherOperator;

# A test object that imports overload and overloads something other than
# stringification. It calls the method it uses to_string just to make sure
# that we don't look for this method naively.

use strict;
use warnings;
no warnings 'uninitialized';

use overload '+' => \&to_string;

sub to_string {
    return 'Clearly wrong';
}

sub new {
    my $package = shift || __PACKAGE__;
    my $self = bless { param => shift } => $package;
    return $self;
}

1;
