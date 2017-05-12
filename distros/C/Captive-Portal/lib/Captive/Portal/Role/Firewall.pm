package Captive::Portal::Role::Firewall;

use strict;
use warnings;

=head1 NAME

Captive::Portal::Role::Firewall - firewall methods for Captive::Portal

=head1 DESCRIPTION

Does all stuff needed to dynamically update iptables and ipset.

=cut

our $VERSION = '4.10';

use Log::Log4perl qw(:easy);
use Try::Tiny;

use Role::Basic;
requires qw(
  cfg
  spawn_cmd
  list_sessions_from_disk
  get_session_lock_handle
  read_session_handle
  delete_session_from_disk
);

# Role::Basic exports ALL subroutines, there is currently no other way to
# prevent exporting private methods, sigh
#
my ($_fw_install_rules);

=head1 ROLES

=over

=item $capo->fw_start_session($ip_address, $mac_address)

Add tuple IP/MAC to the ipset named I<capo_sessions_ipset>. Members of this ipset have Internet access and are no longer redirected to the login/splash page crossing the gateway.

Also insert this IP into capo_activity_ipset, needed for stateful restarts.

=cut

sub fw_start_session {
  my $self = shift;

  my $ip = shift
    or LOGDIE("missing session IP");

  my $mac = shift
    or LOGDIE("missing session MAC");

  if ( $self->cfg->{MOCK_FIREWALL} ) {
    DEBUG 'MOCK_FIREWALL, mocking start session';
    return 1;
  }

  my @cmd1 = ( 'ipset', '-exist', 'add', 'capo_sessions_ipset', "$ip,$mac" );
  my @cmd2 = ( 'ipset', '-exist', 'add', 'capo_activity_ipset', "$ip" );

  my $error;
  try {
    $self->spawn_cmd(@cmd1);
    $self->spawn_cmd(@cmd2);
  }
  catch { $error = $_ };

  die "$error\n" if $error;

  return;
}

=item $capo->fw_stop_session($ip_address, $mac_address)

Delete tuple IP/MAC from the ipset named I<capo_sessions_ipset>.

=cut

sub fw_stop_session {
  my $self = shift;

  my $ip = shift
    or LOGDIE("missing session IP");

  if ( $self->cfg->{MOCK_FIREWALL} ) {
    DEBUG 'MOCK_FIREWALL, mocking stop session';
    return;
  }

  my @cmd = ( 'ipset', '-exist', 'del', 'capo_sessions_ipset', $ip, );

  my $error;
  try { $self->spawn_cmd(@cmd) } catch { $error = $_ };

  die "$error\n" if $error;

  return;
}

=item $capo->fw_reload_sessions()

This method is called during startup of the Captive::Portal when the old state of the clients must be preserved. Reads the sessions from disc cache and calls fw_start_session for all ACTIVE clients. 

=cut

sub fw_reload_sessions {
  my $self = shift;

  DEBUG "reload firewall rules for cached sessions";

  # list all the cached sessions from disk and install rules
  foreach my $ip ( $self->list_sessions_from_disk ) {

    # fetch session data, lock timeout 1s

    my $lock_handle = $self->get_session_lock_handle(
      key      => $ip,
      blocking => 1,
      shared   => 0,
      timeout  => 1_000_000,    # 1_000_000 us = 1s
    );

    my $session = $self->read_session_handle($lock_handle);

    unless ($session) {
      DEBUG "delete empty or malformed session for $ip";
      $self->delete_session_from_disk($ip);
      next;
    }

    next unless $session->{STATE} eq 'active';

    my $error;
    try { $self->fw_start_session( $ip, $session->{MAC} ) }
    catch { $error = $_ };

    if ($error) {
      ERROR($error);
      $self->delete_session_from_disk($ip);
    }
  }
}

=item $capo->fw_status()

Counts the members of the ipset 'capo_sessions_ipset'. Returns the number of members in this set on success (maybe 0) or undef on error (e.g. ipset undefined).

=cut

sub fw_status {
  my $self = shift;

  my ( $sessions, $error );
  try { $sessions = $self->fw_list_sessions } catch { $error = $_ };

  return if $error;
  return unless defined $sessions;

  my $count = scalar keys %$sessions;
  DEBUG "firewall status: running, $count sessions installed";

  return $count;
}

=item $capo->fw_list_sessions()

Parses the output of:
    ipset list capo_sessions_ipset

and returns a hashref for the tuples { ip => mac, ... }

=cut

