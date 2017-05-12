package Bot::Cobalt::Plugin::Extras::Relay;
$Bot::Cobalt::Plugin::Extras::Relay::VERSION = '0.021003';
## Simplistic relaybot plugin
use Scalar::Util 'reftype';

use Bot::Cobalt;
use Bot::Cobalt::Common;

sub new { bless +{}, shift }

sub get_relays {
  my ($self, $context, $channel) = @_;
  return unless $context and $channel;

  ## array of arrays mapping relay relationships
  ## $channel = [
  ##   [
  ##     $target_context,
  ##     $target_channel
  ##   ],
  ## ]
  return unless exists $self->{Relays}->{$context};
  my $relays = $self->{Relays}->{$context}->{$channel} // return;
  return unless @$relays;
  wantarray ? return @$relays : return $relays ;
}

sub add_relay {
  my ($self, $ref) = @_;
  ## take a hash mapping From and To
  return unless $ref and ref $ref eq 'HASH';

  my $from = $ref->{From} // return;
  my $to   = $ref->{To}   // return;

  my $context0 = $from->{Context} // return;
  my $chan0    = $from->{Channel} // return;

  my $context1 = $to->{Context} // return;
  my $chan1    = $to->{Channel} // return;

  ## context0:chan0 is relayed to *1:
  push( @{ $self->{Relays}->{$context0}->{$chan0} },
    [ $context1, $chan1 ],
  );
  ## and vice-versa:
  push( @{ $self->{Relays}->{$context1}->{$chan1} },
    [ $context0, $chan0 ],
  );

  logger->debug(
    "relaying: $context0 $chan0 -> $context1 $chan1"
  );
  return 1
}

sub Cobalt_register {
  my ($self, $core) = splice @_, 0, 2;

  my $pcfg = $core->get_plugin_cfg($self);
  my $relays = $pcfg->{Relays};
  unless (ref $relays and reftype $relays eq 'ARRAY') {
    $core->log->warn("'Relays' conf directive not valid, should be a list");
  } else {
    for my $ref (@$relays) {
      $self->add_relay($ref);
    }
  }

  register( $self, 'SERVER',
    [
      'public_msg',
      'ctcp_action',

      'user_joined',
      'user_kicked',
      'user_left',
      'user_quit',
      'nick_changed',

      'public_cmd_relay',
      'public_cmd_rwhois',

      'relay_push_join_queue',
    ],
  );

  $core->log->info("Loaded relay system");

  $core->timer_set( 3,
    {
      Event => 'relay_push_join_queue',
      Alias => $core->get_plugin_alias($self),
    },
    'RELAYBOT_JOINQUEUE'
  );

  return PLUGIN_EAT_NONE
}

sub Cobalt_unregister {
  my ($self, $core) = splice @_, 0, 2;
  $core->log->info("Unloaded");
  return PLUGIN_EAT_NONE
}

sub Bot_relay_push_join_queue {
  my ($self, $core) = splice @_, 0, 2;

  $self->_push_left_queue;

  my $queue = $self->{JoinQueue}//{};

  SERV: for my $context (keys %$queue) {
    next SERV unless scalar keys %{ $self->{Relays}->{$context} };

    CHAN: for my $channel (keys %{ $queue->{$context} }) {
      my @relays = $self->get_relays($context, $channel);
      next CHAN unless @relays;

      my @pending = @{ $queue->{$context}->{$channel} };
      my $str = "[joined: ${context}:${channel}] ";

      if (@pending > 5) {
        $str .= join ', ', splice @pending, 0, 5;

        my $remaining = scalar @pending;
        $str .= " ($remaining more, truncated)";
      } else {
        $str .= join ', ', @pending;
      }

      ## clear queue
      $queue->{$context}->{$channel} = [];

      RELAY: for my $relay (@relays) {
        my ($to_context, $to_channel) = @$relay;
        broadcast( 'message',
          $to_context,
          $to_channel,
          $str
        );
      } # RELAY

    } # CHAN

  }  # SERV

  $self->{JoinQueue} = {};

  broadcast('relay_push_left_queue');

  $core->timer_set( 3,
    {
      Event => 'relay_push_join_queue',
      Alias => $core->get_plugin_alias($self),
    },
    'RELAYBOT_JOINQUEUE'
  );

  return PLUGIN_EAT_ALL
}

