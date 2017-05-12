package App::RoboBot::Type::Map;
$App::RoboBot::Type::Map::VERSION = '4.004';
use v5.20;

use namespace::autoclean;

use Moose;

extends 'App::RoboBot::Type';

has '+type' => (
    default => 'Map',
);

has '+value' => (
    is        => 'rw',
    isa       => 'HashRef',
    default   => sub { {} },
);

sub evaluate {
    my ($self, $message, $rpl) = @_;

    return unless $self->has_value;

    my %h;

    foreach my $k (keys %{$self->value}) {
        my @r = $self->value->{$k}->evaluate($message, $rpl);

        if (@r && @r > 1) {
            $h{$k} = [@r];
        } elsif (@r) {
            $h{$k} = $r[0];
        } else {
            $h{$k} = undef;
        }
    }

    return \%h;
}

sub build_from_val {
    my ($class, $bot, $list) = @_;

    my %h;

    my ($k, $v);

    foreach my $e (@{$list}) {
        next unless defined $e && ref($e) =~ m{^App::RoboBot::Type};

        if ($e->type eq 'Symbol') {
            $k = $e->value;
            undef $v;
        } else {
            $v = $e;
        }

        return unless defined $k;
        $h{$k} = $v;
    }

    return $class->new(
        bot   => $bot,
        value => \%h,
    );
}

sub flatten {
    my ($self, $rpl) = @_;

    return '{}' unless $self->has_value && scalar(keys(%{$self->value})) > 0;
    return '{' .
        join(' ',
            map {
                sprintf(':%s %s',
                    $_,
                    (defined $self->value->{$_} ? $self->value->{$_}->flatten($rpl) : 'nil')
                )
            } keys %{$self->value}
        ) . '}';
}

__PACKAGE__->meta->make_immutable;

1;
