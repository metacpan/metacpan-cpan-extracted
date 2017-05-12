package App::RoboBot::Type::List;
$App::RoboBot::Type::List::VERSION = '4.004';
use v5.20;

use namespace::autoclean;

use Moose;

use Scalar::Util qw( blessed );

extends 'App::RoboBot::Type';

has '+type' => (
    default => 'List',
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

    my $opener = $self->quoted ? "'(" : '(';

    return $opener . ')' unless $self->has_value && @{$self->value} > 0;
    return $opener . join(' ', map { $_->flatten($rpl) } @{$self->value}) . ')';
}

sub has_function {
    my ($self) = @_;

    return 1
        if $self->has_value
        && defined $self->value->[0]
        && ref($self->value->[0]) eq 'App::RoboBot::Type::Function';
    return 0;
}

__PACKAGE__->meta->make_immutable;

1;