sub _push_left_queue {
  my ($self) = @_;

  my $queue = $self->{LeftQueue}//{};

  SERV: for my $context (keys %$queue) {
    next SERV unless scalar keys %{ $self->{Relays}->{$context} };
    CHAN: for my $channel (keys %{ $queue->{$context} }) {
      my @relays = $self->get_relays($context, $channel);
      next CHAN unless @relays;

      my @pending = @{ $queue->{$context}->{$channel} };
      my $str = "[left: ${context}:${channel}] ";

      if (@pending > 5) {
        $str .= join ', ', splice @pending, 0, 5;

        my $remaining = scalar @pending;
        $str .= " ($remaining more, truncated)";
      } else {
        $str .= join ', ', @pending;
      }

      RELAY: for my $relay (@relays) {
        my ($to_context, $to_channel) = @$relay;

        broadcast( 'message',
          $to_context,
          $to_channel,
          $str
        );
      } # RELAY

    } # CHAN

  }  # SERV

  $self->{LeftQueue} = {};

  return PLUGIN_EAT_ALL
}


sub Bot_public_msg {
  my ($self, $core) = splice @_, 0, 2;
  my $msg     = ${ $_[0] };
  my $context = $msg->context;

  my $channel = $msg->target;

  my @relays = $self->get_relays($context, $channel);
  return PLUGIN_EAT_NONE unless @relays;

  ## don't relay our handled commands
  my @handled = qw/ relay rwhois /;
  if ($msg->cmd) {
    return PLUGIN_EAT_NONE if $msg->cmd
      and grep { $_ eq $msg->cmd } @handled;
  }

  my $src_nick = $msg->src_nick;
  my $text = $msg->message;
  my $str  = "<${src_nick}:${channel}> $text";

  for my $relay (@relays) {
    my $to_context = $relay->[0];
    my $to_channel = $relay->[1];

    ## should be good to relay away ...
    broadcast( 'message',
      $to_context,
      $to_channel,
      $str
    );
  }

  return PLUGIN_EAT_NONE
}

sub Bot_ctcp_action {
  my ($self, $core) = splice @_, 0, 2;
  my $action  = ${ $_[0] };
  my $context = $action->context;

  my $channel = $action->channel || return PLUGIN_EAT_NONE;

  my @relays = $self->get_relays($context, $channel);
  return PLUGIN_EAT_NONE unless @relays;

  my $src_nick = $action->src_nick;
  my $text = $action->message;
  my $str  = "[action:${channel}] * $src_nick $text";

  for my $relay (@relays) {
    my $to_context = $relay->[0];
    my $to_channel = $relay->[1];

    broadcast( 'message',
      $to_context,
      $to_channel,
      $str
    );
  }

  return PLUGIN_EAT_NONE
}

