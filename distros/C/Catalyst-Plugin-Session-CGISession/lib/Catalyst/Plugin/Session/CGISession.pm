package Catalyst::Plugin::Session::CGISession;

use warnings;
use strict;

our $VERSION = '0.04';

use base qw/Class::Data::Inheritable Class::Accessor::Fast/;
use CGI::Session;
use NEXT;
use Carp;
use File::Spec;
use URI;
use URI::Find;
use Data::Dumper;


# QUESTIONS:
#
#
#   Shouldn't the body text rewrite in finalize be limited to
#       content-type qr{text/x?html} ?
#
#   Should extracting embedded session ids from paths be conditional
#       on {rewrite}?  That is, we shouldn't do it unless allowed
#       by config.
#
#   How can someone say "no expiration should be done"?  We can't (yet)
#       use the value zero.  The Cache modules use the value
#       $EXPIRES_NEVER = 'never'
#
#   If session plugins must be setup() before other plugins that use
#       session data, then doesn't that also force calls to finalize()
#       in the session plugins before the others?  So don't we need
#       to explicitly state other plugins should not expect that
#       they will be able to alter session data?  (perhaps we should
#       have a croak() guard against this?)
#
#   Need to trace what happens when ->session() is not called.
#       We don't do any CGIS processing?  (we shouldn't)
#         (but see that Authentication::CDBI *always* calls session)
#
#
# ANSWERS:   (partial or otherwise)
#
#   Is there any way to prevent session processing when static content is
#       (about to be) served?  Hmm, Static::Simple hooks into dispatch()
#       which is called after all the prepare steps.  And session() is
#       being called from Authentication::CDBI::prepare_action()
#     * AndyG changes Static::Simple to hook into prepare_action() chain
#       and short-circuit that to avoid session access on static files.
#
#   Check out the ramifications of ip_match and remote_addr - do we need
#       to disable or allow disabling of the ip_match checks?  If enabled
#       do we need to override remote_addr?
#               $CGI::Session::IP_MATCH = 0;
#               _SESSION_REMOTE_ADDR => $ENV{REMOTE_ADDR} || "",
#               if($CGI::Session::IP_MATCH) {
#                 unless($self->_ip_matches) {
#           sub _ip_matches {
#             return ( $_[0]->{_DATA}->{_SESSION_REMOTE_ADDR} eq $ENV{REMOTE_ADDR} );
#           sub remote_addr {   return $_[0]->{_DATA}->{_SESSION_REMOTE_ADDR}   }
#     * okay, so this feature is disabled by default, as per discussion
#       in the CGIS docs (tutorial in 4.x).  If the user wants to turn
#       this on they can do so using the global variable
#
#   Do we want to provide the CGIS specific APIs like ->param() ??
#       Umm, actually this might be _required_ for some people who
#       are migrating to Catalyst with existing code/assumptions.
#       If it is called ::CGISession we probably have to supply
#       the basics _of_ CGI::Session.
#       yes:    param()  is_new()  flush()
#       no:     load_param()  save_param()
#       ???:    delete()
#     * We will do param/is_new/flush to start with.
#
#
# SPECULATION:
#
#   This might mitigate the lack of locks
#   We could do the no_write_on_close feature if we use the CGIS 4.x
#   undocumented internal method _reset_status() to clear the modified
#   flags.  There is also _unset_status()
#   Isn't it true that merely reading a session object marks it as
#   'modified' and thus must be written out again, simply because the
#   "last access time" has been updated?
#
#
#   Where to document the similarities with C::P::Session::FastMmap,
#   such as:
#     - same cookie name 'session' used
#     - same session hash data access method ->session->{}
#   And differences:
#     - URL embedded session id checking is stricter
#     - session expires time reset by access (expiration time is
#           relative to last access, not session creation)



our $DEFAULT_EXPIRATION_TIME     = 60 * 60 * 24;

# We default the CGI::Session storage to plain files in temp directory
# We use 'File' 'Storable' 'MD5' to match CGIS 3.x case-sensitivity
our $DEFAULT_CGI_SESSION_DSN     = 'driver:File;serializer:Storable;id:MD5';
our $DEFAULT_CGI_SESSION_OPTIONS = { Directory => File::Spec->tmpdir };

# This is the parameter name used with CGI::Session::param() where we
# stuff our session data hash that is exposed with our session() method.
our $SESSION_DATA_PARAMETER_NAME = '_catalyst_session';


use constant SESSION_DUMP_DATA          => 1;
use constant SESSION_DUMP_PARAMS        => 2;
use constant SESSION_DUMP_SESSION       => 3;


__PACKAGE__->mk_accessors('sessionid');


