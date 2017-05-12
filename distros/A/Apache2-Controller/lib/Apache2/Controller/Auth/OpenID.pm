package Apache2::Controller::Auth::OpenID;

=head1 NAME

Apache2::Controller::Auth::OpenID - OpenID for Apache2::Controller

=head1 VERSION

Version 1.001.001 - THIS MODULE DISABLED, DOES NOT WORK.

=cut

use version;
our $VERSION = version->new('1.001.001');

=head1 SYNOPSIS

 PerlLoadModule Apache2::Controller::Directives

 <Location /myapp>
     SetHandler modperl

     # uri to your login controller:
     A2C_Auth_OpenID_Login          login

     # uri to your logout controller:
     A2C_Auth_OpenID_Logout         logout

     # uri to your registration controller:
     A2C_Auth_OpenID_Register       register
     # you might want to put this outside the protected area, 
     # i.e. /other/register - you can use leading '/' for absolute uri

     # idle timeout in seconds, +2m, +3h, +4D, +6M, +7Y, or 'no timeout'
     # default is 1 hour.  a month is actually 30 days, a year 365.
     A2C_Auth_OpenID_Timeout        +1h

     # name of the openid table in database:
     A2C_Auth_OpenID_Table          openid
     
     # key of the username field in table:
     A2C_Auth_OpenID_User_Field     uname

     # key of the openid url field in table:
     A2C_Auth_OpenID_URL_Field      openid_url

     # if you use multiple DBI handles, name the one in pnotes
     # that you should use for reading the openid table:
     A2C_Auth_OpenID_DBI_Name       dbh

     # by default trust_root is the result of $r->construct_url(''),
     # i.e. the top of the site (see Apache::URI)
     A2C_Auth_OpenID_Trust_Root     http://myapp.tld/somewhere

     # set a random string used as salt with time() to sha secret
     A2C_Auth_OpenID_Consumer_Secret

     # but that random salt will be reset if you restart server,
     # which may cause current logins to die, so you can specify
     # your own constant salt of arbitrary length
     A2C_Auth_OpenID_Consumer_Secret    abcdefg1234567

     # if you do not want to preserve GET/POST params 
     # across redirects to the OpenID server, use this flag:
     # A2C_Auth_OpenID_NoPreserveParams

     # if you do not overload get_uname() (see below), then
     # PerlHeaderParserHandlers must be invoked in order
     # to set up the dbi handle before checking auth
     # with the default method.  In this example,
     # MyApp::DBI::Connector is an Apache2::Controller::DBI::Connector
     # and MyApp::Session is an Apache2::Controller::Session::Cookie...
     # see those modules for more info.

     PerlInitHandler            MyApp::Dispatch 
     PerlHeaderParserHandler    MyApp::DBI::Connector
     PerlHeaderParserHandler    MyApp::Session
     PerlHeaderParserHandler    Apache2::Controller::Auth::OpenID
 </Location>

=head1 DESCRIPTION

Implements an authentication mechanism for L<Apache2::Controller>
that uses OpenID.  

This is NOT an AuthenPerlHandler.  This is an implementation
of a simple cookie-based mechanism that shows the browser
a login page, where your controller should present and process an
HTML form for logging in.  

If you want an authentication handler that uses browser-based auth
(the pop-up dialog implemented by HTTP auth protocol) use 
L<Apache::Authen::OpenID>, which is not a part of Apache2::Controller
but should work for you anyway.

Natively this depends on L<Apache2::Controller::Session::Cookie>
and L<Apache2::Controller::DBI::Connector> being configured
correctly, but you could always subclass this and overload the
methods below to get information from other sources.

If no claimed ID is detected, the user is shown the login
page.  If an error occured, you'll find the L<Net::OpenID::Consumer>
error details in the session under C<< {a2c}{openid}{errtext} >>
and C<< {a2c}{openid}{errcode} >>.

=head2 REDIRECTION OR REDISPATCH?

Whether redirecting or redispatching, stuff has to be saved
in the session, so C<< $r->notes->{a2c}{session_force_save} >>
will be set.

=head3 INTERNAL LOGIN, LOGOUT AND REGISTER PAGES

=head4 RELATIVE URIS - REDISPATCH

