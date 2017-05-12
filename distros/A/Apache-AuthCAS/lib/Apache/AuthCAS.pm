# Apache::AuthCAS
# David Castro, April 2004
# $Revision: 1.7 $
#
# Apache auth module to protect underlying resources using Yale's Central
# Authentication service
package Apache::AuthCAS;

$^W = 1;
use diagnostics;
use warnings;
use strict;
use mod_perl qw(StackedHandlers MethodHandlers Authen Authz);
use constant MP2 => $mod_perl::VERSION >= 1.99;
use vars qw($INITIALIZED $SESSION_CLEANUP_COUNTER);

BEGIN {
	if (MP2) {
		require Apache::Const;
		require APR::URI;
		Apache::Const->import(-compile => qw(FORBIDDEN HTTP_MOVED_TEMPORARILY OK DECLINED HTTP_OK));
	} else {
		require Apache::Constants;
		Apache::Constants->import(qw(FORBIDDEN HTTP_MOVED_TEMPORARILY OK DECLINED HTTP_OK));
	}
}

use Apache::URI;
use Net::SSLeay;
use MIME::Base64;
use DBI;

# logging flags
my $LOG_ERROR = "0";
my $LOG_WARN = "1";
my $LOG_INFO = "2";
my $LOG_DEBUG = "3";
my $LOG_INSANE = "4";
my $DEFAULT_LOG_LEVEL = $LOG_ERROR;
my $LOG_LEVEL = $DEFAULT_LOG_LEVEL;
# the URL the client is redirected to when an error occurs
my $DEFAULT_ERROR_URL="http://localhost/cas/error/";
my $ERROR_URL=$DEFAULT_ERROR_URL;
# error codes
my $DB_ERROR_CODE = "Database Service Error";
my $PGT_ERROR_CODE = "CAS Proxy Service Error";
my $INVALID_ST_ERROR_CODE = "Invalid Service Ticket";
my $INVALID_PGT_ERROR_CODE = "Invalid Proxy Granting Ticket";
my $MISSING_NETID_ERROR_CODE = "CAS failed to return NetID";
my $CAS_CONNECT_ERROR_CODE = "CAS couldn't validate service ticket";
# the URL a client is redirected to after logging in
my $SERVICE="";
# the service proxy tickets will be granted for
my $PROXY_SERVICE="";
# the host name of the CAS server
my $CAS_HOST="";
my $DEVEL_CAS_HOST="devel.localhost";
my $PROD_CAS_HOST="localhost";
# the port number for the CAS server
my $CAS_PORT="";
my $DEVEL_CAS_PORT="443";
my $PROD_CAS_PORT="443";
# CAS login URI
my $DEFAULT_CAS_LOGIN_URI="/cas/login";
my $CAS_LOGIN_URI=$DEFAULT_CAS_LOGIN_URI;
# CAS logout URI
my $DEFAULT_CAS_LOGOUT_URI="/cas/logout";
my $CAS_LOGOUT_URI=$DEFAULT_CAS_LOGOUT_URI;
# CAS proxy URI
my $DEFAULT_CAS_PROXY_URI="/cas/proxy";
my $CAS_PROXY_URI=$DEFAULT_CAS_PROXY_URI;
# CAS proxy validate URI
my $DEFAULT_CAS_PROXY_VALIDATE_URI="/cas/proxyValidate";
my $CAS_PROXY_VALIDATE_URI=$DEFAULT_CAS_PROXY_VALIDATE_URI;
# CAS service validate URI
my $DEFAULT_CAS_SERVICE_VALIDATE_URI="/cas/serviceValidate";
my $CAS_SERVICE_VALIDATE_URI=$DEFAULT_CAS_SERVICE_VALIDATE_URI;
# parameter used to pass in PGTIOU
my $PGT_IOU_PARAM = "pgtIou";
# parameter used to pass in PGT
my $PGT_ID_PARAM = "pgtId";
# number of proxy tickets to give the underlying application
my $DEFAULT_NUM_PROXY_TICKETS = 1;
my $NUM_PROXY_TICKETS = $DEFAULT_NUM_PROXY_TICKETS;
# the name of the cookie that will be used for sessions
my $DEFAULT_SESSION_COOKIE_NAME = "APACHECAS";
my $SESSION_COOKIE_NAME = $DEFAULT_SESSION_COOKIE_NAME;
# the domain the session cookies will be sent for
my $DEFAULT_SESSION_COOKIE_DOMAIN = "";
my $SESSION_COOKIE_DOMAIN = "";
# the max time before a session expires (in seconds)
my $DEFAULT_SESSION_TIMEOUT = 1800;
my $SESSION_TIMEOUT = $DEFAULT_SESSION_TIMEOUT;
# the name of the DBI database driver
my $DB_DRIVER = "";
my $DEVEL_DB_DRIVER = "Pg";
my $PROD_DB_DRIVER = "Pg";
# the host name of the database server
my $DB_HOST = "";
my $DEVEL_DB_HOST = "devel.localhost";
my $PROD_DB_HOST = "localhost";
# the port number of the database server
my $DB_PORT = "";
my $DEVEL_DB_PORT = "5432";
my $PROD_DB_PORT = "5432";
# the name of the database for sessions/pgtiou mapping
my $DB_NAME = "";
my $DEVEL_DB_NAME = "apache_cas";
my $PROD_DB_NAME = "apache_cas";
# the name of the session table
my $DB_SESSION_TABLE = "";
my $DEVEL_DB_SESSION_TABLE = "cas_sessions";
my $PROD_DB_SESSION_TABLE = "cas_sessions";
# the name of the pgtiou to pgt mapping table
my $DB_PGTIOU_TABLE = "";
my $DEVEL_DB_PGTIOU_TABLE = "cas_pgtiou_to_pgt";
my $PROD_DB_PGTIOU_TABLE = "cas_pgtiou_to_pgt";
# the user to connnect to the database with
my $DB_USER = "";
my $DEVEL_DB_USER = "develuser";
my $PROD_DB_USER = "produser";
# the password to connect to the databse with
my $DB_PASS = "";
my $DEVEL_DB_PASS = "develpass";
my $PROD_DB_PASS = "prodpass";
# whether or not we want redirect magic to remove service ticket from URL
my $DEFAULT_REMOVE_TICKET = "0";
my $REMOVE_TICKET = $DEFAULT_REMOVE_TICKET;
# are we running with production config, or other?
my $PRODUCTION = "0";
# session cleanup threshold (1 in N requests, session cleanup will occur for
# each Apache thread or process - i.e. for 10 processes, it may take as many as
# 100 requests before session cleanup is performed for a threshold of 10)
my $SESSION_CLEANUP_THRESHOLD = "10";
# when set to true, this module will attempt to make the underlying authz
# mechanism believe that "Basic" authentication has occurred
my $PRETEND_BASIC_AUTH = "0";
# this will turn on initialization that will only occur once for each apache
# process, meaning that changes will require a restart.  This has the benefit
# of speed for high-load sites, but will typically not be what you want.  The
# config of the first resource protected by AuthCAS will persist for the apache
# process that served up the request
my $STATIC_INITIALIZATION = "0";

if (!defined($INITIALIZED)) {
	# default to not initialized
	$INITIALIZED = 0;
}
if (!defined($SESSION_CLEANUP_COUNTER)) {
	# default to 0
	$SESSION_CLEANUP_COUNTER = 0;
}

my $tmp;