# -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
# Create a dummy class to satisfy CGI::Session need for a "query object".
#
# If a session id string is not given in the CGI::Session->new() call,
# CGIS will attempt to discover the session id value by its own means.
# In spite of the fact that we may have already determined that there
# is no incoming session id, CGIS will try anyway - there is no way
# to turn off its discovery actions.
#
# The great problem is that CGIS will try to load CGI.pm and execute a
# calls to CGI->new().  We must prevent this.
#
# One way to prevent this is to supply a "query object" parameter.  CGIS
# will call this object's param() and cookie() methods checking to see
# whether a parameter or cookie named 'CGISESSID' was in the request.
#
# We can certainly use the request object, $c->request, to serve as the
# query object.  It will field the param() and cookie() requests quite
# handily.  However unlikely, though, it is possible that an application
# might use a parameter or cookie with the sought after name, and a
# false 'hit' would happen.  It is even more unlikely that the value
# would look like a session id value, but double accidents happen also.
#
# We can avoid all the nasty possibilities by defining our own dummy
# query object.  To all queries to param() or cookie() we return undef.
# Thus CGIS is finally convinced about what we know already, there is
# no session id available.

package Catalyst::Plugin::Session::CGISession::dummy_query;

sub new {
    my  $class = shift;
    return bless {}, $class;
}

sub param { return; }
sub cookie { return; }

# CgiS::dummy_query::cookie(::dummy_query=HASH(0x1ef8b30)|CGISESSID) called ...
#   at C:/Perl587/site/lib/CGI/Session.pm line 640
# CgiS::dummy_query::param(::dummy_query=HASH(0x1ef8b30)|CGISESSID) called ...
#   at C:/Perl587/site/lib/CGI/Session.pm line 640

package Catalyst::Plugin::Session::CGISession;


# -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -

# This method is called from Catalyst::Setup at plugin initialization time.
# It is expected that all configuration values for session have already
#   been set.

sub setup {
    # warn sprintf "CgiS::setup(%s) called ...\n", join('|',@_);
    my  $self = shift;

    # Establish default values for options

    # Options governing how this module is used
    $self->config->{session}->{rewrite} ||= 0;

    # Options governing how CGI::Session is used
    $self->config->{session}->{expires}  ||= $DEFAULT_EXPIRATION_TIME;
    $self->config->{session}->{cgis_dsn} ||= $DEFAULT_CGI_SESSION_DSN;
    $self->config->{session}->{cgis_options} ||= $DEFAULT_CGI_SESSION_OPTIONS;

    # Options governing how module and CGI::Session interact

    # Note that we do not default the cookie-related configuration
    # options here, but simpy test for presence

    return $self->NEXT::setup(@_);
}



# Called by engines after prepare_cookies() and prepare_path()

# This method attempts to locate a session id two different ways.
#
# First it checks whether a session id has been embedded within the
# request URL path.  This is signaled by the sequence '/-/' followed
# by
#       *any* characters and *any* number of them ??  Can we at least
#       eliminate path separators?  Would it be impractical to limit
#       the possible characters to alphanums, like from MD5?
#       Hmm, Digest docs say binary/hex/base64
#           hex  '0'..'9' and 'a'..'f'          md5=32
#           base64  65-character subset ([A-Za-z0-9+/=]) of US-ASCII is used.
#           base64  'A'..'Z', 'a'..'z', '0'..'9', '+' and '/'.  md5=22
#       So far everyone uses hexdigest or decimal numbers
#    a session id.  If detected, then the request path is truncated
# to only the part preceding the session id marker '/-/'.  The id
# value is used to set $c->sessionid()
#
# The second method is to check for a cookie sent in the request that
# has the name 'session'.  If found then the cookie value is used to
# set $c->sessionid()

sub prepare_action {
    my $c = shift;

    # Try to extract a session id value embedded in request URL
  # if ( $c->request->path =~ /^(.*)\/\-\/(.+)$/ ) {
  # if ( $c->request->path =~ /^(.*)\/\-\/([^/]+)$/ ) {
    if ( $c->request->path =~ /^(.*)\/\-\/([0-9a-f]+)$/ ) {
        $c->request->path($1);
        $c->sessionid($2);
        $c->log->debug(qq/Found sessionid "$2" in path/) if $c->debug;
    }
    # XXX Shouldn't all of the above be conditonal on {rewrite} ?

    if ( my $cookie = $c->request->cookies->{session} ) {
        my $sid = $cookie->value;
        $c->sessionid($sid);
        $c->log->debug(qq/Found sessionid "$sid" in cookie/) if $c->debug;
    }

    $c->NEXT::prepare_action(@_);
}



# Return ref to a session data hash that the caller can use as they want.

sub session {
    my ( $c ) = @_;
    # warn sprintf "CgiS::session(%s) called from (%s,%s)\n", join('|',@_), ( caller() )[1,2];

    return  if ! $c->_cgi_session_created;

  # if ( my $cgis_dump = $c->session_dump(1) ) {
  #     $c->log->debug( $cgis_dump );
  # }

    return  $c->{_session_cgis}->{session_data};
}



