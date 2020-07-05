package HashCondition;

use strict;
use warnings;
use utf8;

sub new {
    my $class = shift;
    my $self  = {};
    $self->{ID}    = shift;
    $self->{Name}  = shift;
    $self->{State} = shift;
    bless( $self, $class );
    return $self;
}

sub ID {
    my $self = shift;
    if (@_) { $self->{ID} = shift; }
    return $self->{ID};
}

sub Name {
    my $self = shift;
    if (@_) { $self->{Name} = shift; }
    return $self->{Name};
}

sub State {
    my $self = shift;
    if (@_) { $self->{State} = shift; }
    return $self->{State};
}

1;