sub initialize($$) {
	my $self = shift;
	my $r = shift;

	# get all of our settings from the server config

	# logging
	if ($tmp = $r->dir_config("CASLogLevel")) {
		$LOG_LEVEL = $tmp;
	} else {
		# default
		$LOG_LEVEL = $DEFAULT_LOG_LEVEL;
	}
	
	Apache->warn("$$: CAS: initialize()") unless ($LOG_LEVEL < $LOG_INFO);

	# determine if we are running in production
	if ($tmp = $r->dir_config("CASProduction")) {
		if (defined($tmp) and ($tmp ne "") and 
			(($tmp eq "1") or ($tmp =~ /true/i))) 
		{
			$PRODUCTION = 1;
		}
		Apache->warn("$$: CAS: initialize(): setting CASProduction to $PRODUCTION") unless ($LOG_LEVEL < $LOG_INFO);
	} else {
		# default
		$PRODUCTION = 0;
	}

	# error pages
	if ($tmp = $r->dir_config("CASErrorURL")) {
		$ERROR_URL = $tmp;
		Apache->warn("$$: CAS: initialize(): setting CASErrorURL to $ERROR_URL") unless ($LOG_LEVEL < $LOG_INFO);
	} else {
		# default
		$ERROR_URL = $DEFAULT_ERROR_URL;
	}

	# service settings
	if ($tmp = $r->dir_config("CASService")) {
		$SERVICE = $tmp;
		Apache->warn("$$: CAS: initialize(): setting CASService to $SERVICE") unless ($LOG_LEVEL < $LOG_INFO);
	} else {
		# default
		$SERVICE = "";
	}
	if ($tmp = $r->dir_config("CASProxyService")) {
		$PROXY_SERVICE = $tmp;
		Apache->warn("$$: CAS: initialize(): setting CASProxyService to $PROXY_SERVICE") unless ($LOG_LEVEL < $LOG_INFO);
	} else {
		# default
		$PROXY_SERVICE = "";
	}

	# CAS server settings
	if ($tmp = $r->dir_config("CASHost")) {
		$CAS_HOST = $tmp;
		Apache->warn("$$: CAS: initialize(): setting cas host to $CAS_HOST") unless ($LOG_LEVEL < $LOG_INFO);
	} elsif ($PRODUCTION) {
		$CAS_HOST = $PROD_CAS_HOST;
		Apache->warn("$$: CAS: initialize(): setting cas host to $CAS_HOST") unless ($LOG_LEVEL < $LOG_INFO);
	} else {
		# default
		$CAS_HOST = $DEVEL_CAS_HOST;
		Apache->warn("$$: CAS: initialize(): setting cas host to $CAS_HOST") unless ($LOG_LEVEL < $LOG_INFO);
	}

	if ($tmp = $r->dir_config("CASPort")) {
		$CAS_PORT = $tmp;
		Apache->warn("$$: CAS: initialize(): setting cas port to $CAS_PORT") unless ($LOG_LEVEL < $LOG_INFO);
	} elsif ($PRODUCTION) {
		$CAS_PORT = $PROD_CAS_PORT;
		Apache->warn("$$: CAS: initialize(): setting cas port to $CAS_PORT") unless ($LOG_LEVEL < $LOG_INFO);
	} else {
		# default
		$CAS_PORT = $DEVEL_CAS_PORT;
		Apache->warn("$$: CAS: initialize(): setting cas port to $CAS_PORT") unless ($LOG_LEVEL < $LOG_INFO);
	}

	# CAS URIs
	if ($tmp = $r->dir_config("CASLoginURI")) {
		$CAS_LOGIN_URI = $tmp;
		Apache->warn("$$: CAS: initialize(): setting CASLoginURI to $CAS_LOGIN_URI") unless ($LOG_LEVEL < $LOG_INFO);
	} else {
		# default
		$CAS_LOGIN_URI = $DEFAULT_CAS_LOGIN_URI;
	}
	if ($tmp = $r->dir_config("CASLogoutURI")) {
		$CAS_LOGOUT_URI = $tmp;
		Apache->warn("$$: CAS: initialize(): setting CASLogoutURI to $CAS_LOGOUT_URI") unless ($LOG_LEVEL < $LOG_INFO);
	} else {
		# default
		$CAS_LOGOUT_URI = $DEFAULT_CAS_LOGOUT_URI;
	}
	if ($tmp = $r->dir_config("CASProxyURI")) {
		$CAS_PROXY_URI = $tmp;
		Apache->warn("$$: CAS: initialize(): setting CASProxyURI to $CAS_PROXY_URI") unless ($LOG_LEVEL < $LOG_INFO);
	} else {
		# default
		$CAS_PROXY_URI = $DEFAULT_CAS_PROXY_URI;
	}
	if ($tmp = $r->dir_config("CASProxyValidateURI")) {
		$CAS_PROXY_VALIDATE_URI = $tmp;
		Apache->warn("$$: CAS: initialize(): setting CASProxyValidateURI to $CAS_PROXY_VALIDATE_URI") unless ($LOG_LEVEL < $LOG_INFO);
	} else {
		# default
		$CAS_PROXY_VALIDATE_URI = $DEFAULT_CAS_PROXY_VALIDATE_URI;
	}
	if ($tmp = $r->dir_config("CASServiceValidateURI")) {
		$CAS_SERVICE_VALIDATE_URI = $tmp;
		Apache->warn("$$: CAS: initialize(): setting CASServiceValidateURI to $CAS_SERVICE_VALIDATE_URI") unless ($LOG_LEVEL < $LOG_INFO);
	} else {
		# default
		$CAS_SERVICE_VALIDATE_URI = $DEFAULT_CAS_SERVICE_VALIDATE_URI;
	}

	# number of proxy tickets to add to the request
	if ($tmp = $r->dir_config("CASNumProxyTickets")) {
		$NUM_PROXY_TICKETS = $tmp;
		Apache->warn("$$: CAS: initialize(): setting CASNumProxyTickets to $NUM_PROXY_TICKETS") unless ($LOG_LEVEL < $LOG_INFO);
	} else {
		# default
		$NUM_PROXY_TICKETS = $DEFAULT_NUM_PROXY_TICKETS;
	}
	
	# session settings
	if ($tmp = $r->dir_config("CASSessionCookieName")) {
		$SESSION_COOKIE_NAME = $tmp;
		Apache->warn("$$: CAS: initialize(): setting CASSessionCookieName to $SESSION_COOKIE_NAME") unless ($LOG_LEVEL < $LOG_INFO);
	} else {
		# default
		$SESSION_COOKIE_NAME = $DEFAULT_SESSION_COOKIE_NAME;
	}
	if ($tmp = $r->dir_config("CASSessionCookieDomain")) {
		$SESSION_COOKIE_DOMAIN = $tmp;
		Apache->warn("$$: CAS: initialize(): setting CASSessionCookieDomain to $SESSION_COOKIE_DOMAIN") unless ($LOG_LEVEL < $LOG_INFO);
	} else {
		# default
		$SESSION_COOKIE_DOMAIN = $DEFAULT_SESSION_COOKIE_DOMAIN;
	}
	if ($tmp = $r->dir_config("CASSessionTimeout")) {
		$SESSION_TIMEOUT= $tmp;
		Apache->warn("$$: CAS: initialize(): setting CASSessionTimeout to $SESSION_TIMEOUT") unless ($LOG_LEVEL < $LOG_INFO);
	} else {
		# default
		$SESSION_TIMEOUT= $DEFAULT_SESSION_TIMEOUT;
	}

	# database settings
	if ($tmp = $r->dir_config("CASDatabaseDriver")) {
		$DB_DRIVER = $tmp;
		Apache->warn("$$: CAS: initialize(): setting database driver to $DB_DRIVER") unless ($LOG_LEVEL < $LOG_INFO);
	} elsif ($PRODUCTION) {
		$DB_DRIVER = $PROD_DB_DRIVER;
		Apache->warn("$$: CAS: initialize(): setting database driver to $DB_DRIVER") unless ($LOG_LEVEL < $LOG_INFO);
	} else {
		# default
		$DB_DRIVER = $DEVEL_DB_DRIVER;
		Apache->warn("$$: CAS: initialize(): setting database driver to $DB_DRIVER") unless ($LOG_LEVEL < $LOG_INFO);
	}
	if ($tmp = $r->dir_config("CASDatabaseHost")) {
		$DB_HOST = $tmp;
		Apache->warn("$$: CAS: initialize(): setting database host to $DB_HOST") unless ($LOG_LEVEL < $LOG_INFO);
	} elsif ($PRODUCTION) {
		$DB_HOST = $PROD_DB_HOST;
		Apache->warn("$$: CAS: initialize(): setting database host to $DB_HOST") unless ($LOG_LEVEL < $LOG_INFO);
	} else {
		# default
		$DB_HOST = $DEVEL_DB_HOST;
		Apache->warn("$$: CAS: initialize(): setting database host to $DB_HOST") unless ($LOG_LEVEL < $LOG_INFO);
	
	}
	if ($tmp = $r->dir_config("CASDatabasePort")) {
		$DB_PORT = $tmp;
		Apache->warn("$$: CAS: initialize(): setting database port to $DB_PORT") unless ($LOG_LEVEL < $LOG_INFO);
	} elsif ($PRODUCTION) {
		$DB_PORT = $PROD_DB_PORT;
		Apache->warn("$$: CAS: initialize(): setting database port to $DB_PORT") unless ($LOG_LEVEL < $LOG_INFO);
	} else {
		# default
		$DB_PORT = $DEVEL_DB_PORT;
		Apache->warn("$$: CAS: initialize(): setting database port to $DB_PORT") unless ($LOG_LEVEL < $LOG_INFO);
	}
	if ($tmp = $r->dir_config("CASDatabaseName")) {
		$DB_NAME = $tmp;
		Apache->warn("$$: CAS: initialize(): setting database name to $DB_NAME") unless ($LOG_LEVEL < $LOG_INFO);
	} elsif ($PRODUCTION) {
		$DB_NAME = $PROD_DB_NAME;
		Apache->warn("$$: CAS: initialize(): setting database name to $DB_NAME") unless ($LOG_LEVEL < $LOG_INFO);
	} else {
		# default
		$DB_NAME = $DEVEL_DB_NAME;
		Apache->warn("$$: CAS: initialize(): setting database name to $DB_NAME") unless ($LOG_LEVEL < $LOG_INFO);
	}
	if ($tmp = $r->dir_config("CASDatabaseSessionTable")) {
		$DB_SESSION_TABLE = $tmp;
		Apache->warn("$$: CAS: initialize(): setting session table to $DB_SESSION_TABLE") unless ($LOG_LEVEL < $LOG_INFO);
	} elsif ($PRODUCTION) {
		$DB_SESSION_TABLE = $PROD_DB_SESSION_TABLE;
		Apache->warn("$$: CAS: initialize(): setting session table to $DB_SESSION_TABLE") unless ($LOG_LEVEL < $LOG_INFO);
	} else {
		# default
		$DB_SESSION_TABLE = $DEVEL_DB_SESSION_TABLE;
		Apache->warn("$$: CAS: initialize(): setting session table to $DB_SESSION_TABLE") unless ($LOG_LEVEL < $LOG_INFO);
	}
	if ($tmp = $r->dir_config("CASDatabasePGTIOUTable")) {
		$DB_PGTIOU_TABLE = $tmp;
		Apache->warn("$$: CAS: initialize(): setting pgtiou table to $DB_PGTIOU_TABLE") unless ($LOG_LEVEL < $LOG_INFO);
	} elsif ($PRODUCTION) {
		$DB_PGTIOU_TABLE = $PROD_DB_PGTIOU_TABLE;
		Apache->warn("$$: CAS: initialize(): setting pgtiou table to $DB_PGTIOU_TABLE") unless ($LOG_LEVEL < $LOG_INFO);
	} else {
		# default
		$DB_PGTIOU_TABLE = $DEVEL_DB_PGTIOU_TABLE;
		Apache->warn("$$: CAS: initialize(): setting pgtiou table to $DB_PGTIOU_TABLE") unless ($LOG_LEVEL < $LOG_INFO);
	}
	if ($tmp = $r->dir_config("CASDatabaseUser")) {
		$DB_USER = $tmp;
		Apache->warn("$$: CAS: initialize(): setting database user to $DB_USER") unless ($LOG_LEVEL < $LOG_INFO);
	} elsif ($PRODUCTION) {
		$DB_USER = $PROD_DB_USER;
		Apache->warn("$$: CAS: initialize(): setting database user to $DB_USER") unless ($LOG_LEVEL < $LOG_INFO);
	} else {
		# default
		$DB_USER = $DEVEL_DB_USER;
		Apache->warn("$$: CAS: initialize(): setting database user to $DB_USER") unless ($LOG_LEVEL < $LOG_INFO);
	}
	if ($tmp = $r->dir_config("CASDatabasePass")) {
		$DB_PASS = $tmp;
		Apache->warn("$$: CAS: initialize(): setting database password to $DB_PASS") unless ($LOG_LEVEL < $LOG_INFO);
	} elsif ($PRODUCTION) {
		$DB_PASS = $PROD_DB_PASS;
		Apache->warn("$$: CAS: initialize(): setting database password to $DB_PASS") unless ($LOG_LEVEL < $LOG_INFO);
	} else {
		# default
		$DB_PASS = $DEVEL_DB_PASS;
		Apache->warn("$$: CAS: initialize(): setting database password to $DB_PASS") unless ($LOG_LEVEL < $LOG_INFO);
	}

	if (!$DB_HOST or !$DB_PORT or !$DB_NAME or !$DB_USER or !$DB_PASS) {
		Apache->warn("$$: CAS: initialize(): database not properly configured.  Please specify: 'CASDatabaseHost', 'CASDatabasePort', 'CASDatabaseName', 'CASDatabaseUser', 'CASDatabasePassword'");
	}

	if ($tmp = $r->dir_config("CASRemoveTicket")) {
		$REMOVE_TICKET = $tmp;
		Apache->warn("$$: CAS: initialize(): setting CASRemoveTicket to $REMOVE_TICKET") unless ($LOG_LEVEL < $LOG_INFO);
	} else {
		# default
		$REMOVE_TICKET = $DEFAULT_REMOVE_TICKET;
	}

	# specify that we have been successfully initialized
	$INITIALIZED = 1;
}

