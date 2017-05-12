# Apache2::AuthCAS
# Jason Hitt, March 2007
#
# Apache auth module to protect underlying resources using JA-SIG's Central
# Authentication Service
package Apache2::AuthCAS;

$Apache2::AuthCAS::VERSION = "0.4";

use strict;
use warnings FATAL => 'all';

use Apache2::RequestRec ();
use Apache2::RequestIO ();
use Apache2::RequestUtil ();
#use Apache2::ServerRec ();
use Apache2::Module ();
use Apache2::URI ();

use Apache2::Const -compile => qw(FORBIDDEN HTTP_MOVED_TEMPORARILY OK DECLINED HTTP_OK :log);

use mod_perl2;
use vars qw($INITIALIZED $SESSION_CLEANUP_COUNTER);

use APR::URI;
use Apache2::Log;
use Net::SSLeay;
use MIME::Base64;
use DBI;
use URI::Escape;
use XML::Simple;

# logging flags
my $LOG_ERROR  = 0;
my $LOG_WARN   = 1;
my $LOG_INFO   = 2;
my $LOG_DEBUG  = 3;
my $LOG_EMERG  = 4;

my %ERROR_CODES = (
    "DB"               => "Database Service Error",
    "PGT"              => "CAS Proxy Service Error",
    "PGT_RECEPTOR"     => "Proxy Receptor Error",
    "INVALID_RESPONSE" => "Invalid Service Response",
    "INVALID_PGT"      => "Invalid Proxy Granting Ticket",
    "MISSING_PGT"      => "Missing Proxy Granting Ticket",
    "CAS_CONNECT"      => "CAS couldn't validate service ticket",
);

my %DEFAULTS = (
        "Host"                    => "localhost",
        "Port"                    => "443",
        "LoginUri"                => "/cas/login",
        "LogoutUri"               => "/cas/logout",
        "ProxyUri"                => "/cas/proxy",
        "ProxyValidateUri"        => "/cas/proxyValidate",
        "ServiceValidateUri"      => "/cas/serviceValidate",

        "LogLevel"                => 0,
        "PretendBasicAuth"        => 0,
        "Service"                 => undef,
        "ProxyService"            => undef,
        "ErrorUrl"                => "http://localhost/cas/error/",
        "SessionCleanupThreshold" => 10,
        "SessionCookieName"       => "APACHECAS",
        "SessionCookieDomain"     => undef,
        "SessionCookieSecure"     => 0,
        "SessionTimeout"          => 1800,
        "RemoveTicket"            => 0,
        "NumProxyTickets"         => 0,

        "DbDriver"                => "Pg",
        "DbDataSource"            => "dbname=apache_cas;host=localhost;port=5432",
        "DbSessionTable"          => "cas_sessions",
        "DbUser"                  => "cas",
        "DbPass"                  => "cas",
);

# default to 0
$SESSION_CLEANUP_COUNTER = 0 if (!defined($SESSION_CLEANUP_COUNTER));

sub dbConnect($)
{
    my($self) = @_;

    my $dbh = DBI->connect(
        "dbi:" . $self->casConfig("DbDriver")
            . ":" . $self->casConfig("DbDataSource"),
        $self->casConfig("DbUser"), $self->casConfig("DbPass"),
        { AutoCommit => 1 }
    );
    if (!defined($dbh))
    {
        $self->logMsg("db connect error: $DBI::errstr");
        return undef;
    }

    return $dbh;
}

sub getApacheConfig($)
{
    my($self) = @_;
    $self->{'casConfig'} = Apache2::Module::get_config('Apache2::AuthCAS::Configuration'
        , $self->{'request'}->server
        , $self->{'request'}->per_dir_config);

    # Now add in our defaults
    foreach my $key (keys(%DEFAULTS))
    {
        $self->{'casConfig'}->{$key} = $DEFAULTS{$key}
            if !exists($self->{'casConfig'}->{$key});
    }

    $self->logMsg("Apache Config:", $LOG_DEBUG);
    foreach my $key (sort(keys(%{$self->{'casConfig'}})))
    {
        my $val = $self->casConfig($key) || 'undef';
        $self->logMsg("    $key => $val", $LOG_DEBUG);
    }
}

sub casConfig($$)
{
    my($self, $var) = @_;

    return $self->{'casConfig'}->{$var};
}

sub logMsg($$;$)
{
    my($self, $msg, $logLevel) = @_;

    $logLevel = $LOG_ERROR if (!$logLevel);

    if ($self->casConfig("LogLevel") >= $logLevel)
    {
        my $sub = (caller(1))[3];
        $sub =~ /(\w+)$/;
        $self->{'request'}->log->alert("CAS($$): $1: $msg");
    }
}

