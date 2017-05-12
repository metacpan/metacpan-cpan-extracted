package Bot::Cobalt::Plugin::Seen;
$Bot::Cobalt::Plugin::Seen::VERSION = '0.021003';
use v5.10;
use Bot::Cobalt;
use Bot::Cobalt::Common;
use Bot::Cobalt::DB;

use Path::Tiny;

sub SDB () { 0 }
sub BUF () { 1 }

sub new { 
  bless [
    undef, # SDB
    +{},   # BUF
  ], shift
}

sub _parse_nick {
  my ($context, $nickname) = @_;
  lc_irc $nickname, (core->get_irc_casemap($context) || 'rfc1459')
}

## FIXME method to retrieve users w/ similar hosts
## !seen search ... ?

sub retrieve {
  my ($self, $context, $nickname) = @_;
  $nickname = _parse_nick($context, $nickname);

  my $ref = $self->[BUF]->{$context}->{$nickname}; # intentional autoviv
  unless (defined $ref) {
    my $db = $self->[SDB];
    unless ($db->dbopen) {
      logger->warn("dbopen failed in retrieve; cannot open SeenDB");
      return
    }
    my $thiskey = $context .'%'. $nickname;
    $ref = $db->get($thiskey);
    $db->dbclose;
  }

  ref $ref ? $ref : ()
}

sub Cobalt_register {
  my ($self, $core) = splice @_, 0, 2;
    
  my $pcfg = $core->get_plugin_cfg($self);
  my $seendb_path = path(
    $core->var .'/'. ($pcfg->{SeenDB} || "seen.db")
  );
  
  logger->info("Opening SeenDB at $seendb_path");

  $self->[BUF] = +{};
  $self->[SDB] = Bot::Cobalt::DB->new(file => $seendb_path);
  
  my $rc = $self->[SDB]->dbopen;
  $self->[SDB]->dbclose;
  unless ($rc) {
    logger->warn("Failed to open SeenDB at $seendb_path");
    die "Unable to open SeenDB at $seendb_path"
  }

  register( $self, 'SERVER', 
    qw/
    
      public_cmd_seen
      
      nick_changed      
      chan_sync
      user_joined
      user_left
      user_quit
      
      seendb_update
      
      seenplug_deferred_list
      
    /,
  );
  
  core->timer_set( 6, 
    +{ Event => 'seendb_update' },
    'SEENDB_WRITE'
  );
  
  logger->info("Loaded");
  
  PLUGIN_EAT_NONE
}

sub Cobalt_unregister {
  my ($self, $core) = splice @_, 0, 2;
  $self->Bot_seendb_update($core, \1);
  $core->log->info("Unloaded");
  PLUGIN_EAT_NONE
}

sub Bot_seendb_update {
  my ($self, $core) = splice @_, 0, 2;
  my $force_flush = @_ ? ${ $_[0] } : 0;

  my $buf = $self->[BUF];
  unless (keys %$buf) {
    $core->timer_set( 2, +{ Event => 'seendb_update' } );
    return PLUGIN_EAT_ALL
  }

  my $db  = $self->[SDB];

  CONTEXT: for my $context (keys %$buf) {
    unless ($db->dbopen) {
      logger->warn("dbopen failed in update; cannot update SeenDB");
      # FIXME exponential back-off?
      $core->timer_set( 6, +{ Event => 'seendb_update' } );
      return PLUGIN_EAT_ALL
    }

    my $writes;
    NICK: for my $nickname (keys %{ $buf->{$context} }) {
      ## if we've done a lot of writes, yield back (unless we're cleaning up)
      if (!$force_flush && $writes && $writes % 50 == 0) {
        $db->dbclose;
        broadcast 'seendb_update';
        return PLUGIN_EAT_ALL
      }
      ## .. else flush this item to disk
      my $thisbuf = delete $buf->{$context}->{$nickname};
      my $thiskey = $context .'%'. $nickname;
      $db->put($thiskey, $thisbuf);
      ++$writes;
    } ## NICK
    $db->dbclose;
    
    delete $buf->{$context} unless keys %{ $buf->{$context} };
  
  } ## CONTEXT
  
  $core->timer_set( 2, +{ Event => 'seendb_update' } );  

  return PLUGIN_EAT_ALL
}

sub Bot_user_joined {
  my ($self, $core) = splice @_, 0, 2;
  my $join    = ${ $_[0] };
  my $context = $join->context;

  my $nick = $join->src_nick;
  my $user = $join->src_user;
  my $host = $join->src_host;
  my $chan = $join->channel;

  $nick = _parse_nick($context, $nick);
  $self->[BUF]->{$context}->{$nick} = +{
    TS       => time(),
    Action   => 'join',
    Channel  => $chan,
    Username => $user,
    Host     => $host,
  };
  
  PLUGIN_EAT_NONE
}

sub Bot_chan_sync {
  my ($self, $core) = splice @_, 0, 2;
  my $context = ${$_[0]};
  my $channel = ${$_[1]};

  broadcast seenplug_deferred_list => $context, $channel;

  PLUGIN_EAT_NONE
}

sub Bot_seenplug_deferred_list {
  my ($self, $core) = splice @_, 0, 2;
  my $context = ${$_[0]};
  my $channel = ${$_[1]};
    
  my $irc   = $core->get_irc_object($context);
  my @nicks = $irc->channel_list($channel);
  for my $nick (@nicks) {
    $nick = _parse_nick($context, $nick);
    $self->[BUF]->{$context}->{$nick} = +{
      TS       => time(),
      Action   => 'present',
      Channel  => $channel,
      Username => '',
      Host     => '',
    };
  }
  
  PLUGIN_EAT_ALL
}

