package Captive::Portal;

use strict;
use warnings;

our $VERSION = '4.10';

=head1 NAME

Captive::Portal - Perl based solution for controlled network access

=head1 ABSTRACT

A so called I<Captive Portal> written in perl for Linux Gateways. For a longer explanation see:

L<http://en.wikipedia.org/wiki/Captive_Portal>

=head1 DESCRIPTION

Captive::Portal a.k.a. CaPo is a hotspot solution for Linux Gateways. CaPo is developed and in service at Ulm University for thousands of concurrent users.

The main focus is scalability, performance, simple administration and user-friendliness. The goals have been achieved by using scalable technologies like ipset/iptables, FastCGI/CGI and a fine tuned concurrent session handling based on the filesystem locking mechanism without any need for an additional RDBMS.

CaPo is compatible with any FastCGI/CGI enabled HTTPS-server.

=head1 ALGORITHM IN SHORT

=over 4

=item 1. Access Denied

Only selected protocols like DHCP/DNS/NTP/IMAPS/IPSec/... to selected servers are allowed for unauthenticated clients.

=item 2. Internal NAT redirect

HTTP-traffic on the gateways inside interface - from unauthenticated clients - is redirected by an iptables(8) NAT-rule to a port the HTTP-server is listening, e.g.

 iptables -t nat -A PREROUTING -i eth1 -p tcp --dport 80 -j REDIRECT --to-port 5281

=item 3. External HTTP redirect

The HTTP-server redirects the HTTP-request by a rewrite rule to an HTTPS-request for the CaPo script I<capo.fcgi> , e.g.

 <VirtualHost *:5281>
     RewriteEngine On
     RewriteRule   .*  https://gateway.acme.org/capo/? [R,L]
 </VirtualHost>

 CLIENT REQUEST:

    GET /foo/bar HTTP/1.1
    Host: www.test.org

 SERVER RESPONSE:

    HTTP/1.1 302 Found
    Location: https://gateway.acme.org/capo/

=item 4. SESSION LOGIN

The I<capo.fcgi> script, fired due to this redirected request, offers a splash/login page. After successful login the firewall is dynamically changed to allow this clients IP/MAC tuple for internet access by ipset(8):

    ipset add capo_sessions_ipset CLIENT_IP,CLIENT_MAC

=item 5.  SESSION LOGOUT

The capo.fcgi script offers a status/logout page. After successful logout the firewall is dynamically changed to disallow this IP/MAC tuple for internet access.

    ipset del capo_sessions_ipset CLIENT_IP

=item 6. SESSION IDLE

A cronjob fires periodically the capo-ctl.pl script checking for idle or malformed sessions. Idle means, the client didn't send any packet for a period of time (cfg param: IDLE_TIME = 10min). Clients sending packets are registered via iptables/ipset in the capo_activity_ipset.

=item 7. COMFORTABLE SESSION REACTIVATION

For a short period of time (cfg param: KEEP_OLD_STATE_PERIOD = 1h) the session is still on disc, but in IDLE state. If a client has cookies enabled and a HTTP request matches the stored IP/MAC/COOKIE data on disc, the session is reactivated without a login page.

=back

=head1 INSTALLATION

Please see the INSTALL file in this distribution.

=head1 CONFIGURATION

The configuration file is searched in the following default places:

    $ENV{CAPTIVE_PORTAL_CONFIG} ||
    $Bin/../etc/local/config.pl ||
    $Bin/../etc/config.pl

=head1 LOGGING

Logging is handled by the Log::Log4perl module. The logging configuration is searched in the following default places:

    $ENV{CAPTIVE_PORTAL_LOG4PERL}   ||
    $Bin/../etc/local/log4perl.conf ||
    $Bin/../etc/log4perl.conf

=head1 LOCAL ADAPTATION

The HTML files are generated from templates (Template-Toolkit syntax). You should use the original template files as stanzas and put the locally changed versions into the local template tree. The template search order prefers the local templates.

The CSS is based on the wonderful blueprint css framework, see L<http://www.blueprintcss.org/>. Of course you may use your own styles if needed.

The firewall rules and commands are also generated from template files. Normally there is no need to change the firewall rules but it would be possible to add some local needed additional rules without changing the perl code. Be careful, you must understand the algorithm and the different states. Best you ask the author for any modifications.

=head1 I18N