# used for underlying services that need proxy tickets (PTs)
sub authenticate($$)
{
    my($class, $r) = @_;

    # Only authenticate the first internal request
    return (Apache2::Const::OK) unless $r->is_initial_req;

    # Let's make this easy on ourselves and pass an object around
    # for reading config variables and the request object
    my $self = {};
    bless($self, ref $class || $class);
    $self->{'request'} = $r;
    $self->getApacheConfig();

    # grab the uri that was requested
    my $uri = $r->parsed_uri;

    # Check for a logout request (CAS 3 single sign-off)
    my $query = $uri->query() || "";
    $query =~ /logoutRequest=(.*?)[&;]/;
    my $logoutRequest = $1;

    if ($logoutRequest)
    {
        $logoutRequest =~ /<samlp:SessionIndex>(ST-[0-9]+-[^<]+)<\/samlp:SessionIndex>/;
        my $delete_service_ticket = $1;

        $self->logMsg("deleting session mapping for service_ticket='$delete_service_ticket'", $LOG_DEBUG);

        my $dbh = $self->dbConnect() or return 0;
        $dbh->do("DELETE FROM " . $self->casConfig("DbSessionTable")
            . " WHERE service_ticket= ?", undef, $delete_service_ticket 
        );
        if ($dbh->err)
        {
            $self->logMsg("error deleting session mapping for service_ticket='$delete_service_ticket' ($DBI::errstr)", $LOG_DEBUG);
        }
    }

    # perform any cleanup that is needed
    $self->cleanup();

    # see if any of our other handlers have specified that they have already
    # sufficiently checked the authenticating user
    my $authenticated = $r->subprocess_env->{'AUTHENTICATED'} || "";
    $self->logMsg("authenticated='$authenticated'", $LOG_DEBUG);
    return (Apache2::Const::OK) if ($authenticated eq "true");

    # Parse the query string to get the ticket, plus any GET variables
    # to rebuild our service string (which is needed for CAS to send the
    # client back to the originating service).

    my %params = $self->parse_query_parameters($uri->query);

    # Check for a proxy receptor call
    if ($params{'pgt'} and $params{'pgtIou'})
    {
        return $self->proxy_receptor($params{'pgtIou'}, $params{'pgt'});
    }

    # Check for a session cookie
    if (my $cookie = $r->headers_in->{'Cookie'})
    {
        # we have a session cookie, so we need to get the session id
        $self->logMsg("cookie found: '$cookie'", $LOG_DEBUG);

        # get session id from the cookie
        my $cookieName = $self->casConfig("SessionCookieName");
        $cookie =~ /.*$cookieName=([^;]+)(\s*;.*|\s*$)/;
        my $sid = $1;
        $self->logMsg(($sid ? "" : "no") . " session id found", $LOG_DEBUG);

        # Check for a valid session id
        if ($sid and defined(my $rc = $self->check_session($sid)))
        {
            return $rc;
        }
    }
    else
    {
        my $service = $self->this_url(1);
        $self->logMsg("no session cookie for service: '$service'", $LOG_DEBUG);
    }

    # No session (or an expired one).  Check for a ticket
    if (my $ticket = $params{'ticket'})
    {
        # validate service ticket through CAS, since no valid cookie was found
        my($error, $user, $pgtiou) = $self->validate_service_ticket($ticket);

        if ($error)
        {
            return $self->redirect($self->casConfig("ErrorUrl"), $error);
        }

        # map a new session id to this pgtiou and give the client a cookie
        my $sid = $self->create_session($user, $pgtiou, $ticket);

        if (!$sid)
        {
            # if something bad happened, like database unavailability
            return $self->redirect($self->casConfig("ErrorUrl"), $ERROR_CODES{"DB"});
        }

        my $cookie = $self->casConfig("SessionCookieName") . "=$sid;path=/";
        if ($self->casConfig("SessionCookieDomain"))
        {
            $cookie .= ";domain=." . $self->casConfig("SessionCookieDomain");
        }
        if ($self->casConfig("SessionCookieSecure"))
        {
            $cookie .= ";secure";
        }

        # send the cookie to the browser
        $self->setHeader(0, 'Set-Cookie', $cookie);

        # in case we redirect (considered an "error")
        $r->err_headers_out->{"Set-Cookie"} = $cookie;

        if ($self->casConfig("ProxyService"))
        {
            return $self->do_proxy($sid, undef, $user, 1);
        }
        else
        {
            $self->setHeader(1, 'CAS_FILTER_USER', $user);
            $self->add_basic_auth($user);

            # redirect to this same page minus the ticket
            return $self->redirect_without_ticket() if ($self->casConfig("RemoveTicket"));

            return (Apache2::Const::OK);
        }
    }

    # No valid session, no ticket.  Redirect to CAS login
    return $self->redirect_login();
}