sub _cgi_session_created {
    my ( $c ) = @_;
    # warn sprintf "CgiS::_cgi_session_created(%s) called from (%s,%s)\n", join('|',@_), ( caller() )[1,2];

    my $cgisess;

    # Is session area already present?
    if ( defined $c->{_session_cgis}
      && defined $c->{_session_cgis}->{cgisess} ) {
        $cgisess = $c->{_session_cgis}->{cgisess};
    }
    else {
        # We need to create the CGI::Session object and data.  If the
        # session is continued, we should find the sessiond id from
        # request cookie or path (see prepare_action).
        my  $sid = $c->sessionid;
        $cgisess = $c->_cgi_session_object_new( $sid );
    }

    return  $cgisess;
}


sub _cgi_session_object_new {
    my ( $c, $id_or_query ) = @_;

    # CGI::Session expects either a session id string or a "query object"
    # as the second argument in the call to new().
    #
    # For continued sessions we will have found the session id in cookie
    # or path and put it in the $id_or_query parameter.
    #
    # But if this is the first request, we don't have anything to give
    # CGI::Session.  This is very bad as CGI::Session might try to do a
    # call to CGI->new() out of a desire to resolve the lack of knowledge.
    #
    # We can supply a "query object" by giving CGIS the $c->request ref.
    # But CGIS will use its default session parameter name 'CGISESSID'
    # to poll ->cookie() and ->param() for values.  If a user request
    # should happen to have a form/URL parameter named 'CGISESSID' ?  XXX

    # Default the "id or query" parameter to our request object
    if ( ! defined $id_or_query ) {
        $id_or_query
            = Catalyst::Plugin::Session::CGISession::dummy_query->new();
    }

    my  $cgisess = $c->{session} = CGI::Session->new(
            $c->config->{session}->{cgis_dsn},
            $id_or_query,
            $c->config->{session}->{cgis_options},
        );

    if ( ! defined $cgisess ) {
        $c->log->error( "Unable to create CGI::Session object, "
                      . "error message was: '" . CGI::Session->errstr() . "'" );
        return undef;
    }

    # If a session object expiration time was set in the configuration,
    # ask CGI::Session to honor the time limit by setting expire time
    # on the whole session.
    my  $expires = $c->config->{session}->{expires};
    if ( $expires ) {
        $cgisess->expire( $expires );
    }

    # Start building our session-related data area

    # Save ref to CGI::Session object
    $c->{_session_cgis}->{cgisess} = $cgisess;

    # C::P::Session::FastMmap has established a convention that there is
    # one public session 'stash', a hash available to callers of ->session().
    # CGIS is closer to the CGI.pm param() method and allows access to
    # individually named parameters.
    # We will emulate the C::P::S::F method by using one CGIS parameter
    # named '_catalyst_session'

    my  $session_data_ref;

    # If this session is new, we need to initialize the session data
    # parameter to a created anonymous hash.
    if( $cgisess->is_new() ) {
        $session_data_ref = {};
    }
    else {
        # Restore the hash ref from session entry's persistent data
        $session_data_ref = $cgisess->param($SESSION_DATA_PARAMETER_NAME);
        if ( ! defined $session_data_ref ) {
            $session_data_ref = {};
        }
    }

    # We will make this hash ref available to callers, and save the
    #   entire hash at finalize()
    $c->{_session_cgis}->{session_data} = $session_data_ref;
    $cgisess->param( $SESSION_DATA_PARAMETER_NAME => $session_data_ref );

    # Set the visible session id from the CGI::Session object, in case
    #   the value was just created by CGIS
    $c->sessionid( $cgisess->id );

    if( $cgisess->is_new() ) {
        $c->log->debug( q{Created session '} . $c->sessionid . q{'});
    }
    else {
        $c->log->debug( q{Retrieved session '} . $c->sessionid . q{'});
    }

    return $cgisess;
}



sub _cgi_session_object_close {
    my ( $c ) = @_;

    my $cgisess = $c->{_session_cgis}->{cgisess};
    croak "Missing CGI::Session object" unless defined $cgisess;
    # warn sprintf "CgiS::_cgi_session_object_close() found CGI::S object %s\n", $cgisess;

    my  $session_data_ref = $c->{_session_cgis}->{session_data};

  # if ( my $cgis_dump = $c->session_dump(1) ) {
  #     $c->log->debug( $cgis_dump );
  # }

    my  $dump_requested_type = $c->{_session_cgis}->{session_dump_request};
    if ( $dump_requested_type
      && $c->debug  ) {
        my  $cgis_dump  = $c->session_dump( $dump_requested_type );
        if ( defined $cgis_dump ) {
            $c->log->debug( $cgis_dump );
        }
    }

    # The latest CGI::Session release suggests a small difference in
    # the best way to close session objects and write data to storage
    if ( $CGI::Session::VERSION >= 4 ) {
        $cgisess->flush;
    }
    else {
        $cgisess->close;
    }
}


# There are two places that the current session id value is stored, one
# using our accessor sessionid() and another residing in the CGI::Session
# object.  We'll trust the CGI::Session copy and work with that.

