package Bot::Cobalt::Conf::File::Plugins;
$Bot::Cobalt::Conf::File::Plugins::VERSION = '0.021003';
use v5.10;
use strictures 2;
use Carp;

use Scalar::Util 'blessed';

use Bot::Cobalt::Common ':types';
use Bot::Cobalt::Conf::File::PerPlugin;

use Path::Tiny;
use Types::Path::Tiny -types;

use List::Objects::WithUtils;
use List::Objects::Types -types;

use Moo;
extends 'Bot::Cobalt::Conf::File';


has etcdir => (
  required  => 1,
  is        => 'rwp',
  isa       => Path,
  coerce    => 1,
);


has _per_plug_objs => (
  lazy      => 1,
  is        => 'ro',
  isa       => HashObj,
  coerce    => 1,
  builder   => '_build_per_plugin_objs',  
);

sub _build_per_plugin_objs {
  my ($self) = @_;
  
  ##  Create PerPlugin cf objs for each plugin
  hash(
    $self->cfg_as_hash->keys->map(sub {
      ( $_ => $self->_create_perplugin_obj($_) )
    })->all
  )
}

sub _create_perplugin_obj {
  my ($self, $alias) = @_;
  
  my $this_cfg = $self->cfg_as_hash->get($alias)
    || confess "_create_perplugin_obj passed unknown alias $alias";

  my %new_opts;

  $new_opts{module} = $this_cfg->{Module}
    || confess "No Module defined for plugin $alias";

  if (defined $this_cfg->{Config}) {
    my $this_cf_path = path($this_cfg->{Config});
    unless ( $this_cf_path->is_absolute ) {
      $this_cf_path = path( $self->etcdir .'/'. $this_cf_path );
    }

    $new_opts{config_file} = $this_cf_path  
  }  

  $new_opts{autoload} = 0
    if $this_cfg->{NoAutoLoad};

  $new_opts{priority} = $this_cfg->{Priority}
    if defined $this_cfg->{Priority};

  if (defined $this_cfg->{Opts}) {
    confess "Opts: directive for plugin $alias is not a hash"
      unless ref $this_cfg->{Opts} eq 'HASH';
    
    $new_opts{extra_opts} = $this_cfg->{Opts};
  }

  Bot::Cobalt::Conf::File::PerPlugin->new(
    %new_opts
  );
}

sub plugin {
  my ($self, $plugin) = @_;
  
  confess "plugin() requires a plugin alias"
    unless defined $plugin;

  $self->_per_plug_objs->{$plugin}
}

sub list_plugins {
  my ($self) = @_;
  
  [ keys %{ $self->_per_plug_objs } ]
}

sub clear_plugin {
  my ($self, $plugin) = @_;
  
  confess "clear_plugin requires a plugin alias"
    unless defined $plugin;

  delete $self->_per_plug_objs->{$plugin}
}

sub load_plugin {
  my ($self, $plugin) = @_;
  
  confess "load_plugin requires a plugin alias"
    unless defined $plugin;
    
  $self->_per_plug_objs->{$plugin} 
    = $self->_create_perplugin_obj($plugin)
}

sub install_plugin {
  my ($self, $plugin, $plugin_obj) = @_;
  
  unless (defined $plugin_obj) {
    confess
      "install_plugin requires a plugin alias and Conf object"
  }
  
  unless (blessed $plugin_obj &&
    $plugin_obj->isa('Bot::Cobalt::Conf::File::PerPlugin') ) {
  
    confess
      "install_plugin requires a Bot::Cobalt::Conf::File::PerPlugin object"
  }
  
  $self->_per_plug_objs->{$plugin} = $plugin_obj
}


around 'validate' => sub {
  my ($orig, $self, $cfg) = @_;

  1
};


1;
__END__

=pod

=head1 NAME

Bot::Cobalt::Conf::File::Plugins - Bot::Cobalt plugins config

=head1 SYNOPSIS

  my $plugins_cfg = Bot::Cobalt::Conf::File::Plugins->new(
    etcdir => $path_to_etcdir,

    cfg_path => $path_to_plugins_cf,    
  );

  ## Retrieve array reference of plugin aliases seen:
  my $plugins_arr = $plugins_cfg->list_plugins;

  ## Retrieve Bot::Cobalt::Conf::File::PerPlugin object:
  my $this_plugin_cf = $plugins_cfg->plugin( $alias );

=head1 DESCRIPTION

This is the L<Bot::Cobalt::Conf::File> subclass for "plugins.conf" -- its 
primary purpose is to handle L<Bot::Cobalt::Conf::File::PerPlugin> 
instances, retrievable via L</plugin>.

The constructor requires a B<etcdir> to be used as a relative base path 
for plugin-specific configuration files.

(This is a core configuration class; there is generally no need for 
plugin authors to use these objects directly.)

=head2 clear_plugin

Takes a plugin alias.
Removes the configuration object for the specified plugin.

=head2 install_plugin

Takes a plugin alias and a L<Bot::Cobalt::Conf::File::PerPlugin> or 
subclass thereof.
Installs the new object under the specified alias.

=head2 list_plugins

Returns an array reference of currently tracked plugin aliases.

=head2 load_plugin

Takes a plugin alias.
Loads or re-instances the L<Bot::Cobalt::Conf::File::PerPlugin> object 
for the specified plugin.

=head2 plugin

Takes a plugin alias.
Returns the L<Bot::Cobalt::Conf::File::PerPlugin> object for the 
specified plugin (or boolean false).

=head1 AUTHOR

Jon Portnoy <avenj@cobaltirc.org>

=cut
