# session management, authorization and authentication for AxKit
package Apache::AxKit::Plugin::Session;
use strict;
use vars qw($redirect_location);

BEGIN {
    use Apache::Table;
    use Apache::Session::File;
    use Apache::Constants qw(:common :response);
    our $VERSION = 1.00;
}

#######################################################
# this code comes from Apache::AuthCookieURL (modified)
#

use mod_perl qw(1.24 StackedHandlers MethodHandlers Authen Authz);
use Apache::Constants qw(:common M_GET REDIRECT MOVED);
use Apache::URI ();
use Apache::Cookie;
use URI::Escape;
use URI;

# store reason of failed authentication, authorization or login for later retrieval
#======================
sub orig_save_reason ($;$) {
#----------------------
    my ($self, $error_message) = @_;
    $self->debug(3,"======= save_reason(".join(',',@_).")");
    my $r = Apache->request();
    my $auth_name = $r->auth_name || 'AxKitSession';
    my $auth_type = $r->auth_type || __PACKAGE__;
    # Pass a cookie with the error reason that can be read after the redirect.
    # Use a cookie with no time limit
    if (@_ <= 1) {
        # delete error message cookie if it exists
        if ( exists $r->pnotes('COOKIES')->{$auth_type.'_'.$auth_name.'Reason'} ) {
            $self->send_cookie(value=>'', name=>'Reason');
            delete $r->pnotes('COOKIES')->{$auth_type.'_'.$auth_name.'Reason'};
        }
    } elsif ($error_message) {
        # set error message cookie if error message exists
        $self->send_cookie(name=>'Reason', value=>$error_message);
        $r->pnotes('COOKIES')->{$auth_type.'_'.$auth_name.'Reason'} = $error_message;
    }
}
# ____ End of save_reason ____



#==================
sub orig_get_reason($) {
#------------------
    my ($self) = @_;
    $self->debug(3,"======= orig_get_reason(".join(',',@_).")");
    my $r = Apache->request();
    my $auth_name = $r->auth_name || 'AxKitSession';
    my $auth_type = $r->auth_type || __PACKAGE__;

    parse_input();
    return $r->pnotes('COOKIES')->{$auth_type.'_'.$auth_name.'Reason'};
}
# ____ End of get_reason ____


# save args of original request so it can be replayed after a redirect
#=====================
sub orig_save_params ($$) {
#---------------------
    my ($self, $uri) = @_;
    $self->debug(3,"======= save_params(".join(',',@_).")");
    my $r = Apache->request();

    parse_input(1);
    $uri = new URI($uri);
    $uri->query_form(%{$r->pnotes('INPUT')||{}});
    return $uri->as_string;
}
# ____ End of save_params ____



# restore args of original request in $r->pnotes('INPUT')
#=======================
sub orig_restore_params ($) {
#-----------------------
    my ($self) = @_;
    $self->debug(3,"======= restore_params(".join(',',@_).")");
    my $r = Apache->request();

    parse_input();
}
# ____ End of restore_params ____



#===================
sub login_form ($) {
#-------------------
    my ($self) = @_;
    $self->debug(3,"======= login_form(".join(',',@_).")");
    my $r = Apache->request();
    my $auth_name = $r->auth_name || 'AxKitSession';
    my $authen_script;
    unless ($authen_script = $r->dir_config($auth_name.'LoginScript')) {
        $r->log_reason("PerlSetVar '${auth_name}LoginScript' missing", $r->uri);
        return SERVER_ERROR;
    }

    my $uri = uri_escape($r->uri);
    $authen_script =~ s/((?:[?&])destination=)/$1$uri/;
    $self->debug(3,"Internally redirecting to $authen_script");
    $r->custom_response(FORBIDDEN, $authen_script);
    return FORBIDDEN;
}
# ____ End of login_form ____



####################################################################################
# you don't normally need to override anything below

#================
sub debug ($$$) {
#----------------
    my ($self, $level, $msg) = @_;
    my $r = Apache->request();
    my $debug = $r->dir_config('AxDebugSession') || 0;
    $r->log_error($msg) if $debug >= $level;
}
# ____ End of debug ____

#================
sub parse_input {
#----------------
    my ($full) = @_;
    my $or = my $r = Apache->request();

    while ($r->prev) {
        $r = $r->prev;
        $r = $r->main || $r;
    }
    if ($r->pnotes('INPUT') && $r ne $or) {
            $or->pnotes('INPUT',$r->pnotes('INPUT'));
            $or->pnotes('UPLOADS',$r->pnotes('UPLOADS'));
            $or->pnotes('COOKIES',$r->pnotes('COOKIES'));
            $or->pnotes('COOKIES',{}) unless $or->pnotes('COOKIES');
	    return;
    }

    my %cookies;
    my %cookiejar = Apache::Cookie->new($r)->parse;
    foreach (sort keys %cookiejar) {
        my $cookie = $cookiejar{$_};
        $cookies{$cookie->name} = $cookie->value;
    }
    $or->pnotes('COOKIES',\%cookies);
    $r->pnotes('COOKIES',$or->pnotes('COOKIES')) if ($r ne $or);

    # avoid parsing the input so later modules can modify it
    return if (!$full);
    return if $r->pnotes('INPUT');

    # from Apache::RequestNotes  
    my $maxsize   = $r->dir_config('MaxPostSize') || 1024;
    my $uploads   = $r->dir_config('DisableUploads') =~ m/Off/i ? 0 : 1;

    my $apr = Apache::Request->instance($r,
        POST_MAX => $maxsize,
        DISABLE_UPLOADS => $uploads,
    );
    $r->pnotes('INPUT',$apr->parms);
    $r->pnotes('UPLOADS',[ $apr->upload ]);
    if ($r ne $or) {
        $or->pnotes('INPUT',$r->pnotes('INPUT'));
        $or->pnotes('UPLOADS',$r->pnotes('UPLOADS'));
    }
}
# ____ End of parse_input ____



#===========================
sub external_redirect ($$) {
#---------------------------
    my ($self, $uri) = @_;
    $self->debug(3,"======= external_redirect(".join(',',@_).")");
    my $r = Apache->request();
    $r->header_out('Location' => $uri);
    return $self->fixup_redirect($r);
}
# ____ End of external_redirect ____



#====================
sub send_cookie($@) {
#--------------------
    my ($self, %settings) = @_;
    $self->debug(3,"======= send_cookie(".join(',',@_).")");
    my $r = Apache->request();
    my $auth_name = $r->auth_name || 'AxKitSession';
    my $auth_type = $r->auth_type || __PACKAGE__;

    return if $r->dir_config($auth_name.'NoCookie');

    $settings{name} = "${auth_type}_$auth_name".($settings{name}||'');

    for (qw{Path Expires Domain Secure}) {
    my $s = lc();
        next if exists $settings{$s};

        if (my $value = $r->dir_config($auth_name.$_)) {
            $settings{$s} = $value;
        }
        delete $settings{$s} if !defined $settings{$s};
    }

    # need to do this so will return cookie when url is munged.
    $settings{path} ||= '/';
    $settings{domain} ||= $r->hostname;

    my $cookie = Apache::Cookie->new($r, %settings);
    $cookie->bake;
    $r->err_headers_out->add("Set-Cookie" => $cookie->as_string);

    $self->debug(3,'Sent cookie: ' . $cookie->as_string);
}
# ____ End of send_cookie ____