# But this is strange - we need to define which of these is most correct,
# lest some code use ->sessionid, such as the redirect-rewrite code below.

sub finalize {
    my ( $c ) = @_;
    # warn sprintf "CgiS::finalize(%s) called ...\n", join('|',@_);

    # If the rewrite feature is enabled, update redirect URL when defined
    # using ->sessionid
    if ( $c->config->{session}->{rewrite}
      && $c->sessionid
      && $c->response->redirect           ) {
        my $redirect = $c->response->redirect;
        $c->response->redirect( $c->uri($redirect) );
    }

    if ( defined $c->{_session_cgis}
      && defined $c->{_session_cgis}->{session_data} ) {

        my $cgisess = $c->{_session_cgis}->{cgisess};
        croak "Missing CGI::Session object" unless defined $cgisess;

        # Grab the session id before closing the CGIS object
        my  $sid = $cgisess->id;

        $c->_cgi_session_object_close();

        # The CGI::Session expiration time is reset on every session
        # access.  We'll apply the same logic to cookies, updating
        # on every request

        # Build the session id cookie.  We always include the
        #   session id and expires values.
        my  %cookie = (
                value   => $sid,
                expires => '+' . $c->config->{session}->{expires} . 's'
            );

        # If there are cookie-specific configuration values to add
        # to cookie.  Note that config 'expires' can override default.
        foreach my $option ( qw{ expires domain path secure } ) {
            my  $value = $c->config->{session}->{"cookie_$option"};
            if ( defined $value ) {
                $cookie{$option} = $value;
            }
        }
        # This cookie will be sent in response
        $c->response->cookies->{session} = \%cookie;

        # If rewrite was configured, update every URL in body text
        if ( $c->config->{session}->{rewrite}
          && $c->sessionid
          && defined $c->res->body
          && length  $c->res->body            ) {
            my $finder = URI::Find->new(
                sub {
                    my ( $uri, $orig ) = @_;
                    my $base = $c->request->base;
                    return $orig unless $orig =~ /^$base/;
                    return $orig if $uri->path =~ /\/-\//;
                    return $c->uri($orig);
                }
            );
            $finder->find( \$c->res->{body} );
        }
    }

    return $c->NEXT::finalize(@_);
}




sub uri {
    my ( $c, $uri ) = @_;
    if ( my $sid = $c->sessionid ) {
        $uri = URI->new($uri);
        my $path = $uri->path;
        $path .= '/' unless $path =~ /\/$/;
        $uri->path( $path . "-/$sid" );
        return $uri->as_string;
    }
    return $uri;
}


# -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
#   Additional pass-through APIs for specialized CGI::Session features

sub session_param {
    my  $c = shift;
    # warn sprintf "CgiS::param(%s) called from (%s,%s)\n", join('|',@_), ( caller() )[1,2];

    my  $cgisess = $c->_cgi_session_created;
    return  if ! defined $cgisess;

    return $cgisess->param(@_);
}


sub session_expire {
    my  $c = shift;
    # warn sprintf "CgiS::expire(%s) called from (%s,%s)\n", join('|',@_), ( caller() )[1,2];

    my  $cgisess = $c->_cgi_session_created;
    return  if ! defined $cgisess;

    return $cgisess->expire(@_);
}


sub session_flush {
    my ( $c ) = @_;
    # warn sprintf "CgiS::flush(%s) called from (%s,%s)\n", join('|',@_), ( caller() )[1,2];

    my  $cgisess = $c->_cgi_session_created;
    return  if ! defined $cgisess;

    return $cgisess->flush();
}


sub session_delete {
    my ( $c ) = @_;
    # warn sprintf "CgiS::delete(%s) called from (%s,%s)\n", join('|',@_), ( caller() )[1,2];

    my  $cgisess = $c->_cgi_session_created;
    return  if ! defined $cgisess;

    return $cgisess->delete();
}


sub session_is_new {
    my ( $c ) = @_;
    # warn sprintf "CgiS::is_new(%s) called from (%s,%s)\n", join('|',@_), ( caller() )[1,2];

    my  $cgisess = $c->_cgi_session_created;
    return  if ! defined $cgisess;

    return $cgisess->is_new();
}



sub session_dump {
    my ( $c, $type ) = @_;
    # warn sprintf "CgiS::session_dump(%s) called from (%s,%s)\n", join('|',@_), ( caller() )[1,2];

    return  if ! defined $c->{_session_cgis};
    my $cgisess = $c->{_session_cgis}->{cgisess};
    return  if ! defined $cgisess;

    my  $cgis_dump;
    if ( $type == SESSION_DUMP_DATA ) {
        my  $data_ref  = $c->{_session_cgis}->{session_data};
        $cgis_dump = Data::Dumper->Dump([ $data_ref ],['*cgis_session_data']);
    }
    elsif ( $type == SESSION_DUMP_PARAMS ) {
        my  $data_ref  = $cgisess->dataref();
        $cgis_dump = Data::Dumper->Dump([ $data_ref ],['*cgis_data']);
    }
    elsif ( $type == SESSION_DUMP_DATA ) {
        $cgis_dump = $cgisess->dump();
    }

    return  $cgis_dump;
}