sub fw_list_sessions {
  my $self = shift;

  if ( $self->cfg->{MOCK_FIREWALL} ) {
    DEBUG 'MOCK_FIREWALL, mocking ipset';
    return {};
  }

  my @cmd = qw(ipset list capo_sessions_ipset);

  my ( $stdout, $error );
  try { ($stdout) = $self->spawn_cmd(@cmd) } catch { $error = $_ };

  LOGDIE $error if $error;

  my @lines = split "\n+", $stdout;

  # ipv4 address in quad decimal
  my $ip_quad_dec_rx = qr(\d{1,3} \. \d{1,3} \. \d{1,3} \. \d{1,3})x;

  # regex for MAC address matching
  my $hex_digit_rx = qr/[A-F,a-f,0-9]/;
  my $mac_rx       = qr/(?:$hex_digit_rx{2}:){5} $hex_digit_rx{2}/x;

  ####
  # parse the output of:
  #    ipset list capo_sessions_ipset
  #
  # this looks like:
  #----------------
  # Name: capo_sessions_ipset
  # Type: bitmap:ip,mac
  # References: 2
  # Default binding:
  # Header: from: 10.10.0.0 to: 10.10.0.255
  # Members:
  # 10.10.0.2,00:15:2C:FA:BB:80
  # 10.10.0.3,00:15:2C:FA:DB:80
  # 10.10.0.15,00:11:63:9C:9B:85
  # 10.10.0.21,00:1F:4F:EC:B9:42
  # 10.10.0.30,00:54:81:21:7B:01
  # ...
  # Bindings:

  my $sessions = {};
  foreach my $line (@lines) {

    # skip emtpy lines from ipset list
    next if $line =~ m/^\s*$/;

    # skip comment lines from ipset list
    next if $line =~ m/:\s|:\Z/;

    $line =~ m/^\s* ($ip_quad_dec_rx) , ($mac_rx) \s* $/x;
    my $ip  = $1;
    my $mac = $2;

    unless ( defined $ip && defined $mac ) {
      ERROR "Couldn't parse line: $line";
      next;
    }

    $sessions->{$ip} = uc $mac;
  }

  return $sessions;
}

=item $capo->fw_list_activity()

Reads and flushes the ipset 'capo_activity_ipset'  and returns a hashref for the tuples { ip => timeout, ... }

Captive::Portal doesn't rely on JavaScript or any other client technology to test for idle clients. A cronjob must call periodically:

   capo-ctl.pl [-f capo.cfg] [-l log4perl.cfg] purge

in order to detect idle clients. The firewall rules add active clients to the ipset 'capo_activity_ipset' and the purger reads this set for activity checks.

=cut

sub fw_list_activity {
  my $self = shift;

  if ( $self->cfg->{MOCK_FIREWALL} ) {
    DEBUG 'MOCK_FIREWALL, mocking ipset';
    return {};
  }

  my ( $stdout, $error );
  try {
    ($stdout) = $self->spawn_cmd(qw(ipset list capo_activity_ipset));
  }
  catch {
    $error = $_;
  };

  LOGDIE $error if $error;

  my @lines = split "\n+", $stdout;

  # ipv4 address in quad decimal
  my $ip_quad_dec_rx = qr(\d{1,3} \. \d{1,3} \. \d{1,3} \. \d{1,3})x;

  ####
  # parse the output of:
  #    ipset list capo_activity_ipset
  #
  # this looks like:
  #----------------
  # Name: capo_activity_ipset
  # ...
  # Type: bitmap:ip
  # Header: range 10.10.0.0-10.10.255.255 timeout 600
  # Size in memory: 1048688
  # References: 0
  # Members:
  # 10.10.7.7 timeout 98

  my $active_clients = {};
  foreach my $line (@lines) {

    # skip emtpy lines from ipset list
    next if $line =~ m/^\s*$/;

    # skip comment lines from ipset list
    next if $line =~ m/:\s|:\Z/;

    $line =~ m/^\s* ($ip_quad_dec_rx) \s+ timeout \s+ (\d+) /x;
    my $ip      = $1;
    my $timeout = $2;

    unless ( defined $ip && defined $timeout ) {
      ERROR "Couldn't parse line: $line";
      next;
    }

    $active_clients->{$ip} = $timeout;
  }

  return $active_clients;
}

=item $capo->fw_clear_sessions()

Flushes the ipset 'capo_sessions_ipset', normally used in start/stop scripts, see capo-ctl.pl.

=cut

sub fw_clear_sessions {
  my $self = shift;

  $self->$_fw_install_rules('flush_capo_sessions');
}

=item $capo->fw_start()

Calls the firewall templates in the order flush, init, mangle, nat and filter, see the corresponding firewall templates under I<templates/orig/firewall/>. After the init step the ipsets are filled via I<fw_reload_sessions> from disc cache.

=cut

