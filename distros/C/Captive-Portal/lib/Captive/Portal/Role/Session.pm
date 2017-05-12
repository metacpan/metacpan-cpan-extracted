package Captive::Portal::Role::Session;

use strict;
use warnings;

=head1 NAME

Captive::Portal::Role::Session - session methods for Captive::Portal

=cut

our $VERSION = '4.10';

use Log::Log4perl qw(:easy);
use JSON qw();
use Try::Tiny;
use Digest::MD5 qw(md5_hex);
use Captive::Portal::LockHandle;

use Role::Basic;
requires qw(
  cfg
  spawn_cmd
  normalize_ip
  find_mac
);

# Role::Basic exports ALL subroutines, there is currently no other way to
# prevent exporting private methods, sigh
#
my $_init_session = sub {
    my ( $self, $ip, $mac ) = @_;

    my $new_session = {
        STATE => 'init',
        IP    => $ip,
        MAC   => $mac,
    };

    return $new_session;
};

=head1 DESCRIPTION

IP addresses of clients must be unique. They are determined by the HTTP-Parameter I<REMOTE_ADDR>. The corresponding MAC-address is determined from the ARP-table. If there are duplicate IP-addresses for different MAC-addresses something bad is happening (ARP-spoofing, ...). Captive::Portal warns on duplicate IP-addresses.

Active sessions have corresponding IP/MAC entries in the B<capo_sessions_ipset>.

Session state is recorded on disc under the $SESSIONS_DIR. The session state is JSON encoded.

Example: active session

  {
      "STATE"      : "active",
      "START_TIME" : 1317106093,
      "STOP_TIME"  : "",
      "USERNAME"   : "foo",
      "IP"         : "134.60.239.90",
      "MAC"        : "F0:F4:69:17:89:DE",
      "USER_AGENT" : "Mozilla/5.0 ... Safari/534.50",
      "COOKIE"     : "202ceeee8c0ec85869dbac19c57c3c5e"
  }

=head1 ROLES

All roles throw exceptions on error.

=over 4

=item $capo->get_current_session()

Returns the current- or a new initialized session-hash for this HTTP-Client.

=cut

sub get_current_session {
    my $self = shift;

    my $query = $self->{CTX}{QUERY};

    my ( $ip, $mac_from_arptable );
    $ip = $query->remote_addr
      or LOGDIE "Couldn't fetch client IP from HTTP query\n";

    $ip = $self->normalize_ip($ip);

    DEBUG "try to find MAC addr for ip '$ip'";
    $mac_from_arptable = $self->find_mac($ip);

    unless ($mac_from_arptable) {
        WARN "request from '$ip', no MAC address found";
        return;
    }

    DEBUG("use mac '$mac_from_arptable' for ip '$ip'");

    # fetch session data, non-blocking shared lock
    # don't fill the lock queue with readers

    my ( $session, $error );
    try {
        my $lock_handle = $self->get_session_lock_handle(
            key      => $ip,
            try      => 10,
            blocking => 0,
            shared   => 1,
        );

        $session = $self->read_session_handle($lock_handle);
    }
    catch { $error = $_ };

    die "$error\n" if $error;

    unless ($session) {

        DEBUG "initialize new session for $ip/$mac_from_arptable";
        $session = $self->$_init_session( $ip, $mac_from_arptable );

        return $session;
    }

    # session for IP exists already, check for same MAC address
    if ( $mac_from_arptable eq $session->{MAC} ) {

        DEBUG "return current session for $ip";
        return $session;

    }

    ###############################
    # handle duplicate IP address
    #

    my $mac  = $session->{MAC};
    my $user = $session->{USERNAME};

    DEBUG "old session $user/$ip/$mac with different MAC on disk cache";

    #
    # is old session still marked as active?
    # die with error page
    #
    if ( $session->{STATE} eq 'active' ) {
        WARN "$user/$ip/$mac -> duplicate IP from $mac_from_arptable";
        die "Your IP address is duplicate: $ip\n";
    }

    ########
    # old session is already idle, init new session,
    # disk cache is rewritten after login
    #
    DEBUG "initialize new session for $ip/$mac_from_arptable";
    $session = $self->$_init_session( $ip, $mac_from_arptable );

    return $session;
}

=item $capo->open_sessions_dir()

Open/create the sessions directory defined in the config file.

=cut

sub open_sessions_dir {
    my $self = shift;

    my $sessions_dir = $self->cfg->{SESSIONS_DIR};

    unless ( -d $sessions_dir ) {

        DEBUG("create sessions directory: $sessions_dir");
        my @cmd = ( 'mkdir', '-p', $sessions_dir );

        my $error;
        try {
            $self->spawn_cmd(@cmd);
        }
        catch {
            $error = $_;
        };

        LOGDIE $error if $error;
    }

    # the sessions directory must be writable

    LOGDIE "missing write permissions on '$sessions_dir'"
      unless -w $sessions_dir;

    return 1;
}

=item $capo->clear_sessions_from_disk()

Unlink all session files from disk.

=cut

sub clear_sessions_from_disk {
    my $self = shift;

    DEBUG 'clearing all sessions';

    foreach my $key ( $self->list_sessions_from_disk ) {

        my $error;
        try {
            my $lock_handle = $self->get_session_lock_handle(
                key      => $key,
                blocking => 0,
                shared   => 0,      # EXCL
                try      => 10,
            );

            DEBUG "delete session: $key";
            $self->delete_session_from_disk($key);

        }
        catch { $error = $_ };
        LOGDIE "$error\n" if $error;
    }

    return 1;
}

