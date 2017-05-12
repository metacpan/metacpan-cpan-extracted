package Bot::Cobalt::IRC::Role::UserEvents;
$Bot::Cobalt::IRC::Role::UserEvents::VERSION = '0.021003';
## POD lives in Bot::Cobalt::IRC for now ...

use 5.12.1;

use Bot::Cobalt;
use Bot::Cobalt::Common;

use Moo::Role;

use strictures 2;

requires qw/
  ircobjs
/;

sub Bot_send_message { Bot_message(@_) }
sub Bot_message {
  my ($self, $core) = splice @_, 0, 2;
  
  unless (defined $_[2]) {
    logger->error("Bot_message received without enough arguments");
    return PLUGIN_EAT_NONE
  }

  my $context = ${$_[0]};
  my $target  = ${$_[1]};
  my $txt     = ${$_[2]};

  return PLUGIN_EAT_NONE
    unless defined $self->ircobjs->{$context}
    and $core->is_connected($context);

  ## USER event Outgoing_message for output filters
  my @msg = ( $context, $target, $txt );
  my $eat = $core->send_user_event( 'message', \@msg );

  unless ($eat == PLUGIN_EAT_ALL) {
    my ($target, $txt) = @msg[1,2];
    
    if (defined $target && defined $txt && $txt ne '') {
      $self->ircobjs->{$context}->yield( 'privmsg',
        $target,
        $txt
      );

      broadcast( 'message_sent', 
        $context, $target, $txt 
      );

      ++$core->State->{Counters}->{Sent};
    } else {
      logger->error(
        "Bot_message without defined target and txt after Outgoing_message"
      )
    }
  }

  return PLUGIN_EAT_NONE
}


sub Bot_send_notice { Bot_notice(@_) }
sub Bot_notice {
  my ($self, $core) = splice @_, 0, 2;

  unless (defined $_[2]) {
    logger->error("Bot_notice received without enough arguments");
    return PLUGIN_EAT_NONE
  }

  my $context = ${$_[0]};
  my $target  = ${$_[1]};
  my $txt     = ${$_[2]};

  return PLUGIN_EAT_NONE
    unless defined $self->ircobjs->{$context}
    and $core->is_connected($context);

  ## USER event Outgoing_notice
  my @notice = ( $context, $target, $txt );
  my $eat = $core->send_user_event( 'notice', \@notice );

  unless ($eat == PLUGIN_EAT_ALL) {
    my ($target, $txt) = @notice[1,2];

    $self->ircobjs->{$context}->yield( 'notice', 
      $target, 
      $txt
    );

    broadcast( 'notice_sent', $context, $target, $txt );
  }

  return PLUGIN_EAT_NONE
}


sub Bot_send_action { Bot_action(@_) }
sub Bot_action {
  my ($self, $core) = splice @_, 0, 2;

  unless (defined $_[2]) {
    logger->error("Bot_action received without enough arguments");
    return PLUGIN_EAT_NONE
  }

  my $context = ${$_[0]};
  my $target  = ${$_[1]};
  my $txt     = ${$_[2]};

  return PLUGIN_EAT_NONE
    unless defined $self->ircobjs->{$context}
    and $core->is_connected($context);

  ## USER event Outgoing_ctcp (CONTEXT, TYPE, TARGET, TEXT)
  my @ctcp = ( $context, 'ACTION', $target, $txt );
  my $eat = $core->send_user_event( 'ctcp', \@ctcp );

  unless ($eat == PLUGIN_EAT_ALL) {
    my ($target, $txt) = @ctcp[2,3];

    $self->ircobjs->{$context}->yield( 'ctcp',
      $target,
      'ACTION '.$txt
    );

    broadcast( 'ctcp_sent', $context, 'ACTION', $target, $txt );
  }

  return PLUGIN_EAT_NONE
}


sub Bot_topic {
  my ($self, $core) = splice @_, 0, 2;

  unless (defined $_[1]) {
    logger->error("Bot_topic received without enough arguments");
    return PLUGIN_EAT_NONE
  }

  my $context = ${$_[0]};
  my $channel = ${$_[1]};
  my $topic   = defined $_[2] ? ${$_[2]} : "" ;

  return PLUGIN_EAT_NONE
    unless defined $self->ircobjs->{$context}
    and $core->is_connected($context);

  return PLUGIN_EAT_NONE unless $core->is_connected($context);

  $self->irc->yield( 'topic', $channel, $topic );

  return PLUGIN_EAT_NONE
}

sub Bot_mode {
  my ($self, $core) = splice @_, 0, 2;

  unless (defined $_[2]) {
    logger->error("Bot_mode received without enough arguments");
    return PLUGIN_EAT_NONE
  }

  my $context = ${$_[0]};
  my $target  = ${$_[1]}; ## channel or self normally
  my $modestr = ${$_[2]}; ## modes + args

  return PLUGIN_EAT_NONE
    unless defined $self->ircobjs->{$context}
    and $core->is_connected($context);

  my ($mode, @args) = split ' ', $modestr;

  $self->ircobjs->{$context}->yield( 'mode', $target, $mode, @args );

  return PLUGIN_EAT_NONE
}

sub Bot_kick {
  my ($self, $core) = splice @_, 0, 2;

  unless (defined $_[2]) {
    logger->error("Bot_kick received without enough arguments");
    return PLUGIN_EAT_NONE
  }

  my $context = ${$_[0]};
  my $channel = ${$_[1]};
  my $target  = ${$_[2]};
  my $reason  = defined $_[3] ? ${$_[3]} : 'Kicked';

  return PLUGIN_EAT_NONE
    unless defined $self->ircobjs->{$context}
    and $core->is_connected($context);

  return PLUGIN_EAT_NONE unless $core->is_connected($context);

  $self->ircobjs->{$context}->yield( 'kick', $channel, $target, $reason 
);

  return PLUGIN_EAT_NONE
}


sub Bot_join {
  my ($self, $core) = splice @_, 0, 2;

  unless (defined $_[1]) {
    logger->error("Bot_join received without enough arguments");
    return PLUGIN_EAT_NONE
  }

  my $context = ${$_[0]};
  my $channel = ${$_[1]};

  return PLUGIN_EAT_NONE
    unless defined $self->ircobjs->{$context}
    and $core->is_connected($context);

  $self->ircobjs->{$context}->yield( 'join', $channel );

  return PLUGIN_EAT_NONE
}

sub Bot_part {
  my ($self, $core) = splice @_, 0, 2;

  unless (defined $_[1]) {
    logger->error("Bot_part received without enough arguments");
    return PLUGIN_EAT_NONE
  }

  my $context = ${$_[0]};
  my $channel = ${$_[1]};
  my $reason  = defined $_[2] ? ${$_[2]} : 'Leaving' ;

  return PLUGIN_EAT_NONE
    unless defined $self->ircobjs->{$context}
    and $core->is_connected($context);

  $self->ircobjs->{$context}->yield( 'part', $channel, $reason );

  return PLUGIN_EAT_NONE
}

sub Bot_send_raw {
  my ($self, $core) = splice @_, 0, 2;

  unless (defined $_[1]) {
    logger->error("Bot_send_Raw received without enough arguments");
    return PLUGIN_EAT_NONE
  }

  my $context = ${$_[0]};
  my $raw     = ${$_[1]};

  return PLUGIN_EAT_NONE
    unless defined $self->ircobjs->{$context}
    and $core->is_connected($context);

  $self->ircobjs->{$context}->yield( 'quote', $raw );

  broadcast( 'raw_sent', $context, $raw );

  return PLUGIN_EAT_NONE
}


1
