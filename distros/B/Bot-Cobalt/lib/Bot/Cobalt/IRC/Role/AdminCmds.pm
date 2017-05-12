package Bot::Cobalt::IRC::Role::AdminCmds;
$Bot::Cobalt::IRC::Role::AdminCmds::VERSION = '0.021003';
use strictures 2;
use Scalar::Util 'reftype';

use Bot::Cobalt;
use Bot::Cobalt::Common;

use Try::Tiny;

use Moo::Role;


sub Bot_public_cmd_server {
  my ($self, $core) = splice @_, 0, 2;
  my $msg = ${ $_[0] };
  my $context  = $msg->context;
  my $src_nick = $msg->src_nick;

  return PLUGIN_EAT_ALL unless
    $core->auth->has_flag($context, $src_nick, 'SUPERUSER');
  
  my $cmd = lc($msg->message_array->[0] || 'list');
  my $meth = '_cmd_'.$cmd;
  unless ( $self->can($meth) ) {
    broadcast message => $msg->context, $msg->channel,
      "Unknown command; try one of: list, current, connect, disconnect";
    return PLUGIN_EAT_ALL
  }
  
  logger->debug("Dispatching $cmd for $src_nick");
  $self->$meth($msg)
}

sub _cmd_list {
  my ($self, $msg) = @_;
  my @contexts = keys %{ core->Servers };
  my $pcfg = plugin_cfg($self);
  ## FIXME look for contexts that are conf'd but not active
  
  broadcast message => $msg->context, $msg->channel,
    "Active contexts: " . join ' ', @contexts ;
  
  PLUGIN_EAT_ALL
}

sub _cmd_current {
  my ($self, $msg) = @_;

  broadcast message => $msg->context, $msg->channel,
    "Currently on context ".$msg->context;

  PLUGIN_EAT_ALL
}

{ no warnings 'once'; *_cmd_reconnect = *_cmd_connect; }
sub _cmd_connect {
  my ($self, $msg) = @_;
  
  my $pcfg = plugin_cfg($self);
  
  unless (ref $pcfg && reftype $pcfg eq 'HASH' && keys %$pcfg) {
    broadcast message => $msg->context, $msg->channel,
      "Could not locate any network configuration.";
    logger->error("_cmd_connect could not find an IRC network cfg");
    return PLUGIN_EAT_ALL
  }
  
  my $target_ctxt = $msg->message_array->[1];
  unless (defined $target_ctxt) {
    broadcast message => $msg->context, $msg->channel,
      "No context specified.";
    return PLUGIN_EAT_ALL
  }
  
  unless ($pcfg->{Networks}->{$target_ctxt}) {
    broadcast message => $msg->context, $msg->channel,
      "Could not locate configuration for context $target_ctxt";
    return PLUGIN_EAT_ALL
  }
  
  ## Do we already have this context?
  if (my $ctxt_obj = irc_context($target_ctxt) ) {
    if ($ctxt_obj->connected) {
      broadcast message => $msg->context, $msg->channel,
        "Attempting reconnect for context $target_ctxt";
    }
    logger->info("Attempting reconnect for context $target_ctxt");
    broadcast ircplug_disconnect => $target_ctxt;
    broadcast ircplug_connect => $target_ctxt;
    broadcast ircplug_timer_serv_retry =>
      +{ context => $target_ctxt, delay => 300 } ;
    return PLUGIN_EAT_ALL
  }

  broadcast message => $msg->context, $msg->channel,
    "Issuing connect for context $target_ctxt";
  
  my $src_nick = $msg->src_nick;
  my $auth_usr = core->auth->username($msg->context, $src_nick);
  
  logger->info(
   "Issuing connect for context $target_ctxt",
   "(Issued by $src_nick [$auth_usr])"
  );
    
  broadcast ircplug_connect => $target_ctxt;
  
  return PLUGIN_EAT_ALL 
}

sub _cmd_disconnect {
  my ($self, $msg) = @_;
  my $target_ctxt = $msg->message_array->[1];
  
  unless (defined $target_ctxt) {
    broadcast message => $msg->context, $msg->channel,
      "No context specified.";
    return PLUGIN_EAT_ALL
  }
  
  my $ctxt_obj;
  unless ($ctxt_obj = irc_context($target_ctxt) ) {
    broadcast message => $msg->context, $msg->channel,
      "Could not find context object for $target_ctxt";
    return PLUGIN_EAT_ALL
  }

  unless (keys %{ core->Servers } > 1) {
    broadcast message => $msg->context, $msg->channel,
      "Refusing disconnect; have no other active contexts.";
    return PLUGIN_EAT_ALL
  }
  
  broadcast message => $msg->context, $msg->channel,
    "Attempting to disconnect from $target_ctxt";

  my $src_nick = $msg->src_nick;
  my $auth_usr = core->auth->username($msg->context, $src_nick);
  
  logger->info(
   "Issuing disconnect for context $target_ctxt",
   "(Issued by $src_nick [$auth_usr])"
  );

  broadcast ircplug_disconnect => $target_ctxt;
  
  return PLUGIN_EAT_ALL
}


sub Bot_ircplug_timer_serv_retry {
  my ($self, $core) = splice @_, 0, 2;
  my $hints = ${ $_[0] };
    
  my $context = $hints->{context};
  my $delay   = $hints->{delay} || 300;

  logger->debug("ircplug_timer_serv_retry called for $context");
  my $ctxt_obj;
  unless ($ctxt_obj = irc_context($context) && $ctxt_obj->connected) {
    logger->info("Attempting reconnect to $context . . .");
    broadcast ircplug_connect => $context;
    core->timer_set( $delay,
      +{
        Event => 'ircplug_timer_serv_retry',
        Args  => [ +{ context => $context, delay => $delay } ],
      },
    );
  }
  
  return PLUGIN_EAT_ALL
}

1;
__END__

=pod

=head1 NAME

Bot::Cobalt::IRC::Role::AdminCmds - IRC-specific admin commands

=head1 SYNOPSIS

  ## Check current context name:
  !server current

  ## List contexts:
  !server list  

  ## Issue a (re)connect:
  !server connect Main
  
  ## Issue a disconnect:
  !server disconnect Alpha

=head1 DESCRIPTION

This is a L<Moo::Role> consumed by the default IRC plugin 
(L<Bot::Cobalt::IRC>). It provides basic administrative commands 
specific to IRC connection control.

As a failsafe you cannot disconnect from all contexts. See the C<die> 
command provided by L<Bot::Cobalt::Plugin::Master> instead.
However, Issuing a connect for a currently-connected context will 
attempt a reconnection (note that it's possible to 'lose' bots this way, 
particularly if the configuration or the remote server has changed in 
some way).

See the L</SYNOPSIS> for basic usage information; all commands require
SUPERUSER access.

=head1 AUTHOR

Jon Portnoy <avenj@cobaltirc.org>

=cut