sub check_session($$$)
{
    my($self, $sid) = @_;

    # we set up our own session here, so that we don't have to continually
    # go through this whole process!  we associate a session id with a PGTIOU

    # try to get a session record for the session id we received
    # session_data - session id, last accessed, netid, pgtiou
    if (my($last_accessed, $user, $pgt) = $self->get_session_data($sid))
    {
        # make sure the session is still valid
        if ($last_accessed + $self->casConfig("SessionTimeout") >= time())
        {
            # session is still valid
            $self->logMsg("session '$sid' is still valid", $LOG_DEBUG);

            # record the last time the session was accessed
            # if something bad happened, like database unavailability
            if (!$self->touch_session($sid))
            {
                return $self->redirect($self->casConfig("ErrorUrl"), $ERROR_CODES{"DB"});
            }

            if ($self->casConfig("ProxyService"))
            {
                return $self->do_proxy($sid, $pgt, $user, 0);
            }
            else
            {
                $self->setHeader(1, 'CAS_FILTER_USER', $user);
                $self->add_basic_auth($user);

                return (Apache2::Const::OK);
            }
        }
        else
        {
            $self->logMsg("session '$sid' has expired", $LOG_DEBUG);
            $self->delete_session_data($sid);
        }
    }
    else
    {
        $self->logMsg("session '$sid' is invalid", $LOG_DEBUG);
    }

    return undef;
}

sub cleanup()
{
    my($self) = @_;

    $SESSION_CLEANUP_COUNTER++;
    $self->logMsg("counter=$SESSION_CLEANUP_COUNTER", $LOG_DEBUG);

    # perform session cleanup
    if ($SESSION_CLEANUP_COUNTER == 1)
    {
        $self->delete_expired_sessions();
    }

    # reset counter if we have reached our threshold
    $SESSION_CLEANUP_COUNTER = 0
        if ($SESSION_CLEANUP_COUNTER >= $self->casConfig("SessionCleanupThreshold"));
}

sub add_basic_auth($$)
{
    my($self, $user) = @_;

    if ($self->casConfig("PretendBasicAuth"))
    {
        # setup this up for underlying authz modules that rely
        # on Basic auth having been performed
        $self->setHeader(1, 'Authorization'
            , "Basic " . encode_base64($user . ":DUMMYPASS"));
        $self->{'request'}->ap_auth_type("Basic");
        $self->{'request'}->user($user);
    }
}

sub redirect_without_ticket($)
{
    my($self) = @_;

    $self->logMsg("redirecting to remove service ticket from service string", $LOG_INFO);

    $self->setHeader(0, 'Location', $self->this_url());
    return (Apache2::Const::HTTP_MOVED_TEMPORARILY);
}

sub redirect_login($)
{
    my($self) = @_;

    $self->logMsg("start", $LOG_DEBUG);

    my $service = $self->this_url(1);
    $self->logMsg("redirecting to CAS for service: '$service'", $LOG_INFO);

    $service = uri_escape($service);
    $self->setHeader(0, 'Location', "https://"
        . $self->casConfig("Host") . ":" . $self->casConfig("Port")
        . $self->casConfig("LoginUri") . "?service=$service");
    return (Apache2::Const::HTTP_MOVED_TEMPORARILY);
}

sub redirect($;$$)
{
    my($self, $url, $errcode) = @_;

    if ($url)
    {
        my $service = $self->this_url(1);
        $self->logMsg("redirecting to url: '$url' service: '$service'", $LOG_INFO);

        $self->setHeader(0, 'CAS_FILTER_CAS_HOST',      $self->casConfig("Host"));
        $self->setHeader(0, 'CAS_FILTER_CAS_PORT',      $self->casConfig("Port"));
        $self->setHeader(0, 'CAS_FILTER_CAS_LOGIN_URI', $self->casConfig("LoginUri"));
        $self->setHeader(0, 'CAS_FILTER_SERVICE',       $service);

        $self->logMsg("redirecting to error page") if ($errcode);
        $errcode = "" if (!$errcode);

        $service = uri_escape($service);
        $self->setHeader(0, 'Location'
            , "$url?login_url=https://" . $self->casConfig("Host")
            . ":" . $self->casConfig("Port") . $self->casConfig("LoginUri")
            . "?service=$service&errcode=$errcode");
        return (Apache2::Const::HTTP_MOVED_TEMPORARILY);
    }
    else
    {
        $self->logMsg("no redirect URL, displaying message", $LOG_INFO);
        $self->{'request'}->content_type('text/html');
        $self->{'request'}->print("<html><body>service misconfigured</body></html>");
        $self->{'request'}->rflush();
        return (Apache2::Const::HTTP_OK);
    }
}