There exists a template tree for each supported language. Some system/error messages used by the program must also be translated for the message catalog in the config file.

=cut

use POSIX qw(strftime);
use Log::Log4perl qw(:easy);
use Try::Tiny;
use Template;

# consume CaPo roles
use Role::Basic qw(with);
with qw(
  Captive::Portal::Role::Config
  Captive::Portal::Role::Utils
  Captive::Portal::Role::I18N
  Captive::Portal::Role::AuthenSimple
  Captive::Portal::Role::Session
  Captive::Portal::Role::Firewall
);

#################################################
# create CaPo object once
#
# read the config
# drop privileges
# create Template object
# create authentication object
# open/create session dir
#
sub new {
    my $class = shift or LOGDIE "missing param 'class'\n";

    # create empty object
    my $self = bless {}, $class;

    my $opts = {};
    if ( ref $_[0] && ref $_[0] eq 'HASH' ) {
        $opts = shift;
    }
    else {
        %$opts = @_;
    }

    # parse cfg file or use defaults
    if ( $opts->{cfg_file} ) {
        DEBUG('new(): parse cfg file');
        $self->parse_cfg_file( $opts->{cfg_file} );
    }

    DEBUG 'new(): drop privileges';
    $self->drop_privileges;

    DEBUG 'new(): try to create Template object with INCLUDE_PATH: ',
      join( ':', $self->cfg->{TEMPLATE_INCLUDE_PATH} );

    $self->{template} = Template->new(
        { INCLUDE_PATH => $self->cfg->{TEMPLATE_INCLUDE_PATH}, } )
      or LOGDIE "$Template::ERROR\n";

    DEBUG 'new(): create Authen::Simple object';
    $self->build_authenticator
      or LOGDIE "Couldn't build Authen::Simple object\n";

    # check/create sessions-dir
    DEBUG 'new(): check or create sessions-dir';
    $self->open_sessions_dir;

    return $self;    # CaPo object
}

##############################################
# run is the entry point for any http request
#
sub run {
    my $self = shift;    # CaPo object

    my $query = shift or LOGDIE "run(): missing param 'query'\n";
    my $path_info   = $query->path_info   || '';
    my $client_addr = $query->remote_addr || '?.?.?.?';

    DEBUG('------------- run(): REQUEST BEGIN --------------');

    # rip passwords from url for safe logging
    my $safe_url = $query->self_url;
    $safe_url =~ s/password=     .+? (;|\Z) /password=******;/x;
    $safe_url =~ s/admin_secret= .+? (;|\Z) /admin_secret=******;/x;

    DEBUG "got request from $client_addr: $safe_url  ...";
    DEBUG "got path_info: $path_info";

    my $error;
    try {

        ########
        # reset this requests context with current request values
        #
        $self->{CTX}            = {};
        $self->{CTX}{QUERY}     = $query;
        $self->{CTX}{PATH_INFO} = $path_info;

        $self->{CTX}{HEADER} = $query->header(
            -type    => 'text/html',
            -charset => 'UTF-8',
        );
        $self->{CTX}{BODY} = '';
        $self->{CTX}{LANG} = $self->choose_language;
        DEBUG( 'choosen language: ' . $self->{CTX}{LANG} );

        $self->{CTX}{TMPL_VARS}               = {};
        $self->{CTX}{TMPL_VARS}{version}      = $VERSION;
        $self->{CTX}{TMPL_VARS}{ssl_required} = $self->cfg->{SSL_REQUIRED};

        ########
        # start the dispatcher for this request
        #
        $self->dispatch;
    }
    catch { $error = $_ };

    if ($error) {
        WARN "catched error: $error";

        $self->{CTX}{BODY} = error_page_500($error);

        $self->{CTX}{HEADER} = $query->header(
            -status  => 500,
            -type    => 'text/html',
            -charset => 'UTF-8',
        );
    }

    ########
    # print this requests answer page
    #
    DEBUG('print http-header');
    print $self->{CTX}{HEADER};

    # ... or LOGDIE "Couldn't print HTTP header";
    # not possible, bug in older FCGI versions, sigh

    DEBUG('print http-body');
    print $self->{CTX}{BODY};

    # ... or LOGDIE "Couldn't print HTTP body";
    # not possible, bug in older FCGI versions, sigh

    DEBUG('------------- run(): REQUEST END ----------------');
    return;
}

