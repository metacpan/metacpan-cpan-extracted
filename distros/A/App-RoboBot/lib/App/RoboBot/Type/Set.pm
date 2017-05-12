package App::RoboBot::Type::Set;
$App::RoboBot::Type::Set::VERSION = '4.004';
use v5.20;

use namespace::autoclean;

use Moose;

use Scalar::Util qw( blessed );

extends 'App::RoboBot::Type';

has '+type' => (
    default => 'Set',
);

has '+value' => (
    is        => 'rw',
    isa       => 'ArrayRef',
    default   => sub { [] },
);

sub ast {
    my ($self) = @_;

    my $ast = [];

    if ($self->has_value) {
        push(@{$ast}, $_->ast) foreach @{$self->value};
    }

    return $self->type, $ast;
}

sub evaluate {
    my ($self, $message, $rpl) = @_;

    return unless $self->has_value;
    return map {
        blessed($_) && $_->can('evaluate')
        ? $_->evaluate($message, $rpl)
        : $_
    } @{$self->value};
}

sub flatten {
    my ($self, $rpl) = @_;

    return '||' unless $self->has_value && @{$self->value} > 0;
    return '|' . join(' ', map { $_->flatten($rpl) } @{$self->value}) . '|';
}

sub union {
    return unless __PACKAGE__->_two_sets_only(@_);

    my ($set_a, $set_b) = @_;

    if ($set_a->size == 0 || $set_b->size == 0) {
        return __PACKAGE__->new( bot => $set_a->bot, value => [] );
    }

    my @new_set;

    foreach my $v (@{$set_a->value}) {
        push(@new_set, $v);
    }

    foreach my $v (@{$set_b->value}) {
        push(@new_set, $v) unless $set_a->contains($v);
    }

    return __PACKAGE__->new( bot => $set_a->bot, value => \@new_set );
}

sub intersection {
    return unless __PACKAGE__->_two_sets_only(@_);

    my ($set_a, $set_b) = @_;

    if ($set_a->size == 0 || $set_b->size == 0) {
        return __PACKAGE__->new( bot => $set_a->bot, value => [] );
    }

    my @new_set;

    foreach my $v (@{$set_a->value}) {
        push(@new_set, $v) if $set_b->contains($v);
    }

    return __PACKAGE__->new( bot => $set_a->bot, value => \@new_set );
}

sub set_difference {
    return unless __PACKAGE__->_two_sets_only(@_);

    my ($set_a, $set_b) = @_;

    if ($set_a->size == 0 || $set_b->size == 0) {
        return __PACKAGE__->new( bot => $set_a->bot, value => [] );
    }

    my @new_set;

    foreach my $v (@{$set_a->value}) {
        push(@new_set, $v) unless $set_b->contains($v);
    }

    return __PACKAGE__->new( bot => $set_a->bot, value => \@new_set );
}

sub symmetric_difference {
    return unless __PACKAGE__->_two_sets_only(@_);

    my ($set_a, $set_b) = @_;

    if ($set_a->size == 0 || $set_b->size == 0) {
        return __PACKAGE__->new( bot => $set_a->bot, value => [] );
    }

    my @new_set;

    foreach my $v (@{$set_a->value}) {
        push(@new_set, $v) unless $set_b->contains($v);
    }

    foreach my $v (@{$set_b->value}) {
        push(@new_set, $v) unless $set_a->contains($v);
    }

    return __PACKAGE__->new( bot => $set_a->bot, value => \@new_set );
}

sub contains {
    my ($self, $value) = @_;

    return 0 if $self->size == 0;
    return 1 if grep { $_->cmp($value) } @{$self->value};
    return 0;
}

sub size {
    my ($self) = @_;

    return 0 unless $self->has_value;
    return scalar(@{$self->value});
}

sub _two_sets_only {
    my ($class, $set_a, $set_b, @rest) = @_;

    # Failure if there were more than two objects. @rest should have been empty.
    return 0 if @rest && @rest > 0;

    # Failure if either A or B are undefined.
    return 0 unless defined $set_a && defined $set_b;

    # Failure if either A or B is not a App::RoboBot::Type::Set object.
    return 0 unless ref($set_a) eq $class && ref($set_b) eq $class;

    # All good. Only had two arguments and both were defined as ::Set objects.
    return 1;
}

__PACKAGE__->meta->make_immutable;

1;
