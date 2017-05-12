package Bot::Cobalt::Core::Role::EasyAccessors;
$Bot::Cobalt::Core::Role::EasyAccessors::VERSION = '0.021003';
use strictures 2;

use Scalar::Util 'blessed', 'reftype';
use Carp;

use Moo::Role;

requires qw/
  cfg
  PluginObjects
/;


sub get_channels_cfg {
  my ($self, $context) = @_;

  confess "get_channels_cfg expects a server context name"
    unless defined $context;

  ## Returns empty hash if there's no conf for this context
  my $chcfg = $self->cfg->channels->context($context) || {};
  
  for my $channel (keys %$chcfg) {
    ## Might be an empty string:
    $chcfg->{$channel} = +{}
      unless ref $chcfg->{$channel}
      and reftype $chcfg->{$channel} eq 'HASH'
  }
  
  $chcfg
}

sub get_core_cfg {
  my ($self) = @_;

  $self->cfg->core
}

sub get_plugin_alias {
  my ($self, $plugobj) = @_;
  confess "get_plugin_alias expects an object" 
    unless blessed $plugobj;
  
  $self->PluginObjects->{$plugobj}
}

sub get_plugin_cfg {
  my ($self, $plugin) = @_;
  ## my $plugcf = $core->get_plugin_cfg( $self )

  confess "get_plugin_cfg expects a plugin alias or loaded object"
    unless defined $plugin;

  my $alias;

  if (blessed $plugin) {
    ## plugin obj specified
    unless ($alias = $self->PluginObjects->{$plugin}) {
      carp "get_plugin_cfg; No alias for $plugin";
      return
    }
  } else {
    ## string alias specified
    $alias = $plugin;
  }

  my $pcfg_obj = $self->cfg->plugins->plugin($alias);

  ## Return empty hash if this plugin has no config
  return {} unless blessed $pcfg_obj;
  
  ## Return opts() hash
  $pcfg_obj->opts
}


1;
__END__

=pod

=head1 NAME

Bot::Cobalt::Core::Role::EasyAccessors

=head1 SYNOPSIS

  ## Inside a Bot::Cobalt plugin:
  
  # Current plugin alias:
  my $current_alias = $core->get_plugin_alias($self);

  ## Channels hash for specified context:
  my $chan_cf_hash = $core->get_channels_cfg($context);
  
  ## opts() hash for specified plugin object or alias:
  my $plugin_cf = $core->get_plugin_cfg($self);
  
  ## Core configuration object (Bot::Cobalt::Conf::File::Core):
  my $core_cf = $core->get_core_cfg;
  
=head1 DESCRIPTION

L<Bot::Cobalt> core interface role providing 
simple methods for accessing some of the configuration state tracked by 
L<Bot::Cobalt::Core>.

=head2 get_channels_cfg

Returns the channel configuration hash for the specified context (or an 
empty hash).

Same as:

  $core->cfg->channels->context($context) || {};

=head2 get_core_cfg

Returns the core's L<Bot::Cobalt::Conf::File::Core> object.

Same as: 

  $core->cfg->core

=head2 get_plugin_alias

Takes an object (or a stringified object, but this happens 
automatically) and returns the registered alias for the plugin if it is 
loaded.

=head2 get_plugin_cfg

Retrieves the current 'opts()' configuration hash for the specified 
plugin (or an empty hash).

Takes either a plugin object (as a reference only) or a plugin alias (as 
a string).

Same as:

  $core->cfg->plugins->plugin(
    $core->get_plugin_alias($self)
  );

=head1 AUTHOR

Jon Portnoy <avenj@cobaltirc.org>

=cut