##############################################
# dispatch this request to the proper handler
# different actions can be requested by CGI parameters or path_info
#
# status:     show a short status page
# is_running: show in plain text numbers of active sessions
# login:      process login and show active page
# logout:     process logout and show splash page
# .*:         show splash page
#
sub dispatch {
    my $self = shift;

    DEBUG 'running DISPATCH handler ...';

    # this requests parameters are in the context slot
    my $query     = $self->{CTX}{QUERY};
    my $path_info = $self->{CTX}{PATH_INFO};

    ###############################################################
    # first check for status requests
    ###############################################################

    #############
    # check if the status page is requested via path_info

    if ( $path_info =~ m/\b status \b/x ) {
        return $self->summary_status_view;
    }

    # or via cgi parameter
    if ( exists $query->Vars->{status} ) {
        return $self->summary_status_view;
    }

    #############
    # check if the is_running status page is requested via path_info

    if ( $path_info =~ m/\b is_running \b/x ) {
        return $self->is_running_view;
    }

    # or via cgi parameter
    if ( exists $query->Vars->{is_running} ) {
        return $self->is_running_view;
    }

    ###############################################################
    # now dispatch all the remaining client requests
    ###############################################################

    #############
    # stop client request if client MAC isn't available
    # perhaps coming from wrong interface

    my $session = $self->get_current_session
      or return $self->no_mac_view;

    # ok, got current session or created new on the fly
    $self->{CTX}{SESSION} = $session;

    # missing SSL detected by JS, recorded from client via ajax
    # check logfile for maybe man-in-the-middle attacks
    return $self->no_ssl_detected
      if exists $query->Vars->{no_ssl};

    # login requested
    return $self->login
      if exists $query->Vars->{login};

    # logout requested
    return $self->logout
      if exists $query->Vars->{logout};

    # first hit, no session established yet
    return $self->splash_view
      if $session->{STATE} eq 'init';

    # just a reload of an active session
    return $self->active_view
      if $session->{STATE} eq 'active';

    # reenable an idle session if the cookie is still valid
    return $self->idle_view
      if $session->{STATE} eq 'idle' && $self->match_cookie;

    # it's a reload after a logout or idle session,
    $self->{CTX}{TMPL_VARS}{msg_text} =
      $self->gettext('msg_001') . " $session->{STATE}";

    $self->{CTX}{TMPL_VARS}{msg_type} = 'info';

    return $self->splash_view;
}

##############################################
# no client MAC address found, show respective page
# we need client IP/MAC address tuple for login
#
sub no_mac_view {
    my $self = shift;

    DEBUG('running NO_MAC handler ...');

    # this requests parameters are in the context slot
    my $output = \$self->{CTX}{BODY};

    my $template = "view/$self->{CTX}{LANG}/nomac.tt";

    $self->{template}->process( $template, $self->{CTX}{TMPL_VARS}, $output )
      or LOGDIE $self->{template}->error . "\n";
}

##############################################
# no ssl encryption recorded by client via ajax
#
sub no_ssl_detected {
    my $self = shift;

    DEBUG('running NO_SSL handler ...');

    my $query   = $self->{CTX}{QUERY};
    my $session = $self->{CTX}{SESSION};

    my $ip  = $session->{IP}  || '';
    my $mac = $session->{MAC} || '';

    # value is victim or aggressor
    my $role = $query->Vars->{no_ssl};

    $self->{CTX}{HEADER} = $query->header(
        -type    => 'text/plain',
        -charset => 'UTF-8',

        # maybe cross-domain-request from http -> https
        -access_control_allow_origin => '*',
    );

    if ( $role eq 'victim' ) {

        # JS ajax call via https
        ERROR("maybe MITM victim IP/MAC: '$ip/$mac'");
        $self->{CTX}{BODY} = $self->gettext('msg_007');
    }
    elsif ( $role eq 'mitm' ) {

        # JS ajax call via http,
        # proxied from aggressor via https
        ERROR("maybe MITM aggressor IP/MAC: '$ip/$mac'");
        $self->{CTX}{BODY} = '';
    }
    else {

        # logic error
        ERROR("MITM unknown role from JS: '$role'");
    }

    return;
}