sub Bot_user_left {
  my ($self, $core) = splice @_, 0, 2;
  my $part    = ${ $_[0] };
  my $context = $part->context;
  
  my $nick = $part->src_nick;
  my $user = $part->src_user;
  my $host = $part->src_host;
  my $chan = $part->channel;

  $nick = _parse_nick($context, $nick);
  $self->[BUF]->{$context}->{$nick} = +{
    TS => time(),
    Action   => 'part',
    Channel  => $chan,
    Username => $user,
    Host     => $host,
  };

  PLUGIN_EAT_NONE
}

sub Bot_user_quit {
  my ($self, $core) = splice @_, 0, 2;
  my $quit    = ${ $_[0] };
  my $context = $quit->context;
  
  my $nick = $quit->src_nick;
  my $user = $quit->src_user;
  my $host = $quit->src_host;
  my $common = $quit->common;

  $nick = _parse_nick($context, $nick);
  $self->[BUF]->{$context}->{$nick} = +{
    TS => time(),
    Action   => 'quit',
    Channel  => $common->[0],
    Username => $user,
    Host     => $host,
  };
  
  PLUGIN_EAT_NONE
}

sub Bot_nick_changed {
  my ($self, $core) = splice @_, 0, 2;
  my $nchange = ${ $_[0] };
  my $context = $nchange->context;
  return PLUGIN_EAT_NONE if $nchange->equal;
  
  my $old = $nchange->old_nick;
  my $new = $nchange->new_nick;
  
  my $irc = $core->get_irc_obj($context);
  my $src = $irc->nick_long_form($new) || $new;
  my ($nick, $user, $host) = parse_user($src);
  
  my $first_common = $nchange->channels->[0];

  $self->[BUF]->{$context}->{$old} = +{
    TS => time(),
    Action   => 'nchange',
    Channel  => $first_common,
    Username => $user || 'unknown',
    Host     => $host || 'unknown',
    Meta     => { To => $new },
  };
  
  $self->[BUF]->{$context}->{$new} = +{
    TS => time(),
    Action   => 'nchange',
    Channel  => $first_common,
    Username => $user || 'unknown',
    Host     => $host || 'unknown',
    Meta     => { From => $old },
  };
  
  PLUGIN_EAT_NONE
}

sub Bot_public_cmd_seen {
  my ($self, $core) = splice @_, 0, 2;
  my $msg     = ${ $_[0] };
  my $context = $msg->context;
  
  my $channel = $msg->channel;
  my $nick    = $msg->src_nick;
  
  my $targetnick = $msg->message_array->[0];
  
  unless ($targetnick) {
    broadcast message => $context, $channel,
      "Need a nickname to look for, $nick";
    return PLUGIN_EAT_NONE
  }
  
  my $ref = $self->retrieve($context, $targetnick);
  
  unless ($ref) {
    broadcast message => $context, $channel,
      "${nick}: I don't know anything about $targetnick";

    return PLUGIN_EAT_NONE
  }
  
  my $last_ts   = $ref->{TS};
  my $last_act  = $ref->{Action}  // '';
  my $last_chan = $ref->{Channel};
  my $last_user = $ref->{Username};
  my $last_host = $ref->{Host};
  my $meta = $ref->{Meta} // {};

  my $ts_delta = time - $last_ts ;
  my $ts_str   = secs_to_str_y($ts_delta);

  my $resp;
  ACTION: {
    if ($last_act eq 'quit') {
      $resp = 
        "$targetnick was last seen quitting IRC $ts_str ago";
      last ACTION
    }
    
    if ($last_act eq 'join') {
      $resp =
        "$targetnick was last seen joining $last_chan $ts_str ago";
      last ACTION
    }
    
    if ($last_act eq 'part') {
      $resp =
        "$targetnick was last seen leaving $last_chan $ts_str ago";
      last ACTION
    }
    
    if ($last_act eq 'present') {
      $resp =
        "$targetnick was last seen when I joined $last_chan $ts_str ago";
      last ACTION
    }
    
    if ($last_act eq 'nchange') {
      if ($meta->{From}) {
        $resp = "$targetnick was last seen changing nicknames from "
          . $meta->{From} .
          " $ts_str ago";

      } elsif ($meta->{To}) {
        $resp = "$targetnick was last seen changing nicknames to "
          . $meta->{To} .
          " $ts_str ago";
      } else {
        logger->warn("BUG; no To/From recorded for nick change");
        $resp = 'Something weird happened; check log file for details.';
      }

      last ACTION
    }

    logger->warn("BUG; unknown action '$last_act'");
    $resp = 'Something weird happened; check log file for details.';
  }  

  broadcast message => $context, $channel, $resp;  
  
  PLUGIN_EAT_NONE
}

1;
__END__

=pod

=head1 NAME

Bot::Cobalt::Plugin::Seen - Bot::Cobalt 'seen' plugin

=head1 SYNOPSIS

  !seen SomeNickname

=head1 DESCRIPTION

A fairly basic 'seen' command; tracks users joining, leaving, and 
changing nicknames.

Uses L<Bot::Cobalt::DB> for storage.

The path to the SeenDB can be specified via C<plugins.conf>:

  Seen:
    Module: Bot::Cobalt::Plugin::Seen
    Opts:
      SeenDB: path/relative/to/var/seen.db

=head1 AUTHOR

Jon Portnoy <avenj@cobaltirc.org>

=cut