# params
#     apache request object
#     ticket to be validated
# returns a hash with keys on success
#       'user', 'pgtiou'
# NULL on failure
sub validate_service_ticket($$$)
{
    my($self, $ticket) = @_;

    my $proxy = $self->casConfig("ProxyService") ? "1" : "0";

    my $service = $self->this_url(1);
    $self->logMsg("Validating service ticket '$ticket' for service '$service'", $LOG_DEBUG);

    my $url;
    if ($proxy)
    {
        my $pgtUrl = $self->{'request'}->construct_url();
        $url = $self->casConfig("ProxyValidateUri") . "?pgtUrl=$pgtUrl&";
    }
    else
    {
        $url = $self->casConfig("ServiceValidateUri") . "?";
    }

    $service = uri_escape($service);
    $url .= "service=$service&ticket=$ticket";

    $self->logMsg("request URL: '$url'", $LOG_DEBUG);

    # Net::SSLeay::trace options
    # 0=no debugging, 1=ciphers, 2=trace, 3=dump data
    $Net::SSLeay::trace = ($self->casConfig("LogLevel") >= $LOG_EMERG) ? 3 : 0;

    my($page) = Net::SSLeay::get_https(
        $self->casConfig("Host"), $self->casConfig("Port"), $url);
    $self->logMsg("response page: $page", $LOG_EMERG);

    # if we had some type of connection problem
    if (!defined($page))
    {
        $self->logMsg("error validating service");
        return ($ERROR_CODES{"CAS_CONNECT"});
    }

    my $casResponse = eval { XMLin($page); } || {};

    my($errorMsg, $user, $pgtiou);
    if (my $successBlock = $casResponse->{"cas:authenticationSuccess"})
    {
        $user = $successBlock->{"cas:user"};
        $self->logMsg("valid service ticket, user='$user'", $LOG_DEBUG);

        # only try to get PGTIOU if we are doing proxy stuff
        if ($proxy)
        {
            if ($pgtiou = $successBlock->{"cas:proxyGrantingTicket"})
            {
                $self->logMsg("proxying - pgtiou='$pgtiou'", $LOG_DEBUG);
            }
            else
            {
                $self->logMsg("proxying and no pgtiou in response from CAS", $LOG_ERROR);
                $errorMsg = $ERROR_CODES{"PGT"};
            }
        }
    }
    elsif (my $failBlock = $casResponse->{"cas:authenticationFailure"})
    {
        $errorMsg = $failBlock->{"code"} . " " . $failBlock->{"content"};
        $self->logMsg("authentication failure, access denied ($errorMsg)" , $LOG_DEBUG);
    }
    else
    {
        $self->logMsg("invalid service response", $LOG_DEBUG);
        $errorMsg = $ERROR_CODES{"INVALID_RESPONSE"};
    }

    return ($errorMsg, $user, $pgtiou);
}

sub proxy_receptor($$$)
{
    my($self, $pgtiou, $pgt) = @_;

    # This is the proxy receptor.
    # We should only enter here when CAS sends us the PGTIOU and the PGT
    if ($pgtiou and $pgt)
    {
        $self->logMsg("proxy receptor invoked with '$pgtiou' => '$pgt'", $LOG_DEBUG);

        # save the pgtiou/pgt mapping
        if (!$self->set_pgt($pgtiou, $pgt))
        {
            $self->logMsg("couldn't save '$pgtiou' => '$pgt'");
            return $self->redirect($self->{'request'}
                , $self->casConfig("ErrorUrl"), $ERROR_CODES{"PGT_RECEPTOR"});
        }

        $self->logMsg("saved '$pgtiou' => '$pgt'", $LOG_DEBUG);

        # Return a successful response to CAS.
        # We have to not let the request fall through to real content here.
        $self->{'request'}->push_handlers(PerlResponseHandler => \&send_proxysuccess);
        return (Apache2::Const::OK);
    }
    else
    {
        $self->logMsg("invalid proxy receptor call - missing ticket information"
            , $LOG_DEBUG);
        return $self->redirect($self->casConfig("ErrorUrl") , $ERROR_CODES{"PGT_RECEPTOR"});
    }
}