##############################################
# CLIENT API: no special action required, show splash page
#
sub splash_view {
    my $self = shift;

    DEBUG('running SPLASH handler ...');

    # this requests parameters are in the context slot
    my $output = \$self->{CTX}{BODY};

    my $template = "view/$self->{CTX}{LANG}/splash.tt";

    $self->{template}->process( $template, $self->{CTX}{TMPL_VARS}, $output )
      or LOGDIE $self->{template}->error . "\n";
}

##############################################
# CLIENT API: client session automatically reactivated by matching
# IP/MAC tuple and cookie, show active page with
# proper informational message
#
sub idle_view {
    my $self = shift;

    DEBUG('running IDLE reactivation handler ...');

    #############
    # stop client request if firewall rules aren't loaded
    LOGDIE "Firewall rules for Captive::Portal not loaded, "
      . "please inform the administrators.\n"
      unless defined $self->fw_status;

    # this requests parameters are in the context slot
    my $query   = $self->{CTX}{QUERY};
    my $session = $self->{CTX}{SESSION};

    my $username = $session->{USERNAME};
    my $ip       = $session->{IP};
    my $mac      = $session->{MAC};

    $session->{STATE}     = 'active';
    $session->{STOP_TIME} = '';

    # EXCL lock, change ipset and session in one transaction
    {
        my $lock_handle = $self->get_session_lock_handle(
            key      => $ip,
            shared   => 0,
            blocking => 1,
            timeout  => 3_000_000,    # 3_000_000 us = 3s
        );

        # remove possible ipset-entry due to some race condition
        try { $self->fw_stop_session($ip) } catch {};

        $self->fw_start_session( $ip, $mac );
        $self->write_session_handle( $lock_handle, $session );
    }

    INFO "$username/$ip/$mac -> cookie match, session reactivated";

    # it's a reload after a idle session, reenabled with valid cookie
    $self->{CTX}{TMPL_VARS}{msg_type} = 'info';
    $self->{CTX}{TMPL_VARS}{msg_text} = $self->gettext('msg_006');

    return $self->active_view($session);
}

##############################################
# CLIENT API: show active page after login or reactivation
# after idle
#
sub active_view {
    my $self = shift;

    # this requests parameters are in the context slot
    my $query   = $self->{CTX}{QUERY};
    my $session = $self->{CTX}{SESSION};

    DEBUG('running ACTIVE handler ...');

    my $output = \$self->{CTX}{BODY};
    $self->{CTX}{TMPL_VARS}{username} = $session->{USERNAME};

    my $template = "view/$self->{CTX}{LANG}/active.tt";

    $self->{template}->process( $template, $self->{CTX}{TMPL_VARS}, $output )
      or LOGDIE $self->{template}->error . "\n";

    DEBUG "create http header with session cookie";

    $self->{CTX}{HEADER} = $query->header(
        -type    => 'text/html',
        -charset => 'UTF-8',
        -cookie  => $self->mk_cookie,
    );

}

##############################################
# CLIENT API: process login and show active page
#
sub login {
    my $self = shift;

    DEBUG('running LOGIN handler ...');

    # this requests parameters are in the context slot
    my $query   = $self->{CTX}{QUERY};
    my $session = $self->{CTX}{SESSION};

    my $ip         = $session->{IP};
    my $mac        = $session->{MAC};
    my $user_agent = $query->user_agent || 'unknown';

    DEBUG("login requested for '$ip/$mac'");

    if ( $session->{STATE} eq 'active' ) {

        # STATE already active but login requested again,
        # reset wrong url query params with external redirect
        DEBUG('--> REDIRECT, login requested for ACTIVE session');

        $self->{CTX}{HEADER} = $query->redirect( $query->url );
        return;
    }

    my $username = lc $query->param('username');
    my $password = $query->param('password');

    # forbid HTML code injection
    $username = $query->escapeHTML($username) if $username;

    unless ( $username && $password ) {
        DEBUG('parameter missing at login request');

        $self->{CTX}{TMPL_VARS}{username} = $username;
        $self->{CTX}{TMPL_VARS}{msg_text} = $self->gettext('msg_002');
        $self->{CTX}{TMPL_VARS}{msg_type} = 'error';

        return $self->splash_view;
    }

    # trim whitespace
    $username =~ s/^\s+|\s+$//g;
    $password =~ s/^\s+|\s+$//g;

    unless ( $self->authenticate( $username, $password ) ) {
        DEBUG("login FAILED for '$username'");

        $self->{CTX}{TMPL_VARS}{username} = $username;
        $self->{CTX}{TMPL_VARS}{msg_text} = $self->gettext('msg_003');
        $self->{CTX}{TMPL_VARS}{msg_type} = 'error';

        return $self->splash_view;
    }

    DEBUG("login OK for '$username'");

    #############
    # stop client request if firewall rules aren't loaded
    LOGDIE "Firewall rules for Captive::Portal not loaded, "
      . "please inform the administrators.\n"
      unless defined $self->fw_status;

    $session->{STATE}      = 'active';
    $session->{START_TIME} = time();
    $session->{STOP_TIME}  = '';
    $session->{USERNAME}   = $username;
    $session->{USER_AGENT} = $user_agent;
    $session->{COOKIE}     = $self->mk_cookie->value;

    # EXCL lock, change ipset and session in one transaction
    {
        my $lock_handle = $self->get_session_lock_handle(
            key      => $ip,
            shared   => 0,
            blocking => 1,
            timeout  => 3_000_000,    # 3_000_000 us = 3s
        );

        # remove possible ipset-entry due to some race condition
        try { $self->fw_stop_session($ip) } catch {};

        $self->fw_start_session( $ip, $mac );
        $self->write_session_handle( $lock_handle, $session );
    }

    INFO "$username/$ip/$mac -> login, User-Agent: $user_agent";

    return $self->active_view($session);
}

