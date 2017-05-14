package Apache2::UserDirAuthz;

use strict;
use warnings;

use Apache2::Access ();
use Apache2::RequestRec;
use Apache2::RequestUtil ();
use Apache2::ServerRec;

use Apache2::Const -compile => qw(OK HTTP_UNAUTHORIZED);

sub handler {
    my $r = shift;

    my $user = $r->user;
    unless (defined($user)) {
        $r->server->log_error("Apache2::UserDirAuthz: no user");
        $r->note_basic_auth_failure;
        return Apache2::Const::HTTP_UNAUTHORIZED;
    }

    my $uri = $r->uri;
    my $userdirrealms = $r->dir_config('userdirrealms');

    my $allowed_prefix = $user;
    if ($user =~ /\@/ and defined($userdirrealms)) {
        # This doesn't allow for realms with commas in their names.  Note
        # PerlSetVar can only take a single value.  Is there an equivalent
        # for multivalued things?
        for my $realm (split(',', $userdirrealms)) {
            if ($user =~ /(.*)\@$realm$/) {
                $allowed_prefix = $1;
            }
        }
    }

    # Note that the slashes below are literal, not re delimiters.
    if ($uri =~ m,^/${allowed_prefix}/,) {
            return Apache2::Const::OK;
    }

    $r->server->log_error("Apache2::UserDirAuthz: user '$user' not allowed access to location '$uri'");
    $r->note_basic_auth_failure;
    return Apache2::Const::HTTP_UNAUTHORIZED;
}

1;

=head1 NAME

Apache2::UserDirAuthz - simple one directory per username access control

=head1 SYNOPSIS

    PerlSetVar userdirrealms example.org,example.com
    
    <Location />
        AuthType Kerberos     # should work with any authtype
        Require valid-user
        PerlAuthzHandler Apache2::UserDirAuthz
    </Location>

=head1 DESCRIPTION

When used as a PerlAuthzHandler with Apache+mod_perl, Apache2::UserdirAuthz
will perform simple access control, where each user has access to the
part of the hierarchy named after their username.  For example, a
user "tom" will have access to all locations under C</tom/>, such as
C</tom/index.html>, C</tom/logo.png>, and so on.

If the username contains an @, the part after the @ can be conditionally
stripped off by setting C<userdirrealms> with C<PerlSetVar>.  This is
useful when using with Kerberos, where usernames are of the form
C<user@realm>.  To set realm stripping for multiple realms, separate
with commas, as demonstrated in the SYNOPSIS.

Any requests for paths outside the user's own prefix result in a 401
response (the handler returns C<Apache2::Const::HTTP_UNAUTHORIZED>).

If the username contains a slash, this is taken literally when
constructing the prefix for the (path portion of the) URI.  So, if
the username is C<host/foo.example.org@EXAMPLE.ORG>, and the
C<EXAMPLE.ORG> realm is stripped, then the user will have access
to URIs under C</host/foo.example.org/>.

=head1 AUTHOR

Tom Jones <tom.jones@bccx.com>

=cut