sub session_dump_at_close {
    my ( $c, $type ) = @_;
    # warn sprintf "CgiS::dump_at_close(%s) called from (%s,%s)\n", join('|',@_), ( caller() )[1,2];

    return  if ! defined $c->{_session_cgis};

    if ( defined $type
      && $type >= SESSION_DUMP_DATA
      && $type <= SESSION_DUMP_SESSION ) {
        $c->{_session_cgis}->{session_dump_request} = $type;
    }
    # XXX should we allow a value that "turns off" the current value?

    # Return the current setting
    return  $c->{_session_cgis}->{session_dump_request};
}


# -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -


1; # Magic true value required at end of module
__END__


# We need to check under what conditions CGIS might try to access CGI
# parameters by itself.
#   - query()
#   uses query()
#       - header() aka http_header()
#       - cookie()
#       - save_param()
#       - load_param()
#       - load()        <<== whoa! We need to prevent this!
#             Do we need to supply a query object to CGIS from $c->request ????
#             See internal object param _QUERY, set from load() from new()
# We can supply a "query object" by giving CGIS the $c->request ref.
# But CGIS will use its default session parameter name 'CGISESSID'
# to poll ->cookie() and ->param() for values.  If a user request
# should happen to have a form/URL parameter named 'CGISESSID' ?  XXX
#
# I could create a dummy package and bless an object into it, that
# simply returns undef for every call to ->param() or ->cookie() ?


# -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -


=head1 NAME

Catalyst::Plugin::Session::CGISession - use CGI::Session for persistent session data


=head1 VERSION

This document describes Catalyst::Plugin::Session::CGISession version 0.0.1


=head1 SYNOPSIS

    use Catalyst  qw{ ... Session::CGISession ... };

    MyApp->config->{session} = {
    	expires	  => 3600,
        rewrite   => 1,
    };

    $c->session->{user_email} = 'quibble@dibble.edu';

    # Later, in another following request:

    $smtp->to( $c->session->{user_email} );


=head1 DESCRIPTION

=for author to fill in:
    Write a full description of the module and its features here.
    Use subsections (=head2, =head3) as appropriate.

This plugin provides the same functionality as the original
L<Session::FastMmap|Catalyst::Plugin::Session::FastMmap> plugin but uses the
L<CGI::Session|CGI::Session> module for the session data management.

The motivations to develop this plugin were:

=over 4

=item *
      provide better session data expiration handling, as is
      available through the CGI::Session module


=item *
      provide an easier migration to Catalyst for applications that
      have been using CGI::Session and its param() and other methods


=item *
      allow Windows users to avoid the workarounds needed to make
      Cache::FastMmap work

=back

The difference in session expiration between this plugin and
C<Session::FastMmap>
is small but important.  CGI::Session resets the expiration time limit
on every access to the session.  A one day time limit means the session
data disappears 24 hours after the I<last> request using that session.
With Session::FastMmap the limit would be 24 hours after the I<first>
request, when the session is created.

While this plugin adds some functions and methods beyond those available
with C<Session::FastMmap>,
new development most likely should avoid using these features.
Try to use only the common feature, L<session()|/session>,
to stay compatible with C<Session::FastMmap>
and other future session plugins.


=head1 INTERFACE

=head2 PUBLIC METHODS

=head3 session

Returns a hash reference that the caller can use to store persistent
data items.
Everything stored into this hash will be saved to storage when a
request completes.  Upon the next request with the same session id
the saved data will again be available through this method.

This method performs the same functions as Session::FastMmap::session.

=head3 uri

Extends an uri with session id if needed.
This is used when the C<{rewrite}> configuration option is enabled.

    my $uri = $c->uri('http://localhost/foo');

This method performs the same functions as Session::FastMmap::uri.


=head2 EXPOSED CGI::SESSION METHODS

Applications might require some of the specialized features of CGI:Session.
A small number of CGI::Session methods are exposed through this plugin.


=head3 session_param

A single session data hash may be too restrictive for some applications.
In particular, some applications may want to expire individual data items
separately, as is allowed by CGI::Session.  See the CGI::Session
L<C<param()>|CGI::Session/"param"> method documentation for more details.


=head3 session_expire

Setting a data item-specific expiration time is done with the CGI::Session
L<expire()|CGI::Session/expire> method.  Please see that documentation
for details.

=head3 session_is_new

It may be useful for applications to know when a session is newly created
and not a continuation of a previous session.  This is usually detectable
by checking for missing previous values.  But if an application really has
to know, the CGI::Session L<is_new()|CGI::Session/is_new> method
will tell you.  Please see that documentation for details.