##############################################
# CLIENT API: process logout and show splash page
#
sub logout {
    my $self = shift;

    DEBUG('running LOGOUT handler ...');

    # this requests parameters are in the context slot
    my $query   = $self->{CTX}{QUERY};
    my $session = $self->{CTX}{SESSION};
    my $ip      = $session->{IP};
    my $mac     = $session->{MAC};

    DEBUG("logout requested for '$ip/$mac'");
    unless ( $session->{STATE} eq 'active' ) {

        # no active session, but logout requested
        # reset wrong url query params with external redirect
        DEBUG('--> REDIRECT, logout requested for INACTIVE session');

        $self->{CTX}{HEADER} = $query->redirect( $query->url );
        return;
    }

    #############
    # stop client request if firewall rules aren't loaded
    LOGDIE "Firewall rules for Captive::Portal not loaded, "
      . "please inform the administrators.\n"
      unless defined $self->fw_status;

    $session->{STATE}     = 'logout';
    $session->{STOP_TIME} = time();
    $session->{COOKIE}    = undef;

    my $username = $session->{USERNAME};

    # EXCL lock, change ipset and session in one transaction
    {
        my $lock_handle = $self->get_session_lock_handle(
            key      => $ip,
            shared   => 0,
            blocking => 1,
            timeout  => 3_000_000,    # 3_000_000 us = 3s
        );

        $self->write_session_handle( $lock_handle, $session );
        $self->fw_stop_session($ip);
    }

    INFO "$username/$ip/$mac -> logout";

    $self->{CTX}{TMPL_VARS}{username} = $username;
    $self->{CTX}{TMPL_VARS}{msg_text} = $self->gettext('msg_004');
    $self->{CTX}{TMPL_VARS}{msg_type} = 'info';

    return $self->splash_view;
}

