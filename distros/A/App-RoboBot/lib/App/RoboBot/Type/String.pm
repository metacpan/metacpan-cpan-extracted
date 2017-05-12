package App::RoboBot::Type::String;
$App::RoboBot::Type::String::VERSION = '4.004';
use v5.20;

use namespace::autoclean;

use Moose;

extends 'App::RoboBot::Type';

has '+type' => (
    default => 'String',
);

has '+value' => (
    is        => 'rw',
    isa       => 'Str',
);

sub flatten {
    my ($self, $rpl) = @_;

    return 'nil' unless $self->has_value;

    my $v;

    if (defined $rpl && ref($rpl) eq 'HASH' && exists $rpl->{$self->value}) {
        $v = $rpl->{$self->value};
    } else {
        $v = $self->value;
    }

    $v =~ s{"}{\\"}g;
    $v =~ s{\n}{\\n}g;
    $v =~ s{\r}{\\r}g;
    $v =~ s{\t}{\\t}g;

    return '"' . $v . '"';
}

__PACKAGE__->meta->make_immutable;

1;