sub send_proxysuccess($$)
{
    my($self) = @_;

    $self->logMsg("sending proxy success for CAS callback", $LOG_DEBUG);

    $self->{'request'}->content_type("text/html");
    $self->{'request'}->print("<casClient:proxySuccess xmlns:casClient=\"http://www.yale.edu/tp/casClient\"/>\n");
    $self->{'request'}->rflush();
    return (Apache2::Const::OK);
}

sub get_proxy_tickets($$;$$)
{
    my($self, $pgt, $target, $numTickets) = @_;

    return () if (!$target or !$numTickets);

    $self->logMsg("retrieving '$numTickets' PTs for PGT='$pgt', target='$target'", $LOG_DEBUG);

    my @tickets = ();

    # Net::SSLeay::trace options
    # 0=no debugging, 1=ciphers, 2=trace, 3=dump data
    $Net::SSLeay::trace = ($self->casConfig("LogLevel") >= $LOG_EMERG) ? 3 : 0;

    my $uri = $self->casConfig("ProxyUri") . "?pgt=$pgt&targetService=$target";
    $self->logMsg("Proxy request URL: '$uri'", $LOG_DEBUG);

    for (my $i = 0; $i < $numTickets; $i++)
    {
        my ($page) = Net::SSLeay::get_https(
            $self->casConfig("Host"), $self->casConfig("Port"), $uri);
        $self->logMsg("page: $page", $LOG_EMERG);

        my $casResponse = eval { XMLin($page); } || "";

        if (my $successBlock = $casResponse->{"cas:proxySuccess"})
        {
            if (my $proxyTicket = $successBlock->{"cas:proxyTicket"})
            {
                $self->logMsg("retrieved PT: '$proxyTicket'", $LOG_DEBUG);
                push(@tickets, $proxyTicket);
            }
            else
            {
                $self->logMsg("no PT in response", $LOG_DEBUG);
                return ();
            }
        }
        elsif (my $failBlock = $casResponse->{"cas:proxyFailure"})
        {
            my $errorMsg = $failBlock->{"code"} . " " . $failBlock->{"content"};
            $self->logMsg("proxy response failure ($errorMsg)" , $LOG_DEBUG);
            return ();
        }
        else
        {
            $self->logMsg("invalid proxy ticket response", $LOG_DEBUG);
            return ();
        }
    }

    return @tickets;
}

# place data in the session
sub create_session($$$$)
{
    my($self, $uid, $pgtiou, $ticket) = @_;

    $self->logMsg("creating session for uid='$uid'"
        . ($pgtiou ? ", pgtiou='$pgtiou'" : ""), $LOG_DEBUG);

    my $sid = sprintf("%10d-", time());
    srand();
    for (my $i = 0; $i < 21; $i++)
    {
        $sid .= ('.', '/', 0..9, 'A'..'Z', 'a'..'z')[rand 64];
    }

    $self->logMsg("sid='$sid'", $LOG_DEBUG);

    my $dbh = $self->dbConnect() or return undef;

    $dbh->do("INSERT INTO " . $self->casConfig("DbSessionTable")
        . " (id, last_accessed, user_id, pgtiou, service_ticket)"
        . " VALUES (?, ?, ?, ?, ?)"
        , undef, $sid, time(), $uid, $pgtiou, $ticket
    );

    if ($dbh->err)
    {
        $self->logMsg("error creating session ($DBI::errstr)", $LOG_DEBUG);
        undef($sid);
    }

    $dbh->disconnect();

    return $sid;
}

# "touch" the session
sub touch_session($$)
{
    my($self, $sid) = @_;

    $self->logMsg("touching session '$sid'", $LOG_DEBUG);

    my $dbh = $self->dbConnect() or return 0;

    $dbh->do("UPDATE " . $self->casConfig("DbSessionTable")
        . " SET last_accessed = ? WHERE id = ?"
        , undef, time(), $sid
    );

    my $rc = 1;
    if ($dbh->err)
    {
        $self->logMsg("error touching session ($DBI::errstr)", $LOG_DEBUG);
        $rc = 0;
    }

    $dbh->disconnect();

    return $rc;
}

