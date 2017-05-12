package App::RoboBot::Type::Macro;
$App::RoboBot::Type::Macro::VERSION = '4.004';
use v5.20;

use namespace::autoclean;

use Moose;

use Scalar::Util qw( blessed );

extends 'App::RoboBot::Type';

has '+type' => (
    default => 'Macro',
);

has '+value' => (
    is        => 'rw',
    isa       => 'Str',
    required  => 1,
);

sub evaluate {
    my ($self, $message, $rpl, @args) = @_;

    return unless exists $self->bot->macros->{$message->network->id}{lc($self->value)};
    return $self->bot->macros->{$message->network->id}{lc($self->value)}->expand(
        $message,
        $rpl,
        map {
            blessed($_) && $_->can('evaluate')
            ? $_->evaluate($message, $rpl)
            : $_
        } @args
    );
}

sub flatten {
    my ($self, $rpl) = @_;

    return $self->value;
}

__PACKAGE__->meta->make_immutable;

1;