# used for underlying services that need proxy tickets (PTs)
sub authenticate($$) {
	my $self = shift;
	my $r = shift;
	my $tmp;

	# Only authenticate the first internal request
	return (MP2 ? Apache::OK : Apache::Constants::OK) unless $r->is_initial_req;

	# get our configuration, unless we already have and we are running static
	unless ($STATIC_INITIALIZATION and $INITIALIZED) {
		$self->initialize($r);
	}

	# perform any cleanup that is needed
	$self->cleanup($r);
	
	Apache->warn("$$: CAS: authenticate()") unless ($LOG_LEVEL < $LOG_DEBUG);

	# see if any of our other handlers have specified that they have already
	# sufficiently checked the authenticating user
	my $authenticated = $r->subprocess_env->{'AUTHENTICATED'} || "";
	Apache->warn("$$: CAS: authenticated='$authenticated'") unless ($LOG_LEVEL < $LOG_DEBUG);

	if ($authenticated eq "true") {
		return (MP2 ? Apache::OK : Apache::Constants::OK);
	}

	# Parse the query string to get the ticket, plus any GET variables
	# to rebuild our service string (which is needed for CAS to send the
	# client back to the originating service).

	# grab the uri that was requested
	my $uri = $r->parsed_uri;
	my $path = $uri->path();
	my $unparsed = $uri->unparse();
	my $query = $uri->query || "";
	if ($query) {
		$path .= "?$query";
	} elsif ($unparsed =~ /\?$/) {
		$path .= "?";
	}

	# grab out the params we need to use for tests
	my $ticket = "";
	my $pgt = "";
	my $pgtiou = "";
	if ($query ne "") {
		my @params = split(/&/, $query);
		foreach (@params) {
			my ($key, $value) = split(/=/, $_);
			Apache->warn("$$: CAS: authenticate(): PARAMS: '$key' => '$value'") unless ($LOG_LEVEL < $LOG_DEBUG);
			if ($key eq "ticket") {
				Apache->warn("$$: CAS: authenticate(): ticket found: '$value'") unless ($LOG_LEVEL < $LOG_DEBUG);
				$ticket = $value || "";
			}
			if ($key eq $PGT_ID_PARAM) {
				Apache->warn("$$: CAS: authenticate(): PGTID found: '$value'") unless ($LOG_LEVEL < $LOG_DEBUG);
				$pgt = $value;
			}
			if ($key eq $PGT_IOU_PARAM) {
				Apache->warn("$$: CAS: authenticate(): PGTIOU found: '$value'") unless ($LOG_LEVEL < $LOG_DEBUG);
				$pgtiou = $value;
			}
		}
	}
	
	# this is the proxy receptor, should only enter here when CAS sends us the
	# PGTIOU and the PGT
	if (($pgtiou ne "") and ($pgt ne "")) {
		Apache->warn("$$: CAS: authenticate(): proxy receptor invoked with '$pgtiou' => '$pgt'") unless ($LOG_LEVEL < $LOG_DEBUG);

		# save the pgtiou/pgt mapping
		if (!$self->set_pgt($pgtiou, $pgt)) {
			Apache->warn("$$: CAS: authenticate(): couldn't save '$pgtiou' => '$pgt', redirecting to error page") unless ($LOG_LEVEL < $LOG_ERROR);
			return $self->redirect($r, $ERROR_URL, $DB_ERROR_CODE);
		}

		Apache->warn("$$: CAS: authenticate(): saved '$pgtiou' => '$pgt'") unless ($LOG_LEVEL < $LOG_DEBUG);

		# return a successful response to CAS
		# have to not let request fall through to real content here
		$r->push_handlers(PerlResponseHandler => \&send_proxysuccess);
	} # else treat this as a normal authentication request

	# determine any session cookies/session id we may have recieved
	my ($cookie, $sid) = ("", "");
	if (!defined($cookie = $r->header_in('Cookie'))) {
		# if we don't have a session cookie, the user can't be valid
		Apache->warn("$$: CAS: authenticate(): no session cookie found") unless ($LOG_LEVEL < $LOG_DEBUG);

		my $service;
		if ($SERVICE eq "") {
			# use the current URL as the service
			$service = $self->this_url_encoded($r);
		} else {
			# use the static entry point into this service
			$service = $self->urlEncode($SERVICE);
		}
		Apache->warn("$$: CAS: authenticate(): no session cookie for service: '$service'") unless ($LOG_LEVEL < $LOG_DEBUG);
	} else {
		# we have a session cookie, so we need to get the session id
		Apache->warn("$$: CAS: authenticate(): cookie found: '$cookie'") unless ($LOG_LEVEL < $LOG_DEBUG);

		# get session id from the cookie
		$cookie =~ /.*$SESSION_COOKIE_NAME=([^;]+)(\s*;.*|\s*$)/;
		$sid = $1 || "";
		if (!$sid) {
			# no sessions id in cookie?
			Apache->warn("$$: CAS: authenticate(): no session id found in cookie: '$cookie'") unless ($LOG_LEVEL < $LOG_DEBUG);
		} else {
			Apache->warn("$$: CAS: authenticate(): session id '$sid' found in cookie: '$cookie'") unless ($LOG_LEVEL < $LOG_DEBUG);
		}
	}

	# if we don't have a session id and there is no service ticket, redirect
	# the user to CAS (they have never been authenticated)
	if (!$ticket and !$sid) {
		Apache->warn("$$: CAS: authenticate(): no ticket and no cookie, redirecting to login") unless ($LOG_LEVEL < $LOG_DEBUG);
		return $self->redirect_login($r);
	} 
	
	# note: we should have a session id or a service ticket.

	# if we have a session id
	my $user="";
	if ($sid) {
		# we set up our own session here, so that we don't have to continually
		# go through this whole process!  we associate a session id with a
		# PGTIOU
	
		# try to get a session record for the session id we recieved
		my @session_data; # session id, last accessed, netid, pgtiou
		if (@session_data = $self->get_session_data($sid)) {
			Apache->warn("$$: CAS: authenticate(): session data: ".join(",",@session_data)) unless ($LOG_LEVEL < $LOG_DEBUG);

			# we found the session id in out session hash
			my $last_accessed = $session_data[1];

			# make sure the session is still valid
			Apache->warn("$$: CAS: authenticate(): session last_accessed=$last_accessed") unless ($LOG_LEVEL < $LOG_DEBUG);
			if ($last_accessed + $SESSION_TIMEOUT >= time()) {
				# session is still valid
				Apache->warn("$$: CAS: authenticate(): session '$sid' is still valid") unless ($LOG_LEVEL < $LOG_DEBUG);

				# record the last time the session was accessed
				$session_data[1] = time();
				Apache->warn("$$: CAS: authenticate(): setting last accessed time to '".time()."'") unless ($LOG_LEVEL < $LOG_DEBUG);

				# if something bad happened, like database unavailability
				if (!$self->set_session_data(@session_data)) {
					Apache->warn("$$: CAS: authenticate(): problem saving session data, redirecting to the error page") unless ($LOG_LEVEL < $LOG_ERROR);
					return $self->redirect($r, $ERROR_URL, $DB_ERROR_CODE);
				} else {
					Apache->warn("$$: CAS: authenticate(): saved session data: ".join(",",@session_data)) unless ($LOG_LEVEL < $LOG_DEBUG);
				}
				
				# set the pgtiou
				$user = $session_data[2];
				$pgtiou = $session_data[3];

				if ($PROXY_SERVICE) {
					return $self->do_proxy($r, $sid, $pgtiou, $user, 0);
				} else {
					# no proxy stuff, so we are done
					Apache->warn("$$: CAS: authenticate(): no proxy stuff, we are done") unless ($LOG_LEVEL < $LOG_DEBUG);

					Apache->warn("$$: CAS: authenticate(): setting header CAS_FILTER_USER=$user") unless ($LOG_LEVEL < $LOG_DEBUG);
					$r->header_in('CAS_FILTER_USER', $user);

					if ($PRETEND_BASIC_AUTH) {
						# setup this up for underlying authz modules that rely on Basic auth having been performed
						$r->header_in('Authorization', "Basic " . encode_base64($user . ":DUMMYPASS"));
						$r->user($user);
						$r->connection->user($user);
						$r->connection->auth_type("Basic");
					}

					return (MP2 ? Apache::OK : Apache::Constants::OK);
				}
			} else {
				Apache->warn("$$: CAS: authenticate(): session '$sid' has expired") unless ($LOG_LEVEL < $LOG_DEBUG);
				if (!$self->delete_session_data($sid)) {
					Apache->warn("$$: CAS: authenticate(): couldn't delete expired session id='$sid'") unless ($LOG_LEVEL < $LOG_WARN);
				}
				Apache->warn("$$: CAS: authenticate(): deleted expired session '$sid'") unless ($LOG_LEVEL < $LOG_DEBUG);
				
				$sid = "";
			}
		} else {
			Apache->warn("$$: CAS: authenticate(): session '$sid' is invalid") unless ($LOG_LEVEL < $LOG_DEBUG);
			$sid = "";
		}
	}
	# note: not an else if, because we may find an invalid session id and
	#       fallback to ticket

	# if we have a service ticket
	if (($sid eq "") and ($ticket ne "")) {
		# validate service ticket through CAS, since no valid cookie was found
		my %properties = $self->validate_service_ticket($r, $ticket, $PROXY_SERVICE ?"1":"0");
		if ($properties{'error'}) {
			# error occurred validating service ticket
			return $self->redirect($r, $ERROR_URL, $properties{'error'});
		} else {
			Apache->warn("$$: CAS: authenticate(): valid service ticket '$ticket'") unless ($LOG_LEVEL < $LOG_DEBUG);
		}

		$pgtiou = $properties{'pgtiou'} || "";
		$user = $properties{'user'} || "";

		# we should get back a netid when validating a service ticket
		if ($user eq "") {
			return $self->redirect($r, $ERROR_URL, $MISSING_NETID_ERROR_CODE);
		}

		$sid = &create_session_id();

		Apache->warn("$$: CAS: authenticate(): setting sid='$sid' for netid='$user'") unless ($LOG_LEVEL < $LOG_DEBUG);

		# map a new session id to this pgtiou and give the client a cookie
		my $time = time();
		Apache->warn("$$: CAS: authenticate(): trying to save session data: ".join(",",$sid, $time, $user, $pgtiou)) unless ($LOG_LEVEL < $LOG_DEBUG);
		if (!$self->set_session_data($sid, $time, $user, $pgtiou)) {
			# if something bad happened, like database unavailability
			Apache->warn("$$: CAS: authenticate(): problem saving session data, redirecting to the error page") unless ($LOG_LEVEL < $LOG_ERROR);
			return $self->redirect($r, $ERROR_URL, $DB_ERROR_CODE);
		} else {
			Apache->warn("$$: CAS: authenticate(): saved session data: ".join(",",$sid, $time, $user, $pgtiou)) unless ($LOG_LEVEL < $LOG_DEBUG);
		}

		Apache->warn("$$: CAS: authenticate(): sending session cookie") unless ($LOG_LEVEL < $LOG_DEBUG);
		my $cookie = "$SESSION_COOKIE_NAME=$sid;path=/";
		if ($SESSION_COOKIE_DOMAIN ne "") {
			$cookie .= ";domain=.$SESSION_COOKIE_DOMAIN";
		}

		# send the cookie to the browser
		$r->header_out("Set-Cookie" => $cookie);

		# in case we redirect (considered an "error")
		$r->err_header_out("Set-Cookie" => $cookie);
	} else {
		Apache->warn("$$: CAS: authenticate(): no valid session id or ticket") unless ($LOG_LEVEL < $LOG_DEBUG);
		return $self->redirect_login($r);
	}

	Apache->warn("$$: CAS: authenticate(): got user: '$user'") unless ($LOG_LEVEL < $LOG_DEBUG);
	Apache->warn("$$: CAS: authenticate(): got PGTIOU: '$pgtiou'") unless ($LOG_LEVEL < $LOG_DEBUG);

	if ($PROXY_SERVICE) {
		return $self->do_proxy($r, $sid, $pgtiou, $user, 1);
	} else {
		# no proxy stuff, so we are done
		Apache->warn("$$: CAS: authenticate(): no proxy stuff, so we are done") unless ($LOG_LEVEL < $LOG_DEBUG);

		# redirect to this same page minus the ticket
		if (($REMOVE_TICKET eq "true") || ($REMOVE_TICKET eq "1")) {
			Apache->warn("$$: CAS: authenticate(): setting header CAS_FILTER_USER=$user") unless ($LOG_LEVEL < $LOG_DEBUG);
			$r->header_in('CAS_FILTER_USER', $user);

			if ($PRETEND_BASIC_AUTH) {
				# setup this up for underlying authz modules that rely on Basic auth having been performed
				$r->header_in('Authorization', "Basic " . encode_base64($user . ":DUMMYPASS"));
				$r->user($user);
				$r->connection->user($user);
				$r->connection->auth_type("Basic");
			}

			Apache->warn("$$: CAS: authenticate(): trying to remove service ticket from URI") unless ($LOG_LEVEL < $LOG_DEBUG);
			return $self->redirect_without_ticket($r);
		} else {
			Apache->warn("$$: CAS: authenticate(): setting header CAS_FILTER_USER=$user") unless ($LOG_LEVEL < $LOG_DEBUG);
			$r->header_in('CAS_FILTER_USER', $user);

			if ($PRETEND_BASIC_AUTH) {
				# setup this up for underlying authz modules that rely on Basic auth having been performed
				$r->header_in('Authorization', "Basic " . encode_base64($user . ":DUMMYPASS"));
				$r->user($user);
				$r->connection->user($user);
				$r->connection->auth_type("Basic");
			}

			Apache->warn("$$: CAS: authenticate(): not trying to remove service ticket from URI") unless ($LOG_LEVEL < $LOG_DEBUG);
			return (MP2 ? Apache::OK : Apache::Constants::OK);
		}
	}

	# failed if we got this far, but shouldn't
	return (MP2 ? Apache::FORBIDDEN : Apache::Constants::FORBIDDEN);
}

