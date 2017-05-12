package Authen::CAS::External::Response;

use 5.008001;
use strict;
use utf8;
use warnings 'all';

# Module metadata
our $AUTHORITY = 'cpan:DOUGDUDE';
our $VERSION   = '0.08';

use Authen::CAS::External::Library qw(ServiceTicket TicketGrantingCookie);
use LWP::UserAgent 5.819;
use Moose 0.89;
use MooseX::StrictConstructor 0.08;
use MooseX::Types::Moose qw(Str);
use URI 1.22;

# Clean the imports are the end of scope
use namespace::clean 0.04 -except => [qw(meta)];

# Attributes

has destination => (
	is  => 'ro',
	isa => 'URI',

	clearer   => '_clear_destination',
	predicate => 'has_destination',
);
has notification => (
	is  => 'ro',
	isa => Str,

	clearer   => '_clear_notification',
	predicate => 'has_notification',
);
has response => (
	is  => 'ro',
	isa => 'HTTP::Response',

	clearer   => '_clear_response',
	predicate => 'has_response',
);
has service => (
	is  => 'ro',
	isa => 'URI',

	clearer   => '_clear_service',
	predicate => 'has_service',
);
has service_ticket => (
	is  => 'ro',
	isa => ServiceTicket,

	clearer   => '_clear_service_ticket',
	predicate => 'has_service_ticket',
);
has ticket_granting_cookie => (
	is  => 'ro',
	isa => TicketGrantingCookie,

	clearer   => '_clear_ticket_granting_cookie',
	predicate => 'has_ticket_granting_cookie',
);

# Methods

sub get_cookies {
	my ($self, @cookie_names) = @_;

	if (!$self->is_success) {
		confess 'Unable to retrieve cookies from a failed response';
	}

	if (!$self->has_destination) {
		confess 'Unable to retrieve cookies without a destination';
	}

	# Create a new user agent to use
	my $user_agent = LWP::UserAgent->new(
		cookie_jar    => {},
		max_redirects => 0,
	);

	# Make a HEAD request
	my $response = $user_agent->head($self->destination);

	if (@cookie_names == 0) {
		# Return the cookies a a string
		return $user_agent->cookie_jar->as_string;
	}

	# Cookies to return
	my %cookies;

	# Find the cookies
	$user_agent->cookie_jar->scan(sub {
		my (undef, $key, $value, undef, $domain) = @_;

		if ($domain eq $self->destination->host) {
			# Go through each cookie name
			foreach my $cookie_name (@cookie_names) {
				if ($cookie_name eq $key) {
					# Set the cookie for return
					$cookies{$cookie_name} = $value;
				}
			}
		}
	});

	# Return the found cookies as a hash
	return %cookies;
}

sub is_success {
	my ($self) = @_;

	# If there is a ticket granting ticket, the login
	# was successful
	return $self->has_ticket_granting_cookie;
}

#
# PRIVATE METHODS
#

sub BUILD {
	my ($self) = @_;

	if (!$self->has_destination
		&& $self->has_service
		&& $self->has_service_ticket) {
		# The destination is the service with the sertice ticket
		# as "ticket" in the query parameters
		$self->destination($self->service->query_param('ticket', $self->service_ticket));
	}

	return;
}

# Make immutable
__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 NAME

Authen::CAS::External::Response - Response from CAS interaction.

=head1 VERSION

This documentation refers to version 0.08.

=head1 SYNOPSIS

  my $response = $cas_external->authenticate;

  if (!$response->is_success) {
    croak 'Authentication failed';
  }

  # Get a PHP Session cookie
  my %cookies = $response->get_cookies('PHPSESSID');
  my $PHP_SESSION_ID = $cookies{PHPSESSID};

  # Continue the request
  $response = $ua->get($response->destination);

=head1 DESCRIPTION

This module is rarely created by anything other than
L<Authen::CAS::External::UserAgent|Authen::CAS::External::UserAgent>. This is
an object that is provided to make determining what the CAS response was easier.

=head1 ATTRIBUTES

=head2 destination

This contains a L<URI|URI> object that is the URL to the destination service after
authentication. This means that by going to this URL, the client should be at
the service fully authenticated. Use L</has_destination> to determine if the
response has a destination address.

  if ($response->has_destination) {
    my $service_page = $user_agent->get($response->destination);
  }

=head2 notification

B<Added in version 0.05>; be sure to require this version for this feature.

This contains a string with a notification for the user from the CAS server.
This is usually not set, but can be if the server uses something which tells
the user their password is going to expire.

  if ($response->has_notification) {
    warn $response->notification;
  }

=head2 response

This contains a L<HTTP::Response|HTTP::Response> object that is the response
that occurred right before the user agent would have left the CAS site. This
would be useful for custom parsing of the response. Use L</has_response> to
determine if the response has a response.

=head2 service

This contains a L<URI|URI> object that is the URL of the service. This would
typically be the host and path part of the destination service. Use
L</has_service> to determine if the response has a service.

=head2 service_ticket

This is the service ticket that has been granted for the service. Use
L</has_service_ticket> to determine if the response has a service ticket.

=head2 ticket_granting_cookie

This is the ticket granting cookie that has been given to the user agent to
allow for re-authentication with the CAS service in the future without
providing a username and password. Use L</has_ticket_granting_cookie> to
determine if the response has a ticket granting cookie.

=head1 METHODS

=head2 get_cookies

This method is for convenience purposes. Using this method, a HEAD request
will be made to the destination URL and will return a hash of the cookie
names and their values that would have been set.

B<get_cookies()>

When no arguments are provided, returns a string of the cookies, using the
as_string method of L<HTTP::Cookie|HTTP::Cookie>.

B<get_cookies(@list_of_cookie_names)>

When given a list of cookie names, a hash is returned with only those cookies
where the cookie name is the key and the value is the value.

=head2 has_destination

Returns a Boolean of whether or not the response has an associated
L</destination>.

=head2 has_notification

B<Added in version 0.05>; be sure to require this version for this feature.

Returns a Boolean of whether or not the response has an associated
L</notification>.

=head2 has_response

Returns a Boolean of whether or not the response has an associated
L</response>.

=head2 has_service

Returns a Boolean of whether or not the response has an associated L</service>.

=head2 has_service_ticket

Returns a Boolean of whether or not the response has an associated
L</service_ticket>.

=head2 has_ticket_granting_cookie

Returns a Boolean of whether or not the response has an associated
L</ticket_granting_cookie>.

=head2 is_success

Returns a Boolean of whether or not this response indicates a successful
authentication.

=head1 DEPENDENCIES

=over 4

=item * L<LWP::UserAgent|LWP::UserAgent> 5.819

=item * L<Moose|Moose> 0.89

=item * L<MooseX::StrictConstructor|MooseX::StrictConstructor> 0.08

=item * L<URI|URI> 1.22

=item * L<namespace::clean|namespace::clean> 0.04

=back

=head1 AUTHOR

Douglas Christopher Wilson, C<< <doug at somethingdoug.com> >>

=head1 BUGS AND LIMITATIONS

Please report any bugs or feature requests to
C<bug-authen-cas-external at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Authen-CAS-External>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

I highly encourage the submission of bugs and enhancements to my modules.

=head1 LICENSE AND COPYRIGHT

Copyright 2009 Douglas Christopher Wilson.

This program is free software; you can redistribute it and/or
modify it under the terms of either:

=over 4

=item * the GNU General Public License as published by the Free
Software Foundation; either version 1, or (at your option) any
later version, or

=item * the Artistic License version 2.0.

=back
