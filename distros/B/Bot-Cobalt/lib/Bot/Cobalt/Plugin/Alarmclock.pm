package Bot::Cobalt::Plugin::Alarmclock;
$Bot::Cobalt::Plugin::Alarmclock::VERSION = '0.021003';
use strictures 2;
use v5.10;

use File::Spec ();

use Bot::Cobalt;
use Bot::Cobalt::DB;
use Bot::Cobalt::Utils 'timestr_to_secs';

use Object::Pluggable::Constants ':ALL';


sub new { 
  bless +{ 
    # $self->timers->{$timerid} = [ $context, $username ]
    _timers => +{},
    _db     => undef,
  }, shift
}

sub timers        { shift->{_timers} }
sub clear_timers  { shift->{_timers} = +{} }

sub _init_from_db {
  my ($self) = @_;
  my $db = $self->{_db};
  unless ($db->dbopen) {
    logger->error("dbopen failure for alarmclock db in _init_from_db");
    logger->error("persistent alarms may be broken!");
    return
  }
  my $count = 0;
  ID: for my $id ($db->dbkeys) {
    my $alarm = $db->get($id);
    unless ($alarm && ref $alarm eq 'HASH') {
      logger->warn(
        defined $alarm ? 
            "Alarm '$id' not a HASH; alarmclock db may be broken!"
          : "Could not retrieve alarm '$id'; alarmclock db may be broken!"
      );
      next ID
    }
    my $expires_at = $alarm->{At};
    unless ($expires_at) {
      logger->warn("No 'At' expiry for timer id '$id', removing");
      $db->del($id);
      next ID
    }
    if ($expires_at <= time) {
      logger->debug("Expiring stale alarmclock '$id'");
      $db->del($id);
      next ID
    }
    $alarm->{Alias} = plugin_alias($self);
    my $secs = $expires_at - time;
    my $new_id = core->timer_set( $secs, $alarm );
    if ($new_id) {
      $self->timers->{$new_id} = [ $alarm->{Context}, $alarm->{User} ];
      $db->put($new_id => $alarm);
      $db->del($id);
      ++$count
    } else {
      logger->warn("Failed to readd alarmclock timer '$id'");
    }
  }
  $db->dbclose;
  $count
}

sub _delete_alarm {
  my ($self, $id) = @_;
  my $db = $self->{_db};
  unless ($db->dbopen) {
    logger->error("dbopen failure for alarmclock db in _delete_alarm");
    logger->error("persistent alarms may be broken!");
  }
  my $ret = $db->del($id);
  unless ($ret) {
    logger->warn("attempted to delete nonexistant alarm ID '$id'");
  }
  $db->dbclose;
  $ret
}


sub Cobalt_register {
  my ($self, $core) = splice @_, 0, 2;

  # FIXME config option for persistent alarms?
  my $dbpath = File::Spec->catfile( $core->var, 'alarmclock.db' );
  $self->{_db} = Bot::Cobalt::DB->new(
    file => $dbpath,
  );
  my $count = $self->_init_from_db;

  register( $self, SERVER => qw/
    public_cmd_alarmclock
    public_cmd_alarmdelete
    public_cmd_alarmdel
    public_cmd_alarmclear
    executed_timer
  / );

  logger->info("Loaded alarm clock ($count existing alarms loaded)");

  PLUGIN_EAT_NONE
}

sub Cobalt_unregister {
  my ($self, $core) = splice @_, 0, 2;
  logger->info("Unregistering core IRC plugin");
  core->timer_del_alias( core->get_plugin_alias($self) );
  $self->clear_timers;
  PLUGIN_EAT_NONE
}

sub Bot_deleted_timer { Bot_executed_timer(@_) }

sub Bot_executed_timer {
  my ($self, $core) = splice @_, 0, 2;
  my $timerid = ${$_[0]};

  return PLUGIN_EAT_NONE
    unless exists $self->timers->{$timerid};

  logger->debug("clearing timer state for $timerid")
    if core->debug > 1;

  delete $self->timers->{$timerid};
  $self->_delete_alarm($timerid);

  PLUGIN_EAT_NONE
}

sub Bot_public_cmd_alarmclear {
  my ($self, $core) = splice @_, 0, 2;
  my $msg = ${ $_[0] };

  my $context = $msg->context;
  my $nick    = $msg->src_nick;

  my $auth_usr = core->auth->username($context, $nick);
  return PLUGIN_EAT_NONE unless $auth_usr
    and core->auth->has_flag($context, $nick, 'SUPERUSER');

  my $target_ctxt = $msg->message_array->[0];

  logger->info(
    "Clearing all alarms"
    . ($target_ctxt ? " for context $target_ctxt" : "")
    . " per $nick ($auth_usr)"
  );

  my $count = 0;
  DELETE: for my $timerid (keys %{ $self->timers }) {
    if ($target_ctxt) {
      my $ctxt_set = $self->timers->{$timerid}->[0];
      next DELETE unless $target_ctxt eq $ctxt_set;
    }
    core->timer_del($timerid);
    delete $self->timers->{$timerid};
    $self->_delete_alarm($timerid);
    ++$count
  }

  broadcast( 'message', $context, $msg->channel,
    core->rpl( q{ALARMCLOCK_DELETED},
      nick    => $nick,
      timerid => (
        $target_ctxt ? "ALL [$target_ctxt] ($count)" : "ALL ($count)"
      ),
    )
  );

  PLUGIN_EAT_ALL
}