sub cleanup($$) {
	my $self = shift;
	my $r = shift;

	$SESSION_CLEANUP_COUNTER++;
	Apache->warn("$$: CAS: cleanup(): counter=$SESSION_CLEANUP_COUNTER") unless ($LOG_LEVEL < $LOG_DEBUG);

	# perform session cleanup
	if ($SESSION_CLEANUP_COUNTER == 1) {
		Apache->warn("$$: CAS: initialize(): performing session cleanup");
		$self->delete_expired_sessions();
		Apache->warn("$$: CAS: initialize(): performing pgt/pgtiou cleanup");
		$self->delete_expired_pgts();
	} 

	# reset counter if we have reached our threshold
	if ($SESSION_CLEANUP_COUNTER >= $SESSION_CLEANUP_THRESHOLD) {
		# reset counter
		$SESSION_CLEANUP_COUNTER = 0;
	}
}

sub redirect_without_ticket($$) {
	my $self = shift;
	my $r = shift;

	Apache->warn("$$: CAS: redirect_without_ticket(): redirecting to remove service ticket from service string") unless ($LOG_LEVEL < $LOG_INFO);

	# this_url() strips the service ticket
	my $url = $self->this_url($r);
	$r->header_out("Location" => $url);
	return (MP2 ? Apache::HTTP_MOVED_TEMPORARILY : Apache::Constants::HTTP_MOVED_TEMPORARILY);
}

sub redirect_login($$) {
	my $self = shift;
	my $r = shift;

	Apache->warn("$$: CAS: redirect_login()") unless ($LOG_LEVEL < $LOG_DEBUG);

	my $service;
	if ($SERVICE eq "") {
		# use the current URL as the service
		$service = $self->this_url_encoded($r);
	} else {
		# use the static entry point into this service
		$service = $self->urlEncode($SERVICE);
	}
	Apache->warn("$$: CAS: redirect_login(): redirecting to CAS for service: '$service'") unless ($LOG_LEVEL < $LOG_INFO);
	my $redirect_url = "https://$CAS_HOST:$CAS_PORT$CAS_LOGIN_URI?service=$service";
	$r->header_out("Location" => $redirect_url);
	return (MP2 ? Apache::HTTP_MOVED_TEMPORARILY : Apache::Constants::HTTP_MOVED_TEMPORARILY);
}

sub redirect($$) {
	my $self = shift;
	my $r = shift;
	my $url = shift || "";
	my $errcode = shift || "";

	Apache->warn("$$: CAS: redirect()") unless ($LOG_LEVEL < $LOG_DEBUG);

	if ($url) {
		my $service;
		if ($SERVICE eq "") {
			# use the current URL as the service
			$service = $self->this_url_encoded($r);
			Apache->warn("$$: CAS: redirect(): using self as service") unless ($LOG_LEVEL < $LOG_DEBUG);
		} else {
			# use the static entry point into this service
			$service = $self->urlEncode($SERVICE);
			Apache->warn("$$: CAS: redirect(): using configured service") unless ($LOG_LEVEL < $LOG_DEBUG);
		}
		$r->header_out("CAS_FILTER_CAS_HOST", $CAS_HOST);
		$r->header_out("CAS_FILTER_CAS_PORT", $CAS_PORT);
		$r->header_out("CAS_FILTER_CAS_LOGIN_URI", $CAS_LOGIN_URI);
		$r->header_out("CAS_FILTER_SERVICE", $service);
		Apache->warn("$$: CAS: redirect(): redirecting to url: '$url' service: '$service'") unless ($LOG_LEVEL < $LOG_INFO);
		$r->header_out("Location" => "$url?login_url=https://$CAS_HOST:$CAS_PORT$CAS_LOGIN_URI&service=$service&errcode=$errcode");
		return (MP2 ? Apache::HTTP_MOVED_TEMPORARILY : Apache::Constants::HTTP_MOVED_TEMPORARILY);
	} else {
		Apache->warn("$$: CAS: redirect(): no redirect URL, displaying message") unless ($LOG_LEVEL < $LOG_INFO);
		$r->content_type ('text/html');
		$r->print("<html><body>service misconfigured</body></html>");
		$r->rflush;
		return (MP2 ? Apache::HTTP_OK : Apache::Constants::HTTP_OK);
	}
}