If the uris for these pages are relative, not absolute, i.e.
they are handled by the same controller that we're going to
anyway, then it
tries setting the uri and re-dispatching by grabbing the dispatch
class name out of C<< $r->pnotes->{a2c}{dispatch_class} >> and 
instantiating a new dispatch handler object.

(Dispatch can't keep the handler
subref around in pnotes due to circular references, or reliably assume 
that we know at what location in
the C<< PerlInitHandler >> stack the dispatch handler coderef was
stored by Apache, so we just create a new one - this is assured
to be faster than creating an entire new request, which would
do that anyway.)

So in this case, the content for the login, logout, or register pages will
appear even though the browser uri still displays the requested
protected URI.

=head4 ABSOLUTE URIS - REDIRECT

If the uris for the internal pages are absolute, i.e.
they might be handled by a different controller than the
one that was dispatched, a redirect using Location HTTP header
is used.

=head3 EXTERNAL OPENID PAGES

Any time the browser needs to go to an external page (the openid server),
a redirect using a Location: HTTP header is used.

=head2 PRESERVATION OF INITIAL REQUEST

=head3 REQUESTED URI

When it goes to your login, or register page, it 
stashes the user's uri into the session as 
C<< {a2c}{openid}{previous_uri} >>
and should preserve this for the return url.  It uses
C<< $r->construct_url() >> as the trusted root.  

When the user passes the authentication process (C<< $csr->verified_identity >>),
it sets C<< $r->pnotes->{a2c}{openid_logged_in} >> for this request
to let your handler know if you want to display a message like 
"You have successfully logged in" or something.

=head3 GET AND POST VARS

The whole point of OpenID is that the login mechanism is
invisible - as long as the user can claim to own the url,
and the auth server returns a positive response, then the
user's session should continue.

So, this preserves GET parmas and the POST body through the 
login process and the redirect sequence to the OpenID server,
including when the local session times out.  If they come back
after a while and click a submit button, but either their
local session has timed out or their OpenID server session
has timed out through whatever mechanism that uses, then after
they log into OpenID and are redirected back to the protected
area, the GET params and POST body are restored, and it will
do what the user expected when they clicked the submit button.

This behavior
is a feature, so it is enabled by default, but it may not
be expected, so you can turn it off by using the directive
flag C<< A2C_Auth_OpenID_NoPreserveParams >>.

=head1 DIRECTIVES

L<Apache2::Controller::Directives/Apache2::Controller::Auth::OpenID>

=head1 CACHING

If you want to provide a cache for L<Net::OpenID::Consumer>
to pass onto L<URI::Fetch>, subclass this module and implement
a method C<< cache() >> that returns the appropriate cache object.

=head1 CAVEATS

I have heard there are trickier things one can do to ensure the
security of a session based cookie.  This module just implements
a simple association of a user with a session key by storing a flag
and a last-accessed time value in the session hash, nothing fancier.
If you have recommendations, please let me know.

This calls C<< $r->connection->get_remote_host >> and saves it
in the C<< {a2c}{openid} >> section of the session hash.  So if
you don't want it to do DNS lookups, set directive C<< HostNameLookups off >>.

=cut

use strict;
use warnings FATAL => 'all';
use English '-no_match_vars';

use Carp qw( longmess );

use base qw( 
    Apache2::Controller::NonResponseRequest 
);

use Log::Log4perl qw(:easy);
use YAML::Syck;
use Digest::SHA qw( sha224_base64 );
use Net::OpenID::Consumer;
use URI;
use List::MoreUtils qw(any);

use Apache2::Const -compile => qw( OK SERVER_ERROR REDIRECT );

use Apache2::Controller::X;

=head2 new

Overloaded constructor will always throw an L<Apache2::Controller::X>
because this module does not work.

=cut

sub new {
    a2cx __PACKAGE__." is disabled, does not work, do not use.";
}

# hopefully we get the same default consumer secret as in top level
use Apache2::Controller::Const qw( $DEFAULT_CONSUMER_SECRET );

=head1 OVERLOADABLE METHODS

The only method which should be overloaded in your subclass
is C<< get_uname( $openid_url ) >> which returns the username
string that corresponds to the openid url supplied by the cookie.
When overloading, you get the RequestRec in C<< $self->{r} >>.

=head2 get_uname

 my $uname = $self->get_uname($openid_url);

Takes a string which is the supplied openid_url.
You can overload C<< get_uname >> to supply it
by some other means, such as by LDAP.