sub Bot_public_cmd_alarmdelete { Bot_public_cmd_alarmdel(@_) }

sub Bot_public_cmd_alarmdel {
  my ($self, $core) = splice @_, 0, 2;
  my $msg = ${$_[0]};

  my $context = $msg->context;
  my $nick    = $msg->src_nick;

  my $auth_usr = core->auth->username($context, $nick);
  return PLUGIN_EAT_NONE unless $auth_usr;

  my $timerid = $msg->message_array->[0];
  return PLUGIN_EAT_ALL unless $timerid;

  my $channel = $msg->channel;

  unless (exists $self->timers->{$timerid}) {
    broadcast( 'message', $context, $channel,
      core->rpl( q{ALARMCLOCK_NOSUCH},
        nick    => $nick,
        timerid => $timerid,
      )
    );

    return PLUGIN_EAT_ALL
  }

  my $thistimer = $self->timers->{$timerid};
  my ($ctxt_set, $ctxt_by) = @$thistimer;
  ## did this user set this timer?
  ## original user may've been undef if LevelRequired == 0
  unless ($ctxt_set eq $context && defined $ctxt_by && $auth_usr eq $ctxt_by) {
    my $auth_lev = core->auth->level($context, $nick);
    ## superusers can override:
    unless ($auth_lev == 9999) {
      broadcast( 'message', $context, $channel,
        core->rpl( q{ALARMCLOCK_NOTYOURS},
          nick    => $nick,
          timerid => $timerid,
        )
      );
      return PLUGIN_EAT_ALL
    }
  }

  core->timer_del($timerid);
  delete $self->timers->{$timerid};
  $self->_delete_alarm($timerid);

  broadcast( 'message', $context, $channel,
    core->rpl( q{ALARMCLOCK_DELETED},
      nick    => $nick,
      timerid => $timerid,
    )
  );

  PLUGIN_EAT_ALL
}


sub Bot_public_cmd_alarmclock {
  my ($self, $core) = splice @_, 0, 2;
  my $msg     = ${$_[0]};

  my $context = $msg->context;
  my $setter  = $msg->src_nick;

  my $cfg = plugin_cfg( $self );

  my $minlevel = $cfg->{LevelRequired} // 1;

  ## quietly do nothing for unauthorized users
  unless (core->auth->level($context, $setter) >= $minlevel) {
    logger->debug(
      "ignoring unauthorized alarmclock from '$setter' on '$context'"
    );
    return PLUGIN_EAT_NONE
  }
  
  ## undef if $minlevel == 0
  my $auth_usr = core->auth->username($context, $setter);

  ## This is the array of (format-stripped) args to the _public_cmd_
  my $args = $msg->message_array;
  ## -> f.ex.:  split ' ', !alarmclock 1h10m things and stuff
  my $timestr = shift @$args;
  ## the rest of this string is the alarm text:
  my $txtstr  = join ' ', @$args;

  $txtstr = "$setter: ALARMCLOCK: ".$txtstr ;

  ## set a timer
  my $secs = timestr_to_secs($timestr) || 1;
  my $channel = $msg->channel;

  my $alarm = +{
    Type    => 'msg',
    User    => $auth_usr,
    Context => $context,
    Target  => $channel,
    Text    => $txtstr,
    Alias   => plugin_alias($self),
    At      => time + $secs,
  };
  my $id = core->timer_set( $secs, $alarm );

  my $resp;
  if ($id) {
    $self->timers->{$id} = [ $context, $auth_usr ];
    $resp = core->rpl( q{ALARMCLOCK_SET},
        nick => $setter,
        secs => $secs,
        timerid => $id,
        timestr => $timestr,
    );
    my $db = $self->{_db};
    if ($db->dbopen) {
      $db->put($id => $alarm);
      $db->dbclose;
    } else {
      logger->error("dbopen failure for alarmclock db during add");
    }
  } else {
    $resp = core->rpl( q{RPL_TIMER_ERR} );
  }

  if ($resp) {
    broadcast( 'message', $context, $channel, $resp );
  }

  PLUGIN_EAT_ALL
}

1;
__END__

=pod

=head1 NAME

Bot::Cobalt::Plugin::Alarmclock - Timed IRC highlights

=head1 SYNOPSIS

  # Set alarms:
  > !alarmclock 20m go do some something
  > !alarmclock 1h30m stop staring at irc

  # Remove alarms by timer ID:
  > !alarmdel a1b2c

  # Superusers can remove all alarms (version 0.21.1+):
  > !alarmclear
  # ... or all alarms for a specific context:
  > !alarmclear Main

=head1 DESCRIPTION

This plugin allows authorized users to set a time via either a time string
(see L<Bot::Cobalt::Utils/"timestr_to_secs">) or a specified number of seconds.

When the timer expires, the bot will highlight the user's nickname and
display the specified string in the channel in which the alarmclock was set.

For example:

  !alarmclock 5m check my laundry
  !alarmclock 2h15m10s remind me in 2 hours 15 mins 10 secs

(Accuracy down to the second is not guaranteed. Plus, this is IRC. Sorry.)

As of C<v0.20.1>, alarmclocks will persist between bot runs.

=head1 AUTHOR

Jon Portnoy <avenj@cobaltirc.org>

=cut