# params
#     apache request object
#     ticket to be validated
#     1 or 0, whether we need proxy tickets
# returns a hash with keys on success
# 	  'user', 'pgtiou'
# NULL on failure
sub validate_service_ticket($$) {
	my $self = shift;
	my $r = shift;
	my $ticket = shift;
	my $proxy = shift;

	Apache->warn("$$: CAS: validate_service_ticket(): validating service ticket '$ticket' through CAS") unless ($LOG_LEVEL < $LOG_DEBUG);
	my %properties;

	my $service;
	if ($SERVICE eq "") {
		# use the current URL as the service
		$service = $self->this_url_encoded($r);
	} else {
		# use the static entry point into this service
		$service = $self->urlEncode($SERVICE);
	}

	Apache->warn("$$: CAS: validate_service_ticket(): requesting validation for service: '$service'") unless ($LOG_LEVEL < $LOG_DEBUG);
	my $tmp;
	# FIXME - diff urls for proxy vs. none?
	if ($proxy) {
		$tmp = $CAS_PROXY_VALIDATE_URI . "?service=$service&ticket=$ticket&pgtUrl=$service";
	} else {
		$tmp = $CAS_SERVICE_VALIDATE_URI . "?service=$service&ticket=$ticket";
	}

	Apache->warn("$$: CAS: validate_service_ticket(): request URL: '$tmp'") unless ($LOG_LEVEL < $LOG_DEBUG);

	if ($LOG_LEVEL >= $LOG_INSANE) {
		$Net::SSLeay::trace = 3;  # 0=no debugging, 1=ciphers, 2=trace, 3=dump data
	} else {
		$Net::SSLeay::trace = 0;  # 0=no debugging, 1=ciphers, 2=trace, 3=dump data
	}
	#$Net::SSLeay::linux_debug = 1;

	my ($page, $response, %reply_headers) = Net::SSLeay::get_https($CAS_HOST, $CAS_PORT, $tmp);

	# if we had some type of connection problem
	if (!defined($page)) {
		Apache->warn("$$: CAS: validate_service_ticket(): error validating service");
		$properties{'error'} = $CAS_CONNECT_ERROR_CODE;
		return %properties;
	}

	Apache->warn("$$: CAS: validate_service_ticket(): page: $page") unless ($LOG_LEVEL < $LOG_INSANE);
	Apache->warn("$$: CAS: validate_service_ticket(): response: $response") unless ($LOG_LEVEL < $LOG_INSANE);

	# FIXME - add a check for a 404 error/other errors
	if ($page =~ /<cas:user>([^<]+)<\/cas:user>/) {
		my $user = $1;
		chomp $user;
		Apache->warn("$$: CAS: validate_service_ticket(): valid service ticket, user '$user' authenticated") unless ($LOG_LEVEL < $LOG_DEBUG);
		$properties{'user'} = $user;
	
		# only try to get PGTIOU if we are doing proxy stuff
		if ($proxy) {
			if ($page =~ /<cas:proxyGrantingTicket>([^<]+)<\/cas:proxyGrantingTicket>/) {
				Apache->warn("$$: CAS: validate_service_ticket(): got pgt='$1' for user='$user'") unless ($LOG_LEVEL < $LOG_DEBUG);
				if ($1 ne "") {
					$properties{'pgtiou'} = $1;
				} else {
					Apache->warn("$$: CAS: validate_service_ticket(): empty PGT in response from CAS") unless ($LOG_LEVEL < $LOG_ERROR);
				}
			} else {
				Apache->warn("$$: CAS: validate_service_ticket(): no PGT in response from CAS") unless ($LOG_LEVEL < $LOG_ERROR);
				$properties{'error'} = $PGT_ERROR_CODE;
				return %properties;
			}
		}
	} else {
		Apache->warn("$$: CAS: validate_service_ticket(): invalid service ticket, user denied access") unless ($LOG_LEVEL < $LOG_DEBUG);
		$properties{'error'} = $INVALID_ST_ERROR_CODE;
		return %properties;
	}

	return %properties;
}

sub send_proxysuccess($$) {
	my $self = shift;
	my $r = shift;

	Apache->warn("$$: CAS: send_proxysuccess(): sending proxy success for CAS callback") unless ($LOG_LEVEL < $LOG_DEBUG);

	$r->content_type("text/html");
	$r->print("<casClient:proxySuccess xmlns:casClient=\"http://www.yale.edu/tp/casClient\"/>\n");
	$r->rflush();
	return (MP2 ? Apache::OK : Apache::Constants::OK);
}

sub get_proxy_tickets($$) {
	my $self = shift;
	my $pgt = shift;
	my $target = shift;
	my $num_tickets = shift;

	Apache->warn("$$: CAS: get_proxy_tickets()") unless ($LOG_LEVEL < $LOG_DEBUG);

	my @tickets;
	
	for (my $i=0; $i < $num_tickets; $i++) {
		my $uri = "$CAS_PROXY_URI?pgt=$pgt&targetService=$target";
		Apache->warn("$$: CAS: get_proxy_tickets(): using PGT to obtain PT: calling URL '$uri'") unless ($LOG_LEVEL < $LOG_DEBUG);

		if ($LOG_LEVEL >= $LOG_INSANE) {
			$Net::SSLeay::trace = 3;  # 0=no debugging, 1=ciphers, 2=trace, 3=dump data
		} else {
			$Net::SSLeay::trace = 0;  # 0=no debugging, 1=ciphers, 2=trace, 3=dump data
		}

		my ($page, $response, %reply_headers) = Net::SSLeay::get_https($CAS_HOST, $CAS_PORT, $uri);

		if ($page =~ /<cas:proxySuccess>/) {
			Apache->warn("$$: CAS: get_proxy_tickets(): successful proxy request") unless ($LOG_LEVEL < $LOG_DEBUG);
			if ($page =~ /<cas:proxyTicket>([^<]+)<\/cas:proxyTicket>/) {
				Apache->warn("$$: CAS: get_proxy_tickets(): successfully retrieved proxy ticket") unless ($LOG_LEVEL < $LOG_DEBUG);
				push(@tickets, $1);
			} else {
				Apache->warn("$$: CAS: get_proxy_tickets(): no proxy ticket in response") unless ($LOG_LEVEL < $LOG_DEBUG);
				return qw();
			}
		} else {
			Apache->warn("$$: CAS: get_proxy_tickets(): unsuccessful proxy request") unless ($LOG_LEVEL < $LOG_DEBUG);
			return qw();
		}
	}

	if (@tickets) {
		return @tickets;
	} else {
		return qw();
	}
}

# place data in the session
sub set_session_data($$) {
	my $self = shift;
	my $sid = shift;
	my $last_accessed = shift;
	my $uid = shift;
	my $pgtiou = shift || "";

	Apache->warn("$$: CAS: set_session_data()") unless ($LOG_LEVEL < $LOG_DEBUG);

	my $dbh = DBI->connect("dbi:$DB_DRIVER:dbname=$DB_NAME;host=$DB_HOST;port=$DB_PORT", $DB_USER, $DB_PASS, { AutoCommit => 1 });
	if (!defined($dbh)) {
		Apache->warn("$$: CAS: set_session_data(): db connect error: $DBI::errstr") unless ($LOG_LEVEL < $LOG_ERROR);
		return "";
	}

	# see if this session already exists
	my $sth = $dbh->prepare("SELECT id FROM $DB_SESSION_TABLE WHERE id=?;");
	$sth->execute($sid);
	if ($sth->fetch()) {
		Apache->warn("$$: CAS: set_session_data(): found session sid='$sid' to update") unless ($LOG_LEVEL < $LOG_DEBUG);

		#print "DEBUG: '$id', '$last_accessed', '$uid', '$pgtiou'\n";
		Apache->warn("$$: CAS: set_session_data(): SQL: UPDATE $DB_SESSION_TABLE SET last_accessed='$last_accessed', uid='$uid', pgtiou='$pgtiou' WHERE id='$sid';") unless ($LOG_LEVEL < $LOG_DEBUG);
		my $sth = $dbh->prepare("UPDATE $DB_SESSION_TABLE SET last_accessed=?, uid=?, pgtiou=? WHERE id=?;");
		$sth->execute($last_accessed, $uid, $pgtiou, $sid);
		my $rc = $sth->err;

		# if we have an error when updating the session
		if ($rc) {
			Apache->warn("$$: CAS: set_session_data(): error updating session sid='$sid'") unless ($LOG_LEVEL < $LOG_DEBUG);
			$sth->finish();
			$dbh->disconnect();
			return "";
		}
		Apache->warn("$$: CAS: set_session_data(): updated session sid='$sid': last_accessed='$last_accessed', uid='$uid', pgtiou='$pgtiou'") unless ($LOG_LEVEL < $LOG_DEBUG);
	} else {
		Apache->warn("$$: CAS: set_session_data(): creating new session sid='$sid' to update") unless ($LOG_LEVEL < $LOG_DEBUG);

		#print "DEBUG2: '$id', '$last_accessed', '$uid', '$pgtiou'\n";
		my $sth = $dbh->prepare("INSERT INTO $DB_SESSION_TABLE(id,last_accessed,uid,pgtiou) VALUES(?, ?, ?, ?);");
		$sth->execute($sid, $last_accessed, $uid, $pgtiou);
		my $rc = $sth->err;

		# if we have an error when updating the session
		if ($rc) {
			$sth->finish();
			$dbh->disconnect();
			return "";
		}
	}

	$sth->finish();
	$dbh->disconnect();

	return 1;
}

