package App::RoboBot::Type::Expression;
$App::RoboBot::Type::Expression::VERSION = '4.004';
use v5.20;

use namespace::autoclean;

use Moose;

use Scalar::Util qw( blessed );

extends 'App::RoboBot::Type';

has '+type' => (
    default => 'Expression',
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

    return unless defined $message && $message->isa('App::RoboBot::Message');
    return unless $self->has_value;

    my @r;

    if (defined $self->value->[0] && $self->value->[0]->type eq 'Function') {
        my ($fn, @args) = @{$self->value};

        return $fn->evaluate($message, $rpl, @args);
    } elsif (defined $self->value->[0] && $self->value->[0]->type eq 'Macro') {
        my ($macro, @args) = @{$self->value};

        return $macro->evaluate($message, $rpl, @args);
    } else {
        return map {
            blessed($_) && $_->can('evaluate')
            ? $_->evaluate($message, $rpl)
            : $_
        } @{$self->value};
    }
}

sub flatten {
    my ($self, $rpl) = @_;

    my $opener = $self->quoted ? "'(" : '(';

    return $opener . ')' unless $self->has_value && @{$self->value} > 0;
    return $opener . join(' ', map { $_->flatten($rpl) } @{$self->value}) . ')';
}

sub function {
    my ($self, $fn) = @_;

    if (defined $fn) {
        return unless ref($fn) eq 'App::RoboBot::Type::Function';

        if ($self->has_value) {
            if (defined $self->value->[0] && ref($self->value->[0]) eq 'App::RoboBot::Type::Function') {
                $self->value->[0] = $fn;
            } else {
                push(@{$self->value}, $fn);
            }
        } else {
            $self->value([$fn]);
        }
    }

    return unless $self->has_function;
    return $self->value->[0];
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
