package Bot::Cobalt::Conf;
$Bot::Cobalt::Conf::VERSION = '0.021003';
use strictures 2;
use Carp;

use Bot::Cobalt::Common ':types';

use Bot::Cobalt::Conf::File::Core;
use Bot::Cobalt::Conf::File::Channels;
use Bot::Cobalt::Conf::File::Plugins;

use Path::Tiny;
use Types::Path::Tiny -types;

use Scalar::Util 'blessed';


use Moo;

has etc => (
  required  => 1,
  is        => 'rw',
  isa       => Path,
  coerce    => 1,
);

has debug => (
  is        => 'rw',
  isa       => Bool,
  builder   => sub { 0 }
);

has path_to_core_cf => (
  lazy      => 1,
  is        => 'rwp',
  isa       => Path,
  coerce    => 1,
  builder   => sub {
    path( shift->etc .'/cobalt.conf' )
  },
);

has path_to_channels_cf => (
  lazy      => 1,
  is        => 'rwp',
  isa       => Path,
  coerce    => 1,
  builder   => sub {
    path( shift->etc .'/channels.conf' )
  },
);

has path_to_plugins_cf => (
  lazy      => 1,
  is        => 'rwp',
  isa       => Path,
  coerce    => 1,
  builder   => sub {
    path( shift->etc .'/plugins.conf' )
  },
);


has core => (
  lazy      => 1,
  is        => 'ro',
  predicate => 'has_core',
  writer    => 'set_core',
  isa       => InstanceOf['Bot::Cobalt::Conf::File::Core'],
  builder   => sub {
    my ($self) = @_;
    Bot::Cobalt::Conf::File::Core->new(
      debug     => $self->debug,
      cfg_path  => $self->path_to_core_cf,
    )
  },
);

has channels => (
  lazy      => 1,
  is        => 'ro',
  predicate => 'has_channels',
  writer    => 'set_channels',
  isa       => InstanceOf['Bot::Cobalt::Conf::File::Channels'],
  builder   => sub {
    my ($self) = @_;
    Bot::Cobalt::Conf::File::Channels->new(
      debug     => $self->debug,
      cfg_path  => $self->path_to_channels_cf,
    )
  },
);

has plugins => (
  lazy      => 1,
  is        => 'ro',
  predicate => 'has_plugins',
  writer    => 'set_plugins',
  isa       => InstanceOf['Bot::Cobalt::Conf::File::Plugins'],
  builder   => sub {
    my ($self) = @_;
    Bot::Cobalt::Conf::File::Plugins->new(
      debug     => $self->debug,
      cfg_path  => $self->path_to_plugins_cf,
      etcdir    => $self->etc,
    )
  },
);


1;
__END__

=pod

=head1 NAME

Bot::Cobalt::Conf - Bot::Cobalt configuration manager

=head1 SYNOPSIS

  my $cfg = Bot::Cobalt::Conf->new(
    etc => $path_to_etc_dir,
  );

  ## Or with specific paths
  ## (Still need an etcdir)
  my $cfg = Bot::Cobalt::Conf->new(
    etc => $path_to_etc_dir,

    # Default paths are probably fine (based on etc, above):
    path_to_core_cf     => $core_cf_path,
    path_to_channels_cf => $chan_cf_path,
    path_to_plugins_cf  => $plugins_cf_path,
  );

  ## Bot::Cobalt::Conf::File::Core
  $cfg->core;

  ## Bot::Cobalt::Conf::File::Channels
  $cfg->channels;

  ## Bot::Cobalt::Conf::File::Plugins
  $cfg->plugins;

=head1 DESCRIPTION

A configuration manager class for L<Bot::Cobalt> -- L<Bot::Cobalt::Core>
loads and accesses configuration objects via instances of this class.

=head1 SEE ALSO

L<Bot::Cobalt::Conf::File::Core>

L<Bot::Cobalt::Conf::File::Channels>

L<Bot::Cobalt::Conf::File::Plugins>

L<Bot::Cobalt::Conf::File::PerPlugin>

L<Bot::Cobalt::Conf::File>

=head1 AUTHOR

Jon Portnoy <avenj@cobaltirc.org>

=cut