# takes a session id and returns an array
sub get_session_data($$) {
	my $self = shift;
	my $sid = shift;

	Apache->warn("$$: CAS: get_session_data()") unless ($LOG_LEVEL < $LOG_DEBUG);

	# retrieve a session object for this session id
	my $dbh = DBI->connect("dbi:$DB_DRIVER:dbname=$DB_NAME;host=$DB_HOST;port=$DB_PORT", $DB_USER, $DB_PASS, { AutoCommit => 1 });
	if (!defined($dbh)) {
		Apache->warn("$$: CAS: get_session_data(): db connect error: $DBI::errstr") unless ($LOG_LEVEL < $LOG_ERROR);
		return ();
	}
	my $sth = $dbh->prepare("SELECT last_accessed, uid, pgtiou FROM $DB_SESSION_TABLE WHERE id=?;");
	$sth->execute($sid);
	my ($last_accessed, $uid, $pgtiou);
	$sth->bind_columns(\$last_accessed, \$uid, \$pgtiou);
	my $result = $sth->fetch();
	$sth->finish();
	$dbh->disconnect();

	if ($result) {
		Apache->warn("$$: CAS: get_session_data(): got session data for sid='$sid': last_accessed='$last_accessed' uid='$uid' pgtiou='$pgtiou'") unless ($LOG_LEVEL < $LOG_DEBUG);
		return ($sid, $last_accessed, $uid, $pgtiou);
	}
	Apache->warn("$$: CAS: get_session_data(): couldn't get session data for sid='$sid'") unless ($LOG_LEVEL < $LOG_DEBUG);
	return ();
}

# delete session
sub delete_session_data($$) {
	my $self = shift;
	my $sid = shift;

	Apache->warn("$$: CAS: delete_session_data()") unless ($LOG_LEVEL < $LOG_DEBUG);

	# retrieve a session object for this session id
	my $dbh = DBI->connect("dbi:$DB_DRIVER:dbname=$DB_NAME;host=$DB_HOST;port=$DB_PORT", $DB_USER, $DB_PASS, { AutoCommit => 1 });
	if (!defined($dbh)) {
		Apache->warn("$$: CAS: delete_session_data(): db connect error: $DBI::errstr") unless ($LOG_LEVEL < $LOG_ERROR);
		return "";
	}
	my $sth = $dbh->prepare("DELETE FROM $DB_SESSION_TABLE WHERE id=?");
	$sth->execute($sid);

	# if we have an error when updating the session
	my $rc = $sth->err;
	my $count = $sth->rows;
	if ($rc) {
		Apache->warn("$$: CAS: delete_session_data(): error deleting session mapping for sid='$sid'") unless ($LOG_LEVEL < $LOG_DEBUG);
		$sth->finish();
		$dbh->disconnect();
		return "";
	}
	Apache->warn("$$: CAS: delete_session_data(): deleted '$count' session mappings for sid='$sid'") unless ($LOG_LEVEL < $LOG_DEBUG);

	$sth->finish();
	$dbh->disconnect();

	return 1;
}

# delete expired sessions
sub delete_expired_sessions($$) {
	my $self = shift;

	Apache->warn("$$: CAS: delete_expired_sessions()") unless ($LOG_LEVEL < $LOG_DEBUG);

	my $oldest_valid_time = time() - $SESSION_TIMEOUT;
	Apache->warn("$$: CAS: delete_expired_sessions(): deleting sessions older than '$oldest_valid_time'") unless ($LOG_LEVEL < $LOG_DEBUG);

	# retrieve a session object for this session id
	my $dbh = DBI->connect("dbi:$DB_DRIVER:dbname=$DB_NAME;host=$DB_HOST;port=$DB_PORT", $DB_USER, $DB_PASS, { AutoCommit => 1 });
	if (!defined($dbh)) {
		Apache->warn("$$: CAS: delete_expired_sessions(): db connect error: $DBI::errstr") unless ($LOG_LEVEL < $LOG_ERROR);
		return "";
	}
	Apache->warn("$$: CAS: delete_expired_sessions(): SQL: DELETE FROM $DB_SESSION_TABLE WHERE last_accessed<$oldest_valid_time;");
	my $sth = $dbh->prepare("DELETE FROM $DB_SESSION_TABLE WHERE last_accessed < ?;");
	$sth->execute($oldest_valid_time);

	# if we have an error when updating the session
	my $rc = $sth->err;
	my $count = $sth->rows;
	if ($rc) {
		Apache->warn("$$: CAS: delete_expired_sessions(): error deleting expired sessions") unless ($LOG_LEVEL < $LOG_ERROR);
		$sth->finish();
		$dbh->disconnect();
		return "";
	}
	Apache->warn("$$: CAS: delete_expired_sessions(): deleted '$count' session mappings") unless ($LOG_LEVEL < $LOG_DEBUG);

	$sth->finish();
	$dbh->disconnect();

	return 1;
}

# place the pgt mapping in the database
sub set_pgt($$) {
	my $self = shift;
	my $pgtiou = shift;
	my $pgt = shift;

	Apache->warn("$$: CAS: set_pgt()") unless ($LOG_LEVEL < $LOG_DEBUG);

	my $dbh = DBI->connect("dbi:$DB_DRIVER:dbname=$DB_NAME;host=$DB_HOST;port=$DB_PORT", $DB_USER, $DB_PASS, { AutoCommit => 1 });
	if (!defined($dbh)) {
		Apache->warn("$$: CAS: set_pgt(): db connect error: $DBI::errstr") unless ($LOG_LEVEL < $LOG_ERROR);
		return "";
	}

	# see if this pgt already exists
	my $sth = $dbh->prepare("SELECT pgt FROM $DB_PGTIOU_TABLE WHERE pgtiou=?;");
	$sth->execute($pgtiou);

	my $count = $sth->rows;
	if ($sth->fetch()) {
		# we shouldn't already have this!
		$sth->finish();
		$dbh->disconnect();
		return "";
	} else {
		Apache->warn("$$: CAS: set_pgt(): adding pgtiou/pgt map for pgtiou='$pgtiou' pgt='$pgt'") unless ($LOG_LEVEL < $LOG_DEBUG);

		#print "DEBUG2: '$pgtiou', '$pgt'\n";
		my $created = time();
		my $sth = $dbh->prepare("INSERT INTO $DB_PGTIOU_TABLE values(?, ?, ?);");
		$sth->execute($pgtiou, $pgt, $created);
		my $rc = $sth->err;

		# if we have an error when updating the session
		if ($rc) {
			$sth->finish();
			$dbh->disconnect();
			return "";
		}
	}
	
	Apache->warn("$$: CAS: set_pgt(): updated '$count' pgtiou/pgt map") unless ($LOG_LEVEL < $LOG_DEBUG);

	$sth->finish();
	$dbh->disconnect();

	return 1;
}

# takes a pgtiou and returns a pgt
sub get_pgt($$) {
	my $self = shift;
	my $pgtiou = shift;
	my $sid = shift || "";

	Apache->warn("$$: CAS: get_pgt(): getting pgtiou/pgt map for pgtiou='$pgtiou'") unless ($LOG_LEVEL < $LOG_DEBUG);

	# retrieve a pgt for this pgtiou
	my $dbh = DBI->connect("dbi:$DB_DRIVER:dbname=$DB_NAME;host=$DB_HOST;port=$DB_PORT", $DB_USER, $DB_PASS, { AutoCommit => 1 });
	if (!defined($dbh)) {
		Apache->warn("$$: CAS: get_pgt(): db connect error: $DBI::errstr") unless ($LOG_LEVEL < $LOG_ERROR);
		return "";
	}
	my $sth = $dbh->prepare("SELECT pgt FROM $DB_PGTIOU_TABLE WHERE pgtiou=?;");
	$sth->execute($pgtiou);
	my $pgt;
	$sth->bind_col(1, \$pgt);
	my $result = $sth->fetch();
	$sth->finish();
	$dbh->disconnect();

	if ($result) {
		Apache->warn("$$: CAS: get_pgt(): got pgtiou/pgt map pgtiou='$pgtiou' pgt='$pgt'") unless ($LOG_LEVEL < $LOG_DEBUG);
		return $pgt;
	}
	Apache->warn("$$: CAS: get_pgt(): coudln't get pgtiou/pgt map pgtiou='$pgtiou'") unless ($LOG_LEVEL < $LOG_DEBUG);
	return "";
}

# deletes a pgt/pgtiou mapping
sub delete_pgt($$) {
	my $self = shift;
	my $pgtiou = shift;

	Apache->warn("$$: CAS: delete_pgt()") unless ($LOG_LEVEL < $LOG_DEBUG);

	# retrieve a session object for this session id
	my $dbh = DBI->connect("dbi:$DB_DRIVER:dbname=$DB_NAME;host=$DB_HOST;port=$DB_PORT", $DB_USER, $DB_PASS, { AutoCommit => 1 });
	if (!defined($dbh)) {
		Apache->warn("$$: CAS: delete_pgt(): db connect error: $DBI::errstr") unless ($LOG_LEVEL < $LOG_ERROR);
		return "";
	}
	my $sth = $dbh->prepare("DELETE FROM $DB_PGTIOU_TABLE WHERE pgtiou=?;");
	$sth->execute($pgtiou);

	# if we have an error when updating the session
	my $rc = $sth->err;
	my $count = $sth->rows;
	if ($rc) {
		Apache->warn("$$: CAS: delete_pgt(): error deleting pgtiou/pgt mapping for pgtiou='$pgtiou'") unless ($LOG_LEVEL < $LOG_DEBUG);
		$sth->finish();
		$dbh->disconnect();
		return "";
	}
	Apache->warn("$$: CAS: delete_pgt(): deleted '$count' pgtiou/pgt mappings for pgtiou='$pgtiou'") unless ($LOG_LEVEL < $LOG_DEBUG);

	$sth->finish();
	$dbh->disconnect();

	return 1;
}

