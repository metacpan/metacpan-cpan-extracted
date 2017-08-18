package TestObject;

use strict;
use warnings;

sub new {
    my $self = bless {} => shift || __PACKAGE__;
    if (@_) {
        $self->{id} = shift;
    }
    return $self;
}

sub id {
    my $self = shift;
    if (@_) {
        $self->{id} = shift;
    }
    $self->{id};
}

1;