# takes a session id and returns an array
sub get_session_data($$)
{
    my($self, $sid) = @_;

    $self->logMsg("retrieving session data for sid='$sid'", $LOG_DEBUG);

    # retrieve a session object for this session id
    my $dbh = $self->dbConnect() or return ();

    my($last_accessed, $uid, $pgt) = $dbh->selectrow_array(
        "SELECT last_accessed, user_id, pgt FROM "
        . $self->casConfig("DbSessionTable")
        . " WHERE id = ?"
        , undef, $sid
    );

    $dbh->disconnect();

    if (!$dbh->err and $last_accessed)
    {
        $self->logMsg("session data for sid='$sid':"
            . " last_accessed='$last_accessed' uid='$uid'"
            . ($pgt ? "pgt='$pgt'" : ""), $LOG_DEBUG);
        return ($last_accessed, $uid, $pgt);
    }

    $self->logMsg("couldn't get session data for sid='$sid'", $LOG_DEBUG);
    return ();
}

# delete session
sub delete_session_data($$)
{
    my($self, $sid) = @_;

    $self->logMsg("deleting session mapping for sid='$sid'", $LOG_DEBUG);

    # retrieve a session object for this session id
    my $dbh = $self->dbConnect() or return 0;

    $dbh->do("DELETE FROM " . $self->casConfig("DbSessionTable") . " WHERE id = ?"
        , undef, $sid
    );

    my $rc = 1;
    if ($dbh->err)
    {
        $self->logMsg("error deleting session mapping for sid='$sid' ($DBI::errstr)", $LOG_DEBUG);
        $rc = 0;
    }

    $dbh->disconnect();

    return $rc;
}

# delete expired sessions
sub delete_expired_sessions($)
{
    my($self) = @_;

    my $oldestValidTime = time() - $self->casConfig("SessionTimeout");
    $self->logMsg("deleting sessions older than '$oldestValidTime'", $LOG_DEBUG);

    # retrieve a session object for this session id
    my $dbh = $self->dbConnect() or return 0;

    $dbh->do("DELETE FROM " . $self->casConfig("DbSessionTable")
        . " WHERE last_accessed < ?"
        , undef, $oldestValidTime
    );

    my $rc = 1;
    if ($dbh->err)
    {
        $self->logMsg("error deleting expired sessions ($DBI::errstr)", $LOG_ERROR);
        $rc = 0;
    }

    $dbh->disconnect();

    return $rc;
}

# place the pgt mapping in the database
sub set_pgt($$$)
{
    my($self, $pgtiou, $pgt) = @_;

    $self->logMsg("adding map for pgtiou='$pgtiou' pgt='$pgt'", $LOG_DEBUG);

    my $dbh = $self->dbConnect() or return 0;

    $dbh->do(
        "UPDATE " . $self->casConfig("DbSessionTable") . "
        SET pgt = ?
        WHERE pgtiou = ?"
        , undef, $pgt, $pgtiou
    );

    my $rc = 1;
    if ($dbh->err)
    {
        $self->logMsg("error adding map ($DBI::errstr)", $LOG_ERROR);
        $rc = 0;
    }

    $dbh->disconnect();

    return $rc;
}

sub do_proxy($$$$$$)
{
    my($self, $sid, $pgt, $user, $removeTicket) = @_;

    $self->logMsg("proxying request, sid='$sid'", $LOG_DEBUG);
    $self->logMsg("pgt='$pgt'", $LOG_DEBUG) if ($pgt);

    if (!$pgt)
    {
        my(@sessionData) = $self->get_session_data($sid);
        $pgt = $sessionData[2];
        $self->logMsg("pgt lookup, pgt='$pgt'", $LOG_DEBUG) if ($pgt);
    }

    if (!$pgt)
    {
        return $self->redirect($self->casConfig("ErrorUrl")
            , $ERROR_CODES{"MISSING_PGT"});
    }

    my @tickets = $self->get_proxy_tickets(
        $pgt, $self->casConfig("ProxyService"), $self->casConfig("NumProxyTickets"));
    if (scalar(@tickets))
    {
        # place headers in request for underlying service
        my $service = $self->this_url(1);

        $self->logMsg("Setting CAS FILTER response headers", $LOG_DEBUG);

        $self->setHeader(1, 'CAS_FILTER_CAS_HOST',      $self->casConfig("Host"));
        $self->setHeader(1, 'CAS_FILTER_CAS_PORT',      $self->casConfig("Port"));
        $self->setHeader(1, 'CAS_FILTER_CAS_LOGIN_URI', $self->casConfig("LoginUri"));
        $self->setHeader(1, 'CAS_FILTER_SERVICE',       $service);
        $self->setHeader(1, 'CAS_FILTER_USER',          $user);

        $self->setHeader(1, 'CAS_FILTER_PT',  $tickets[0]);
        for (my $i = 1; $i <= scalar(@tickets); $i++)
        {
            $self->setHeader(1, "CAS_FILTER_PT$i", $tickets[$i-1]);
        }

        $self->add_basic_auth($user);

        if ($removeTicket and $self->casConfig("RemoveTicket"))
        {
            return $self->redirect_without_ticket();
        }

        return (Apache2::Const::OK);
    }
    else
    {
        $self->delete_session_data($sid);
        return $self->redirect($self->casConfig("ErrorUrl")
            , $ERROR_CODES{"INVALID_PGT"});
    }
}