sub fw_start {
  my $self = shift;

  if ( $self->cfg->{MOCK_FIREWALL} ) {
    DEBUG 'MOCK_FIREWALL, mocking start firewall';
    return 1;
  }

  # proper order of steps is essential for uninterrupted reloads

  foreach my $step (qw/flush init mangle nat filter/) {

    $self->$_fw_install_rules($step);

    # after the init step prefill the capo_sessions
    # with cached sessions from disk
    $self->fw_reload_sessions if $step eq 'init';
  }
}

=item $capo->fw_stop()

Calls the firewall template I<flush>, see the corresponding firewall template under I<templates/orig/firewall/>.

=cut

sub fw_stop {
  my $self = shift;

  if ( $self->cfg->{MOCK_FIREWALL} ) {
    DEBUG 'MOCK_FIREWALL, mocking stop firewall';
    return 1;
  }

  $self->$_fw_install_rules('flush');
}

=item $capo->fw_purge_sessions()

Detect idle sessions, mark them as IDLE in disk cache and remove entry in ipset.

=cut

sub fw_purge_sessions {
  my $self = shift;

  DEBUG 'running ' . __PACKAGE__ . ' fw_purge_sessions ...';

  if ( $self->cfg->{MOCK_FIREWALL} ) {
    DEBUG 'MOCK_FIREWALL, mocking purge';
    return 1;
  }

  my $this_run = time();

  ######
  # 3 sources of information about a session
  #
  # - session cache on disk with ip/mac/user/state/timestamps/...
  # - ipset capo_sessions_ipset   with ip address as key, mac address as value
  # - ipset capo_activity_ipset   with ip address as key, mac address as value
  #

  my $fw_sessions = $self->fw_list_sessions;
  my $fw_activity = $self->fw_list_activity;

  # Walk over all disk sessions, be aware, only current session is locked!

  # There will be race conditions with running fcgi processes
  # for sessions not currently handled (locked), but see below
  # for handling these races.
  #
  # This is by intention not locking for a long time and delaying
  # http responses!

  foreach my $ip ( $self->list_sessions_from_disk ) {

    my ( $lock_handle, $error );
    try {

      # get the EXCL lock for the session file
      # hold this lock until next loop iteration
      # via lexical scope of $lock_handle
      #
      $lock_handle = $self->get_session_lock_handle(
        key      => $ip,
        blocking => 1,
        shared   => 0,         # EXCL
        timeout  => 50_000,    # 50_000 us -> 50ms
      );

    }
    catch { $error = $_ };

    if ($error) {
      WARN $error;             # could not get the EXCL lock, skip this session
      next;                    # session
    }

    my $session = $self->read_session_handle($lock_handle);

    unless ($session) {
      DEBUG "delete empty or malformed session: $ip";
      $self->delete_session_from_disk($ip);

      next;                    # session
    }

    # The session ip must also be in the ipset capo_sessions_ipset.
    # fetch and delete it. If there are still ipset entries
    # left after the loop over all sessions, handle it as error
    # or as race condition at end of the purger

    my $fw_session_entry = delete $fw_sessions->{$ip};

    # tmp store for easier logging, no other functionality
    my $mac  = $session->{MAC};
    my $user = $session->{USERNAME};

    ######## let's start

    ###########################################################
    # remove old sessions with STATES like (logout, idle, max-session-...)
    # after KEEP_OLD_STATE_PERIOD
    ###########################################################

    if ( $session->{STATE} ne 'active' ) {

      # remove really old sessions not in active STATE
      if ( $this_run - $session->{STOP_TIME} >
        $self->cfg->{KEEP_OLD_STATE_PERIOD} )
      {
        DEBUG "$user/$ip/$mac" . ' -> delete old session from disk cache';

        my $error;
        try { $self->delete_session_from_disk($ip) } catch { $error = $_ };

        ERROR $error if $error;
      }

      next;    # session
    }

    ###############################################################
    # SESSION_MAX limit reached, stop/mark active and idle sessions
    ###############################################################

    my $session_start = $session->{START_TIME};
    my $session_max   = $self->cfg->{SESSION_MAX};

    if ( ( $this_run - $session_start > $session_max )
      && ( $session->{STATE} eq 'active' || $session->{STATE} eq 'idle' ) )
    {

      INFO "$user/$ip/$mac -> stopped, MAX_SESSION limit";

      my $error;
      try { $self->fw_stop_session($ip) } catch { $error = $_ };

      ERROR $error if $error;

      $session->{STATE}     = 'max-session-timeout';
      $session->{STOP_TIME} = $this_run;

      undef $error;
      try {
        $self->write_session_handle( $lock_handle, $session );
      }
      catch { $error = $_ };

      ERROR $error if $error;

      next;    # session
    }

    next unless $session->{STATE} eq 'active';

    ################################################################
    # below this point we handle only sessions with STATE = active
    ################################################################

    ###########################################################
    # ipset-entry was missing for current session at
    # mainloop entry. Maybe it was a race condition.
    # Check if there is still no ipset-entry for this session
    # now we have the lock.
    #
    # We don't check this unconditionally for every session,
    # this would be to expansive for thousand of clients.
    ###########################################################

    if (  ( not defined $fw_session_entry )
      and ( not defined $self->fw_list_sessions->{$ip} ) )
    {

      WARN "$user/$ip/$mac -> delete session, ipset-entry missing";

      my $error;
      try { $self->delete_session_from_disk($ip); } catch { $error = $_ };

      ERROR $error if $error;

      next;    # session
    }

    ###########################################################
    ###########################################################
    # now start with the IDLE check for this active session
    ###########################################################
    ###########################################################

    ###########################################################
    # packets seen from this client within last IDLE_TIME period?
    # the capo_activity_ipset has the internal countdown timer
    # set with IDLE_TIME, great thanks to the ipset developers!
    ###########################################################

    next if exists $fw_activity->{$ip};

    ###########################################################
    ###########################################################
    # after that the client wasn't seen for IDLE_TIME
    ###########################################################
    ###########################################################

    INFO "$user/$ip/$mac -> session is IDLE";

    $session->{STATE}     = 'idle';
    $session->{STOP_TIME} = $this_run;

    undef $error;
    try {
      $self->fw_stop_session($ip);
      $self->write_session_handle( $lock_handle, $session );
    }
    catch { $error = $_ };
    ERROR $error if $error;

    next;    # session

  }    # session mainloop end

  ###########################################################
  # Handle remaining ipset session entries with
  # no corresponding session file. Be careful,
  # maybe a race condition between purger and fcgi script
  # was the reason for that inconsistency
  ###########################################################

  foreach my $ip ( keys %{$fw_sessions} ) {

    # check if there is still no session file for that ipset entry
    #
    my ( $lock_handle, $error );
    try {

      # get the EXCL lock for the session
      # hold this lock until next loop iteration
      #
      $lock_handle = $self->get_session_lock_handle(
        key      => $ip,
        blocking => 1,
        shared   => 0,
        timeout  => 50_000,    # 50_000 us -> 50ms
      );

    }
    catch { $error = $_ };

    if ($error) {
      WARN $error;
      next;
    }

    my $session = $self->read_session_handle($lock_handle);

    # skip, now we have a valid session for this ipset session entry
    next if $session;

    # Still no session for this ipset session entry, but
    # we have the lock, now we can check if the ipset entry
    # is still set

    next unless defined $self->fw_list_sessions->{$ip};

    WARN "$ip -> delete ipset entry without session file";

    undef $error;
    try { $self->fw_stop_session($ip) } catch { $error = $_ };
    ERROR $error if $error;

    next;
  }
}