##############################################
# ADMIN API: show brief status page
# if a matching admin secret is present, show
# a detail status page
#
sub summary_status_view {
    my $self = shift;

    # this requests parameters are in the context slot
    my $query = $self->{CTX}{QUERY};

    DEBUG('running SUMMARY_STATUS handler ...');

    # show detail_status, if cgi-param admin_secret exists
    if ( exists $query->Vars->{admin_secret} ) {

        LOGDIE "ADMIN_SECRET missing in config file\n"
          unless $self->cfg->{ADMIN_SECRET};

        if ( $query->param('admin_secret') eq $self->cfg->{ADMIN_SECRET} ) {
            return $self->detail_status_view;
        }
        else {

            ERROR "wrong 'admin_secret'";

            $self->{CTX}{TMPL_VARS}{msg_text} = $self->gettext('msg_005');
            $self->{CTX}{TMPL_VARS}{msg_type} = 'error';
        }
    }

    my $summary = {};

    # record session states
    foreach my $key ( $self->list_sessions_from_disk ) {

        # fetch session data

        my ( $error, $lock_handle );
        try {
            $lock_handle = $self->get_session_lock_handle(
                key      => $key,
                shared   => 1,
                blocking => 0,
                try      => 2,
            );
        }
        catch { $error = $_ };

        if ($error) {
            WARN "Couldn't get the lock for $key";
            next;
        }

        my $session = $self->read_session_handle($lock_handle);

        unless ($session) {

            # maybe just redirected, but no other action
            # get_session_lock_handle creates emtpy session files
            $summary->{init}++;

            next;
        }

        # sum up the different session states
        $summary->{ $session->{STATE} }++;

    }

    $self->{CTX}{TMPL_VARS}{stopped}++
      unless defined $self->fw_status;

    # record seen active clients behind capo firewall
    $self->{CTX}{TMPL_VARS}{client_candidates} =
      scalar keys %{ $self->fw_list_activity };

    $self->{CTX}{TMPL_VARS}{query}   = $query;
    $self->{CTX}{TMPL_VARS}{summary} = $summary;

    my $output   = \$self->{CTX}{BODY};
    my $template = "view/$self->{CTX}{LANG}/summary_status.tt";

    $self->{template}->process( $template, $self->{CTX}{TMPL_VARS}, $output )
      or LOGDIE $self->{template}->error . "\n";

    return;
}

##############################################
# ADMIN API: show detail status page
#
sub detail_status_view {
    my $self = shift;

    # this requests parameters are in the context slot
    my $query = $self->{CTX}{QUERY};

    DEBUG('running DETAIL_STATUS handler ...');

    # allowed query filter
    my $filter_by_state    = $query->param('filter_state')    || undef;
    my $filter_by_ip       = $query->param('filter_ip')       || undef;
    my $filter_by_username = $query->param('filter_username') || undef;

    my @filtered_sessions = ();
    my $summary           = {};

    foreach my $key ( $self->list_sessions_from_disk ) {

        # fetch session data

        my $lock_handle = $self->get_session_lock_handle(
            key      => $key,
            blocking => 1,
            shared   => 1,
            timeout  => 1_000_000,    # 1_000_000 us = 1s
        );

        my $session = $self->read_session_handle($lock_handle);

        unless ($session) {

            # maybe just redirected, but no other action
            # get_session_lock_handle creates emtpy session files
            $summary->{init}++;

            next;
        }

        # sum up the different session states
        $summary->{ $session->{STATE} }++;

        if ( defined $filter_by_state ) {
            next
              unless $session->{STATE} =~ m/\Q$filter_by_state\E/i;
        }

        if ( defined $filter_by_ip ) {
            next
              unless $session->{IP} =~ m/\Q$filter_by_ip\E/i;
        }

        if ( defined $filter_by_username ) {
            next
              unless $session->{USERNAME} =~ m/\Q$filter_by_username\E/i;
        }

        # time() -> strftime() conversion for output

        my $start_time = $session->{START_TIME};
        my $stop_time  = $session->{STOP_TIME};

        $session->{LOCAL_START_TIME} =
          $start_time
          ? strftime( '%F %T', localtime($start_time) )
          : '';

        $session->{LOCAL_STOP_TIME} =
          $stop_time
          ? strftime( '%F %T', localtime($stop_time) )
          : '';

        $session->{IP_HEX} = $self->ip2hex( $session->{IP} );

        push @filtered_sessions, $session;
    }

    ########################
    # check sort params

    my $sort_reverse;
    if ( $query->param('flip_sort_order') ) {
        $query->delete('flip_sort_order');
        undef $sort_reverse;
    }
    else {
        $query->param( 'flip_sort_order', 1 );
        $sort_reverse = 1;
    }

    DEBUG "sort direction is reverse" if $sort_reverse;

    my $sort_by;
    $sort_by = 'IP'         if defined $query->param('sort_by_ip');
    $sort_by = 'MAC'        if defined $query->param('sort_by_mac');
    $sort_by = 'USERNAME'   if defined $query->param('sort_by_username');
    $sort_by = 'STATE'      if defined $query->param('sort_by_state');
    $sort_by = 'START_TIME' if defined $query->param('sort_by_start_time');
    $sort_by = 'STOP_TIME'  if defined $query->param('sort_by_stop_time');

    # default
    $sort_by ||= 'IP';

    # used for default string sort even for ip addresses and times
    $sort_by = 'IP_HEX'           if $sort_by eq 'IP';
    $sort_by = 'LOCAL_START_TIME' if $sort_by eq 'START_TIME';
    $sort_by = 'LOCAL_STOP_TIME'  if $sort_by eq 'STOP_TIME';

    DEBUG "sort_by is set to '$sort_by'";

    if ($sort_reverse) {
        @filtered_sessions =
          sort { $b->{$sort_by} cmp $a->{$sort_by} } @filtered_sessions;
    }
    else {
        @filtered_sessions =
          sort { $a->{$sort_by} cmp $b->{$sort_by} } @filtered_sessions;
    }

    $self->{CTX}{TMPL_VARS}{stopped}++
      unless defined $self->fw_status;

    # record seen active clients behind capo firewall
    $self->{CTX}{TMPL_VARS}{client_candidates} =
      scalar keys %{ $self->fw_list_activity };

    $self->{CTX}{TMPL_VARS}{query}    = $query;
    $self->{CTX}{TMPL_VARS}{summary}  = $summary;
    $self->{CTX}{TMPL_VARS}{sessions} = \@filtered_sessions;

    my $output = \$self->{CTX}{BODY};

    # CGI parameter 'astext' defines html or text
    if ( exists $query->Vars->{astext} ) {
        $self->{CTX}{HEADER} =
          $query->header( -type => 'text/plain', -charset => 'UTF-8' );

        my $template = 'view/any/status_astext.tt';

        $self->{template}
          ->process( $template, $self->{CTX}{TMPL_VARS}, $output )
          or LOGDIE $self->{template}->error . "\n";
    }
    else {
        my $template = "view/$self->{CTX}{LANG}/detail_status.tt";

        $self->{template}
          ->process( $template, $self->{CTX}{TMPL_VARS}, $output )
          or LOGDIE $self->{template}->error . "\n";
    }

    return;
}

