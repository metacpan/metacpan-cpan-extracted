package App::RoboBot::Type::Symbol;
$App::RoboBot::Type::Symbol::VERSION = '4.004';
use v5.20;

use namespace::autoclean;

use Moose;

extends 'App::RoboBot::Type';

has '+type' => (
    default => 'Symbol',
);

has '+value' => (
    is        => 'ro',
    isa       => 'Str',
    required  => 1,
    writer    => '_set_value',
);

around 'value' => sub {
    my ($orig, $self, $new) = @_;

    if (defined $new) {
        $new =~ s{^\:+}{};

        $self->_set_value($new);
    }

    return $self->$orig;
};

sub BUILD {
    my ($self) = @_;

    $self->_set_value($1) if $self->value =~ m{^\:+(.+)};
}

sub flatten {
    my ($self, $rpl) = @_;

    return ':' . $self->value;
}

__PACKAGE__->meta->make_immutable;

1;