#=============
sub key ($) {
#-------------
    my $self = shift;
    $self->debug(3,"======= key(".join(',',@_).")");
    my $r = Apache->request;
    my $auth_name = $r->auth_name || 'AxKitSession';
    my $auth_type = $r->auth_type || __PACKAGE__;

    parse_input();
    my $mr = $r;
    while ($mr->prev) {
        last if $mr->notes('SESSION_ID');
        $mr = $mr->prev;
        last if $mr->notes('SESSION_ID');
        $mr = $r->main || $mr;
    }
    my $session = $mr->notes('SESSION_ID');
    if ($session) {
        $r->notes('SESSION_ID',$session);
        $self->debug(5,"- present session: $session");
        return $session;
    }
    $session = $r->pnotes('COOKIES')->{$auth_type.'_'.$auth_name};
    if ($session) {
        $self->debug(5,"- cookie session: $session");
        $r->notes('SESSION_ID',$session);
        return $session;
    }
    my $prefix = $r->notes('SessionPrefix');

    $self->debug(5,"- session referer: ".$mr->header_in('Referer'));
    if ($prefix && $mr->header_in('Referer')) {
        my $rest = $mr->uri.($r->args?'?'.$r->args:'');
        my $ref = $session = $mr->header_in('Referer');
        $session =~ s/^https?:\/\///i;
        my $x;
        $x = $mr->hostname;
        $session =~ s/^$x//i;
        $x = $mr->server->port;
        $session =~ s/^:$x//i;
        $session =~ s/^\/+([^\/]+)\/.*$/$1/;
	if (substr($session,0,length($prefix)) eq $prefix) {
            my $sess = $self->_get_session_from_store($r,substr($session,length($prefix))); # not revive logged out sessions
            $self->debug(5,"- session after stripping: $session, prefix: $prefix");
            if (!$sess or keys(%$sess) > 1) {
                $self->debug(4,"Referer: ".$r->header_in('Referer').", session: $session");
                # redirect to the sessionified URL if we took our ID from Referer:
                if (substr($rest,0,1) eq '/') {
                    $self->debug(1,"! absolute link from $ref to $rest");
                    $r->status(REDIRECT);
                    $self->external_redirect($self->save_params("/$session$rest"));
                    return REDIRECT;
		}
            }
	    untie(%$sess) if $sess;
        } else {
            undef $session;
        }
    }

    $r->notes('SESSION_ID',$session);
    return $session;
}
# ____ End of key ____



####################################################################################
# Handlers


# PerlFixupHandler for user tracking in unprotected documents
#========================
sub recognize_user ($$) {
#------------------------
    my ($self, $r) = @_;
    $self->debug(3,"======= recognize_user(".join(',',@_).")");
    my $auth_name = $r->auth_name || 'AxKitSession';
    my $auth_type = $r->auth_type || __PACKAGE__;

    my $session = $self->key();
    return REDIRECT if $session eq REDIRECT;

    $self->debug(1,"session provided  = '$session'");
    return OK unless $session;

    if (my ($user) = $auth_type->authen_ses_key($r, $session)) {
        $self->debug(2,"recognize user = '$user'");
        $r->connection->user($user);
    }
    return OK;
}
# ____ End of recognize_user ____



# PerlTransHandler for session tracking via URL
#===============================
sub translate_session_uri ($$) {
#-------------------------------
    my ($self, $r) = @_;
    $self->debug(3,"======= translate_session_uri(".join(',',@_).")");
    $self->debug(3,"uri: ".$r->uri);

    # Important! The existence of SessionPrefix is used as indicator
    # that URL sessions are in use, so set it before declining
    my $prefix = $r->dir_config('SessionPrefix') || 'Session-';
    $r->notes('SessionPrefix',$prefix);

    return DECLINED unless $r->is_initial_req;


    # retrieve session id from URL or HTTP 'Referer:' header
    my (undef, $session, $rest) = split /\/+/, $r->uri, 3;
    $rest ||= '';
    return DECLINED unless $session && $session =~ /^$prefix(.+)$/;

    # Session ID found.  Extract and make it available in notes();
    $session = $1;

    $self->debug(1,"Found session ID '$session' in url");

    $r->notes(SESSION_ID => $session);
    $r->subprocess_env(SESSION_ID => $session);

    # Make the prefix and session available to CGI scripts for use in absolute
    # links or redirects
    $r->subprocess_env(SESSION_URLPREFIX => "/$prefix$session");
    $r->notes(SESSION_URLPREFIX => "/$prefix$session");

    # Remove the session from the URI
    $r->uri( "/$rest" );
    $self->debug(3,'Requested URI = \''.$r->uri."'");

    return DECLINED;
}
# ____ End of translate_session_uri ____



