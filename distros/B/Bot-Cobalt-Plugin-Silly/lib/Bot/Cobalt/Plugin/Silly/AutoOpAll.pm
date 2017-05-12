package Bot::Cobalt::Plugin::Silly::AutoOpAll;
$Bot::Cobalt::Plugin::Silly::AutoOpAll::VERSION = '0.031002';
use strictures 2;

use Object::Pluggable::Constants ':ALL';
use IRC::Utils 'lc_irc';

sub new { bless +{}, shift }

sub Cobalt_register {
  my ($self, $core) = splice @_, 0, 2;

  $core->plugin_register( $self, SERVER =>
    'user_joined',
    'public_cmd_aopall',
  );

  $core->log->info("Loaded");

  PLUGIN_EAT_NONE
}

sub Cobalt_unregister {
  my ($self, $core) = splice @_, 0, 2;
  $core->log->info("Unloaded");
  PLUGIN_EAT_NONE
}


sub Bot_public_cmd_aopall {
  my ($self, $core) = splice @_, 0, 2;
  my $msg = ${ $_[0] };
  my $context = $msg->context;

  ## !aopall #chan
  ## !aopall -#chan

  my $nick = $msg->src_nick;
  my $lev = $core->auth->level($context, $nick);
  return PLUGIN_EAT_ALL unless $lev >= 3;

  my $casemap = $core->get_irc_casemap($context) || 'rfc1459' ;
  my $chan = $msg->message_array->[0];
  $chan = lc_irc($chan, $casemap);

  if ( index($chan, '-') == 0 ) {
    # Deletion
    $chan = substr($chan, 1);
    my $resp;
    if (delete $self->{$context}->{$chan}) {
      $resp = "No longer autoopping on $chan";
    } else {
      $resp = "No such chan ($chan) found";
    }
    $core->send_event( notice => $context, $nick, $resp );
  } else {
    $self->{$context}->{$chan} = 1;
    $core->send_event( notice => $context, $nick, 
      "AutoOpping all on $chan"
    );
  }
  
  PLUGIN_EAT_ALL
}

sub Bot_user_joined {
  my ($self, $core) = splice @_, 0, 2;
  my $joined  = ${ $_[0] };

  my $context = $joined->context;
  my $chan = $joined->channel;
  my $nick = $joined->src_nick;

  my $casemap = $core->get_irc_casemap($context) || 'rfc1459' ;
  $chan = lc_irc($chan, $casemap);

  if (exists $self->{$context}->{$chan}) {
    $core->send_event( mode => $context, $chan, "+o $nick" );
  }

  PLUGIN_EAT_NONE
}

1;
__END__

=pod

=head1 NAME

Bot::Cobalt::Plugin::Silly::AutoOpAll - AutoOp everyone

=head1 SYNOPSIS

  > !plugin load AOPAll Bot::Cobalt::Plugin::Silly::AutoOpAll
  # Add channel to auto-op everyone on:
  > !aopall #mychan
  # Remove channel:
  > !aopall -#mychan

The !aopall command equires at least access level 3.

=head1 DESCRIPTION

A L<Bot::Cobalt> plugin.

Automatically op every user joining a channel specified via '!aopall'
(assuming the bot is opped, of course).

=head1 AUTHOR

Jon Portnoy <avenj@cobaltirc.org>

=cut
