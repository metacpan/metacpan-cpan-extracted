package Authen::CAS::External;

use 5.008001;
use strict;
use utf8;
use warnings 'all';

# Module metadata
our $AUTHORITY = 'cpan:DOUGDUDE';
our $VERSION   = '0.08';

use Authen::CAS::External::Library qw(TicketGrantingCookie);
use Moose 0.89;
use MooseX::StrictConstructor 0.08;
use MooseX::Types::Moose qw(Str);
use URI 1.22;

# Clean the imports are the end of scope
use namespace::clean 0.04 -except => [qw(meta)];

# Role

with 'Authen::CAS::External::UserAgent';

# Attributes

has password => (
	is  => 'rw',
	isa => Str,

	clearer   => 'clear_password',
	predicate => 'has_password',
	trigger   => sub { shift->clear_ticket_granting_cookie },
);
has ticket_granting_cookie => (
	is  => 'rw',
	isa => TicketGrantingCookie,

	clearer       => 'clear_ticket_granting_cookie',
	documentation => q{The Ticket Granting Cookie for the CAS user session},
	predicate     => 'has_ticket_granting_cookie',
);
has username => (
	is  => 'rw',
	isa => Str,

	clearer   => 'clear_username',
	predicate => 'has_username',
	trigger   => sub { shift->clear_ticket_granting_cookie },
);

# Methods

sub authenticate {
	my ($self, %args) = @_;

	# Splice out the variables
	my ($service, $gateway, $renew) = @args{qw(service gateway renew)};

	# Get the URI to request
	my $url = $self->service_request_url(
		(defined $gateway ? (gateway => $gateway) : () ),
		(defined $renew   ? (renew   => $renew  ) : () ),
		(defined $service ? (service => $service) : () ),
	);

	# Do not redirect back to service
	my $redirect_back = $self->redirect_back;
	$self->redirect_back(0);

	# Get the service
	my $response = $self->get($url);

	# Restore previous value
	$self->redirect_back($redirect_back);

	if (!$self->has_previous_response) {
		confess 'Failed retrieving response';
	}

	# Set our ticket granting ticket if we have one
	if ($self->previous_response->has_ticket_granting_cookie) {
		$self->ticket_granting_cookie($self->previous_response->ticket_granting_cookie);
	}

	# Return the last response
	return $self->previous_response;
}

sub get_cas_credentials {
	my ($self, $service) = @_;

	# This default callback stub simply returns the stored
	# credentials
	if (!$self->has_username) {
		confess 'Unable to authenticate because no username was provided';
	}

	if (!$self->has_password) {
		confess 'Unable to authenticate because no password was provided';
	}

	# Return username, password
	return $self->username, $self->password;
}

sub get_cas_ticket_granting_cookie {
	my ($self, %args) = @_;

	# Splice out the variables
	my ($username, $service) = @args{qw(username service)};

	# This default callback stub simply returns the stored
	# credentials
	if (!$self->has_ticket_granting_cookie) {
		return;
	}

	# Return ticket granting ticket
	return $self->ticket_granting_cookie;
}

# Make immutable
__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 NAME

Authen::CAS::External - Authenticate with CAS servers as a browser
would.

=head1 VERSION

This documentation refers to version 0.08.

=head1 SYNOPSIS

  my $cas_auth = Authen::CAS::External->new(
      cas_url => 'https://cas.mydomain.com/',
  );

  # Set the username and password
  $cas_auth->username('joe_smith');
  $cas_auth->password('hAkaT5eR');

  my $response = $cas_auth->authenticate();

  my $secured_page = $ua->get($response->destination);

=head1 DESCRIPTION

Provides a way to authenticate with a CAS server just as a browser
would. This is useful with web scrapers needing to login to a CAS
site.

=head1 CONSTRUCTOR

This is fully object-oriented, and as such before any method can be used, the
constructor needs to be called to create an object to work with.

=head2 new

This will construct a new object.

=over

=item new(%attributes)

C<%attributes> is a HASH where the keys are attributes (specified in the
L</ATTRIBUTES> section).

=item new($attributes)

C<$attributes> is a HASHREF where the keys are attributes (specified in the
L</ATTRIBUTES> section).

=back

=head1 ATTRIBUTES

=head2 cas_url

This is the URL of the CAS site excluding /login. This can be a URI object
or a string of a URL.

=head2 password

This is the password to use for logging in to the CAS site. When set, this
clears the L</ticket_granting_cookie>.

=head2 ticket_granting_cookie

This is the ticket granting cookie to use for logging into the CAS site. This
can be set to log in with just the cookie and no username or password.

=head2 username

This is the username to use for logging in to the CAS site. When set, this
clears the L</ticket_granting_cookie>.

=head1 METHODS

=head2 authenticate

This method will authenticate against the CAS service using the already supplied
username and password and will return a
L<Authen::CAS::External::Response|Authen::CAS::External::Response> object.

This method takes a HASH with the following keys:

=over

=item gateway

This is a Boolean of if the gateway parameter should be sent to the CAS server.
The default is to not send any gateway parameter.

=item renew

This is a Boolean of if the renew parameter should be sent to the CAS server.
The default is to not send any renew parameter.

=item service

This is a string that specifies the service value to send to the CAS server.
The default is to not send any service parameter.

=back

=head2 get_cas_credentials

This method is not actually used, but is required for classes to consume the
L<Authen::CAS::External::UserAgent|Authen::CAS::External::UserAgent> role as
this class does. This method will return the currently set username and
password to the user agent.

=head2 get_cas_ticket_granting_cookie

This method is not actually used but is required for classes to consume the
L<Authen::CAS::External::UserAgent|Authen::CAS::External::UserAgent> role as
this class does. This method will return the currently set ticket granting
cookie if the username requested matches the username set (and always should).

=head1 DEPENDENCIES

=over 4

=item * L<Moose|Moose> 0.89

=item * L<MooseX::StrictConstructor|MooseX::StrictConstructor> 0.08

=item * L<MooseX::Types::Moose|MooseX::Types::Moose>

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

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

  perldoc Authen::CAS::External

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Authen-CAS-External>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Authen-CAS-External>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Authen-CAS-External>

=item * Search CPAN

L<http://search.cpan.org/dist/Authen-CAS-External/>

=back

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
