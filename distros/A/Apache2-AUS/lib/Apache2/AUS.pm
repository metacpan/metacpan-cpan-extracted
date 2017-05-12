package Apache2::AUS;

use 5.006;
use strict;
use warnings;
use Apache2::RequestRec ();
use Apache2::RequestUtil ();
use Apache2::Request ();
use Apache2::AUS::RequestRec ();
use Apache2::AUS::Util qw(
    create_session bake_session_cookie set_remote_user
    check_requirement auth_failure go
);
use Apache2::Const qw(OK FORBIDDEN DECLINED AUTH_REQUIRED);
use Apache2::Access;
use Apache2::Log;
use Carp qw(verbose);

our $VERSION = "0.02";

return 1;

sub Init {
    my($class, $r) = @_;
    
    my $session = $r->aus_session || create_session($r);
    my $use_count = $session->param('_use_count');
    $use_count ++;
    $session->param('_use_count', $use_count);
    $r->headers_out->add('Set-Cookie', bake_session_cookie($r, $session));
    $r->aus_session($session);
    $r->push_handlers(PerlFixupHandler => \&_Fixup);

    if(my $u = $session->user) {
        $r->user($u->{id});
    }
    
    return OK;
}

# Save our session before handling the Response phase.
# This ensures that other things touching the session (eg; CGI)
# will have a current copy they can load and save, as well as
# making sure we don't save over their changes when $r
# goes out of scope.

sub _Fixup {
    my $r = shift;
    my $session = $r->aus_session;
    $session->flush;
    return OK;
}

sub Response {
    my($class, $r) = @_;
    my $session = $r->aus_session;
    my $req = Apache2::Request->new($r, DISABLE_UPLOADS => 1);
    my $table = $req->param;
    my $go = $table->{go} || '/';
    my $go_error = $table->{go_error} || $go;
    
    if($table->{logout}) {
        $session->logout;
        return go($r, $go);
    } elsif($table->{user} && $table->{password}) {
        my $user = eval { $session->login(@$table{'user','password'}); };
        my $err = $@;
        $session->_set_status($session->STATUS_MODIFIED);
        $session->flush;
        if($err) {
            auth_failure($r, $err);
            return go($r, $go_error);
        } else {
            $r->user($user->{id});
            return go($r, $go);
        }
    } else {
        $r->subprocess_env('Username or password not specified.');
        return go($r, $go_error);
    }
}

sub Authen {
    my($class, $r) = @_;
    my $requires = $r->requires;
    if($requires && scalar(@$requires)) {
        my $session = $r->aus_session;
        my $user = $session->user;
        foreach (
            map { [ split(" ", $_->{requirement}) ] } (@$requires)
        ) {
            unless(check_requirement($r, $_)) {
                $r->log_reason(sprintf(
                    qq{[%s] %d(%s) does not satisfy requirement "%s"},
                    $r->connection->remote_ip,
                    ($user ? $user->{id} : 0), ($user ? $user->{name} : ""),
                    join(" ", @$_), $r->uri
                ));
                
                return FORBIDDEN;
            }
        }
        return OK;
    } else {
        return OK;
    }
}

=pod

=head1 NAME

Apache2::AUS - Authorization, Users, and Sessions for Apache2.

=head1 SYNOPSIS

In httpd.conf:

  PerlModule            Apache2::AUS
  PerlInitHandler       Apache2::AUS->Init

Then in a mod_perl handler:

  my $session = $r->aus_session;
  if($session->param('foo')) {
      ...
  }

=head1 DESCRIPTION

B<Note:> I<This is an alpha release. The interface is somewhat stable and
well-tested, but other changes may come as I work in implementing this on
my website.>

C<Apache2::AUS> is a mod_perl package that provides access to
C<Schema::RDBMS::AUS> sessions and users from Apache2. For a more
detailed description of Authentication, Users, and Sessions with
Schema::RDBMS::AUS, see L<it's documentation|Schema::RDBMS::AUS>.
Environment variables and some other required settings are documented
there.

This document focuses on how to use the apache2 bindings to access
(or restrict access based upon) Schema::RDBMS::AUs's
users, groups, and sessions:

=head1 ACCESS TO THE SESSION OBJECT

The C<AUS_SESSION_ID> envrionment variable is set by the
L<Schema::RDBMS::AUS|Schema::RDBMS::AUS> package for each request,
so you can look up the session data manually in the database if you
want, or initialize your own L<CGI::Session::AUS|CGI::Session::AUS>
object to manipulate it. Apache2::AUS will flush all of it's changes
to the session object just before apache's C<HTTP Response> phase,
so you should always have the most current information and be able
to save your changes safely. Here's an example of how to obtain the
session from a CGI script:

  #!perl

  use strict;
  use warnings;
  use CGI;
  use CGI::Session::AUS;
  
  my $cgi = CGI->new;
  
  my $session = CGI::Session::AUS->new
      or die "I need a session object to continue!";
  
  if($session->param("has_cheese")) {
    print $cgi->header, "You have cheese!\n";
    exit;
  }