=cut

sub get_uname {
    my ($self, $openid_url) = @_;

    a2cx "get_uname() requires an openid_url string param"
        if !$openid_url || ref $openid_url;

    my $conf = $self->{conf};

    my $pnotes = $self->pnotes;
    DEBUG sub { "pnotes: ".Dump($pnotes) };

    my $dbh = $self->pnotes->{a2c}{ $conf->{dbi_name} }
        || a2cx "Database handle '$conf->{dbi_name}' is not connected in pnotes"
            ." for default handler ".__PACKAGE__;

    my $uname;
    eval {
        ($uname) = $dbh->selectrow_array(
            qq| SELECT  $conf->{user_field} 
                FROM    $conf->{table} 
                WHERE   $conf->{url_field} = ? 
            |, undef, $openid_url
        );
    };
    a2cx "Error in default get_uname() from dbh: $EVAL_ERROR"
        if $EVAL_ERROR;

    return $uname;
}

=head1 INTERNAL METHODS

"These aren't the methods you're looking for."

"These aren't the methods we're looking for."

"He can go about his business."

"You can go about your business."

"Move along."

"Move along.  Move along."

You don't access these methods.  This is internal documentation.

=head2 default_directives 

Calculate and return the hash of directive defaults.
(Some of these are based on the current <Location> of the handler.)

=cut

sub default_directives {
    my ($self) = @_;
    return (
        login           => "login",
        logout          => "logout",
        register        => "register",
        timeout         => 3600,
        table           => 'openid',
        user_field      => 'uname',
        url_field       => 'openid_url',
        trust_root      => $self->construct_url(q{}),
        dbi_name        => 'dbh',
        lwp_class       => 'LWPx::ParanoidAgent',
        lwp_opts        => {
            timeout         => 20,
        },
        consumer_secret => $DEFAULT_CONSUMER_SECRET,
        nopreserveparams => 0,
    );
}

=head2 openid_url_normalize 

Correct trailing double /'s etc. in the openid url.

=cut

