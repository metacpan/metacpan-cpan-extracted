package TestObject::WithName;

use strict;
use warnings;

sub new {
    my $self = bless {} => shift || __PACKAGE__;
    if (@_) {
        $self->{name} = shift;
    }
    return $self;
}

sub name {
    my $self = shift;
    if (@_) {
        $self->{name} = shift;
    }
    $self->{name};
}

1;
