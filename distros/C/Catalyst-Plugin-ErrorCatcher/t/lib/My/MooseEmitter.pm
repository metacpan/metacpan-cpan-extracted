package My::MooseEmitter;
# vim: ts=8 sts=4 et sw=4 sr sta
use Moose;

has c => (
    is          => 'ro',
    init_arg    => 'c',
);

has jason => (
    is          => 'rw',
    default     => 'tired',
);

has faked_value => (
    is          => 'rw',
    init_arg    => 'faked_config_value',
    required    => 1,
);

has from_config => (
    is          => 'ro',
    init_arg    => 'some_config_value',
    required    => 1,
);

sub BUILDARGS {
   my ($class, $args) = @_; 

   $args->{faked_config_value} = 'not really here';

   return {
       %{$args},
       %{ $args->{c}->config->{$class} }
   };
}

sub BUILD {
    my $self = shift;
    $self->c->config->{"My::MooseEmitter"}{set_in_new} = 1;
    return 1;
}

sub emit {
    my $self    = shift;
    my $c       = shift;
    my $output  = shift;
    $self->c->config->{"My::MooseEmitter"}{set_in_emit} = 1;
}

1;