# delete pgts that have no session associated with 'em and are old
sub delete_expired_pgts($$) {
	my $self = shift;

	Apache->warn("$$: CAS: delete_expired_pgts()") unless ($LOG_LEVEL < $LOG_DEBUG);

	# retrieve a session object for this session id
	my $dbh = DBI->connect("dbi:$DB_DRIVER:dbname=$DB_NAME;host=$DB_HOST;port=$DB_PORT", $DB_USER, $DB_PASS, { AutoCommit => 1 });
	if (!defined($dbh)) {
		Apache->warn("$$: CAS: delete_expired_pgts(): db connect error: $DBI::errstr") unless ($LOG_LEVEL < $LOG_ERROR);
		return "";
	}

	my $oldest_valid_time = time() - $SESSION_TIMEOUT;
	my $sth = $dbh->prepare("DELETE FROM $DB_PGTIOU_TABLE WHERE pgtiou NOT IN (SELECT pgtiou FROM $DB_SESSION_TABLE) AND created < ?;");
	$sth->execute($oldest_valid_time);

	# if we have an error when updating the session
	my $rc = $sth->err;
	my $count = $sth->rows;
	if ($rc) {
		Apache->warn("$$: CAS: delete_expired_pgts(): error deleting pgtiou/pgt mappings") unless ($LOG_LEVEL < $LOG_DEBUG);
		$sth->finish();
		$dbh->disconnect();
		return "";
	}
	Apache->warn("$$: CAS: delete_expired_pgts(): deleted '$count' pgtiou/pgt mappings") unless ($LOG_LEVEL < $LOG_DEBUG);

	$sth->finish();
	$dbh->disconnect();

	return 1;
}

sub do_proxy($$) {
	my $self = shift;
	my $r = shift;
	my $sid = shift;
	my $pgtiou = shift;
	my $user = shift;
	my $ticket_redirect = shift; # enable ticket removal redirect?
	
	my $pgt;

	Apache->warn("$$: CAS: do_proxy(): looking up PGTIOU='$pgtiou' in cache") unless ($LOG_LEVEL < $LOG_DEBUG);
	if (!($pgt = $self->get_pgt($pgtiou, $sid))) {
		Apache->warn("$$: CAS: do_proxy(): PGTIOU='$pgtiou' not found in cache!, deleting mapping and session, then redirecting to error page") unless ($LOG_LEVEL < $LOG_WARN);

		# deleting this PGTIOU mapping
		if (!$self->delete_pgt($pgtiou)) {
			Apache->warn("$$: CAS: do_proxy(): couldn't delete pgt '$pgtiou'") unless ($LOG_LEVEL < $LOG_WARN);
		} else {
			Apache->warn("$$: CAS: do_proxy(): deleted pgt '$pgtiou'") unless ($LOG_LEVEL < $LOG_DEBUG);
		}

		# deleting session, since a new PGTIOU can't be retrieved until the
		# user tries to login to the CAS server again
		$self->delete_session_data($sid);

		return $self->redirect($r, $ERROR_URL, $INVALID_PGT_ERROR_CODE);
	}
	Apache->warn("$$: CAS: do_proxy(): PGTIOU='$pgtiou' found in cache, PGT='$pgt'") unless ($LOG_LEVEL < $LOG_DEBUG);

	my @tickets = $self->get_proxy_tickets($pgt, $PROXY_SERVICE, $NUM_PROXY_TICKETS);
	if (@tickets) {
		Apache->warn("$$: CAS: do_proxy(): got PT='".join(',', @tickets)."'") unless ($LOG_LEVEL < $LOG_DEBUG);

		# place headers in request for underlying service
		my $service;
		if ($SERVICE eq "") {
			# use the current URL as the service
			$service = $self->this_url_encoded($r);
		} else {
			# use the static entry point into this service
			$service = $self->urlEncode($SERVICE);
		}

		Apache->warn("$$: CAS: do_proxy(): setting header CAS_FILTER_HOST=$CAS_HOST") unless ($LOG_LEVEL < $LOG_DEBUG);
		Apache->warn("$$: CAS: do_proxy(): setting header CAS_FILTER_PORT=$CAS_PORT") unless ($LOG_LEVEL < $LOG_DEBUG);
		Apache->warn("$$: CAS: do_proxy(): setting header CAS_FILTER_LOGIN_URI=$CAS_LOGIN_URI") unless ($LOG_LEVEL < $LOG_DEBUG);
		Apache->warn("$$: CAS: do_proxy(): setting header CAS_FILTER_SERVICE=$service") unless ($LOG_LEVEL < $LOG_DEBUG);
		Apache->warn("$$: CAS: do_proxy(): setting header CAS_FILTER_USER=$user") unless ($LOG_LEVEL < $LOG_DEBUG);
		if ($LOG_LEVEL >= $LOG_DEBUG) {
			for (my $i=1; $i <= scalar(@tickets); $i++) {
				if ($i == 1) {
					Apache->warn("$$: CAS: do_proxy(): setting header CAS_FILTER_PT=".$tickets[0]);
					Apache->warn("$$: CAS: do_proxy(): setting header CAS_FILTER_PT1=".$tickets[0]);
				} else {
					Apache->warn("$$: CAS: do_proxy(): setting header CAS_FILTER_PT$i=".$tickets[$i-1]);
				}
			}
		}
		$r->header_in("CAS_FILTER_CAS_HOST", $CAS_HOST);
		$r->header_in("CAS_FILTER_CAS_PORT", $CAS_PORT);
		$r->header_in("CAS_FILTER_CAS_LOGIN_URI", $CAS_LOGIN_URI);
		$r->header_in("CAS_FILTER_SERVICE", $service);
		$r->header_in('CAS_FILTER_USER', $user);

		if ($PRETEND_BASIC_AUTH) {
			# setup this up for underlying authz modules that rely on Basic auth having been performed
			$r->header_in('Authorization', "Basic " . encode_base64($user . ":DUMMYPASS"));
			$r->user($user);
			$r->connection->user($user);
			$r->connection->auth_type("Basic");
		}

		for (my $i=1; $i <= scalar(@tickets); $i++) {
			if ($i == 1) {
				$r->header_in('CAS_FILTER_PT', $tickets[0]);
				$r->header_in('CAS_FILTER_PT1', $tickets[0]);
			} else {
				$r->header_in("CAS_FILTER_PT$i", $tickets[$i-1]);
			}
		}

		# if we enabled ticket redirecting
		if ($ticket_redirect) {
			# redirect to this same page minus the ticket
			if (($REMOVE_TICKET eq "true") || ($REMOVE_TICKET eq "1")) {
				Apache->warn("$$: CAS: authenticate(): trying to remove service ticket from URI") unless ($LOG_LEVEL < $LOG_DEBUG);
				return $self->redirect_without_ticket($r);
			} else {
				Apache->warn("$$: CAS: authenticate(): not trying to remove service ticket from URI") unless ($LOG_LEVEL < $LOG_DEBUG);
				return (MP2 ? Apache::OK : Apache::Constants::OK);
			}
		}
		return (MP2 ? Apache::OK : Apache::Constants::OK);
	} else {
		Apache->warn("$$: CAS: do_proxy(): failed to get PT") unless ($LOG_LEVEL < $LOG_WARN);

		# deleting this PGTIOU mapping
		if (!$self->delete_pgt($pgtiou)) {
			Apache->warn("$$: CAS: do_proxy(): couldn't delete pgt '$pgtiou'") unless ($LOG_LEVEL < $LOG_WARN);
		} else {
			Apache->warn("$$: CAS: do_proxy(): deleted pgt '$pgtiou'") unless ($LOG_LEVEL < $LOG_DEBUG);
		}

		# deleting this session for this user
		Apache->warn("$$: CAS: do_proxy(): deleting session data for sid='$sid'") unless ($LOG_LEVEL < $LOG_DEBUG);
		$self->delete_session_data($sid);

		Apache->warn("$$: CAS: do_proxy(): redirecting to CAS error page") unless ($LOG_LEVEL < $LOG_DEBUG);
		return $self->redirect($r, $ERROR_URL, $INVALID_PGT_ERROR_CODE);
	}
}

# generate a new session id
sub create_session_id() {
	my $sid = "";
	srand();
	for (my $i=0; $i < 32; $i++) {
		$sid .= ('.', '/', 0..9, 'A'..'Z', 'a'..'z')[rand 64];
	}

	return $sid;
}

sub urlEncode {
	shift; # remove the request object
	my $string = shift @_;

	# put spaces back in for the "+"s
	#$string =~ tr/ /+/;

	# get rid of carrage returns (leave line feeds in)
	$string =~ s/\cM//g;

	# substitute any non-alphanumeric, reserved, and unsafe characters
	# with the hex encoding
	$string =~ s/([^a-zA-Z0-9])/'%'.unpack("H2",$1)/ge;

	return $string;
}

