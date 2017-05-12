package Ambrosia::Utils::Queue;
use strict;
use warnings;

use Ambrosia::Meta;

class sealed
{
    private => [qw/__list __strategy/]
};

our $VERSION = 0.010;

use Ambrosia::Utils::Enumeration property => __strategy => (STRATEGY_LIFO => 1, STRATEGY_FIFO => 2);

sub _init
{
    my $self = shift;
    $self->SUPER::_init(@_);
    $self->__list ||= [];
    $self->SET_STRATEGY_FIFO();
}

sub add
{
    my $self = shift;
    push @{$self->__list}, @_;
    $self;
}

sub inhead
{
    my $self = shift;
    unshift @{$self->__list}, @_;
    $self;
}

sub next()
{
    my $self = shift;

    if ( $self->IS_STRATEGY_LIFO )
    {
        return pop @{$self->__list};
    }
    else
    {
        return shift @{$self->__list};
    }
}

sub last()
{
    my $self = shift;

    return undef unless $self->size();

    if ( $self->IS_STRATEGY_LIFO )
    {
        return $self->__list->[0];
    }
    else
    {
        return $self->__list->[-1];
    }
}

sub head()
{
    my $self = shift;

    if ( $self->IS_STRATEGY_LIFO )
    {
        return pop @{$self->__list};
    }
    else
    {
        return shift @{$self->__list};
    }
}

sub first()
{
    my $self = shift;

    return undef unless $self->size();

    if ( $self->IS_STRATEGY_LIFO )
    {
        return $self->__list->[-1];
    }
    else
    {
        return $self->__list->[0];
    }
}

sub size()
{
    return scalar @{$_[0]->__list};
}

sub clear()
{
    $_[0]->__list = [];
    $_[0];
}

sub reset
{
    shift()->clear->add(@_);
}

1;

__END__

=head1 NAME

Ambrosia::Utils::Queue - creates queue with two strategy LIFO and FIFO.

=head1 VERSION

version 0.010

=head1 DESCRIPTION

C<Ambrosia::Utils::Queue> creates queue with two strategy LIFO and FIFO.

=head1 CONSTRUCTOR

=head1 THREADS

Not tested.

=head1 BUGS

Please report bugs relevant to C<Ambrosia> to <knm[at]cpan.org>.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010-2012 Nickolay Kuritsyn. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Nikolay Kuritsyn (knm[at]cpan.org)

=cut