sub openid_url_normalize {
    my ($self, $openid_url) = @_;
    my $orig_url = $openid_url;
    my ($scheme) = $openid_url =~ m{ \A (\w+) : // }mxs;
    $scheme ||= 'http';
    $scheme = lc $scheme;
    $openid_url = URI->new( $openid_url, $scheme )->canonical->as_string
        || a2cx "Could not normalize openid_url '$orig_url'";
    $openid_url =~ s{ /+ \z }{}mxs;
    return $openid_url;
}

=head2 process

Make sure the config directives are assigned or use defaults.

If uri = login uri, process accordingly.

If uri = logout uri, delete session hash login flags and return OK.

=cut

sub _save_errs_in_sess {
    my ($self, $openid_csr) = @_;
    my $sess = $self->pnotes->{a2c}{session};
    my $errcode = $openid_csr->errcode 
        || $openid_csr->{last_errcode} || '[ no error code ]';
    my $errtext = $openid_csr->err 
        || $openid_csr->{last_errtext} || '[ no error text ]';
    $sess->{a2c}{openid}{errtext} = $errtext;
    $sess->{a2c}{openid}{errcode} = $errcode;
    return ($errtext, $errcode);
}

my ($openid_csr, $consumer_secret_string);
my %params_hash;

sub process {
    my ($self) = @_;
    my $uri = $self->uri();

  # my $pnotes = $self->pnotes;
  # DEBUG sub { "Before checking session, pnotes is:\n".Dump($pnotes) };

    # make sure a session object is set up already
    my $sess = $self->pnotes->{a2c}{session}
        || a2cx "No session object configured for handler";

    DEBUG sub { "Entering, processing uri '$uri'.\nsession is:\n".Dump($sess) };

    my $directives = $self->get_directives();
    my %conf = (
        $self->default_directives(),
        ( map {(lc($_) => $directives->{"A2C_Auth_OpenID_$_"})} 
          grep exists $directives->{"A2C_Auth_OpenID_$_"}, qw( 
            Login       Logout      Register    Timeout
            Table       User_Field  URL_Field   DBI_Name    
            Trust_Root  LWP_Class   Allow_Login Consumer_Secret
            NoPreserveParams
        ) ),
    );

    # make a lookup verification map of the internal uris
    $conf{is_internal} = { map {($conf{$_} => 1)} qw( login logout register ) };

    # slap in anything specified in the sub-hash of LWP class options
    my $lwp_opts_directive = $directives->{A2C_Auth_OpenID_LWP_Opts} || { };
    my @lwp_opt_keys = keys %{$lwp_opts_directive};
    DEBUG sub { "Trying to slice in lwp_opts: ".Dump($lwp_opts_directive) };
    @{$conf{lwp_opts}}{@lwp_opt_keys} = @{$lwp_opts_directive}{@lwp_opt_keys}
        if scalar @lwp_opt_keys;

    $self->{conf} = \%conf;

    DEBUG sub { "conf:\n".Dump(\%conf) };
    DEBUG sub { "session:\n".Dump($self->pnotes->{a2c}{session}) };

    # if we're on the register page, allow it through
    return Apache2::Const::OK if $uri eq $self->qualify_uri($conf{register});

    # logout and return if we're processing the logout uri
    if ($uri eq $self->qualify_uri($conf{logout})) {
        DEBUG "requested logout page $conf{logout}, returning logout()";
        return $self->logout();
    }

    # return OK if their session is logged in and timestamp is current
    if ($self->is_logged_in) {
        DEBUG "user is logged in, returning OK";
        return Apache2::Const::OK;
    }
    else {
        DEBUG "user is NOT logged in, continuing auth";
    }

    # consumer object creation is very slow, so we cache in package space:
    if (!defined $openid_csr) {
        my $cache = $self->can('cache') ? $self->cache() : undef;
        eval "use $conf{lwp_class}";
        a2cx "Could not load A2C_Auth_OpenID_LWP_Class ($conf{lwp_class}): "
            ."$EVAL_ERROR" if $EVAL_ERROR;

        # stash string in package to avoid closure circle on this req's %conf.
        # we provide some hardcoded junk if they didn't use the directive 
        # to specify or generate some.
        $consumer_secret_string = $conf{consumer_secret};
        DEBUG "Setting up CSR with secret string '$consumer_secret_string'";

        $openid_csr = Net::OpenID::Consumer->new(
            ua              => $conf{lwp_class}->new(%{ $conf{lwp_opts} }),
            cache           => $cache,
            consumer_secret => sub {
                my ($time) = @_;
                return sha224_base64("$time-$consumer_secret_string");
            },
            debug           => \&DEBUG,
            args            => sub {
                my ($param_name) = @_;
                return wantarray 
                    ? @{ $params_hash{$param_name} } 
                    : $params_hash{$param_name}[0];
            },
        );
    }

    # we have to populate a package space variable params_hash
    # with the params contents, so we won't create a closure
    # that includes the request object when we construct the
    # params subroutine for the openid csr object
    my @param_names = $self->param;
    %params_hash = map {
        my @vals = $self->param($_);
        ($_ => \@vals);
    } @param_names;
    DEBUG sub {
        "params:\n".Dump(\%params_hash);
    };
    
    my $openid_url = $self->param('openid_url') || $sess->{a2c}{openid}{openid_url};

    if ($openid_url) {
        # if there is a param 'openid.identity' from a redirect
        # from the openid server, make sure it is the same as
        # the one we thing we're logging in for, else redirect to login
        if (my $id_from_server = $self->param('openid.identity')) {
            if ($openid_url ne $id_from_server) {
                DEBUG "openid_url '$openid_url' does not match "
                    . "id from server '$id_from_server', redirect to login";
                return $self->redirect_to($conf{login});
            }
        }

        # save the openid url in the session
        $sess->{a2c}{openid}{openid_url} = $openid_url;
    }
    else {
        DEBUG "no openid url detected, redirecting to login page";
        return $self->redirect_to($conf{login});
    }

    $openid_url = $self->{openid_url} = $self->openid_url_normalize($openid_url);

    # first verify that we know about this openid url, and redirect to
    # the registration page if we don't

    DEBUG "looking for uname from openid table using openid_url '$openid_url'";

    my $uname = $self->get_uname($openid_url);

    if (!$uname) {
        DEBUG("no uname! ... ".(defined $uname ? "'$uname'" : '[undef]'));
        return $self->redirect_to($conf{register});
    }

    $self->{uname} = $uname;

    DEBUG "Trying authentication for known user: $uname, $openid_url";
    # okay, handle the authentication

    my $claimed_id;

    my $allow_login = $conf{allow_login};

    if (!$allow_login) {
        $claimed_id = ($openid_csr->claimed_identity($openid_url) || '');
        DEBUG sub {"claimed_id: ".(defined $claimed_id ? $claimed_id : '[undef]')};

        # if claimed id found, make sure session csr errors are cleared
        if ($claimed_id) {
            delete @{ $sess->{a2c}{openid} }{qw( errtext errcode )};
        } 
        # otherwise put the errors in the session and redirect to login
        else {
            my ($errtext, $errcode) = $self->_save_errs_in_sess($openid_csr);
            DEBUG "Claimed ID '$self->{openid_url}' is not an OpenID: "
                . "($errcode) '$errtext'";
            $self->redirect_to($conf{login});
        }
    }

    my $vident;
    DEBUG "proceeding with authentication for uri '$uri'...";

    # we have to do this again?
    $openid_csr->args(sub { return $self->param(@_) });

    if ($allow_login || ($vident = $openid_csr->verified_identity)) {
        my $verified_url = $allow_login ? $openid_url : $vident->url;
        DEBUG sub { "verifd ident: ".(defined $vident ? "'$vident'" : '[undef]') };
        $openid_url = $self->openid_url_normalize($verified_url);

        my $connection = $self->connection;

        my $openid_sess = $sess->{a2c}{openid} ||= { };

        # update the session
        $openid_sess->{logged_in} = 1;
        $openid_sess->{last_accessed_time} = time;
        $openid_sess->{remote_host} = $connection->get_remote_host();
        $openid_sess->{remote_ip}   = $connection->remote_ip();
        $openid_sess->{openid_url}  = $openid_url;

        # restore the saved query params and post body
        $self->args($openid_sess->{previous}{get_args})
            if $openid_sess->{previous}{get_args};

        if (my $post_params = $openid_sess->{previous}{post_params}) {
        }

        # if everything works and we're returning the user okay,
        # make sure to delete the previous url from session hash
        delete $openid_sess->{previous};

        # set a flag for this request so controller can print
        # a "login successful" message
        $self->pnotes->{a2c}{openid_logged_in} = 1;

        $self->user($uname);

        return Apache2::Const::OK;
    }
    elsif (!$self->param('oic.time')) {

        # figure out what uri they're returning to.
        # if we can't figure one out from session,
        # they go back to the login page.
        my $return_uri = $sess->{a2c}{openid}{previous}{uri};
        DEBUG "previous_uri from sess is ".($return_uri || '[none]');

        my %qual_uris = map {($_ => $self->qualify_uri($conf{$_}))} 
            qw( login logout register );

        # depending on what the return uri was supposed to be, set
        # it, or maybe the login uri, or maybe the current uri
        my $real_return_uri 
          = $return_uri                     ? $return_uri
          : $uri eq $qual_uris{logout}      ? $qual_uris{login} # wrong
          : $uri;

        # make sure we save the uri in any case?
        $sess->{a2c}{openid}{previous}{uri} = $real_return_uri;

        my $return_to = $self->construct_url($real_return_uri);
        DEBUG "calling claimed_identity->check_url with return_to '$return_to'";
        DEBUG sub { "openid part of session is ".Dump($sess->{a2c}{openid}) };

        my $check_url = $claimed_id->check_url(
            trust_root  => $conf{trust_root},
            return_to   => $return_to,
        ) || a2cx "Detected no check url from claimed ID";

        DEBUG "got back check_url '$check_url'";
        return $self->redirect_to($check_url);
    }
    elsif (my $setup_url = $self->param('openid.user_setup_url')) {
        DEBUG "redirecting to openid provider setup_url '$setup_url'";
        return $self->redirect_to($setup_url);
    }
    elsif ($openid_csr->user_cancel) {
        # redirect to login page
        DEBUG "user cancelled: redirecting to login";
        return $self->redirect_to($conf{login});
    }
    else {
        my ($errtext, $errcode) = $self->_save_errs_in_sess($openid_csr);
        DEBUG "Error for '$self->{openid_url}': ($errcode) '$errtext'";
        a2cx "Error in OpenID authentication: ($errcode) '$errtext'";
    }
}

=head2 DESTROY

To save memory and be clean, when the object is destroyed,
the package-space var C<< %params_hash >> is cleared.

C<< process() >> has to populate a package space variable 
C<< %params_hash >>
with the params contents, so we won't create a closure
that includes the request object when we construct the
params subroutine for the cached openid CSR object.  Otherwise,
the CSR keeps a reference to our handler object around,
which contains a reference to the request object, and
then neither the request nor the handler object are 
cleaned up after this handler exits.  (Apparently
Apache doesn't execute DESTROY until the next time it
has to run this handler.  Doesn't quite make sense,
but that's the way it behaved.)

=cut

sub DESTROY {
    my ($self) = @_;
    %params_hash = ();
}

=head2 qualify_uri

If the uri is relative, qualifies it by prepending current location.
Otherwise just returns the uri.

=cut

sub qualify_uri {
    my ($self, $uri) = @_;
    a2cx "only use this with in-server path uri's" if $uri =~ m{ \A \w+ : // }mxs;
    $uri = $self->location.'/'.$uri if substr($uri, 0, 1) ne '/';
    return $uri;
}

=head2 redirect_to

 return $self->redirect_to($uri);

If one of the three internal URIs, use C<< redispatch() >>.

Otherwise, use C<< location_redirect >>.

=cut

sub redirect_to {
    my ($self, $where_uri) = @_;
    a2cx "Undefined redirect" if !defined $where_uri;

    my $conf = $self->{conf};
    my $current_uri = $self->uri();

    return exists $conf->{is_internal}{$where_uri}
        ? $self->redispatch($where_uri)
        : $self->location_redirect($where_uri);
}

=head2 location_redirect

 return $self->location_redirect($uri);

Set the Location header and return REDIRECT.

Forces the session to be saved in the cleanup handler.

=cut

sub location_redirect {
    my ($self, $uri) = @_;

    DEBUG "redirecting with location header to $uri";

    $self->err_headers_out->add( Location => $uri );

    # set the flag to force the session to be saved
    $self->pnotes->{a2c}{session_force_save} = 1;

    return Apache2::Const::REDIRECT;
}

=head2 redispatch 

 return $self->redispatch($uri);

For the internal pages (login, logout, register), if they are
relative, re-dispatch them and return OK, else if absolute,
set location and return redirect.

If where == register or login, and the current uri is not
register or login, stash the current uri in
C<< session->{a2c}{openid}{previous}{uri} >>, and if
C<< A2C_Auth_OpenID_NoPreserveParams >> is NOT set,
then it stashes the get args and post body in C<< ...{previous}{get} >>
and C<< ...{previous}{post} >> for reattaching to the request
after successful authentication on the return from the auth server.

=cut

sub redispatch {
    my ($self, $where_uri) = @_;

    DEBUG "redispatch uri '$where_uri'?";

    # if it's an absolute path or schemed url, use a location redirect
    return $self->location_redirect($where_uri)
        if $where_uri =~ m{ \A / }mxs 
        || $where_uri =~ m{ \A \w+ :// }mxs;

    my $conf = $self->{conf};
    my $current_uri = $self->uri();
    my $current_loc = $self->location();
    (my $current_relative_uri = $current_uri) =~ s{ \A \Q$current_loc\E / }{}mxs;
    DEBUG "current_relative_uri '$current_relative_uri'";

    # save the current uri, get vars and post body in session 
    my $register_uri = $conf->{register};
    my $login_uri    = $conf->{login};
    if  (   ($where_uri eq $register_uri || $where_uri eq $login_uri)
        &&  $current_relative_uri ne $register_uri
        &&  $current_relative_uri ne $login_uri
        ) {
        DEBUG "setting session previous_uri to '$current_uri'";
        $self->pnotes->{a2c}{session}{a2c}{openid}{previous}{uri}  = $current_uri;
        $self->preserve_params unless $conf->{nopreserveparams};
    }

    # now set the new URI and redispatch.

    DEBUG "redispatching...";

    my $loc = $self->location;
  # DEBUG "loc is first '$loc'";
    $loc =~ s{ /+ \z }{}mxs;
  # DEBUG "loc is now '$loc'";

    my $where_full_uri = "$loc/$where_uri";
    DEBUG "Trying to redispatch to full uri '$where_full_uri'";

    $self->uri($where_full_uri);

    my $dispatch_class = $self->pnotes->{a2c}{dispatch_class}
        || a2cx 'No dispatch class saved in $r->pnotes->{a2c}{dispatch_class}';
    
  # # clear the previously set response handler

    # redispatch

    # we trap errors, but we use a location redirect if we encounter any
    # we skip the 'process' subroutine because it uses set_handler,
    # which seems like it should work, but in fact stalls the request
    # after the last cleanup handler completes, even though it seems
    # like everything completed successfully.
    my $previously_set_controller = $self->pnotes->{a2c}{controller}
        || a2cx "no controller previously dispatched in pnotes->{a2c}{controller}";

    eval {
        my $redispatch_handler = $dispatch_class->new($self->{r});
        $redispatch_handler->find_controller;
        my $redispatch_controller = $self->pnotes->{a2c}{controller}
            || a2cx "Redispatch set no new controller in pnotes->{a2c}{controller}";
        a2cx "Redispatch controller '$redispatch_controller' is not previously "
            ."set controller '$previously_set_controller'"
            if $redispatch_controller ne $previously_set_controller;
    };
    if (my $X = Exception::Class->caught('Apache2::Controller::X')) {
        WARN "Caught Apache2::Controller::X trying to redispatch $where_full_uri";
        WARN(ref($X).": $X\n".($X->dump ? Dump($X->dump) : '').$X->trace());
        return $self->location_redirect($where_uri);
    }
    elsif ($EVAL_ERROR) {
        WARN "Unknown error trying to redispatch $where_full_uri: $EVAL_ERROR";
        return $self->location_redirect($where_uri);
    }

    return Apache2::Const::OK;
}

=head2 preserve_params

Preserve the GET and POST params in the session.

=cut

sub preserve_params {
    my ($self) = @_;
    my $conf = $self->{conf};

    my $previous = $self->pnotes->{a2c}{session}{a2c}{openid}{previous} ||= { };
    $previous->{get_args}  = $self->args;

    # if we're not POSTing, just return - ??
    return if !$self->method eq 'POST';

    # get the POST body table,
    # and get the params directly from it, so we don't mix in
    # any GET params and keep them straight.
    my $post_body = $self->body;
    my @post_keys = keys %{$post_body};
    my %post_params = map {
        my @vals = $self->body($_);
        ($_ => @vals > 1 ? \@vals : $vals[0]);
    } keys %{$post_body};
            
    $previous->{post_params} = \%post_params;
    return;
}

=head2 is_logged_in

Check the fields in the session hash to make sure they're logged in.
Apply the directive timeout to make sure.  Don't change anything though.
Just return if not logged in, or return 1 if logged in.

=cut

sub is_logged_in {
    my ($self) = @_;
    my $sess = $self->pnotes->{a2c}{session};

    my $openid_sess = $self->pnotes->{a2c}{session}{a2c}{openid};

    DEBUG sub { "openid part of session is ".Dump($openid_sess) };

    return if !$openid_sess->{logged_in};
    
    my $last_accessed = $openid_sess->{last_accessed_time};
    return if !defined $last_accessed;

    my $conf = $self->{conf};
    my $timeout = $conf->{timeout};

    if ($timeout eq 'no timeout') {
        $self->user($self->{uname});
        return 1;
    }

    my $current_time = time;

    DEBUG "comparing last accessed '$last_accessed' to current time '$current_time' with timeout '$timeout'";

    if ($current_time - $timeout > $last_accessed) {
        DEBUG "login session has timed out";
        $self->pnotes->{a2c}{session}{a2c}{openid}{previous_uri} = $self->uri;
        return;
    }

    $self->user($self->{uname});
    return 1;
}

=head2 logout

Log the user out by clearing the relevant fields in the session hash.

=cut

sub logout {
    my ($self) = @_;

    delete @{ $self->pnotes->{a2c}{session}{a2c}{openid} }{qw(
        logged_in
        last_accessed_time
        openid_url
    )};

    return Apache2::Const::OK;
}

=head1 SEE ALSO

L<Apache2::Controller::Directives>

L<Apache2::Controller>

L<Apache2::Controller::NonResponseRequest>

L<Apache2::URI>

L<Net::OpenID::Consumer>

=head1 AUTHOR

Mark Hedges, C<< <hedges at formdata.biz> >>

=head1 COPYRIGHT & LICENSE

Copyright 2008-2010 Mark Hedges, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Apache2::Controller::Auth::OpenID