##############################################
# ADMIN API: show current active session number
#
sub is_running_view {
    my $self = shift;

    # this requests parameters are in the context slot
    my $query = $self->{CTX}{QUERY};

    DEBUG('running IS_RUNNING handler ...');

    $self->{CTX}{HEADER} =
      $query->header( -type => 'text/plain', -charset => 'UTF-8' );

    my $session_count = $self->fw_status;

    if ( defined $session_count ) {
        $self->{CTX}{BODY} = "RUNNING $session_count active sessions";
    }
    else {
        $self->{CTX}{BODY} = "STOPPED";
    }

    return;
}

##############################################
# low level error page without template system
# something died, maybe some modules missing etc.
#
sub error_page_500 {
    my $error_msg = shift;

    # cut off ... 'at file line xxx'
    $error_msg =~ s/\s+ at \s+ \S+ \s+ line \s+ \d+ .*//x;

    my $html = <<'EOF_500';
<!DOCTYPE html>
<html lang="en-US">
  <head>
    <title>Captive::Portal - Error 500</title>
    <style type="text/css">
      body {  padding: 10px; margin: 0px; }
      div.page { font-family: Lucida,sans-serif; border: 1px solid;
        padding: 10px; background-color: #DEDEDE;
      }
      h1 { color: #AA0000; border-bottom: 1px solid #444; }
      h2 { color: #444; }
      div.error { font-family: "lucida console",monospace; font-size: 12px; }
      div.footer { border-top: 1px solid #444; padding-top: 4px; margin-top: 4px;
	font-size: 10px;
      }
    </style>
    <meta charset=UTF-8" />
  </head>
  <body>
    <div class="page">
      <h1>Error 500</h1>
      <div id="content">
	<h2>Internal Server Error</h2>
      </div>
      <div class="error">
__ERROR_MSG__
      </div>
      <div class="footer">
	Powered by <a href="http://search.cpan.org/~gaissmai/Captive-Portal/">Captive::Portal</a>
      </div>
    </div>
  </body>
</html>
EOF_500

    $html =~ s/__ERROR_MSG__/$error_msg/m;
    return $html;
}

1;

=head1 SEE ALSO

L<Captive::Portal::Role::Config>, L<capo.fcgi> and L<capo-ctl.pl>

=head1 CREDITS

Most of the good parts have been implemented by many creative discussion with my colleague Bernd Leibing.

=head1 BUGS AND LIMITATIONS

There are no known problems with this module.

Please report any bugs or feature requests to
C<bug-captive-portal at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Captive-Portal>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

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