# PerlHandler for location /redirect
# if reached via ErrorDocument 301/302 - add session ID for internal redirects/strip for external
# if reached directly, show a self-refreshing page (to strip off unwanted referer headers)
# can be called directly, be sure to set $r->header_out('Location') first
#========================
sub fixup_redirect ($$) {
#------------------------
    my ($self, $r)  = @_;
    $self->debug(3,"======= fixup_redirect(".join(',',@_).")");
    parse_input(1);

    my $mr = $r;
    while ($mr->prev) {
        $mr = $mr->prev;
        $mr = $mr->main || $mr;
    }
    $mr = $mr->main || $mr;
    
    $r->pnotes('INPUT')->{'url'} = $1 if ($r->uri =~ m{^/[a-z]+(/.*)$});
    $r->pnotes('INPUT')->{'url'} =~ s{^/([a-z0-9]+://)}{$1};
    if (!$r->header_out('Location') && (!$r->prev || !$r->prev->header_out('Location')) && !$r->pnotes('INPUT')->{'url'}) {
        $self->debug(1,'called without location header or url paramater');
        return SERVER_ERROR;
    }
    
    my $session = $r->notes('SESSION_URLPREFIX') || $mr->notes('SESSION_URLPREFIX') || '';

    my $uri;

    $uri = Apache::URI->parse($r, $r->header_out('Location') || ($r->prev?$r->prev->header_out('Location'):undef) || $r->pnotes('INPUT')->{'url'});
    if (!$uri->hostname) {
	$uri->hostname($r->hostname);
	$uri->port($r->get_server_port);
    }
    $self->debug(6,"Session: $session, uri: ".$uri->unparse);
    my $same_host = (lc($uri->hostname) eq lc($r->hostname) && ($uri->port||80) == $r->server->port);

    # we have not been internally redirected - show the refresh page, or redirect to
    # ourselves first, if session id is still present
    if ($same_host) {
        $self->debug(6,"same host");
        # add session ID and continue
        if ($session && $uri->path !~ /^$session/) {
            $self->debug(6,"adding session");
            $uri->path($session.$uri->path);
        }
    } else {
        $self->debug(6,"different host");
        if ((!$r->prev || !$r->prev->header_out('Location')) && !$r->header_out('Location')) {
            $self->debug(6,"called externally");
            if (!$session || $mr->parsed_uri->path !~ /^$session/) {
                $self->debug(6,"refresh");
                # we have been called without session id. it's safe now to refresh
                my $location    = $uri->unparse;
                my $message = <<EOF;

<!DOCTYPE HTML PUBLIC "-//IETF//DTD HTML 2.0//EN">
<HTML>
  <HEAD>
    <TITLE>Redirecting...</TITLE>
    <META HTTP-EQUIV=Refresh CONTENT="0; URL=$location">
  </HEAD>
  <BODY bgcolor="#ffffff" text="#000000">
    <H1>Redirecting...</H1>
    You are being redirected <A HREF="$location">here</A>.<P>
  </BODY>
</HTML>
EOF

            $r->content_type('text/html');
            $r->send_http_header;
            $r->print($message);
            $r->rflush;
            return OK;
            }
        }

        $self->debug(6,"external redirect to self, ".$mr->uri);
        # remove session ID and externally redirect to ourselves
        if ($session && $mr->parsed_uri->path =~ /^$session/) {
            my $myuri = $mr->parsed_uri;
            $myuri->path($redirect_location.'/'.$uri->unparse);
            $uri = $myuri;
        }
        $uri->path(substr($uri->path,length($session))) if ($session && $uri->path =~ /^$session/);
    }


    my $status      = (($r->status != MOVED) && (!$r->prev || $r->prev->status != MOVED)?REDIRECT:MOVED);
    my $location    = $uri ? $uri->unparse : 'unknown';
    my $description = ( $status == MOVED ) ? 'Moved Permanently' : 'Found';
    $self->debug(6,"redirect to $location, status $status");

    my $message = <<EOF;

<!DOCTYPE HTML PUBLIC "-//IETF//DTD HTML 2.0//EN">
<HTML>
  <HEAD>
    <TITLE>$status $description</TITLE>
  </HEAD>
  <BODY>
    <H1>$description</H1>
    The document has moved <A HREF="$location">$location</A>.<P>
  </BODY>
</HTML>
EOF

    $r->content_type('text/html');
    $r->status($status);
    $r->header_out('Location', $location);
    $r->header_out('URI', $location);
    $r->send_http_header;

    $r->print($message);

    $r->rflush;

    return $status;
}
# ____ End of fixup_redirect ____


# This one can be used as PerlHandler if a non-mod_perl script is doing the login form
# In that case, be sure to validate the login in authen_cred above!
#===============
sub login ($$) {
#---------------
    my ($self, $r, $destination ) = @_;
    $self->debug(3,"======= login(".join(',',@_).")");
    my $auth_name = $r->auth_name || 'AxKitSession';
    my $auth_type = $r->auth_type || __PACKAGE__;

    parse_input(1);
    my $args = $r->pnotes('INPUT');

    $destination = $$args{'destination'} if @_ < 3;
    if ($destination) {
        $destination = URI->new_abs($destination, $r->uri);
    } else {
        my $mr = $r;
        $mr = $mr->prev while ($mr->prev);
        $mr = $mr->main while ($mr->main);
        $destination = $mr->uri;
    }

    $self->debug(1,"destination = '$destination'");

    # Get the credentials from the data posted by the client, if any.
    my @credentials;
    while (exists $$args{"credential_" . ($#credentials + 1)}) {
        $self->debug(2,"credential_" . ($#credentials + 1) . "= '" .$$args{"credential_" . ($#credentials + 1)} . "'");
        push(@credentials, $$args{"credential_" . ($#credentials + 1)});
    }

    # convert post to get
    if ($r->method eq 'POST') {
        $r->method('GET');
        $r->method_number(M_GET);
        $r->headers_in->unset('Content-Length');
    }

    $r->no_cache(1) unless $r->dir_config($auth_name.'Cache');


    # Exchange the credentials for a session key.
    my ($ses_key, $error_message) = $self->authen_cred($r, @credentials);

    # Get the uri so can adjust path, and to redirect including the query string

    unless ($ses_key) {

        $self->debug(2,"No session returned from authen_cred: $error_message" );
        $self->save_reason($error_message) if ($r->is_main());

    } else {

        $self->debug(2,"ses_key returned from authen_cred: '$ses_key'");

        # Send cookie if a session was returned from authen_cred
        $self->send_cookie(value=>$ses_key);

        # add the session to the URI - if trans handler not installed prefix will be empty
        if (my $prefix = $r->notes('SessionPrefix')) {
            $r->notes('SESSION_URLPREFIX',"/$prefix$ses_key");
        } elsif (!$r->dir_config($auth_name.'LoginScript' ) ||
            lc($r->dir_config($auth_name.'LoginScript' )) eq 'none' ||
            $destination eq $r->uri) {

            # don't redirect if we only set a cookie
            my ($auth_user, $error_message) = $auth_type->authen_ses_key($r, $ses_key);
            $self->debug(2,"login() not redirecting, just setting cookie: user = $auth_user, SID = $ses_key");

            return SERVER_ERROR unless defined $auth_user;

            $r->notes('SESSION_ID',$ses_key);
            $r->connection->user($auth_user);
            return OK;
        }

    }

    if ($destination eq 'none') {
	$self->debug(2,"login() not redirecting: requested by application");
	return OK;
    }
    $self->debug(2,"login() redirecting to $destination");
    return $self->external_redirect($destination);
}
# ____ End of login ____



# Again, this can be used as PerlHandler or called directly
# subclass this one if you want to invalidate a session db
# entry or something like that
#================
sub orig_logout ($$) {
#----------------
    my ($self,$r, $location) = @_;
    $self->debug(3,"======= logout(".join(',',@_).")");
    my $auth_name = $r->auth_name || 'AxKitSession';
    my $auth_type = $r->auth_type || __PACKAGE__;

    # Send the Set-Cookie header to expire the auth cookie.
    $self->send_cookie(value=>'');

    $r->no_cache(1) unless $r->dir_config($auth_name.'Cache');
    $location = $r->dir_config($auth_name.'LogoutURI') if @_ < 3;
    $r->notes('SESSION_URLPREFIX',''); # so error doc doesn't fixup.
    return OK if !$location;
    $r->header_out(Location => $location);
    return REDIRECT;
}
# ____ End of logout ____



# PerlAuthenHandler, this one is the actual check point
#======================
sub authenticate ($$) {
#----------------------
    my ($self, $r) = @_;
    my $auth_type = $self;
    $self->debug(3,"======= authenticate(".join(',',@_).")");
    my ($authen_script, $auth_user);

    my $mr = $r;
    $mr = $mr->prev while ($mr->prev && !$mr->pnotes('SESSION'));
    $r->pnotes('SESSION',$mr->pnotes('SESSION'));
    # This is a way to open up some documents/directories
    return OK if lc $r->auth_name eq 'none';
    return OK if $r->uri eq $r->dir_config(($r->auth_name || 'AxKitSession').'LoginScript');
    return OK if ($r->main?$r->main->uri:$r->uri) =~ m/^$redirect_location(\/|$)/;

    # Only authenticate the first internal request
    # no. See sub authorize for rationale
    #return OK unless $r->is_initial_req;

    if (defined $r->auth_type && $r->auth_type ne $auth_type) {
        # This location requires authentication because we are being called,
        # but we don't handle this AuthType.
        $self->debug(3,"AuthType mismatch: $auth_type != ".$r->auth_type);
        return DECLINED;
    }

    my $auth_name = $r->auth_name || 'AxKitSession';
    $self->debug(2,"auth_name= '$auth_name'");

    parse_input();

    # Check and get session from cookie or URL
    my $session = $self->key;
    return REDIRECT if $session eq REDIRECT;

    $self->debug(1,"session provided  = '$session'");
    $self->debug(2,"requested uri = '" . $r->uri . "'");

    my $error_message;

    unless ($session) {

        $error_message = 'no_session_provided';

    } else {

        # Check and convert the session key into a user name
        ($auth_user, $error_message) = $auth_type->authen_ses_key($r, $session);
        if (defined $auth_user) {
            # We have a valid session key, so we return with an OK value.
            # Tell the rest of Apache what the authentication method and
            # user is.

            $r->connection->user($auth_user);
            $self->debug(1,"user authenticated as $auth_user. Exiting Authen.");

            # Clean up the path by redirecting if cookies are in use and valid
            if ($r->pnotes('COOKIES') && $r->pnotes('COOKIES')->{$auth_type.'_'.$auth_name} &&
                $r->pnotes('COOKIES')->{$auth_type.'_'.$auth_name} eq $session &&
                $r->notes('SESSION_URLPREFIX')) {

                my $uri = $r->uri;
                $uri .= '?'.$r->args if $r->args;
                my $query = $self->save_params($uri);
                $self->debug(3,"URL and Cookies are in use - redirecting to '$query'");

                # prevent the error_document from adding the session back in.
                $r->notes('SESSION_URLPREFIX', undef );

                return $self->external_redirect($query);
            }

            return OK;

        } else {
            # There was a session key set, but it's invalid for some reason. So,
            # remove it from the client now so when the credential data is posted
            # we act just like it's a new session starting.

            $self->debug(1,'Bad session key sent.');
            # Do this even if no cookie was sent
            $auth_type->send_cookie(value=>'');
            $error_message ||= 'bad_session_provided';

        }
    }


    # invalid session id (or none at all) was provided - redirect to the login form

    # If the LoginScript is set to 'NONE' or none is set then only generating a session
    # So call login() directly instead of calling the login form.
    if (!$r->dir_config($auth_name.'LoginScript' ) ||
        lc($r->dir_config($auth_name.'LoginScript' )) eq 'none' ) {

        $self->debug(2,'LoginScript=NONE - calling login()');

        my $rc = $auth_type->login($r, $self->save_params($r->uri));
	#$self->save_reason($error_message) if ($r->is_main());
        return $rc;
    }
    $self->save_reason($error_message) if ($r->is_main());

    return $self->login_form;
}
# ____ End of authenticate ____


# override this one to retrieve permissions from somewhere else.
# you still need to add a dummy 'require something' to httpd.conf
#========================
sub get_permissions($$) {
#------------------------
    my ($self, $r) = @_;
    my $reqs = $r->requires || return ();
    return map { [ split /\s+/, $_->{requirement}, 2 ] } @$reqs;
}
# ____ End of get_permissions ____


# handler for 'require user' directives
#=============
sub user($$) {
#-------------
    my ($self, $r, $args) = @_;
    $self->debug(3,"======= user(".join(',',@_).")");
    my $user = $r->connection->user;
    return OK if grep { $user eq $_ } split /\s+/, $args;
    return FORBIDDEN;
}
# ____ End of user ____

# Apache auto-configuration
#================================
sub initialize_url_sessions($@) {
#--------------------------------
    my ($self, $redirect_location) = @_;
    $redirect_location ||= '/redirect';

    # configure stuff
    push @Apache::ReadConfig::PerlTransHandler, $self.'->translate_session_uri';

    $Apache::ReadConfig::Location{$redirect_location} = {
        'SetHandler' => 'perl-script',
        'PerlHandler' => $self.'->fixup_redirect',
    };
    push @Apache::ReadConfig::ErrorDocument, [ 302, $redirect_location ];
    push @Apache::ReadConfig::ErrorDocument, [ 301, $redirect_location ];
}
# ____ End of import ____

$redirect_location ||= '/redirect';
#__PACKAGE__->initialize_url_sessions($redirect_location) if ($Apache::Server::Starting);

#
# end of AuthCookieURL.pm
#######################################################

sub has_permission {
    my ($r, $attr_target) = @_;
    $attr_target = URI->new_abs($attr_target, $r->uri);
    return 1 if ($r->uri eq $attr_target);
    my $subr =  $r->lookup_uri($attr_target);
    return $subr->status == 200;
}

sub handler {
    my ($r) = @_;
    my $self = __PACKAGE__;

    #$self->debug(5,"Plugin usage: ".$r->connection->user." / ".$r->auth_type);
    return OK if lc($r->auth_type) eq 'none';
    return OK if $r->auth_type && $r->auth_type ne $self;

    $r->auth_type($self);
    $r->auth_name('AxKitSession') unless $r->auth_name;

    my $rc = $self->authenticate($r);
    return OK if $rc == DECLINED;
    return $rc if $rc != OK;

    $rc = $self->authorize($r,$r->requires||[{requirement => 'valid-user'}]);
    return OK if $rc == DECLINED;
    return $rc;
}


# this part does the real work and won't be very useful for
# customization/subclassing.
# You may consider skipping to the 'require' handlers below.

sub makeVariableName($) { my $x = shift; $x =~ s/[^a-zA-Z0-9]/_/g; $x; }

sub save_reason($;$) {
    my ($self, $error_message) = @_;
    $self->debug(3,"--------- save_reason(".join(',',@_).")");
    my $session = Apache->request()->pnotes('SESSION') || return $self->orig_save_reason($error_message);

    if (!$error_message) {
        # delete error message
        delete $$session{'auth_reason'};
        delete $$session{'auth_location'};
    } else {
        # set error message
        $$session{'auth_reason'} = $error_message;
        my $r = Apache->request();
        $$session{'auth_location'} = $r->uri;
        $$session{'auth_location'} .= '?'.$r->args if ($r->args);
    }
}

sub get_reason($) {
    my ($self) = @_;
    $self->debug(3,"--------- get_reason(".join(',',@_).")");
    my $session = Apache->request()->pnotes('SESSION') || return $self->orig_get_reason();

    $$session{'auth_reason'};
}

sub get_location($) {
    my ($self) = @_;
    $self->debug(3,"--------- get_location(".join(',',@_).")");
    my $session = Apache->request()->pnotes('SESSION') || return undef;

    $$session{'auth_location'};
}

sub save_params ($$) {
    my ($self, $uri) = @_;
    $self->debug(3,"--------- save_params(".join(',',@_).")");
    my $r = Apache->request();
    my $session = $r->pnotes('SESSION') || return $self->orig_save_params($uri);

    parse_input(1);
    my $in = $r->pnotes('INPUT');
    my @out = ();
    while(my($key,$val) = each %$in) {
        push @out, $key, $val;
    }

    $$session{'auth_params'} = \@out;
    return $uri;
}

sub restore_params ($) {
    my ($self) = @_;
    $self->debug(3,"--------- restore_params(".join(',',@_).")");
    my $r = Apache->request();
    my $session = $r->pnotes('SESSION') || return $self->orig_restore_params();
    return $self->orig_restore_params() unless $$session{'auth_params'};

    my @in = @{$$session{'auth_params'}};
    my $out = new Apache::Table($r);
    while (@in) {
        $out->add($in[0],$in[1]);
        shift @in; shift @in;
    }
    $r->pnotes('INPUT',$out);
    delete $$session{'auth_params'};
}


sub _cleanup_session ($$) {
    my ($self, $session) = @_;
    $self->debug(3,"--------- _cleanup_session(".join(',',@_).")");
    untie %{$session};
    undef %{$session};
}

sub _get_session_from_store($$;$) {
    my ($self, $r, $session_id) = @_;
    $self->debug(3,"--------- _get_session_from_store(".join(',',@_).")");
    my $auth_name = $r->auth_name || 'AxKitSession';
    my @now = localtime;
    my $session = {};
    my $dir = $r->dir_config($auth_name.'Dir') || '/tmp/sessions';
    my $absdir = $dir;
    $absdir = $r->document_root.'/'.$dir if substr($dir,0,1) ne '/';
    my $args = {
            Directory => $absdir,
            DataSource => $dir,
            FileName => $absdir.'/sessions.db',
            LockDirectory => $absdir.'/locks',
            DirLevels => 3,
            CounterFile => sprintf("$absdir/counters/%04d-%02d-%02d", $now[5]+1900,$now[4]+1,$now[3]),
            $r->dir_config->get($auth_name.'ManagerArgs'),
    };
    eval {
        eval "require ".($r->dir_config($auth_name.'Manager')||'Apache::Session::File') or die $@;
        tie %{$session}, $r->dir_config($auth_name.'Manager')||'Apache::Session::File', $session_id, $args;
    };
    die "Session creation failed. Depending on which session module you use, make sure that directories $absdir, $absdir/locks or $absdir/counters, or database $dir exist and are writable. The error message was: $@" if $@ && !defined $session_id;
    return $session;
}

sub _get_session($$;$) {
    my ($self, $r, $session_id) = @_;
    my $auth_name = $r->auth_name || 'AxKitSession';
    $self->debug(3,"--------- _get_session(".join(',',@_).")");
    my $dir = $r->dir_config($auth_name.'Dir') || '/tmp/sessions';
    my $expire = ($r->dir_config($auth_name.'Expire') || 30) / 5 + 1; #/
    my $check = $r->dir_config($auth_name.'IPCheck');
    my $remote = ($check == 1?($r->header_in('X-Forwarded-For') || $r->connection->remote_ip):
        $check == 2?($r->connection->remote_ip =~ m/(.*)\./):
        $check == 3?($r->connection->remote_ip):
        '');
    my $guest = $r->dir_config($auth_name.'Guest') || 'guest';

    my $mr = $r;
    # find existing session - a bit more complicated than usual since the request could be in
    # different stages of authentication
    if (1 || $session_id) {
        if ($mr->main && (!$mr->pnotes('SESSION') || $mr->pnotes('SESSION')->{'_session_id'} ne $session_id)) {
            $mr = $mr->main;
            #$self->debug(5,"main: ".$mr->main.", sid=".($mr->pnotes('SESSION')||{})->{'_session_id'});
        }
        #$self->debug(5,"prev: ".$mr->prev.", sid=".($mr->pnotes('SESSION')||{})->{'_session_id'});
        while ($mr->prev && (!$mr->pnotes('SESSION') || $mr->pnotes('SESSION')->{'_session_id'} ne $session_id)) {
            $mr = $mr->prev;
            #$self->debug(5,"prev: ".$mr->prev.", sid=".($mr->pnotes('SESSION')||{})->{'_session_id'});
            if ($mr->main && (!$mr->pnotes('SESSION') || $mr->pnotes('SESSION')->{'_session_id'} ne $session_id)) {
                $mr = $mr->main;
                #$self->debug(5,"main: ".$mr->main.", sid=".($mr->pnotes('SESSION')||{})->{'_session_id'});
            }
        }
        $mr ||= $r;
    }

    my $session = {};

    # retrieve session from a previous internal request
    $session = $mr->pnotes('SESSION') if $mr->pnotes('SESSION'); # and $session_id;
    $self->debug(5,"checkpoint beta, session={".join(',',keys %$session)."}");
    # create/retrieve session, providing parameters for several common session managers
    if (!keys %$session) {
        $session = $self->_get_session_from_store($r,$session_id);
        $r->register_cleanup(sub { _cleanup_session($self, $session) });
        if ($@ && $guest) {
            $self->debug(3, "sid $session_id invalid: $@");
            return (undef, 'bad_session_provided');
        }
    }
    $self->debug(5,"checkpoint charlie, sid=".$$session{'_session_id'}.", keys = ".join(",",keys %$session));

    $$session{'auth_access_user'} = $guest unless exists $$session{'auth_access_user'};
    $$session{'auth_first_access'} = time() unless exists $$session{'auth_first_access'};
    $$session{'auth_expire'} = $expire unless exists $$session{'auth_expire'};

    $expire = $$session{'auth_expire'};
    $self->debug(4,'UID = '.$$session{'auth_access_user'});
    # check if remote host changed or session expired; guest sessions never expire
    if (exists $$session{'auth_remote_ip'} && $remote ne $$session{'auth_remote_ip'}) {
        $self->debug(3, "ip mispatch");
        return (undef, 'ip_mismatch') if ($$session{'auth_access_user'} && $$session{'auth_access_user'} ne $guest);
    } elsif ($$session{'auth_access_user'} && $$session{'auth_access_user'} ne $guest && exists $$session{'auth_last_access'} && int(time()/300) > $$session{'auth_last_access'}+$expire) {
        $self->debug(3, "session expired");
        %$session = ();
        eval { tied(%$session)->delete };
        return (undef, 'session_expired');
    } elsif (!exists $$session{'auth_remote_ip'}) {
        $$session{'auth_remote_ip'} = $remote;
    }

    # force new session ID every 5 minutes if Apache::Session::Counted is used, don't write session file on each access
    $$session{'auth_last_access'} = int(time()/300) if $$session{'auth_last_access'} < int(time()/300);

    # store session hash in pnotes
    $r->pnotes('SESSION',$session);

    # global application data
    my $globals = $mr->pnotes('GLOBAL');
    if (!$globals) {
        $globals = {};
	if (my $tie = $r->dir_config($auth_name.'Global')) {
		my ($tie, @tie) = split(/,/,$tie);
		eval "require $tie" || die "Could not load ${auth_name}Global module $tie[0], did you install it? $@";
		tie(%$globals, $tie, @tie) || die "Could tie ${auth_name}Global: $@";
		$r->register_cleanup(sub { _cleanup_session($self, $globals) });
	}
    }
    $r->pnotes('GLOBAL',$globals);

    return $session;
}

# this is a NO-OP! Don't use this one (or ->login) directly,
# unless you have verified the credentials yourself or don't
# want user logins
sub authen_cred($$\@) {
    my ($self, $r, @credentials) = @_;
    $self->debug(3,"--------- authen_cred(".join(',',@_).")");
    my ($session, $err) = $self->_get_session($r);
    return (undef, $err) if $err;
    $$session{'auth_access_user'} = $credentials[0] if defined $credentials[0];
    $r->pnotes('SESSION',$session);
    return $$session{'_session_id'};
}

sub authen_ses_key($$$) {
    my ($self, $r, $session_id) = @_;
    $self->debug(3,"--------- authen_ses_key(".join(',',@_).")");
    my ($session, $err) = $self->_get_session($r, $session_id);
    return (undef, $err) if $err;
    return ($session_id eq $$session{'_session_id'})?$$session{'auth_access_user'}:undef;
}

sub logout($$) {
    my ($self) = shift;
    my ($r) = @_;
    $self->debug(3,"--------- logout(".join(',',$self,@_).")");
    my $session = $r->pnotes('SESSION');
    eval {
	%$session = ('_session_id' => $$session{'_session_id'});
        my $obj = tied(%$session);
	untie(%$session);
	$obj->delete;
    };
    $self->debug(5,'session delete failed: '.$@) if $@;
    return $self->orig_logout(@_);
}

# 'require' handlers

sub subrequest($$) {
    my ($self, $r) = @_;
    $self->debug(3,"--------- subrequest(".join(',',@_).")");
    return ($r->is_initial_req?FORBIDDEN:OK);
}

sub group($$) {
    my ($self, $r, $args) = @_;
    $self->debug(3,"--------- group(".join(',',@_).")");
    my $session = $r->pnotes('SESSION');

    my $groups = $$session{'auth_access_group'};
    $self->debug(10,"Groups: $groups");
    $groups = { $groups => undef } if !ref($groups);
    $groups = {} if (!$groups || ref($groups) ne 'HASH');
    foreach (split(/\s+/,$args)) {
        return OK if exists $$groups{$_};
    }
    return FORBIDDEN;
}

sub level($$) {
    my ($self, $r, $args) = @_;
    $self->debug(3,"--------- level(".join(',',@_).")");
    my $session = $r->pnotes('SESSION');

    if (exists $$session{'auth_access_level'}) {
        return OK if ($$session{'auth_user_level'} >= $args);
    }
    return FORBIDDEN;
}

sub combined($$) {
    my ($self, $r, $args) = @_;
    $self->debug(3,"--------- combined(".join(',',@_).")");
    my ($requirement, $arg);
    while ($args =~ m/\s*(.*?)\s+("(?:.*?(?:\\\\|\\"))*.*?"(?:\s|$)|[^" \t\r\n].*?(?:\s|$))/g) {
        ($requirement, $arg) = ($1, $2);
        $arg =~ s/^"|"\s?$//g;
        $arg =~ s/\\([\\"])/$1/g;
        $requirement = makeVariableName($requirement);
        no strict 'refs';
        my $rc = $self->$requirement($r,$arg);
        $self->debug(4,"-------- $requirement returned $rc");
        return FORBIDDEN if $rc != OK;
    }
    return OK;
}

sub alternate($$) {
    my ($self, $r, $args) = @_;
    $self->debug(3,"--------- alternate(".join(',',@_).")");
    my ($requirement, $arg);
    while ($args =~ m/\s*(.*?)\s+("(?:.*?(?:\\\\|\\"))*.*?"(?:\s|$)|[^" \t\r\n].*?(?:\s|$))/g) {
        ($requirement, $arg) = ($1, $2);
        $arg =~ s/^"|"\s?$//g;
        $arg =~ s/\\([\\"])/$1/g;
        $requirement = makeVariableName($requirement);
        no strict 'refs';
        my $rc = $self->$requirement($r,$arg);
        $self->debug(4,"-------- $requirement returned $rc");
        return OK if $rc == OK;
    }
    return FORBIDDEN;
}

sub not($$) {
    my ($self, $r, $args) = @_;
    $self->debug(3,"--------- not(".join(',',@_).")");
    my ($requirement, $arg) = split /\s+/, $args, 2;
    $requirement = makeVariableName($requirement);
    no strict 'refs';
    my $rc = $self->$requirement($r,$arg);
    $self->debug(4,"-------- $requirement returned $rc");
    return FORBIDDEN if $rc == OK;
    return OK;
}

# methods for retrieving permissions (get_permissions is in AuthCookieURL)

sub default_unpack_requirement {
    my ($self, $req, $args) = @_;
    return [ $req => [ split(/\s+/,$args) ] ];
}
*unpack_requirement_subrequest = \&default_unpack_requirement;
*unpack_requirement_valid_user = \&default_unpack_requirement;
*unpack_requirement_user = \&default_unpack_requirement;
*unpack_requirement_group = \&default_unpack_requirement;
*unpack_requirement_level = \&default_unpack_requirement;

sub unpack_requirement_combined {
    my ($self, $req, $args) = @_;
    no strict 'refs';
    my ($requirement, $arg);
    my $rc = [ $req => [] ];
    while ($args =~ m/\s*(.*?)\s+("(?:.*?(?:\\\\|\\"))*.*?"(?:\s|$)|[^" \t\r\n].*?(?:\s|$))/g) {
        ($requirement, $arg) = ($1, $2);
        $arg =~ s/^"|"\s?$//g;
        $arg =~ s/\\([\\"])/$1/g;
        my $sub = "unpack_requirement_".makeVariableName($requirement);
        push @{$$rc[1]}, $self->$sub($requirement,$arg);
    }
    return $rc;
}

*unpack_requirement_alternate = \&unpack_requirement_combined;

sub unpack_requirement_not {
    my ($self, $req, $args) = @_;
    no strict 'refs';
    my ($requirement, $arg) = split /\s+/, $args, 2;
    my $sub = "unpack_requirement_".makeVariableName($requirement);
    return [ 'not' => $self->$sub($requirement,$arg) ];
}

# methods for storing

sub default_pack_requirement {
    my ($self, $args) = @_;
    return join(' ',@{$$args[1]});
}
*pack_requirement_subrequest = \&default_pack_requirement;
*pack_requirement_valid_user = \&default_pack_requirement;
*pack_requirement_user = \&default_pack_requirement;
*pack_requirement_group = \&default_pack_requirement;
*pack_requirement_level = \&default_pack_requirement;

sub pack_requirement_combined {
    my ($self, $args) = @_;
    no strict 'refs';
    my $rc = '';
    foreach my $req (@{$$args[1]}) {
        my $sub = "pack_requirement_".makeVariableName($$req[0]);
        my $res = $self->$sub($req);
        $res =~ s/([\\"])/\\$1/g;
        $rc .= $$req[0]." \"$res\" ";
    }
    return substr($rc,0,-1);
}

*pack_requirement_alternate = \&pack_requirement_combined;

sub pack_requirement_not {
    my ($self, $args) = @_;
    no strict 'refs';
    my $sub = "pack_requirement_".makeVariableName($$args[1][0]);
    return $$args[1][0].' '.$self->$sub($$args[1]);
}

sub set_permissions($$@) {
    my ($self, $r, @perms) = @_;
    @perms = map { 'require '.$_->[0].' '.$_->[1]."\n" } @perms;
    if ($r->uri =~ m/#[^\/]*$/) {
        push @perms, "SetHandler perl-script\n";
        push @perms, "PerlHandler \"sub { &Apache::Constants::NOT_FOUND; }\"\n";
    }
    # Enabling write access to httpd config files is dangerous, so you will have to find
    # out yourself what to do. Do this only if you absolutely know what you are doing.
    my $configfile = $r->dir_config(($r->auth_name || 'AxKitSession').'AuthFile') || die 'read the fine manual.';
    local (*IN, *OUT);
    if (substr($configfile,0,1) eq '/') {
        open(IN, $configfile) || die "file open error (read): $configfile";
        open(OUT, ">$configfile.new") || die "file open error (write): $configfile.new";
        while (my $line = <IN>) {
            print OUT $line unless $line eq '# do not modify - autogenerated. # '.$r->uri."\n";
            while (my $line = <IN> && $line ne "# end of autogenerated fragment\n") {}
        }
        close(IN);
        print OUT '# do not modify - autogenerated. # '.$r->uri."\n";
        print OUT '<Location '.$r->uri.">\n";
        print OUT @perms;
        print OUT "</Location>\n";
        print OUT "# end of autogenerated fragment\n";
        close(OUT);
        rename("$configfile.new",$configfile);
    } else {
        my $dir = $r->filename;
        $dir =~ s{[^/]*$}{$configfile};
        my $file = $r->uri;
        $file =~ s{.*\/}{};
        $file .= $r->path_info;
        my @lines;
        if (open(IN, $dir)) {
            @lines = <IN>;
            close(IN);
        }
        open(OUT, ">$dir") || die "file open error (write): $dir";
        my $skip = 0;
        for my $line (@lines) {
            $skip = 1 if $line eq '# do not modify - autogenerated. # '.$r->uri."\n";
            print OUT $line unless $skip;
            $skip = 0 if $line eq "# end of autogenerated fragment\n";
        }
        print OUT '# do not modify - autogenerated. # '.$r->uri."\n";
        print OUT '<Files '.$file.">\n";
        print OUT @perms;
        print OUT "</Files>\n";
        print OUT "# end of autogenerated fragment\n";
        close(OUT);
    }
}

# interfaces for the taglib

sub get_permission_set($$) {
    my ($self, $r) = @_;
    my @rc = ();
    foreach my $req ($self->get_permissions($r)) {
        $$req[1] = '' unless defined $$req[1];
        my $sub = 'unpack_requirement_'.makeVariableName($$req[0]);
        push @rc, $self->$sub(@$req);
    }
    return @rc;
}

sub set_permission_set($$@) {
    my ($self, $r, @reqs) = @_;
    my @rc;
    my $req;
    foreach my $req (@reqs) {
        my $sub = "pack_requirement_".makeVariableName($$req[0]);
        push @rc, [ $$req[0], $self->$sub($req) ];
    }
    $self->set_permissions($r,@rc);
}

# overriding AuthCookieURL to implement OR style require handling
sub authorize ($$;$) {
    my ($self, $r, $reqs) = @_;
    my $auth_type = $self;
    $self->debug(3,"------- authorize(".join(',',@_).")");

    # This is a way to open up some documents/directories
    return OK if lc $r->auth_name eq 'none';
    return OK if $r->uri eq $r->dir_config(($r->auth_name || 'AxKitSession').'LoginScript');
    return OK if ($r->main?$r->main->uri:$r->uri) =~ m/^$redirect_location(\/|$)/;

    if (defined $r->auth_type && $r->auth_type ne $auth_type) {
        # This location requires authentication because we are being called,
        # but we don't handle this AuthType.
        $self->debug(3,"AuthType mismatch: $auth_type != ".$r->auth_type);
        return DECLINED;
    }

    my @reqs = ($reqs?@$reqs:$self->get_permissions($r)) or return DECLINED;

    my $user = $r->connection->user;

    unless ($user) {
        # user is either undef or =0 which means the authentication failed
        $r->log_reason("No user authenticated", $r->uri);
        $self->save_reason('no_user') if ($r->is_main());
        return FORBIDDEN;
    }

    foreach my $req (@reqs) {
        my ($requirement, $args) = split /\s/,$req->{requirement},2;
        $args = '' unless defined $args;
        $self->debug(2,"requirements: $requirement = $args");

        return OK if $requirement eq 'valid-user';

        # Call a custom method
        $self->debug(3,"calling $auth_type\-\>$requirement");
        my $ret_val = $auth_type->$requirement($r, $args);
        $self->debug(3,"$requirement returned $ret_val");
        return OK if $ret_val == OK;
    }

    $self->save_reason('access_denied') if ($r->is_main());
    return FORBIDDEN;
}

1;

__END__

=head1 NAME

Apache::AxKit::Plugin::Session - flexible session management for AxKit

=head1 SYNOPSIS

=head2 Basic configuration

This is the B<quickstart:>

    AxAddPlugin Apache::AxKit::Plugin::Session

Put it in .htaccess or httpd.conf. That's all. Easy, huh?

Now some B<alternatives:>

The above line only applies to AxKit documents - usually the right thing. To
get sessions for all files, use:

    PerlFixupHandler Apache::AxKit::Plugin::Session

The above variants need cookies enabled. Visitors that disable them are
honestly screwed. But there is rescue: Get automatic fallback to URL-Encoded
session IDs:

    PerlModule Apache::AxKit::Plugin::Session

    AuthType Apache::AxKit::Plugin::Session
    AuthName AxKitSession

    PerlAuthenHandler Apache::AxKit::Plugin::Session->authenticate
    PerlAuthzHandler Apache::AxKit::Plugin::Session->authorize
    require valid-user

(That _must_ be in httpd.conf)

Note that URL-encoded session IDs are generally regarded bad style and can
create a huge security risk. Used carefully it can mean an enhancement for
your customers. That said, URL sessions are deprecated. There is a different
solution under development.

So, now we made it through basic configuration. Let's try...

=head2 Protecting some documents

To do so, we first need to silence apache's internal authorization:

    AuthType Apache::AxKit::Plugin::Session
    AuthName AxKitSession
    PerlAuthenHandler Apache::AxKit::Plugin::Session->authenticate
    PerlAuthzHandler Apache::AxKit::Plugin::Session->authorize

Then we can do:

    require user admin

Put that into a .htaccess, or in a <Location> section, or similar.

But how can user admin log in? Want a login screen when privileges don't suffice?

    ErrorDocument 403 /login.xsp

C<login.xsp> must call <auth:login>, see L<AxKit::XSP::Auth>.

B<Advanced protection:>

Allow access to user JohnDoe and to user JaneDoe:

        require user JohnDoe JaneDoe

Allow access to members of group internal and mambers of group admin:

        require group internal admin

Allow access to members with level 42 or higher:

        require level 42

Allow access to all users except guest:

        require not user guest

Allow access to all users who are in group powerusers AND
 either longtimeusers or verylongtimeusers (compare "group" above):

	require combined group powerusers group "longtimeusers verylongtimeusers"

Allow access if (group == longtimeusers AND (group == powerusers OR level >= 10))

        require combined group longtimeusers alternate "group powerusers level 10"

You can have as many "require" lines as you want. Access is granted if at least one
rule matches.

=head2 Advanced options

How long is a session valid when idle? (minutes, must be multiple of 5)

    PerlSetVar AxKitSessionExpire 30

Which session module should be used?

    PerlSetVar AxKitSessionManager Apache::Session::File

Where should session files (data and locks) go?

    PerlSetVar AxKitSessionDir /tmp/sessions

Do you want global data? ($r->pnotes('GLOBALS') and AxKit::XSP::Globals)

    PerlSetVar AxKitSessionGlobal Tie::SymlinkTree,/tmp/globals

How's the "guest" user called?

    PerlSetVar AxKitSessionGuest guest

Want to check the IP address for sessions?

    PerlSetVar AxKitSessionIPCheck 1

Beware that IP checking is dangerous: Some people have different IP addresses
for each request, AOL customers for example. There are several values for you
to choose: 0 = no check; 1 = use numeric IP address or X-Forwarded-For, if present;
2 = use numeric IP address with last part stripped (/24 subnet); 3 = use
numeric IP address

=head2 Cookie options

Look at L<Apache::Cookie>. You'll quickly get the idea:

    PerlSetVar AxKitSessionPath /
    PerlSetVar AxKitSessionExpires +1d
    PerlSetVar AxKitSessionDomain some.domain
    PerlSetVar AxKitSessionSecure 1

Path can only be set to "/" if using URL sessions. Do not set "AxKitSessionExpires",
since the default value is best: it keeps the cookies until the user closes his
browser.

Disable cookies: (force URL-encoded sessions)

    PerlSetVar AxKitSessionNoCookie 1

=head2 Internal options

DANGER! Do not fiddle with these unless you know what you are doing.

Want a different redirector location? (default is '/redirect')

    <Perl>$Apache::AxKit::Plugin::Session::redirect_location = "/redir";</Perl>

Debugging:

    PerlSetVar AxDebugSession 5

Prefix to session ID in URLs:

    PerlSetVar SessionPrefix Session-


=head1 DESCRIPTION

WARNING: This version is for AxKit 1.7 and above!

This module is an authentication and authorization handler for Apache, designed specifically
to work with Apache::AxKit. It should be generic enough to work without it as well, only
much of its comfort lies in a separate XSP taglib which is distributed alongside this module.
It combines authentication and authorization in Apache::AuthCookieURL style with session management
via one of the Apache::Session modules. It should even work with Apache::Session::Counted. See those
manpages for more information, but be sure to note the differences in configuration!

In addition to Apache::AuthCookieURL, you get:

=over 4

=item * session data in $r->pnotes('SESSION')

=item * global application data in $r->pnotes('GLOBAL')

=item * sessions without the need to login (guest account)

=item * automatic expiration of sessions after 30 minutes (with
    automatic degradation to guest account, if any)

=item * remote ip check of sessions, for a tiny bit more security

=item * authorization based on users, groups or levels, including logical
        AND, OR and NOT of any requirement

=item * great AxKit taglibs for retrieving, checking and changing most settings

=back

To use authentication, you have to provide a login page which displays a login form,
verifies the values and calls <auth:login> (assuming XSP). Logout pages work
via <auth:logout>. Both functions are provided in the Auth XSP taglib, see
L<AxKit::XSP::Auth> for details.

=head1 ADVANCED

This module is extremely customizable. Please skip this section until you have
the module up and running. This section is only for advanced usage.

=head2 Perl interface 

Authorization via user name works by comparing the user name given at login time:
Apache::AxKit::Plugin::Session->login($r,$user_name)

Authorization via groups and levels works by using 2 session variables:

=over 4

=item * $r->pnotes('SESSION')->{'auth_access_groups'} is a hash which contains an element
    for each group the user is in. The value associated with that key is ignored,
    use undef if you have no other use for that value. Nested groups have to be
    handled by manually adding subgroups to this hash. Access is granted if any
    of the given groups are present in this hash. (i.e., logical OR)

=item * $r->pnotes('SESSION')->{'auth_access_level'} is a numeric level which must be
    or equal to the required level to be granted access. No value at all means
    'do not grant access if any level is required'.

=back

Note that the session dir will always leak. You will have to do manual cleanup, since
automatic removal of old session records is only possible in some cases. The
distribution tarball contains an example script to do that.

=head1 CONFIGURATION SETTINGS

See the synopsis for an overview and quick explanation.

All settings are set with PerlSetVar and may occur in any location PerlSetVar is allowed in,
except SessionPrefix, which must be a global setting.

=over 4

=item * SessionPrefix, AxKitSessionCache, AxKitSessionLoginScript, AxKitSessionLogoutURI,
AxKitSessionNoCookie, AxKitSession(Path|Expires|Domain|Secure)

These settings are similar to Apache::AuthCookieURL. Some of them are very advanced
and probably not needed at all. Some may be broken by now. Please only use the documented
variables shown in the synopsis.

=item * AxKitSessionExpire

Sets the session expire timeout in minutes. The value must be a multiple of 5.

Example: PerlSetVar AxKitSessionExpire 30

Note that the session expire timeout (AxKitSessionExpire) is different from the cookie expire
timeout (AxKitSessionExpires).  You should not set the cookie expire timeout unless you have
a good reason to do so. 

=item * AxKitSessionManager

Specifies the module to use for session handling. Directly supported are File,
DB_File, Counted, and all DB server modules if connecting anonymously. For all
other configurations (including Flex), you need AxKitSessionManagerArgs, too.

Example: PerlSetVar AxKitSessionManager Apache::Session::Counted

=item * AxKitSessionManagerArgs

List of additional session manager parameters in the form: Name Value. Use
with PerlAddVar.

Example: PerlAddVar AxKitSessionManagerArgs User foo

=item * AxKitSessionDir

The location where all session files go, including lockfiles. If you are using
a database server as session backend, this is the server specific db/table string.

Example: PerlSetVar AxKitSessionDir /home/sites/site42/data/session

=item * AxKitSessionGuest

The user name to be recognized as guest account. Setting this to a false
value (the default) disables automatic guest login. If logins are used at
all, this is the only way to get session management for unknown users. If
no logins are used, this MUST be set to some value.

Example: PerlSetVar AxKitSessionGuest guest

=item * AxKitSessionGlobal

Often you want to share a few values across all sessions. That's what
$r->pnotes('GLOBALS') is for: It works just like the session hash, but it is
shared among all sessions. In previous versions, globals were always available,
but since many users didn't care and there were grave problems in the old
implementation, behaviour has changed: You get a fake GLOBALS hash unless you
specify the sotrage method to use using this setting. It takes a comma-separated
list of "tie" parameters, starting with the name of the module to use. Do not use
spaces, and you should use a module that works with a minimum of locking, like
L<Tie::SymlinkTree>. Otherwise, you could get server lockups or bad performance
(which is what you often got in previous versions as well).

Example: PerlSetVar AxKitSessionGlobal Tie::SymlinkTree,/tmp/globals

=item * AxKitSessionIPCheck

The level of IP matching in sessions. A session id is only valid when the
connection is coming from the same remote address. This setting lets you
adjust what will be checked: 0 = nothing, 1 = numeric IP address or
HTTP X-Forwarded-For header, if present, 2 = numeric IP address with last
part stripped off, 3 = whole numeric IP address.

Example: PerlSetVar AxKitSessionIPCheck 3

=back

=head2 Programming interface

By subclassing, you can modify the authorization scheme to your hearts desires. You can store
directory and file permissions in an RDBMS and you can invent new permission types.

To store and retrieve permissions somewhere else than in httpd.conf, override 'get_permissions'
and 'set_permissions'. 'get_permissions' should return a list of arrayrefs, each one
containing a (type,argument-string) pair (e.g., the equivalent of a 'require group foo bar'
would be ['group','foo bar']). Access is granted if one of these requirements are met.
'set_permissions' should store such a list somewhere, if dynamic modification of permissions
is wanted. For more details, read the source.

For a new permission type 'foo', provide 3 subs: 'foo', 'pack_requirements_foo' and
'unpack_requirements_foo'. sub 'foo' should return OK or FORBIDDEN depending on the parameters
and the session variable 'auth_access_foo'. The other two subs can be aliased to
'default_(un)pack_requirements' if your 'require foo' parses like a 'require group'. Read the
source for more information.

=head1 WARNING

URL munging has security issues.  Session keys can get written to access logs, cached by
browsers, leak outside your site, and can be broken if your pages use absolute links to other
pages on-site (but there is HTTP Referer: header tracking for this case). Keep this in mind.

The redirect handler tries to catch the case of external redirects by changing them into
self-refreshing pages, thus removing a possibly sensitive http referrer header. This
won't work from mod_perl, so use Apache::AuthCookieURL's fixup_redirect instead. If you are
adding hyperlinks to your page, change http://www.foo.com to /redirect?url=http://www.foo.com

=head1 REQUIRED

Apache::Session, AxKit 1.7, mod_perl 1.2x

=head1 AUTHOR

Jörg Walter E<lt>jwalt@cpan.orgE<gt>.

=head1 VERSION

1.00

=head1 SEE ALSO

L<Apache::AuthCookie>, L<Apache::AuthCookieURL>, L<Apache::Session>,
L<Apache::Session::File>, L<Apache::Session::Counted>, L<AxKit::XSP::Session>,
L<AxKit::XSP::Auth>, L<AxKit::XSP::Globals>, L<Tie::SymlinkTree>

=cut



