package Test::WibbleObject;
use strict;
use warnings;

sub new {
    my $self = {};
    $self->{name} = undef;
    bless($self);
    return $self;
}

sub name {
    my $self = shift;
    if (@_) { $self->{name} = shift };
    return $self->{name};
}

sub TO_JSON {
    my $self = shift;
    return { name => $self->name };
}

1;
