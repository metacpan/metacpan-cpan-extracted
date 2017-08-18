package TestObject::WithUUID;

use strict;
use warnings;

sub new {
    my $self = bless {} => shift || __PACKAGE__;
    if (@_) {
        $self->{uuid} = shift;
    }
    return $self;
}

sub uuid {
    my $self = shift;
    if (@_) {
        $self->{uuid} = shift;
    }
    $self->{uuid};
}

1;
