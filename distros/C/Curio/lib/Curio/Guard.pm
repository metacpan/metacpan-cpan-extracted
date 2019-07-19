package Curio::Guard;

use strictures 2;
use namespace::clean;

sub new {
    my ($class, $sub) = @_;

    my $self = bless { sub=>$sub }, $class;

    return $self;
}

sub DESTROY {
    my ($self) = @_;

    my $sub = $self->{sub};
    $sub->() if $sub;

    return;
}

1;