=item $capo->list_sessions_from_disk()

Return a list of all session filenames in sessions dir.

=cut

sub list_sessions_from_disk {
    my $self = shift;

    my $sessions_dir = $self->cfg->{SESSIONS_DIR};

    opendir( my $dir_handle, $sessions_dir )
      or LOGDIE "Couldn't opendir $sessions_dir: $!";

    # session filenames are ip addresses
    my @sessions =
      grep { m/\A \d{1,3} \. \d{1,3} \. \d{1,3} \. \d{1,3} \Z/x }
      readdir $dir_handle;

    return @sessions;
}

=item $capo->get_session_lock_handle(%named_params)

Return a filehandle to the clients session file with the requested lock assigned. There is no unlock required, after destroying the filehandle the file is closed and the lock released.

Named parameters:

 key      => ip address of session
 shared   => shared lock, defaults to exclusive lock
 blocking => blocking lock request, defaults to blocking
 try      => number of retries in nonblocking mode, defaults to 1 retry
 timeout  => timeout in blocking mode, defaults to 1s

=cut

sub get_session_lock_handle {
    my $self = shift;
    my %opts = @_;

    LOGDIE "missing param 'key'" unless exists $opts{key};

    $opts{file} = $self->cfg->{SESSIONS_DIR} . "/$opts{key}";

    # just a wrapper for:
    #
    return Captive::Portal::LockHandle->new(%opts);
}

=item $capo->read_session_handle($lock_handle)

Read the session file for $lock_handle and decode the JSON format into a hashref.

=cut

sub read_session_handle {
    my $self = shift;
    my $fh   = shift
      or LOGDIE "missing param 'file_handle'";

    DEBUG "read_session_handle";

    seek( $fh, 0, 0 ) or LOGDIE "Couldn't rewind session file: $!";

    local $/;
    my $slurp = <$fh>;

    unless ( defined $slurp ) {
        ERROR "Couldn't slurp session file: $!";
        return;
    }

    # emtpy file
    return if $slurp eq '';

    my ( $session, $error );
    try { $session = JSON->new->decode($slurp) } catch { $error = $_ };

    if ($error) {

        # JSON exception to logfile
        ERROR $error;

        return;
    }

    return $session;
}

=item $capo->write_session_handle($lock_handle, $session)

Encode the session hashref into JSON and write the session file belonging to $lock_handle.

=cut

sub write_session_handle {
    my $self = shift;

    my $fh = shift
      or LOGDIE "missing param 'file_handle'";

    my $session = shift
      or LOGDIE "missing param 'session'";

    DEBUG "write_session_handle";

    seek( $fh, 0, 0 ) or LOGDIE "Couldn't rewind session file: $!";
    truncate( $fh, 0 ) or LOGDIE "Couldn't truncate session file: $!";

    print $fh JSON->new->pretty->encode($session)
      or LOGDIE "Couldn't write session: $!";
}

=item $capo->delete_session_from_disk($key)

Unlink session file from disk.

=cut

sub delete_session_from_disk {
    my $self = shift;

    my $key = shift
      or LOGDIE "missing param 'session key'";

    DEBUG "delete session from disk '$key'";

    my $fname = $self->cfg->{SESSIONS_DIR} . "/$key";

    unlink $fname or die "Couldn't unlink '$fname': $!";
}

=item $capo->mk_cookie()

Generate a I<CaPo> cookie with random- and session-data or use the already existing session cookie. The cookie is used to fast reactivate an idle session if the IP/MAC/COOKIE is still matching. Cookies are not mandatory, they are just for a better user experience.

=cut

sub mk_cookie {
    my $self = shift;

    my $session = $self->{CTX}{SESSION}
      or LOGDIE "FATAL: missing 'SESSION' in run CTX,";

    my $query = $self->{CTX}{QUERY}
      or LOGDIE "FATAL: missing 'QUERY' in run CTX,";

    my $value;
    if ( $value = $session->{COOKIE} ) {
        DEBUG 'use stored cookie-value from session data';
    }
    else {
        DEBUG 'generate cookie with session- and random-data';

        $value = md5_hex(
                time()
              . $session->{IP}
              . $session->{MAC}
              . $session->{USERNAME}
              . int( rand(100000) ) );
    }

    my $cookie = $query->cookie(
        -name     => 'CaPo',
        -value    => $value,
        -httponly => 1,
        $self->cfg->{SSL_REQUIRED} ? ( -secure => 1 ) : (),
    ) or LOGDIE "Couldn't create cookie\n";

    return $cookie;
}

=item $capo->match_cookie()

Check if request cookie is equal session cookie. Returns true on success and false on failure.

=cut

sub match_cookie {
    my $self = shift;

    DEBUG "compare request cookie with session cookie";

    my $query = $self->{CTX}{QUERY}
      or LOGDIE "FATAL: missing 'QUERY' in run CTX,";

    my $session = $self->{CTX}{SESSION}
      or LOGDIE "FATAL: missing 'SESSION' in run CTX,";

    return unless $session->{COOKIE};

    my $request_cookie = $query->cookie('CaPo');
    return unless $request_cookie;

    return 1 if $request_cookie eq $session->{COOKIE};

    return;
}

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

# vim: sw=4
