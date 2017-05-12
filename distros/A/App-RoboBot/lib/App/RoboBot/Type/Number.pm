package App::RoboBot::Type::Number;
$App::RoboBot::Type::Number::VERSION = '4.004';
use v5.20;

use namespace::autoclean;

use Moose;

extends 'App::RoboBot::Type';

has '+type' => (
    default => 'Number',
);

has '+value' => (
    is        => 'rw',
    isa       => 'Num',
);

sub flatten {
    my ($self, $rpl) = @_;

    return 'nil' unless $self->has_value;
    return '' . $self->value;
}

__PACKAGE__->meta->make_immutable;

1;
