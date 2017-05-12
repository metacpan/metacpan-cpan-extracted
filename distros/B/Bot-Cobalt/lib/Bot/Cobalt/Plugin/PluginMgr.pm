package Bot::Cobalt::Plugin::PluginMgr;
$Bot::Cobalt::Plugin::PluginMgr::VERSION = '0.021003';
## handles and eats: !plugin

use strictures 2;
use v5.10;

use Bot::Cobalt;
use Bot::Cobalt::Common;
use Bot::Cobalt::Conf;
use Bot::Cobalt::Core::Loader;

use Scalar::Util qw/blessed/;


sub new { bless [], shift }

sub Cobalt_register {
  my ($self, $core) = splice @_, 0, 2;

  register( $self, 'SERVER',
    'public_cmd_plugin',
  );

  logger->info("Registered");

  return PLUGIN_EAT_NONE
}

sub Cobalt_unregister {
  my ($self, $core) = splice @_, 0, 2;

  logger->info("Unregistered");

  return PLUGIN_EAT_NONE
}

sub Bot_public_cmd_plugin {
  my ($self, $core) = splice @_, 0, 2;
  my $msg = ${$_[0]};

  my $context = $msg->context;
  my $chan = $msg->channel;
  my $nick = $msg->src_nick;

  my $pcfg = core()->get_plugin_cfg( $self );

  ## default to superuser-only:
  my $required_lev = $pcfg->{LevelRequired} // 9999;

  my $resp;

  my $op = lc($msg->message_array->[0]||'');

  if ( core()->auth->level($context, $nick) < $required_lev ) {
    $resp = core->rpl( q{RPL_NO_ACCESS}, { nick => $nick } );
  } else {
    unless ($op && grep { $_ eq $op } qw/load unload reload list/) {

      broadcast( 'message', $context, $chan,
        "Valid PluginMgr commands: list, load, unload, reload"
      );

      return PLUGIN_EAT_ALL
    }

    my $method = '_cmd_plug_'.lc($op);

    if ($self->can($method)) {
      $resp = $self->$method($msg);
    } else {
      logger->error("Bug; can($method) failed in dispatcher");
      $resp = "Could not find method $method"
    }

  }

  broadcast('message', $context, $chan, $resp) if defined $resp;

  return PLUGIN_EAT_ALL
}

sub _cmd_plug_load {
  my ($self, $msg) = @_;

  ## !load Alias
  ## !load Alias Module

  my ($alias, $module) = @{ $msg->message_array }[1,2];

  return $self->_load($alias, $module)
}

sub _cmd_plug_unload {
  my ($self, $msg) = @_;

  ## !unload Alias

  my $alias = $msg->message_array->[1];

  return $self->_unload($alias) || "Bug; no reply from _unload"
}

sub _cmd_plug_list {
  my ($self, $msg) = @_;

  my $pluglist = core()->plugin_list;

  my @loaded = sort keys %$pluglist;

  my $str = sprintf("Loaded (%d):", scalar @loaded);
  while (my $plugin_alias = shift @loaded) {
    $str .= ' ' . $plugin_alias;

    if ($str && (length($str) > 300 || !@loaded) ) {
      ## either this string has gotten long or we're done
      broadcast( 'message', $msg->context, $msg->channel, $str );
      $str = '';
    }
  }
}

sub _cmd_plug_reload {
  my ($self, $msg) = @_;

  my $alias = $msg->message_array->[1];

  my $plug_obj = core()->plugin_get($alias);

  my $resp;
  if (!$alias) {

    broadcast( 'message', $msg->context, $msg->channel,
      "Bad syntax; no plugin alias specified"
    );

    return

  } elsif (!$plug_obj) {

    broadcast( 'message', $msg->context, $msg->channel,
      core->rpl( q{RPL_PLUGIN_UNLOAD_ERR},
        plugin => $alias,
        err => 'No such plugin found, is it loaded?'
      )
    );

    return

  } elsif (core()->State->{NonReloadable}->{$alias}) {

    broadcast( 'message', $msg->context, $msg->channel,
      core->rpl( q{RPL_PLUGIN_UNLOAD_ERR},
          plugin => $alias,
          err => "Plugin $alias is marked as non-reloadable",
      )
    );

    return
  }

   ## call _unload and send any response from there
  my $unload_resp = $self->_unload($alias);

  broadcast( 'message', $msg->context, $msg->channel, $unload_resp );

  my $pkgisa = ref $plug_obj;

  return $self->_load($alias, $pkgisa);
}