=head3 session_flush

The persistent session data hash is written to backing storage at the end
of every request.  If for some reason an application needs to force an
update early, this method will call the
CGI::Session L<flush()|CGI::Session/flush> method.

=head3 session_delete

Calls the CGI:Session L<delete()|CGI::Session/delete> method which marks
the session as "to be deleted."  Note that the session data is not actually
deleted from storage until the current request finishes, or if you
explicitly call C<session_flush()>.

=head3 session_dump

=head3 session_dump_at_close

CGI::Session provides a  L<dump()|CGI::Session/dump> method as a
convenience during testing.  This plugin extends that method to dump a
varying amount of data and also postponing the request, dumping the data
at end of request into the debug log.

C<session_dump()> will immediately return a string of formatted dump data.
C<session_dump_at_close()> will wait until end of request processing and
then dump the session data into the debug log just before the data is
written to backing storage.

You may specify how much data to dump using a single number value:

=over 4

=item * =1   dump the session data hash returned by  L< C<session()>|/session>

=item * =2   dump the whole CGI::Session parameters hash, including
             parameters set using L< C<session_param()>|/session_param>

=item * =3   dump the entire CGI::Session object

=back

    my $dumped_hash_string = $c->session_dump(1);

will return a string containing the Data::Dumper formatted dump of the
session hash.

    $c->session_dump_at_close(2);

specifies that at end of request processing, the usual session data hash and
also any other parameters should be displayed in the Catalyst debug log.


=head2 EXTENDED CATALYST METHODS

=head3 setup

Check session-related configuration values and default those not
set from the configuration.


=head3 prepare_action

This method attempts to determine the session id for the current request in
two different ways.

First it checks whether a session id has been embedded within the
request URL path.  This is signaled by the sequence C<'/-/'> followed
by
a session id.  If this is found then the request path is truncated
to only the part preceding the session id marker C<'/-/'>.  The part
following the marker is used to set C<$c-E<gt>sessionid()>

The second method is to check for a cookie with the name 'session'
sent in the request.  If found then the cookie value is used to
set C<$c-E<gt>sessionid()>.

If a session id is found by both methods the value from the cookie
will be used.

=head3 finalize

This method is called as part of the end of request processing chain.

If session data has been created or read then this method is responsible for
writing session data out to backing storage.

If the C<rewrite> configuration option is enabled then URI rewriting
is also performed on body text and any redirect URL.


=head1 CONFIGURATION AND ENVIRONMENT

Session::CGISession uses configuration options as
found in C<$c-E<gt>config-E<gt>{session}> data.

=head2 CONFIG OPTIONS FOR MODULE

=head3 expires

How many seconds until the session expires. The default is 24 hours.

Note that the underlying CGI::Session handler resets the session expiration
time upon every access.  Thus a session will not normally expire until this
many seconds have elapsed since the I<last> access to the session.  This is
a useful difference from the Session::FastMmap plugin which sets the
expiration time of a session only once at session creation.


=head3 rewrite

One method for remembering the current session id value from one request
to the next is to embed the session id into every request URL.  If the
user has disabled cookies in their browser this is the only way to pass
session id from one request to another.

When this option is enabled the module will attempt to add the session id
to every URL in the response output.  In addition it will update a
redirect URL when redirect is used.

See method C<uri()>

This configuration option requests the same feature as Session::FastMmap provides.

=head2 CONFIG OPTIONS FOR COOKIES

=head3 cookie_expires

how many seconds until the session cookie expires at the client browser.
See expires option in L<CGI::Cookie|CGI::Cookie> for format.
default is the expires option described above.  This option will
override the default when specified.

=head3 cookie_domain

Domain set in the session cookie.
See domain option in L<CGI::Cookie|CGI::Cookie> for format.
default is none.

=head3 cookie_path

Path set in the session cookie.
See path option in L<CGI::Cookie|CGI::Cookie> for format.
default is none.

=head3 cookie_secure

Secure flag set in the session cookie.
See secure option in L<CGI::Cookie|CGI::Cookie> for format.
default is none.



=head2 CONFIG OPTIONS FOR CGI::SESSION

You may want to explicitly control how and where CGI::Session stores
session data files.  While this module provides defaults
for parameters to CGI::Session, your needs may require specific values.

You may specify values to be given directly to the CGI::Session C<new()>
method using the C<cgis_dsn> and C<cgis_options> configuration parameters.

=head3 cgis_dsn

This option value becomes the first argument to the CGI::Session
L<C<new()>|CGI::Session/new> call, C<$dsn> or B<Data Source Name>.  This parameter
can configure the backing storage type, the method for serializing data,
and the method for creating session id values.  It is a combination
of one, two or three specifications.

The default value used by this module is:

    $c->config->{session}->{cgis_dsn}
            = 'driver:File;serializer:Storable;id:MD5';


=head3 cgis_options

Some of the driver, serializer and id generation modules used with
CGI::Session can be given additional parameters to control how they
work.  One obvious example is telling the plain file driver what
directory to use when storing session files.

