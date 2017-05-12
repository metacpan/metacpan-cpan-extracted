# $Id: AuthTypeKey.pm 1887 2005-11-10 20:37:21Z btrott $

package Apache::AuthTypeKey;
use strict;

our $VERSION = '0.03';

use Authen::TypeKey;
use mod_perl;
use constant MP2 => $mod_perl::VERSION >= 1.99;
BEGIN {
    require base;
    if (MP2) {
        require Apache2::Const;
        Apache2::Const->import(-compile => qw( SERVER_ERROR ));
        base->import(qw( Apache2::AuthCookie ));
    } else {
        require Apache::Constants;
        Apache::Constants->import(qw( SERVER_ERROR ));
        base->import(qw( Apache::AuthCookie ));
    }
}

sub authen_cred {
    my($self, $r, @cred) = @_;
    my $token = $r->dir_config('TypeKeyToken');
    unless ($token) {
        $r->log_error('TypeKeyToken is required');
        return;
    }
    my $tk = Authen::TypeKey->new;
    $tk->token($token);
    $tk->version(1.1);
    my $key = $r->args;
    my $q = Apache::AuthTypeKey::Query->new($key);
    my $res = $tk->verify($q);
    unless ($res) {
        $r->log_error('TypeKey verification failed: ' . $tk->errstr);
    }
    $q->delete('destination');
    $res ? $q->as_string : undef;
}

sub authen_ses_key {
    my($self, $r, $key) = @_;
    my $token = $r->dir_config('TypeKeyToken');
    unless ($token) {
        $r->log_reason('TypeKeyToken is required');
        return MP2 ? Apache::SERVER_ERROR() : Apache::Constants::SERVER_ERROR();
    }
    my $tk = Authen::TypeKey->new;
    $tk->token($token);
    $tk->version(1.1);
    ## When checking the validity of the session key, we need to skip the
    ## expiration check on the signature.
    $tk->skip_expiry_check(1);
    my $res = $tk->verify(Apache::AuthTypeKey::Query->new($key));
    $res ? $res->{name} : undef;
}

## This is needed for 2 reasons:
## 1. Authen::TypeKey currently expects a Query-type object.
## 2. Apache->args breaks on '=' signs in the key/value pairs.
package Apache::AuthTypeKey::Query;
use URI::Escape qw( uri_escape uri_unescape );

sub new {
    my $class = shift;
    my($key) = @_;
    my %p;
    for my $p (split /&/, $key) {
        my($k, $v) = split /=/, $p, 2;
        $p{uri_unescape($k)} = uri_unescape($v);
    }
    bless \%p, $class;
}

sub param  { $_[0]{$_[1]}        }
sub delete { delete $_[0]{$_[1]} }

sub as_string {
    my $q = shift;
    my @s;
    while (my($k, $v) = each %$q) {
        push @s, uri_escape($k) . '=' . uri_escape($v);
    }
    join '&', @s;
}

1;
__END__

=head1 NAME

Apache::AuthTypeKey - Apache authorization handler using TypeKey

=head1 SYNOPSIS

    ## In httpd.conf or .htaccess:
    PerlModule Apache::AuthTypeKey
    PerlSetVar TypeKeyPath /
    PerlSetVar TypeKeyLoginScript /login.pl

    ## These documents require user to be logged in.
    <Location /protected>
    AuthType Apache::AuthTypeKey
    AuthName TypeKey
    PerlAuthenHandler Apache::AuthTypeKey->authenticate
    require valid-user
    PerlSetVar TypeKeyToken your_token
    </Location>

    ## This is the _return URL that the login.pl script should point to.
    <Location /login-protected>
    AuthType Apache::AuthTypeKey
    AuthName TypeKey
    SetHandler perl-script
    PerlHandler Apache::AuthTypeKey->login
    PerlSetVar TypeKeyToken your_token
    </Location>

=head1 DESCRIPTION

I<Apache::AuthTypeKey> implements Apache authentication and authorization
handling using the TypeKey authentication service (I<http://typekey.com/>).
TypeKey is Six Apart's free, open service providing a central login for
people to comment on weblogs, get access to protected information, etc.

To use I<Apache::AuthTypeKey>, you'll need a TypeKey token that identifies
your site. So you'll need to sign up for a TypeKey account at
I<https://www.typekey.com/t/typekey/register>, then fill out the Preferences
form to include the URI of your application. Specifically, this URI should be
the URI for the I</login-protected> area above, because that's the URI that
TypeKey will return to after a user logs in.

I<Apache::AuthTypeKey> is a subclass of I<Apache::AuthCookie>, so it inherits
all of that module's cookie-handling and authorization code. It also inherits
all of that module's configuration settings and options.

=head2 Authentication

Authentication is handled for you through TypeKey, and cookie handling is
handled by I<Apache::AuthCookie>. The value of the cookie will be the string
returned from TypeKey, including the username, email address, name, and a
DSA signature on those values, preventing users from forging the cookie.

=head2 Login Screen

The actual login form is on I<http://www.typekey.com/>; the login screen
that you'll be providing should be just a simple page linking people to that
login screen, along with your TypeKey token and return URI. An example login
screen is in F<eg/login.pl>, but you'll probably wish to customize the HTML,
as it's fairly plain.

The login script functionality is inherited from I<Apache::AuthCookie>, so
it's implemented as a script that you must configure in your I<httpd.conf>
or I<.htaccess>. For example:

    PerlSetVar TypeKeyLoginScript /login.pl

If you'd rather use a different mechanism for your login screen, you can
subclass I<Apache::AuthTypeKey> and override the I<login_form> method. See
the L<Apache::AuthCookie> documentation for more details.

=head2 Authorization

I<Apache::AuthTypeKey>--coupled with TypeKey--will handle all of the
authentication for you, telling you whether someone is a valid TypeKey user.
For authorization, you have a couple of options:

=over 4

=item * Allow any TypeKey user

If you'd like to allow any valid TypeKey user, just use

    require valid-user

as in the I<SYNOPSIS> above.

=item * Allow only certain TypeKey users

If you'd like to allow only certain TypeKey users, you can specify their
TypeKey usernames in standard I<require> statements. For example:

    require user foo
    require user bar

This will allow only the TypeKey users C<foo> and C<bar>.

=item * Override the authorization phase and handle it yourself

If you'd like to do something more complex, like look up valid TypeKey
usernames in a database listing authorized users, you can subclass
I<Apache::AuthTypeKey> and override the I<authorize> method. Note that
I<Apache::AuthTypeKey> doesn't actually provide its own I<authorize>
method anyway--it merely inherits I<Apache::AuthCookie-E<gt>authorize>.

=back

=head1 LICENSE

I<Apache::AuthTypeKey> is free software; you may redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR & COPYRIGHT

Except where otherwise noted, I<Apache::AuthTypeKey> is Copyright 2004 Six
Apart Ltd, cpan@sixapart.com. All rights reserved.

=head1 SEE ALSO

L<Apache::AuthCookie>, L<Authen::TypeKey>

=cut