sub _unload {
  my ($self, $alias) = @_;

  my $resp;

  my $plug_obj = core()->plugin_get($alias);
  my $plugisa = ref $plug_obj || return "_unload broken? no PLUGISA";

  return "Bad syntax; no plugin alias specified"
    unless defined $alias;

  return core->rpl( q{RPL_PLUGIN_UNLOAD_ERR},
      plugin => $alias,
      err => 'No such plugin found, is it loaded?'
  ) unless $plug_obj;

  return core->rpl( q{RPL_PLUGIN_UNLOAD_ERR},
      plugin => $alias,
      err => "Plugin $alias is marked as non-reloadable",
 ) unless Bot::Cobalt::Core::Loader->is_reloadable($plug_obj);

  logger->info("Attempting to unload $alias ($plugisa) per request");

  if ( core()->plugin_del($alias) ) {
    delete core()->PluginObjects->{$plug_obj};

    Bot::Cobalt::Core::Loader->unload($plugisa);

    ## and timers:
    core()->timer_del_alias($alias);

    return core->rpl( q{RPL_PLUGIN_UNLOAD},
        plugin => $alias
    )
  } else {
    return core->rpl( q{RPL_PLUGIN_UNLOAD_ERR},
      plugin => $alias,
      err => 'Unknown core->plugin_del failure'
    )
  }

  return
}

sub _load {
  my ($self, $alias, $module) = @_;

  ## Called for !load / !reload
  ## Return string for IRC

  return "Bad syntax; usage: load <alias> [module]"
    unless defined $alias;

  return "Plugin already loaded: $alias"
    if grep { $_ eq $alias } keys %{ core()->plugin_list };

  return $self->_load_module($alias, $module)
    if defined $module;

  my $plugin_cfg;
  ## No module specified; do we know this alias?
  unless ( $plugin_cfg = core()->cfg->plugins->plugin($alias) ) {
    return core->rpl( q{RPL_PLUGIN_ERR},
      plugin => $alias,
      err => "Plugin '$alias' not found in plugins conf",
    )
  }

  return $self->_load_module(
    $alias,
    $plugin_cfg->module
  )
}

sub _load_module {
  ## _load_module( 'Auth', 'Bot::Cobalt::Plugin::Auth' ) f.ex
  ## load to Core
  ## returns a response string for irc
  my ($self, $alias, $module) = @_;

  my ($err, $obj);
  try {
    $obj = Bot::Cobalt::Core::Loader->load($module);
  } catch {
    $err = $_
  };

  if ($err) {
    logger->warn("Plugin load failure; $err");

    Bot::Cobalt::Core::Loader->unload($module);

    return core->rpl( q{RPL_PLUGIN_ERR},
      plugin => $alias,
      err => "Module $module cannot be found/loaded: $err",
    );
  }

  ## store plugin objects:
  core()->PluginObjects->{$obj} = $alias;

  ## plugin_add returns # of plugins in pipeline on success:
  if (my $loaded = core()->plugin_add( $alias, $obj ) ) {
    unless ( Bot::Cobalt::Core::Loader->is_reloadable($obj) ) {
      core()->State->{NonReloadable}->{$alias} = 1;
      logger->debug("$alias flagged non-reloadable");
    }

    my $modversion = $obj->can('VERSION') ? $obj->VERSION : 1 ;

    return core->rpl( q{RPL_PLUGIN_LOAD},
      plugin  => $alias,
      module  => $module,
      version => $modversion,
    );
  } else {
    ## Couldn't plugin_add
    logger->error("plugin_add failure for $alias");

    ## run cleanup
    Bot::Cobalt::Core::Loader->unload($module);

    delete core()->PluginObjects->{$obj};

    return core->rpl( q{RPL_PLUGIN_ERR},
      plugin => $alias,
      err => "Unknown plugin_add failure",
    );
  }

}


1;
__END__

=pod

=head1 NAME

Bot::Cobalt::Plugin::PluginMgr - IRC plugin manager

=head1 SYNOPSIS

  !plugin list
  !plugin load MyPlugin
  !plugin load MyPlugin Bot::Cobalt::Plugin::User::MyPlugin
  !plugin reload MyPlugin
  !plugin unload MyPlugin

=head1 DESCRIPTION

This is a fairly simplistic online plugin manager.

Required level defaults to 9999 (standard-auth superusers) unless
the LevelRequired option is specified in PluginMgr's plugins.conf
B<Opts> directive:

  PluginMgr:
    Module: Bot::Cobalt::Plugin::PluginMgr
    Opts:
      ## '3' is legacy darkbot 'administrator':
      LevelRequired: 3

=head1 COMMANDS

B<PluginMgr> responds to the C<!plugin> command:

  <JoeUser> !plugin reload DNS

=head2 list

Lists the aliases of all currently loaded plugins.

=head2 load

Load a specified plugin.

If the plugin has a C<plugins.conf> directive, the alias can be 
specified by itself; the Module specified in C<plugins.conf> will be 
used:

  <JoeUser> !plugin load DNS

Otherwise, a module must be specified:

  <JoeUser> !plugin load DNS Bot::Cobalt::Plugin::Extras::DNS

As of Bot-Cobalt-0.013, '!load' no longer rehashes plugin configuration 
values; use '!rehash plugins' from L<Bot::Cobalt::Plugin::Rehash> 
instead.

=head2 unload

Unload a specified plugin.

The only argument is the plugin's alias.

=head2 reload

Unload and re-load the specified plugin.

=head1 AUTHOR

Jon Portnoy <avenj@cobaltirc.org>

=cut
