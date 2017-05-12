package Bot::Cobalt::Plugin::Rehash;
$Bot::Cobalt::Plugin::Rehash::VERSION = '0.021003';
use strictures 2;
use v5.10;

use Bot::Cobalt;
use Bot::Cobalt::Common;
use Bot::Cobalt::Conf;
use Bot::Cobalt::Lang;

use File::Spec;

use strictures 2;

sub new { bless [], shift }

sub Cobalt_register {
  my ($self, $core) = splice @_, 0, 2;

  register( $self, 'SERVER',
    'rehash', 'public_cmd_rehash'
  );

  logger->info("Registered, commands: !rehash");

  PLUGIN_EAT_NONE
}

sub Cobalt_unregister {
  my ($self, $core) = splice @_, 0, 2;
  logger->info("Unregistered");
  PLUGIN_EAT_NONE
}

sub Bot_rehash {
  my ($self, $core) = splice @_, 0, 2;

  $self->_rehash_core_cf;
  $self->_rehash_channels_cf;
  $self->_rehash_plugins_cf;

  PLUGIN_EAT_NONE
}

sub Bot_public_cmd_rehash {
  my ($self, $core) = splice @_, 0, 2;
  my $msg     = ${$_[0]};

  my $context = $msg->context;
  my $channel = $msg->channel;
  my $nick = $msg->src_nick;

  my $auth_lev = core->auth->level($context, $nick);
  my $auth_usr = core->auth->username($context, $nick);

  my $pcfg = plugin_cfg($self) || {};
  my $required_lev = $pcfg->{LevelRequired} // 9999;

  unless ($auth_lev >= $required_lev) {
    my $resp = core->rpl( q{RPL_NO_ACCESS},
      nick => $nick
    );

    broadcast 'message', $context, $channel, $resp;

    return PLUGIN_EAT_ALL
  }
  
  my $type = lc($msg->message_array->[0] || 'all');
  
  my $meth = '_cmd_'.$type;
  
  logger->debug("dispatching $meth for $nick ($auth_usr)");

  my $resp;
  if ( $self->can($meth) ) {
    ## Handlers return a response or die() :
    $resp = try { 
      $self->$meth($msg) 
    } catch {
      my $error = $_;
      logger->error("Rehash ($type) failure; $error");
      "Failed rehash: $error"
    };
  } else {
    $resp = "Unknown config group, try: core, plugins, langset, channels"
  }

  broadcast 'message', $context, $channel, $resp;

  PLUGIN_EAT_ALL
}

## Command handlers:
sub _cmd_all {
  my ($self, $msg) = @_;

  $self->_rehash_core_cf;
  $self->_rehash_channels_cf;
  $self->_rehash_plugins_cf;

  "Rehashed loaded configuration objects."
}

sub _cmd_channels {
  my ($self, $msg) = @_;
  
  $self->_rehash_channels_cf;
  
  "Rehashed current channels configuration."
}

sub _cmd_core {
  my ($self, $msg) = @_;

  $self->_rehash_core_cf;
  
  "Rehashed core configuration."
}

sub _cmd_plugins {
  my ($self, $msg) = @_;
  
  $self->_rehash_plugins_cf;
  
  "Rehashed plugins configuration."
}

sub _cmd_langset {
  my ($self, $msg) = @_;

  my $lang = $msg->message_array->[1];
  
  $self->_rehash_langset($lang);
      
  "Rehashed loaded language set"
}


## Actual configuration reloaders:
sub _rehash_plugins_cf {
  my ($self) = @_;

  require Bot::Cobalt::Conf::File::Plugins;

  my $new_cfg_obj = Bot::Cobalt::Conf::File::Plugins->new(
    etcdir => core()->etc,
    cfg_path   => core()->cfg->plugins->cfg_path,
  );

  core()->cfg->set_plugins( $new_cfg_obj );
  
  logger->info("Reloaded plugins.conf");
  
  broadcast 'rehashed', 'plugins';
}

sub _rehash_channels_cf {
  my ($self) = @_;

  require Bot::Cobalt::Conf::File::Channels;
    
  my $new_cfg_obj = Bot::Cobalt::Conf::File::Channels->new(
    cfg_path => core()->cfg->channels->cfg_path,
  );

  core()->cfg->set_channels( $new_cfg_obj );

  logger->info("Reloaded channels config.");

  broadcast 'rehashed', 'channels';
}

sub _rehash_core_cf {
  my ($self) = @_;

  require Bot::Cobalt::Conf::File::Core;
    
  my $new_cfg_obj = Bot::Cobalt::Conf::File::Core->new(
    cfg_path => core()->cfg->core->cfg_path,
  );

  core()->cfg->set_core( $new_cfg_obj );
  
  logger->info("Reloaded core config.");
  
  ## Bot_rehash ($type) :
  broadcast 'rehashed', 'core';
}

sub _rehash_langset {
  my ($self, $langset) = @_;

  ## FIXME document that you should rehash core then rehash langset
  ##  for updated Language: directives

  $langset ||= core()->cfg->core->language;
  
  my $lang_dir = File::Spec->catdir( core()->etc, 'langs' );

  my $lang_obj =  Bot::Cobalt::Lang->new(
    use_core => 1,
      
    lang_dir => $lang_dir,
    lang     => $langset,
  );

  die "Language set $langset has no RPLs"
    unless scalar keys %{ $lang_obj->rpls } ;

  core()->set_langset( $lang_obj );
  core()->set_lang( $lang_obj->rpls );
  
  logger->info("Reloaded core langset ($langset)");

  broadcast 'rehashed', 'langset';
}


1;
__END__

=pod

=head1 NAME

Bot::Cobalt::Plugin::Rehash - Rehash config or langs on-the-fly

=head1 SYNOPSIS

  Rehash 'cobalt.conf':
   !rehash core
  
  Rehash 'channels.conf':
   !rehash channels
 
  Rehash 'plugins.conf' and plugin-specific configs:
   !rehash plugins
  
  All of the above:
   !rehash all

  Load a different language set:
   !rehash langset ebonics
   !rehash langset english

=head1 DESCRIPTION

Reloads configuration files or language sets on the fly.

Few guarantees regarding consequences are made as of this writing; 
playing with core configuration options might not necessarily always do 
what you expect. (Feel free to report as bugs via either RT or e-mail, 
of course.)

Note that plugin-specific configs will be reloaded when the 'plugins' 
target is. This is new behavior as of Bot-Cobalt-0.013.

=head1 EMITTED EVENTS

Every rehash triggers a B<Bot_rehashed> event, informing the plugin pipeline 
of the newly reloaded configuration values.

The first event argument is the type of rehash that was performed; it 
will be one of I<core>, I<channels>, I<langset>, or I<plugins>.

=head1 AUTHOR

Jon Portnoy <avenj@cobaltirc.org>

=cut
