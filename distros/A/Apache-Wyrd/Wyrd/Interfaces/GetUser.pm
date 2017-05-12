#Copyright barry king <barry@wyrdwright.com> and released under the GPL.
#See http://www.gnu.org/licenses/gpl.html#TOC1 for details
use 5.006;
use strict;
use warnings;
no warnings qw(uninitialized);

package Apache::Wyrd::Interfaces::GetUser;
our $VERSION = '0.98';
use Apache::Wyrd::Cookie;

=pod

=head1 NAME

Apache::Wyrd::Interfaces::GetUser - Get User data from Auth service/Auth Cookies

=head1 SYNOPSIS

[in a subclass of Apache::Wyrd::Handler]

    sub process {
      my ($self) =@_;
      $self->{init}->{user} = $self->user('BASENAME::User');
      return FORBIDDEN
        unless ($self->check_auth($self->{init}->{user}));
      return;
    }

=head1 DESCRIPTION

Provides a User method that will check both the Apache notes table and the
available cookies for a User created by the C<Apache::Wyrd::Services::Auth>
module.  This is needed by any handler which will need to be informed as to the
findings of a stacked C<Apache::Wyrd::Services::Auth> handler.

But this method is not limited only to stacked Auth handlers.  When the AuthPath
SetPerlVar directive of the C<Apache::Wyrd::Services::Auth> module is beyond the
scope of the area where the authorization was checked (in other words, the
cookie is returned to areas of the site where authorization is not required),
this interface is useful for finding what user is browsing the site.

The SYNOPSIS shows the typical use of this interface in a subclass of
C<Apache::Wyrd::Handler>.

=head1 METHODS

I<(format: (returns) name (arguments after self))>

=over

=item (Apache::Wyrd::User) C<user> (scalar)

Given a User object classname (such as BASENAME::User), this method revives any
User object found by an Auth handler and either placed into the Apache notes
table of the current session or in a cookie provided by the browser.

=cut

sub user {
	my ($self, $user_object) = @_;
	eval("use $user_object") unless ($INC{$user_object});
	if ($@) {
		if ($self->can('_error')) {
			$self->_error("User object could not be use-d: $@");
		} else {
			warn("User object could not be use-d: $@");
		}
	}
	my $user = undef;
	#user may have been found in an earlier handler and left in the notes
	my $user_info = $self->req->notes('User');
	if ($user_info) {
		eval('$user=' . $user_object . '->revive($user_info)');
		if ($@) {
			$self->_warn("User could not be made from notes because of: $@.  Using a blank User.");
		}
		return $user;
	}
	#if an Auth handler has not received the request earlier, it may be necessary to build the user out of
	#the browser's cookie.
	my %cookie = Apache::Wyrd::Cookie->fetch;
	my $auth_cookie = $cookie{'auth_cookie'};
	my $ip = undef;
	if ($auth_cookie) {
		$auth_cookie = eval{$auth_cookie->value};
		return undef unless ($auth_cookie);
		use Apache::Wyrd::Services::CodeRing;
		my $cr = Apache::Wyrd::Services::CodeRing->new;
		($ip, $auth_cookie) = split(':', $auth_cookie);
		$ip = ${$cr->decrypt(\$ip)};
		my $ip_ok = 1;
		if ($self->req->dir_config('TieAddr')) {
			my $remote_ip = $self->dbl->req->connection->remote_ip;
			if ($remote_ip ne $ip) {
				$self->_debug("Remote ip $remote_ip does not match cookie IP $ip, discarding cookie");
				$ip_ok = 0;
			} else {
				$self->_debug("Remote ip $remote_ip matches cookie IP $ip, accepting cookie");
			}
		}
		return undef unless ($ip_ok);
		$user_info = ${$cr->decrypt(\$auth_cookie)};
		eval('$user=' . $user_object . '->revive($user_info)');
		if ($@) {
			if ($self->can('_error')) {
				$self->_error("User could not be made from cookie because of: $@");
			} else {
				warn("User could not be made from cookie because of: $@");
			}
		}
		return $user;
	}
	$user_info = $self->null_user_spec($user_object);
	eval('$user=' . $user_object . '->new($user_info)');
	return $user;
}

=pod

=item (hashref) C<null_user_spec> (scalar)

Because the Apache::Wyrd:Services::Auth framework requires that there must
be a user object defined even when no user has logged in, this is a "hook"
method for providing minimum initialization of the non-user user object.  It
is passed the class name of the type of user object being created.  Return
value is a hashref, defaulting to the empty hash. When there is no login,
this method's return value will be passed directly to the C<new> method of
the user object as if it were a new login.

=cut

sub null_user_spec {
	return {};
}

=pod

=back

=head1 BUGS/CAVEATS/RESERVED METHODS

UNKNOWN

=head1 AUTHOR

Barry King E<lt>wyrd@nospam.wyrdwright.comE<gt>

=head1 SEE ALSO

=over

=item Apache::Wyrd

General-purpose HTML-embeddable perl object

=back

=head1 LICENSE

Copyright 2002-2007 Wyrdwright, Inc. and licensed under the GNU GPL.

See LICENSE under the documentation for C<Apache::Wyrd>.

=cut

1;