sub Bot_user_joined {
  my ($self, $core) = splice @_, 0, 2;
  my $join    = ${ $_[0] };

  my $context = $join->context;
  my $channel = $join->channel;

  return PLUGIN_EAT_NONE unless $self->get_relays($context, $channel);

  my $src_nick = $join->src_nick;

  push( @{ $self->{JoinQueue}->{$context}->{$channel} }, $src_nick )
    unless grep { $_ eq $src_nick }
            @{ $self->{JoinQueue}->{$context}->{$channel}//[] };

  return PLUGIN_EAT_NONE
}

sub Bot_user_left {
  my ($self, $core) = splice @_, 0, 2;
  my $part    = ${ $_[0] };

  my $context = $part->context;
  my $channel = $part->channel;

  return PLUGIN_EAT_NONE unless $self->get_relays($context, $channel);

  my $src_nick = $part->src_nick;

  push( @{ $self->{LeftQueue}->{$context}->{$channel} }, $src_nick )
    unless grep { $_ eq $src_nick }
            @{ $self->{LeftQueue}->{$context}->{$channel}//[] };

  return PLUGIN_EAT_NONE
}

sub Bot_user_kicked {
  my ($self, $core) = splice @_, 0, 2;
  my $kick = ${ $_[0] };
  my $context = $kick->context;

  my $channel = $kick->channel;

  my @relays = $self->get_relays($context, $channel);
  return PLUGIN_EAT_NONE unless @relays;

  my $src_nick = $kick->src_nick;
  my $kicked_u = $kick->kicked;
  my $reason   = $kick->reason;

  for my $relay (@relays) {
    my $to_context = $relay->[0];
    my $to_channel = $relay->[1];

    my $str =
      "<kick:${channel}> $kicked_u was kicked by $src_nick ($reason)";
    broadcast( 'message',
      $to_context,
      $to_channel,
      $str
    );
  }

  return PLUGIN_EAT_NONE
}

sub Bot_user_quit {
  my ($self, $core) = splice @_, 0, 2;
  my $quit = ${ $_[0] };
  my $context = $quit->context;

  return PLUGIN_EAT_NONE
    unless $self->{Relays}->{$context};

  my $src_nick = $quit->src_nick;
  my $common   = $quit->common;

  ## see if we have any applicable relays for this quit
  ## send the quit to all of them
  for my $channel (@$common) {
    my @relays = $self->get_relays($context, $channel);
    next unless @relays;

    RELAY: for my $relay (@relays) {
      my ($to_context, $to_channel) = @$relay;

      push(@{ $self->{LeftQueue}->{$context}->{$channel} }, $src_nick )
        unless grep { $_ eq $src_nick }
                 @{ $self->{LeftQueue}->{$context}->{$channel}//[] };
    }
  }

  return PLUGIN_EAT_NONE
}

sub Bot_nick_changed {
  my ($self, $core) = splice @_, 0, 2;
  my $nchg = ${ $_[0] };
  my $context = $nchg->context;

  ## disregard case changes to cut back noise
  return PLUGIN_EAT_NONE if $nchg->equal;

  return PLUGIN_EAT_NONE
    unless $self->{Relays}->{$context};

  my $src_nick = $nchg->new_nick;
  my $old_nick = $nchg->old_nick;
  my $common   = $nchg->channels;

  for my $channel (@$common) {
    my @relays = $self->get_relays($context, $channel);
    next unless @relays;

    RELAY: for my $relay (@relays) {
      my ($to_context, $to_channel) = @$relay;
      my $str =
        "[relay: $channel] $old_nick changed nickname to $src_nick";

      broadcast( 'message', $to_context, $to_channel, $str );
    }
  }

  return PLUGIN_EAT_NONE
}

sub Bot_public_cmd_relay {
  my ($self, $core) = splice @_, 0, 2;
  my $msg     = ${ $_[0] };
  my $context = $msg->context;
  ## Show relay info

  my $channel = $msg->target;

  my @relays = $self->get_relays($context, $channel);

  unless (@relays) {
    broadcast( 'message',
      $context,
      $channel,
      "There are no relays for $channel on context $context"
    );
    return PLUGIN_EAT_ALL
  }

  my $str = "Currently relaying to: ";

  my $idx = 0;
  for my $relay (@relays) {
    my ($to_context, $to_channel) = @$relay;
    $str .= "${to_context}:${to_channel} ";
  }

  broadcast( 'message', $context, $channel, $str );
  return PLUGIN_EAT_ALL
}

sub Bot_public_cmd_rwhois {
  my ($self, $core) = splice @_, 0, 2;
  my $msg     = ${ $_[0] };
  my $context = $msg->context;

  my $channel = $msg->target;

  my ($remotenet, $remoteuser) = @{ $msg->message_array };
  unless ($remotenet && $remoteuser) {
    my $src_nick = $msg->src_nick;
    broadcast( 'message',
      $context,
      $channel,
      "${src_nick}: Usage: rwhois <context> <nickname>"
    );
    return PLUGIN_EAT_ALL
  }

  unless ( $self->get_relays($context, $channel) ) {
    broadcast( 'message',
      $context,
      $channel,
      "There are no active relays for $channel on context $context"
    );
    return PLUGIN_EAT_ALL
  }

  my $irc_obj = $core->get_irc_obj($remotenet);
  unless ( $self->{Relays}->{$remotenet} and ref $irc_obj ) {
    broadcast( 'message',
      $context,
      $channel,
      "We don't seem to have a relay for $remotenet"
    );
    return PLUGIN_EAT_ALL
  }

  my $nickinfo = $irc_obj->nick_info($remoteuser);
  my $resp;
  unless ($nickinfo) {
    $resp = "No such user: $remoteuser";
  } else {
    my $nick = $nickinfo->{Nick};
    my $user = $nickinfo->{User};
    my $host = $nickinfo->{Host};
    my $real = $nickinfo->{Real};
    my $userhost = "${nick}!${user}\@${host}";
    $resp = "$remoteuser ($userhost) [$real]"
  }
  broadcast( 'message', $context, $channel, $resp );

  return PLUGIN_EAT_ALL
}

1;
__END__

=pod

=head1 NAME

Bot::Cobalt::Plugin::Extras::Relay - Multiplex IRC channels

=head1 DESCRIPTION

This plugin is an IRC multiplexer; it can be used to relay IRC channel 
chatter across networks (or on the same network, if you like) in 
flexible ways.

Channels on any context can be mapped to channels on any other 
context; relays are always bidirectional, but you can still map 
one-to-many; see the configuration example below.

=head1 CONFIGURATION

An example relay.conf:

  ## Map Main:#otw <-> IRCNode:#otw
  ## Map Main:#otw <-> Paradox:#perl
  ## (Paradox and IRCNode won't be relayed to each other)
  Relays:
    - From:
        Context: Main
        Channel: '#otw'
      To:
        Context: IRCNode
        Channel: '#otw'
    - From:
        Context: Main
        Channel: '#otw'
      To:
        Context: AlphaChat
        Channel: '#perl'

See etc/plugins/relay.conf in the L<Bot::Cobalt> distribution.

=head1 COMMANDS

=head2 !relay

Display the configured relay for the current channel.

=head2 !rwhois

Remotely 'whois' a user on the relayed end.

=head1 AUTHOR

Jon Portnoy <avenj@cobaltirc.org>

L<http://www.cobaltirc.org>

=cut