# ATTENTION
# private method, not exported to Captive::Portal
#
# $capo->$_fw_install_rules($template_name);
#
# Reads the template, sanitize it and call the commands in the template file via spawn_cmd
#

$_fw_install_rules = sub {
  my $self = shift;
  my $step = shift
    or LOGDIE "missing param 'step'";

  my $cmds;
  my $template  = "firewall/${step}.tt";
  my $tmpl_vars = {
    %{ $self->cfg->{IPTABLES} },
    IDLE_TIME => $self->cfg->{IDLE_TIME},
    ipv4_aton => $self->can('ipv4_aton'),
  };

  DEBUG "get the firewall $step commands via template $template";

  $self->{template}->process( $template, $tmpl_vars, \$cmds )
    or LOGDIE( $self->{template}->error . "\n" );

  ##############################################
  # mangle the command lines
  #

  # remove comment lines
  $cmds =~ s/^ \s* \# .* $ \n//xmg;

  # remove empty lines
  $cmds =~ s/^ \s* $ \n//xmg;

  # concat continuation lines
  $cmds =~ s/\\ \s* $ \n \s*/ /xmg;

  # remove leading whitespace
  $cmds =~ s/^ \s* //xmg;

  my @cmds = split( /\n/, $cmds );

  #
  #################################################

  foreach my $cmd (@cmds) {
    my @cmd = split( /\s+/, $cmd );

    my $error;
    try { $self->spawn_cmd(@cmd) } catch { $error = $_ };

    die $error if $error;
  }
};

1;

=back

=head1 AUTHOR

Karl Gaissmaier, C<< <gaissmai at cpan.org> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2010-2013 Karl Gaissmaier, all rights reserved.

This distribution is free software; you can redistribute it and/or modify it
under the terms of either:

a) the GNU General Public License as published by the Free Software
Foundation; either version 2, or (at your option) any later version, or

b) the Artistic License version 2.0.

=cut

# vim: sw=2