You may use this hash value to supply these additional parameters,
given to CGI::Session C<new()> as the third argument.
These are named parameters and so you must use a hash reference.
An example in code would be:

    $c->config->{session}->{cgis_options}
            = {
                DataSource  => 'dbi:mysql:database=warren;host=rabitton',
                User        => 'flopsie',
                Password    => 'furryface',
              };

An example in the form of a section from a YAML file would be:

    session:
        cgis_dsn: driver:mysql;serializer:Storable;id:MD5
        cgis_options:
            DataSource: dbi:mysql:database=warren;host=rabitton
            User: flopsie
            Password: furryface


Details about the various parameters for drivers and id generation
modules can be found in the L<CGI::Session|CGI::Session/distribution> documentation.

Database driver modules support the following parameters:

  DataSource - the DSN value given to DBI->connect()

  Handle     - a DBI database handle object ($dbh), if already connected

  TableName  - name of the table where session data will be stored

  User       - user privileged to connect to the database defined in DataSource

  Password   - password of the same user

Individual drivers support other parameters, such as:

  file          Directory     where session files will be stored

  db_file       FileName      location of the Berkely DB file

  postgresql    ColumnType    value 'binary' might be needed


The default value used by this module (to match the above default
for cgis_dsn) is:


    $c->config->{session}->{cgis_options}
            = {
                Directory => File::Spec->tmpdir()
              };


=head2 SPECIALIZED OPTIONS FOR CGI::SESSION

CGI::Session has some settings which are not easily specified using
the available API calls.  Unfortunately a number of these can be set
only by storing into global variables.

If you need to change the default values of these CGI::Session settings
you will have to manage to do this in your code, before this plugin module
is called by the C<MyApp-E<gt>setup()> call.

An example will illustrate this.  Suppose that the default values for
C<cgis_dsn> and C<cgis_dsn> are satisfactory, but you want to change
the naming of session files created by the default CGI::Session File
driver.  That driver's default for filenames is C<'cgisess_%s'> and you
would rather use C<'myapp_%s.ses'>.


    use CGI::Session::Driver::file;
    use Catalyst  qw{ ... Session::CGISession ... };

    __PACKAGE__->config->{session} = {
    	expires	  => 7 * 24 * 60 * 60,
        rewrite   => 1,
    };

    $CGI::Session::Driver::file::FileName = 'myapp_%s.ses';

    __PACKAGE__->setup();

The plugin module is not initialized until the call to C<setup()>.
Any prior modifications to the defaults of CGI::Session will be
available to the plugin.

If you are using CGI::Session 3.x you would have to code:

    use CGI::Session::File;

    $CGI::Session::Driver::FileName = 'myapp_%s.ses';


=for great knowledge
     $s = new CGI::Session("driver:file", $sid, {Directory=>'/tmp'});
    Naming conventions of session files are defined by
    $CGI::Session::Driver::file::FileName global variable. Default value of this
    variable is cgisess_%s, where %s will be replaced with respective session ID.
    Should you wish to set your own FileName template, do so before requesting for
    session object:
        $CGI::Session::Driver::file::FileName = "%s.dat";
        $s = new CGI::Session();
    For backwards compatibility with 3.x, you can also use the variable name
    $CGI::Session::File::FileName, which will override one above.
    DRIVER ARGUMENTS
    The only optional argument for file is Directory, which denotes location of the
    directory where session ids are to be kept. If Directory is not set, defaults
    to whatever File::Spec->tmpdir() returns. So all the three lines in th
  db_file
        $s = new CGI::Session("driver:db_file", $sid, {FileName=>'/tmp/cgisessions.db'});
    db_file stores session data in BerkelyDB file using DB_File - Perl module. All
    sessions will be stored in a single file, specified in FileName driver argument
    as in the above example. If FileName isn't given, defaults to
  mysql
        $s = new CGI::Session("driver:mysql", undef, {
                                            TableName=>'my_sessions',
                                            DataSource=>'dbi:mysql:shopping_cart'});
        $s = new CGI::Session( "driver:mysql", $sid, { Handle => $dbh } );
                                                       ^^^^^^
  postgresql
        $session = new CGI::Session("driver:PostgreSQL", undef,
                {Handle=>$dbh, ColumnType=>"binary"});
                 ^^^^^^        ^^^^^^^^^^
  sqlite
        $s = new CGI::Session("driver:sqlite", undef, {TableName=>'my_sessions'});
    DataSource should be in the form of dbi:SQLite:dbname=/path/to/db.sqlt.
        $s = new CGI::Session("driver:sqlite", $sid, {DataSource=>'/tmp/sessions.sqlt'});
        $s = new CGI::Session("driver:sqlite", $sid, {Handle=>$dbh});
  all database drivers
    Following driver arguments are supported:
    DataSource - First argument to be passed to DBI->connect().
    User      - User privileged to connect to the database defined in DataSource.
    Password  - Password of the User privileged to connect to the database defined in DataSource
    Handle    - To set existing database handle object ($dbh) returned by DBI->connect(). Handle will override all the above arguments, if any present.
    TableName - Name of the table session data will be stored in.