sub this_url ($$) {
	# get our request and log object
	my ($self, $r) = @_;

	Apache->warn("$$: CAS: this_url()") unless ($LOG_LEVEL < $LOG_DEBUG);

	# get the local server name
	my $s = $r->server;
	my $local_hostname = $r->hostname;

	# grab the uri that was requested (mod_perl 1.0 compatible)
	my $uri = Apache::URI->parse($r);
	my $uri2 = $r->parsed_uri;
	my $uri3;
	if (MP2) {
		my $curl = $r->construct_url;
		$uri3 = APR::URI->parse($r->pool, $curl);
	}

	my $parsed = $r->parsed_uri;
	my $path = $uri->path;
	my $unparsed = $parsed->unparse();
	my $query = $uri->query || $uri2->query || "";
	if (!$query && defined($uri3)) {
		$query = $uri3->query || "";
	}

	if ($query) {
		Apache->warn("$$: CAS: this_url(): have query string '$query'") unless ($LOG_LEVEL < $LOG_DEBUG);
		$query =~ s/\??&?ticket=[^&]+//;
		if ($query ne "") {
			$path .= "?$query";
		}
	} elsif ($unparsed =~ /\?$/) {
		Apache->warn("$$: CAS: this_url(): adding '?' to query string") unless ($LOG_LEVEL < $LOG_DEBUG);
		$path .= "?";
	} else {
		Apache->warn("$$: CAS: this_url(): no query string") unless ($LOG_LEVEL < $LOG_DEBUG);
	}

	my $local_port = $r->get_server_port ? ($r->get_server_port) : '';
	my $local_port2 = $uri->port ? ($uri->port) : '';
	my $local_port3 = $s->port ? ($s->port) : '';
	my $port = "";
	if ($local_port ne "") {
		Apache->warn("$$: CAS: this_url(): 1: setting port to '$local_port'") unless ($LOG_LEVEL < $LOG_DEBUG);
		$port = $local_port;
	} elsif ($local_port2 ne "") {
		Apache->warn("$$: CAS: this_url(): 2: setting port to '$local_port2'") unless ($LOG_LEVEL < $LOG_DEBUG);
		$port = $local_port2;
	} elsif ($local_port3 ne "") {
		Apache->warn("$$: CAS: this_url(): 3: setting port to '$local_port3'") unless ($LOG_LEVEL < $LOG_DEBUG);
		$port = $local_port3;
	}

	my $scheme = $uri->scheme;
	if (($scheme eq "http") && ($local_port eq "80")) {
		return "$scheme://$local_hostname$path";
	} elsif (($scheme eq "https") && ($local_port eq "443")) {
		return "$scheme://$local_hostname$path";
	}
	return "$scheme://$local_hostname:$local_port$path";
}

sub this_url_encoded ($$) {
	# get our request and log object
	my ($self, $r) = @_;

	Apache->warn("$$: CAS: this_url_encoded()") unless ($LOG_LEVEL < $LOG_DEBUG);

	my $url = $self->this_url($r);

	return $self->urlEncode($url);
}

1;
__END__

=head1 NAME

Apache::AuthCAS - A configurable Apache authentication module that enables you
to protect content on an Apache server using an existing Yale CAS
authentication server.

=head1 SYNOPSIS

C<perl -MCPAN -e 'install Apache::AuthCAS'>

=head1 DESCRIPTION

=head2 General

This module should be loaded in the mod_perl startup script or equivalent.

Add the following lines to an Apache configuration file or .htaccess file:

    AuthType Apache::AuthCAS
    AuthName "CAS"
    PerlAuthenHandler Apache::AuthCAS->authenticate
    require valid-user

    *note* - this simple config assumes that custom settings are configured
             into the module itself.  If not, they will need to be specified
             with PerlSetVar params (see below for examples).

You can configure this module by placing the devel/production settings in the
module itself.  This is particular handy if you would like to make
authentication with this module available via .htaccess to users whom you would
rather not share the database username/password with.

Any options that are not set in the Apache configuration will default to the
values preconfigured in the Apache::AuthCAS module.  Either explicitly override
those options that do not match your environment or set them in the module
itself.

The I<Apache::AuthCAS> module allows a user to protect their non-Java content
on an Apache server with the Yale CAS authentication server.

=head2 Requirements

Perl modules:
    Net::SSLeay
    MIME::Base64
    DBI
    DBD::<module name> (i.e. DBD::Pg)

=head2 Proxiable Credentials

This module can be optionally configured to use proxy credentials.  This is
enabled by setting the I<CASService> and I<CASProxyService> configuration
parameters.

=head2 Examples

Example configuration without proxiable credentials, which assumes that the
module itself has been configured with devel and production variables set:

    AuthType Apache::AuthCAS
    AuthName "CAS"
    PerlAuthenHandler Apache::AuthCAS->authenticate
    PerlSetVar CASProduction "1"
    require valid-user

Example configuration without proxiable credentials, which has not been
modified:

    AuthType Apache::AuthCAS
    AuthName "CAS"
    PerlAuthenHandler Apache::AuthCAS->authenticate
    PerlSetVar CASHost "auth.somedomain.com"
    PerlSetVar CASPort "443"
    PerlSetVar CASErrorURL "https://somedomain.com/cas/error/"
    PerlSetVar CASDatabaseName "cas"
    PerlSetVar CASDatabaseHost "db.somedomain.com"
    PerlSetVar CASDatabasePort "5432"
    PerlSetVar CASDatabaseDriver "Pg"
    PerlSetVar CASDatabaseUser "dbuser"
    PerlSetVar CASDatabasePass "dbpass"
    PerlSetVar CASSessionCookieName "APACHECAS"
    PerlSetVar CASSessionTimeout "1800"
    PerlSetVar CASLogLevel "0"
    PerlSetVar CASRemoveTicket "false"

    require valid-user

Example configuration with proxiable credentials, which assumes that the module
itself has been configured with devel and production variables set:

    AuthType Apache::AuthCAS
    AuthName "CAS"
    PerlAuthenHandler Apache::AuthCAS->authenticate
    PerlSetVar CASProduction "1"
    PerlSetVar CASService "https://somedomain.com/email/"
    PerlSetVar CASProxyService "mail.somedomain.com"
    require valid-user

Example configuration with proxiable credentials, which has not been modified:

    AuthType Apache::AuthCAS
    AuthName "CAS"
    PerlAuthenHandler Apache::AuthCAS->authenticate
    PerlSetVar CASService "https://somedomain.com/email/"
    PerlSetVar CASProxyService "mail.somedomain.com"
    PerlSetVar CASNumProxyTickets "1"
    PerlSetVar CASHost "auth.somedomain.com"
    PerlSetVar CASPort "443"
    PerlSetVar CASErrorURL "https://somedomain.com/cas/error/"
    PerlSetVar CASDatabaseName "cas"
    PerlSetVar CASDatabaseHost "db.somedomain.com"
    PerlSetVar CASDatabasePort "5432"
    PerlSetVar CASDatabaseDriver "Pg"
    PerlSetVar CASDatabaseUser "dbuser"
    PerlSetVar CASDatabasePass "dbpass"
    PerlSetVar CASSessionCookieName "APACHECAS"
    PerlSetVar CASSessionTimeout "1800"
    PerlSetVar CASLogLevel "0"
    PerlSetVar CASRemoveTicket "false"

    require valid-user

=head2 Configuration Options

These are Apache configuration option examples for Apache::AuthCAS

    # the host name of the CAS server
    PerlSetVar CASHost "auth.somedomain.com"

    # the port number for the CAS server
    PerlSetVar CASPort "443"

    # are we running with production config or dev config
    PerlSetVar CASProduction "1"

    # the URL a client is redirected to after logging in
    PerlSetVar CASService "https://somedomain.com/email/"

    # the service proxy tickets will be granted for
    PerlSetVar CASProxyService "mail.somedomain.com"

    # number of proxy tickets to give the underlying application
    PerlSetVar CASNumProxyTickets "2"

    # the URL the client is redirected to when an error occurs
    PerlSetVar CASErrorURL "https://somedomain.com/error/"

    # the name of the DBI database driver
    PerlSetVar CASDatabaseDriver "Pg"

    # the host name of the database server
    PerlSetVar CASDatabaseHost "db.somedomain.com"

    # the port number of the database server
    PerlSetVar CASDatabasePort "5433"

    # the name of the database for sessions/pgtiou mapping
    PerlSetVar CASDatabaseName "cas"

    # the user to connnect to the database with
    PerlSetVar CASDatabaseUser "dbuser"

    # the password to connect to the databse with
    PerlSetVar CASDatabasePass "dbpass"

    # the name of the session table
    PerlSetVar CASDatabaseSessionTable "cas_sessions"

    # the name of the pgtiou to pgt mapping table
    PerlSetVar CASDatabasePGTIOUTable "cas_pgtiou_to_pgt"

    # the level of logging
    PerlSetVar CASLogLevel "4"

    # whether we should perform a redirect, stripping the service ticket
    # once we have already created a session for the client
    PerlSetVar CASRemoveTicket "true"

    # the name of the cookie that will be used for sessions
    PerlSetVar CASSessionCookieName "APACHECAS"
    
    # the max time before a session expires (in seconds)
    PerlSetVar CASSessionTimeout "1800"

    # not currently able to override through Apache configuration:
    #   CAS login URI
    #   CAS logout URI
    #   CAS proxy URI
    #   CAS proxy validate URI
    #   CAS service validate URI
    #   parameter used to pass in PGTIOU
    #   parameter used to pass in PGT
    #   session cleanup threshold
    #   basic authentication emulation

=head1 NOTES

Any options that are not set in the Apache configuration will default to the
values preconfigured in the Apache::AuthCAS module.  Either explicitly override
those options that do not match your environment or set them in the module
itself.

=head1 COMPATIBILITY

This module should work in both mod_perl 1 and 2.  For Apache 2/mod_perl 2, the
Apache::compat may need to be loaded in your mod_perl startup script.  This can
be done by adding:

    use Apache::compat;

into the script included by the PerlRequire directive in your Apache
configuration.  For instance, if your Apache configuration includes the line:

    PerlRequire /usr/local/sbin/modperl_startup.pl

then the "use" line mentioned above should be added to this file.  Consult the
mod_perl documentation for more information regarding mod_perl startup scripts.

=head1 SEE ALSO

=head2 Official Yale CAS Website

http://www.yale.edu/tp/auth/

=head2 mod_perl Documentation

http://perl.apache.org/

=head1 AUTHOR

David Castro <dcastro@apu.edu>

=head1 COPYRIGHT

Copyright (C) 2004 David Castro <dcastro@apu.edu>

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