sub setHeader($$$$)
{
    my($self, $in, $header, $value) = @_;

    $self->logMsg("Setting header: $header = $value", $LOG_DEBUG);

    if ($in)
    {
        $self->{'request'}->headers_in->{$header} = $value;
    }
    else
    {
        $self->{'request'}->headers_out->{$header} = $value;
    }
}

# strips the ticket from the query and returns the full service URL
sub this_url($$;$)
{
    my($self, $serviceOverride) = @_;

    if ($serviceOverride and my $service = $self->casConfig("Service"))
    {
        return $service;
    }

    my $url = $self->{'request'}->construct_url();
    my $uri = $self->{'request'}->parsed_uri;

    if (my $query = $uri->query)
    {
        $query =~ s/\??&?ticket=[^&]+//;
        $url .= "?$query" if ($query ne "");
    }
    elsif ($self->{'request'}->unparsed_uri =~ /\?$/)
    {
        $url .= "?";
    }

    return $url;
}

sub parse_query_parameters($$)
{
    my($self, $query) = @_;

    return () if (!$query);

    my %params = ();
    foreach my $param (split(/&/, $query))
    {
        my($key, $value) = split(/=/, $param);

        $value = "" if (!$value);
        $self->logMsg("PARAM: '$key' => '$value'", $LOG_DEBUG);
        $params{$key} = $value;
    }

    return %params;
}

1;
__END__

=head1 NAME

Apache2::AuthCAS - A configurable Apache authentication module that enables you
to protect content on an Apache server using an existing JA-SIG CAS
authentication server.

=head1 SYNOPSIS

C<perl -MCPAN -e 'install Apache2::AuthCAS'>

=head1 DESCRIPTION

=head2 General

The I<Apache2::AuthCAS> module allows a user to protect arbitrary content
on an Apache server with JA-SIG CAS.

Add the following lines to your Apache configuration file to load the custom
configuration tags for CAS and allow for CAS authentication:

    PerlLoadModule APR::Table
    PerlLoadModule Apache2::AuthCAS::Configuration
    PerlLoadModule Apache2::AuthCAS

At this point, the configuration directives may be used.  All directives
can be nested in Location, Directory, or VirtualHost sections.

Add the following lines to an Apache configuration file or .htaccess file:

    AuthType Apache2::AuthCAS
    AuthName "CAS"
    PerlAuthenHandler Apache2::AuthCAS->authenticate
    require valid-user

    *note* - this simple config assumes that the rest of the settings have
             been set in your Apache configuration file.  If not, they
             will need to be set here (if allowed by your configuration).

Any options that are not set in the Apache configuration will default to the
values preconfigured in the Apache2::AuthCAS module.  Either explicitly override
those options that do not match your environment or set them in the module
itself.

=head2 Requirements

Apache 2.x with mod_perl2

Perl modules:
    Net::SSLeay
    MIME::Base64
    URI::Escape
    XML::Simple
    DBI
    DBD::<module name> (i.e. DBD::Pg)

=head2 Proxiable Credentials

This module can be optionally configured to use proxy credentials.  This is
enabled by setting the I<CASService> and I<CASProxyService> configuration
parameters.

=head2 Examples

Example configuration without proxiable credentials:

    AuthType Apache2::AuthCAS
    AuthName "CAS"
    PerlAuthenHandler Apache2::AuthCAS->authenticate
    require valid-user

    CASHost         "auth.yourdomain.com"
    CASErrorURL     "https://yourdomain.com/cas/error/"
    CASDbDataSource "dbname=cas;host=dbhost.yourdomain.com;port=5432"


Example configuration without proxiable credentials, using custom database
parameters:

    AuthType Apache2::AuthCAS
    AuthName "CAS"
    PerlAuthenHandler Apache2::AuthCAS->authenticate
    require valid-user

    CASHost           "auth.yourdomain.com"
    CASErrorURL       "https://yourdomain.com/cas/error/"
    CASDbDriver       "Oracle
    CASDbDataSource   "sid=yourdb;host=dbhost.yourdomain.com;port=1521"
    CASDbUser         "cas_user"
    CASDbPass         "cas_pass"
    CASDbSessionTable "cas_sessions_service1"


