package Database::BI::Sessions;

use strict;
use warnings;

our $VERSION = '0.022.0';

use Mojo::Base 'Mojolicious::Sessions';

# The login cookie is marked Secure on a reply to a request that came over
# https, so the browser never sends it back over http, where anyone on the
# path could read it and log in as the reader.  Mojolicious::Sessions has one secure
# setting for the whole application; a server reached both ways (or a proxy
# that says X-Forwarded-Proto: https) needs it per request.  Over plain http
# the cookie cannot be Secure, or the browser would drop it and the login
# would never stick.
sub store {
	my ($self, $c) = @_;
	local $self->{secure} = $self->{secure} || $c->req->is_secure;
	return $self->SUPER::store($c);
}

1;

__END__

=head1 NAME

Database::BI::Sessions - Session cookies that are Secure over https

=head1 VERSION

0.022.0

=head1 SYNOPSIS

    $app->sessions(Database::BI::Sessions->new(cookie_name => 'database_bi'));

=head1 DESCRIPTION

A L<Mojolicious::Sessions> whose cookie carries the C<Secure> attribute on every
reply to a request that came over https (directly, or through a trusted proxy
that says so), as well as when C<secure> is set.  L<Database::BI> uses it for
the login session (see L<Database::BI/Logging in>).

=head1 METHODS

=head2 store

=head3 API SPECIFICATION

=head4 INPUT

    $c: the controller whose session is written

=head4 OUTPUT

As L<Mojolicious::Sessions/store>.  The cookie is C<Secure> when C<secure> is set or
C<< $c->req->is_secure >> is true.

=head1 AUTHOR

Nigel Horne C<< <njh@nigelhorne.com> >>

=head1 LICENCE AND COPYRIGHT

Copyright 2026 Nigel Horne.

Usage is subject to the GPL2 licence terms.

=cut
