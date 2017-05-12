package App::Config::Chronicle::Attribute;

use Moose;
extends 'App::Config::Chronicle::Node';
use namespace::autoclean;
use JSON::XS qw( decode_json );

use MooseX::Types -declare => ['LongStr'];
use Moose::Util::TypeConstraints;
use Try::Tiny;

our $VERSION = '0.06';    ## VERSION

subtype 'LongStr', as 'Str';

=head1 NAME

App::Config::Chronicle::Attribute

=head1 ATTRIBUTES

=cut

has 'version' => (
    is => 'rw',
);

sub _check_type {
    my ($self, $value) = @_;
    my $def = $self->{definition};
    $self->{_json_string} //= $def->{isa} eq 'json_string' ? 1 : 0;
    if ($self->{_json_string}) {
        try { $value = decode_json($value) } catch { die "Couldn't decode JSON attribute $value: $_" };
    } else {
        $self->{_type_constraint} //= find_type_constraint($def->{isa});
        unless ($self->{_type_constraint}) {
            die "Couldn't find type constraint for " . $def->{isa} . " for " . $self->name;
        }
        $self->{_type_constraint}->check($value) or die $self->name . " expecting a value of type " . $def->{isa};
    }
    return;
}

=head2 value

=cut

sub value {
    my ($self, $value) = @_;

    if (defined $value) {
        $self->_check_type($value);
        $self->{_value} = $value;
        $self->_set_value($value);
        $self->version($self->data_set->{version});    #Avoids building after set unless version changed.
    } else {
        if (not $self->version or $self->version ne $self->data_set->{version}) {
            my $val = $self->_build_value;
            if (defined $val) {
                $self->value($val);
                $self->version($self->data_set->{version});
            }
        }
    }

    return $self->{_value};
}

=head2 build

=cut

sub build {
    my $self    = shift;
    my $default = $self->definition->{default};
    $self->_check_type($default);
    $self->{_value} = $default;
    return $self;
}

sub _build_value {
    my $self = shift;
    my $value;
    $value //= $self->data_set->{app_config}->get($self->path) if ($self->data_set->{app_config});
    $value //= $self->definition->{default} if ($self->definition);

    return $value;
}

sub _set_value {
    return;
}

__PACKAGE__->meta->make_immutable;

1;