Example configuration with proxiable credentials:

    AuthType Apache2::AuthCAS
    AuthName "CAS"
    PerlAuthenHandler Apache2::AuthCAS->authenticate
    require valid-user

    CASService       "https://yourdomain.com/email/"
    CASProxyService  "mail.yourdomain.com"


Example configuration with proxiable credentials, using custom database parameters:

    AuthType Apache2::AuthCAS
    AuthName "CAS"
    PerlAuthenHandler Apache2::AuthCAS->authenticate
    require valid-user

    CASService       "https://yourdomain.com/email/"
    CASProxyService  "mail.yourdomain.com"
    CASDbDriver       "Oracle
    CASDbDataSource   "sid=yourdb;host=dbhost.yourdomain.com;port=1521"
    CASDbUser         "cas_user"
    CASDbPass         "cas_pass"
    CASDbSessionTable "cas_sessions_service1"

=head2 Configuration Options

These are the Apache configuration options, defaults, and descriptions
for Apache2::AuthCAS.

    # The CAS server parameters.  These should be self explanatory.
    CASHost                     "localhost"
    CASPort                     "443"
    CASLoginUri                 "/cas/login"
    CASLogoutUri                "/cas/logout"
    CASProxyUri                 "/cas/proxy"
    CASProxyValidateUri         "/cas/proxyValidate"
    CASServiceValidateUri       "/cas/serviceValidate"

    # The level of logging, ERROR(0) - EMERG(4)
    CASLogLevel                 0

    # Should we set the 'Basic' authentication header?
    CASPretendBasicAuth         0

    # Where do we redirect if there is an error?
    CASErrorUrl                 "http://localhost/cas/error/"

    # Session cleanup threshold (1 in N requests)
    # Session cleanup will occur for each Apache thread or process -
    #   i.e. for 10 processes, it may take as many as 100 requests before
    # session cleanup is performed with a threshold of 10)

    CASSessionCleanupThreshold  10

    # Session cookie configuration for this service
    CASSessionCookieDomain      ""
    CASSessionCookieName        "APACHECAS"
    CASSessionTimeout           1800

    # Should the ticket parameter be removed from the URL?
    CASRemoveTicket             0

    # Optional override for this service name
    CASService                  ""

    # If you are proxying for a backend service you will need to specify
    # these parameters.  The service is the name of the backend service
    # you are proxying for, the receptor is the URL you will listen at
    # for pgtiou/pgt mappings from the CAS server, and the final parameter
    # specifies how many proxy tickets should be requested for the backend
    # service.
    CASProxyService             ""
    CASNumProxyTickets          0

    # Database parameters for session and ticket management
    CASDbDriver                 "Pg"
    CASDbDataSource             "dbname=apache_cas;host=localhost;port=5432"
    CASDbSessionTable           "cas_sessions"
    CASDbUser                   "cas"
    CASDbPass                   "cas"

=head1 NOTES

Configuration

    Any options that are not set in the Apache configuration will default to the
    values preconfigured in the Apache2::AuthCAS module.  You should explicitly
    override those options that do not match your environment.

Database

    If you installed this module via CPAN shell, cpan2rpm, or some other automated installer, don't forget to create the session table!

    The SQL-92 format of the table is:
        CREATE TABLE cas_sessions (
            id             varchar(32) not null primary key,
            last_accessed  int8        not null,
            user_id        varchar(32) not null,
            pgtiou         varchar(256),
            pgt            varchar(256)
            service_ticket varchar(256)
        );
    Add indexes and adjust as appropriate for your database and usage.

SSL

    Be careful not to use the CASSessionCookieSecure flag with an HTTP resource.
    If this flag is set and the protocol is HTTP, then no cookie will get sent
    to Apache and Apache2::AuthCAS may act very strange.
    Be sure to set CASSessionCookieSecure only on HTTPS resources!

=head1 COMPATIBILITY

This module will only work with mod_perl2.  mod_perl1 is not supported.

=head1 SEE ALSO

=head2 Official JA-SIG CAS Website

http://www.ja-sig.org/products/cas/

=head2 mod_perl Documentation

http://perl.apache.org/

=head1 AUTHORS

Jason Hitt <jhitt@illumasys.com>

=head1 COPYRIGHT

Copyright (C) 2007 Jason Hitt <jhitt@illumasys.com>

This program is free software; you can redistribute it and/or modify it under
the terms of the GNU General Public License as published by the Free Software
Foundation; either version 2 of the License, or (at your option) any later
version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE. See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with
this program; if not, write to the Free Software Foundation, Inc.,
59 Temple Place, Suite 330, Boston, MA 02111-1307 USA


=cut
