package Bot::Cobalt::Conf::File::PerPlugin;
$Bot::Cobalt::Conf::File::PerPlugin::VERSION = '0.021003';
## This is in File:: but NOT a subclass of File.pm

use strictures 2;
use Carp;

use Bot::Cobalt::Common ':types';

use Scalar::Util 'blessed';

use Types::Path::Tiny -types;

use Moo;
with 'Bot::Cobalt::Conf::Role::Reader';


has module => (
  required  => 1,  
  is        => 'rwp',
  isa       => Str,
);

has extra_opts => (
  ## Overrides the plugin-specific cfg.
  lazy      => 1,
  is        => 'ro',
  isa       => HashRef,
  predicate => 'has_extra_opts',
  writer    => 'set_extra_opts',
);

has priority => (
  lazy      => 1,  
  is        => 'ro',
  isa       => Num,
  writer    => 'set_priority',
  predicate => 'has_priority',  
  default   => sub { 1 },
);

has config_file => (
  lazy      => 1,
  is        => 'ro',
  isa       => Path,
  coerce    => 1,
  writer    => 'set_config_file',
  predicate => 'has_config_file',
);

has autoload => (
  lazy      => 1,
  is        => 'ro',
  isa       => Bool,
  default   => sub { 1 },
);

has opts => (
  lazy      => 1,
  is        => 'rwp',
  isa       => HashRef,
  builder   => '_build_opts',
);

sub _build_opts {
  my ($self) = @_;
  
  ##  - readfile() our config_file if we have one
  ##  - override with extra_opts if we have any

  my $opts_hash;
  
  if ( $self->has_config_file ) {
    $opts_hash = $self->readfile( $self->config_file )
  }

  if ( $self->has_extra_opts ) {
    ## 'Opts' directive in plugins.conf was passed in
    $opts_hash->{$_} = $self->extra_opts->{$_}
      for keys %{ $self->extra_opts };
  }

  $opts_hash // {}
}

sub reload_conf {
  my ($self) = @_;
  $self->_set_opts( $self->_build_opts )
}

1;
__END__

=pod

=head1 NAME

Bot::Cobalt::Conf::File::PerPlugin - Bot::Cobalt plugin configs

=head1 SYNOPSIS

  my $this_plugin_cf = Bot::Cobalt::Conf::File::PerPlugin->new(
    module => 'Plugin::Module',
        
    ## Optional; loads to ->opts attrib:
    config_file => $path_to_cf_file,
    
    ## Optional; overrides config_file settings in ->opts:
    extra_opts => {
      LevelRequired => 1,
    },

    ## Optional; used by Bot::Cobalt::Core    
    autoload => 1,    
    priority => 1,
  );

  my $priority = $this_plugin_cf->priority;
  
  my $autoload = $this_plugin_cf->autoload;
  
  my $plugin_opts = $this_plugin_cf->opts;

  ## Force a reload:
  $this_plugin_cf->reload_conf;

=head1 DESCRIPTION

A plugin-specific configuration.

These objects are usually managed by a 
L<Bot::Cobalt::Conf::File::Plugins> instance.

This class consumes Bot::Cobalt::Conf::Role::Reader.

(This is a core configuration class; Plugin authors should 'use 
Bot::Cobalt;' and retrieve the B<opts> attribute via 
B<plugin_cfg> instead.)

=head1 AUTHOR

Jon Portnoy <avenj@cobaltirc.org>

=cut
