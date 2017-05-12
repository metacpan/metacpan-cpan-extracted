package App::RoboBot::Type::Vector;
$App::RoboBot::Type::Vector::VERSION = '4.004';
use v5.20;

use namespace::autoclean;

use Moose;

use Scalar::Util qw( blessed );

extends 'App::RoboBot::Type';

has '+type' => (
    default => 'Vector',
);

has '+value' => (
    is        => 'rw',
    isa       => 'ArrayRef',
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

    return '[]' unless $self->has_value && @{$self->value} > 0;
    return '[' . join(' ', map { $_->flatten($rpl) } @{$self->value}) . ']';
}

__PACKAGE__->meta->make_immutable;

1;