=head1 DIAGNOSTICS

=for author to fill in:
    List every single error and warning message that the module can
    generate (even the ones that will "never happen"), with a full
    explanation of each problem, one or more likely causes, and any
    suggested remedies.

There are conditions where CGI::Session will be unable to create a
session object.  The most likely causes are misconfigured options or
unavailable modules.

When CGI::Session returns an error the error message will be repeated in
the Catalyst error log.  Below is an example error message resulting
from a misspelled name in the C<cgis_dsn> configuration parameter:

  [Thu ... 2005] [catalyst] [e]
    Unable to create CGI::Session object, error:
      'new(): failed: couldn't load CGI::Session::Serialize::storrable:
          Can't locate CGI/Session/Serialize/storrable.pm in @INC

Please note that CGI::Session 3.x DSN names are case-sensitive.
While "driver:mysql" works under CGIS 4.x, it must be "driver:MySQL"
when using CGIS 3.x.


=head1 DEPENDENCIES

=for author to fill in:
    A list of all the other modules that this module relies upon,
    including any restrictions on versions, and an indication whether
    the module is part of the standard Perl distribution, part of the
    module's distribution, or must be installed separately. ]

This module was developed using the first CGI::Session 4.00 release.
It was subsequently tested under 3.95, the last 3.x version.

Testing has been done using:

    Windows XP

        CGI::Session 4.00   'File' driver

        CGI::Session 4.00   MySQL 3.23.x

        CGI::Session 3.95   MySQL 3.23.x
            Note: driver name case sensitivity, e.g.
                cgis_dsn: driver:MySQL;serializer:Storable;id:MD5
            Note: TableName not available, must use global variable, e.g.
                $CGI::Session::MySQL::TABLE_NAME = 'myapp_sessions';

        CGI::Session 3.95   'File' driver
            Note: different global variable $CGI::Session::File::FileName

    Linux

        CGI::Session 3.95   'File' driver
            Note: this driver leaves session data tainted

        CGI::Session 3.95   MySQL 3.23.x

=for documentor:
        Planned:
        CGI::Session 4.00   'File' driver
        CGI::Session 4.00   MySQL 3.23.x


=head1 INCOMPATIBILITIES

=for author to fill in:
    A list of any modules that this module cannot be used in conjunction
    with. This may be due to name conflicts in the interface, or
    competition for system or program resources, or due to internal
    limitations of Perl (for example, many modules that use source code
    filters are mutually incompatible).

None reported.


=head1 BUGS AND LIMITATIONS

=for author to fill in:
    A list of known problems with the module, together with some
    indication Whether they are likely to be fixed in an upcoming
    release. Also a list of restrictions on the features the module
    does provide: data types that cannot be handled, performance issues
    and the circumstances in which they may arise, practical
    limitations on the size of data sets, special cases that are not
    (yet) handled, etc.

No bugs have yet been reported.

Please report any bugs or feature requests to
C<bug-catalyst-plugin-session-cgisession@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.

=head2 Catalyst Plugin Module Order

Other Catalyst plugin modules may rely upon session data in order to
correctly initialize themselves.  This may require some care in the
order that plugin modules are named to Catalyst.

For instance, the C::P::Authentication::CDBI module expects to find
C<$c-E<gt>session-E<gt>{user}> and C<$c-E<gt>session-E<gt>{user_id}>
from any previous session for logged-in users.

Thus when defining the order of plugins you should take care that the
session modules like C::P::Session::CGISession are loaded before any
module that might need session data.

    use Catalyst qw{    ...
                     Session::CGISession
                     Authentication::CDBI
                        ...
                   };

=head1 SEE ALSO

=over 4

=item  L<Catalyst|Catalyst>

=item  L<Catalyst::Plugin::Session::FastMmap|Catalyst::Plugin::Session::FastMmap>

=item  L<Catalyst::Plugin::Session::Flex|Catalyst::Plugin::Session::Flex>

=item  L<CGI::Session|CGI::Session>

=item  L<CGI::Cookie|CGI::Cookie>

=back

=head1 THANKS

To Christian Hansen, from whose test program implementation of
CGI::Session use I borrowed extensively,

To Andy Grundman, for the solution to poking cookie values,

To Sebastian Riedel and Marcus Ramberg, for the
Catalyst::Plugin::Session::FastMmap module used to get me started,

And to them and the rest of the contributors to Catalyst, for a great start!


=head1 AUTHOR

Thomas L. Shinnick  C<< <tshinnic@cpan.org> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2005, Thomas L. Shinnick C<< <tshinnic@cpan.org> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

=cut

#  vim:ft=perl:ts=4:sw=4:et:is:hls:ss=10:
