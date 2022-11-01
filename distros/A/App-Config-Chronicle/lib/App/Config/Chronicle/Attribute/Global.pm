package App::Config::Chronicle::Attribute::Global;

use Moose;
extends 'App::Config::Chronicle::Attribute';

our $VERSION = '0.07';    ## VERSION

=head1 NAME

App::Config::Chronicle::Attribute::Global

=cut

sub _build_value {
    my $self = shift;
    my $value;
    $value //= $self->data_set->{app_settings_overrides}->get($self->path) if ($self->data_set->{app_settings_overrides});
    $value //= $self->data_set->{global}->get($self->path)                 if ($self->data_set->{global});
    $value //= $self->data_set->{app_config}->get($self->path)             if ($self->data_set->{app_config});
    $value //= $self->definition->{default}                                if ($self->definition);

    return $value;
}

sub _set_value {
    my $self  = shift;
    my $value = shift;
    $self->data_set->{global}->set($self->path, $value) if ($self->data_set->{global});
    return;
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;