When operating under mod_perl, it's usually more efficient to pick up
the existing session object yourself. L<Apache2::AUS|Apache2::AUS> makes
this convienent for you by adding an "aus_session" method which you can
use in your own mod_perl handlers:

  sub handler {
    my $r = shift;
    my $session = $r->aus_session
        or die "I need a session to continue!";
        
    if($session->user) {
      ...
    }
  }

See L<CGI::Session::AUS|CGI::Session::AUS> and L<CGI::Session|CGI::Session>
for more information about the session object.

=head1 HANDLERS

All handlers should be called as "class methods" in your C<httpd.conf>, eg:

  <Location /login>
    PerlResponseHandler   Apache2::AUS->Response
  </Location>

=over

=item Init

The C<Init> handler ensures that a session has been attached to this
HTTP request. If the client specified a session ID, that session is loaded
into Apache's request record. Otherwise, a new one is created. This handler
also sends the session cookie back to the user's web browser, and sets
"$r->user" (C<REMOTE_USER> environment variable)

This handler should be applied to every request where having a session
may be useful. Eg;

  <VirtualHost www.myhost.com>
    DocumentRoot /home/myhost/htdocs
    PerlInitHandler     Apache2::AUS->Init
  </VirtualHost>

This handler will also install another handler into to
ensure that your session is saved at the end of each request. See
L</_Fixup> below.

This handler always returns OK.

=item Response

In Apache2::AUS, the C<Response> handler is responsible for logging the user
in. This handler will read any GET / POST arguments (via
L<Apache2::Request|Apache2::Request> so other handlers can use them later).
If "user" and "password" are supplied, a login will be attempted under that
user id. If "logout" is supplied, any logged-in user will be logged out.

If the login was unsuccessful, the AUS_AUTH_FAILURE environment
variable will be set to a string containing the reason why.

This handler always returns OK, and will do an internal redirect to a page
based on the "go" and "go_error" GET / POST arguments;

=over

=item go

The user will be redirected here if the login was successful, or a logout
was requested.

=item go_error

The user will be redirected here if the login was unsuccessful, or if no
login or logout was requested.

=back

Keep in mind these are B<internal> redirects. Apache rewrites environment
variables when doing an internal redirect, so to check for the reason a
login failed, you should check the C<REDIRECT_AUS_AUTH_FAILURE> environment
variable.

=item Authen

The C<Authen> handler is responsible for determining if the current user
is allowed to access a page. The authorization requirements are specified
using apache's standard "require" directive.

The following "require"ments are recognized:

=over

=item valid-user

You must be logged in to view this page.

=item user-id

You must be logged in as one of the specified user ID's to view this page.

Example:

  # only users 4, 10, and 20 may view this page.
  require user-id 4 10 20

=item user-name

You must be logged in as one of the specified user names to view this page.

Example:

  # bob, job, and nob can view this area.
  require user-name bob job nob

=item flag

One of the specified flags must be set to view this page, either on the
requesting user, or a group that user is a member of:

Examples:

  # If you have either the "Cool" or "Neat" flags set, you can view this page
  require flag cool neat
  
  # You need both "dirty" and "smelly" flags to view this page.
  require flag dirty
  require flag smelly

=back

=back

=head1 EXAMPLES

See the "examples/" directory for httpd.conf examples, and samples on
how to manipulate Apache2::AUS sessions from different environments
and scripting languages.

=head1 TODO

=over

=item *

Fix the kludginess of the login handler. It's the only thing that reads
GET/POST arguments, but the whole go/go_error setup seems imperfect to me
right now. If you come up with a better solution, patches are welcome. :)

=item *

Add examples for using Apache2::AUS from PHP and Ruby on Rails, and evolve
the Apache2::AUS/Schema::RDBMS::AUS interfaces to make this easier.

=item *

Add many more unit tests.

=item *

Bring documentation up-to-date with API.

=back

=head1 AUTHOR

Tyler "Crackerjack" MacDonald <japh@crackerjack.net>

=head1 LICENSE

Copyright 2006 Tyler "Crackerjack" MacDonald <japh@crackerjack.net>

This is free software; You may distribute it under the same terms as perl
itself.

=head1 SEE ALSO

L<Schema::RDBMS::AUS>, L<CGI::Session::AUS>, L<http://perl.apache.org/>.

=cut
