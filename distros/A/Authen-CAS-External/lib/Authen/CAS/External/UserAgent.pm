package Authen::CAS::External::UserAgent;

use 5.008001;
use strict;
use utf8;
use warnings 'all';

# Module metadata
our $AUTHORITY = 'cpan:DOUGDUDE';
our $VERSION   = '0.08';

use Authen::CAS::External::Response 0.05;
use HTML::Form 5.817;
use HTML::TokeParser 3.00;
use HTTP::Status 5.817 qw(HTTP_BAD_REQUEST);
use LWP::UserAgent 5.819;
use Moose::Role 0.89;
use MooseX::Types::Moose qw(Bool Str);
use MooseX::Types::URI qw(Uri);
use Scalar::Util 1.14;
use URI 1.22;
use URI::QueryParam;

# Clean the imports are the end of scope
use namespace::clean 0.04 -except => [qw(meta)];

# Role requires

requires qw(
	get_cas_credentials
	get_cas_ticket_granting_cookie
);

# Attributes

has previous_response => (
	is  => 'rw',
	isa => 'Authen::CAS::External::Response',

	clearer       => 'clear_previous_response',
	documentation => q{The previous response from a request on the UserAgent},
	predicate     => 'has_previous_response',
);
has redirect_back => (
	is  => 'rw',
	isa => Bool,

	default       => 0,
	documentation => q{Weither or not for the UserAgent to make a request outside of the CAS site},
);
has user_agent => (
	is  => 'rw',
	isa => 'LWP::UserAgent',

	default       => sub {
		my $ua = LWP::UserAgent->new(cookie_jar => {});
		push @{$ua->requests_redirectable}, 'POST';
		return $ua;
	},
	documentation => q{The LWP::UserAgent to use to make requests},
	handles       => ['get'],
	trigger       => \&_user_agent_trigger,
);
has cas_url => (
	is  => 'rw',
	isa => Uri,

	documentation => q{The URL of the CAS site. This does not include /login},
	coerce        => 1,
	required      => 1,
	trigger       => \&_cas_url_trigger,
);

has _handler_owner_name => (
	is  => 'ro',
	isa => 'Num',

	default  => sub { Scalar::Util::refaddr(shift); },
	init_arg => undef,
);

# Methods

sub service_request_url {
	my ($self, %args) = @_;

	# Get the CAS URL to use
	my $cas_url = exists $args{cas_url} ? $args{cas_url}
	                                    : $self->cas_url;

	# Create the beginning of the URL as a URI
	my $url = URI->new($cas_url);

	# Get the URL path
	my @url_path = $url->path_segments;

	if (@url_path) {
		# Get the last path item
		my $last_path_segment = pop @url_path;

		if ($last_path_segment ne q{}
		    && $last_path_segment ne q{login}) {
			# Add the last piece back
			push @url_path, $last_path_segment;
		}
	}

	# Set the correct path
	$url->path_segments(@url_path, 'login');

	if (exists $args{service}) {
		$url->query_param('service', $args{service});
	}

	if (exists $args{gateway}) {
		$url->query_param('gateway', $args{gateway} ? 'true' : 'false');
	}

	if (exists $args{renew}) {
		$url->query_param('renew', $args{renew} ? 'true' : 'false');
	}

	# Return the URI object
	return $url;
}

# Private Methods

sub _add_user_agent_handlers {
	my ($self, %args) = @_;

	# Get the arguments
	my ($user_agent, $cas_url) = @args{qw(user_agent cas_url)};

	# Default arguments
	$cas_url    ||= $self->cas_url;
	$user_agent ||= $self->user_agent;

	# Get fully-qualified host and path
	my ($cas_host, $cas_path) = map { $_->host, $_->path }
		$self->service_request_url(cas_url => $cas_url);

	# Create the owner reference
	my $owner = \$self;

	# This is a reference to a weak reference to prevent circular references
	Scalar::Util::weaken(${$owner});

	# Add handlers
	$user_agent->add_handler(
		request_prepare => \&_process_ticket_granting_cookie,
		m_host          => $cas_host,
		m_method        => 'GET',
		m_path_match    => qr{\A \Q$cas_path\E}msx,
		object_instance => $owner,
		owner           => $self->_handler_owner_name,
	);
	$user_agent->add_handler(
		response_redirect => \&_process_login_page,
		m_host            => $cas_host,
		m_media_type      => 'html',
		m_path_match      => qr{\A \Q$cas_path\E}msx,
		object_instance   => $owner,
		owner             => $self->_handler_owner_name,
	);
	$user_agent->add_handler(
		response_done   => \&_determine_complete_login,
		m_host          => $cas_host,
		m_path_match    => qr{\A \Q$cas_path\E}msx,
		object_instance => $owner,
		owner           => $self->_handler_owner_name,
	);

	return;
}

sub _cas_url_trigger {
	my ($self, $cas_url, $previous_cas_url) = @_;

	if (defined $previous_cas_url) {
		# Remove the handlers from the current user agent for the previous
		# CAS URL.
		$self->_remove_user_agent_handlers(
			cas_url => $previous_cas_url,
		);
	}

	# Now add the handlers back to the user agent for the new CAS URL.
	$self->_add_user_agent_handlers(
		cas_url => $cas_url,
	);

	return;
}

sub _determine_complete_login {
	my ($response, $user_agent, $info) = @_;
	my $self = ${$info->{object_instance}};

	if ($response->request->method ne 'POST' && !$response->is_redirect) {
		# Redriects are when the login process is completing
		return;
	}

	# Create a location to store the response data
	my %response_data;

	COOKIE:
	{
		# Manually extract the cookies into our own jar
		my $cookie_jar = HTTP::Cookies->new;

		$cookie_jar->extract_cookies($response);

		# Gather the ticket granting ticket
		$cookie_jar->scan(sub {
			my (undef, $key, $value, undef, $domain) = @_;

			if ($domain eq $self->cas_url->host && $key eq 'CASTGC') {
				# Set the ticket
				$response_data{ticket_granting_cookie} = $value;
			}
		});
	}

	# This is for the service redirect link as a URI object
	my $service_redirect;

	if (defined $response->header('Location')) {
		# Set the service redirect link from the Location header
		$service_redirect = URI->new($response->header('Location'));
	}
	else {
		# There was no Location header. This should not happen in the CAS
		# protocol outline. But there is a new addon created by Eric Pierce
		# http://www.ja-sig.org/wiki/display/CASUM/LDAP+Password+Policy+Enforcement
		# which is ment to enforce password expiration policies.
		# THIS SECTION LAST UPDATED 2010-01-11

		# Get the service redirect link from the page
		my $destination = _extract_service_redirect_link($response);

		if (defined $destination) {
			# Set the service redirect
			$response_data{destination} = $destination;
		}

		# Get the notification from the page
		my $notification = _extract_notification($response);

		if (defined $notification) {
			# Set the notification
			$response_data{notification} = $notification;
		}
	}

	# Process the service redirect link
	if (defined $service_redirect
	    && defined(my $ticket = $service_redirect->query_param('ticket'))) {
		# Store the destination
		$response_data{destination} = $service_redirect->clone;

		# Store the ticket
		$response_data{service_ticket} = $ticket;

		# Remove the ticket from the query
		$service_redirect->query_param_delete('ticket');

		# Store the service
		$response_data{service} = $service_redirect->clone;
	}

	my $cas_response = Authen::CAS::External::Response->new(
		response => $response->clone,
		%response_data,
	);

	# Store as the previous response
	$self->previous_response($cas_response);

	if (!$self->redirect_back) {
		# Change the status to indicate request stopped
		$response->code(HTTP_BAD_REQUEST);
		$response->message('Client set to not redirect out of CAS site');
	}

	return;
}

sub _extract_notification {
	my ($response) = @_;

	# For the notification to be populated into
	my $notification;

	# Prase the document using HTML::TokeParser
	my $parser = HTML::TokeParser->new($response->content_ref);

	# Cycle through the tokens on the page
	TOKEN: while (my $token = $parser->get_token) {
		# Move to the next token if this is not a start tag
		next TOKEN
			if $token->[0] ne q{S};

		# Get the tag of this start tag
		my $tag = lc $token->[1];

		if (exists $token->[2]->{class}
		    && defined $token->[2]->{class}
		    && $token->[2]->{class} =~ m{\berrors?\b}imsx) {
			# This token has a class of "error" or "errors" and so should be
			# this notification.
			$notification = $parser->get_trimmed_text("/$tag");

			# End token parsing
			last TOKEN;
		}
	}

	# Return the notification
	return $notification;
}

sub _extract_service_redirect_link {
	my ($response) = @_;

	# For the service redirect to be populated into
	my $service_redirect;

	# Prase the document using HTML::TokeParser
	my $parser = HTML::TokeParser->new($response->content_ref);

	# Cycle through the tokens on the page
	TOKEN: while (my $token = $parser->get_token) {
		# Move to the next token if this is not a start tag
		next TOKEN
			if $token->[0] ne q{S};

		# Get the tag of this start tag
		my $tag = lc $token->[1];

		if ($tag eq q{a}) {
			# This is the start of an anchor tag. Anchor tags need to be
			# scanned for the service redirect.
			if (exists $token->[2]->{href} && $token->[2]->{href} =~ m{ticket=ST-}msx) {
				# This is the service redirect link.

				# Set the service redirect link from this link
				$service_redirect = URI->new($token->[2]->{href});

				# End the parsing
				last TOKEN;
			}
		}
	}

	# Return the service redirect
	return $service_redirect;
}

sub _process_login_page {
	my ($response, $user_agent, $info) = @_;
	my $self = ${$info->{object_instance}};

	if ($response->request->method eq 'POST') {
		if (!$self->has_previous_response) {
			# A POST returning to the login page is a failure
			confess 'The login failed with the supplied credentials';
		}

		# The previous response can determine what occurred
		return;
	}

	# Parse the forms on the page
	my @forms = HTML::Form->parse($response->decoded_content, $response->base);

	# Find the login form
	my $login_form;
	FORM: foreach my $form (@forms) {
		if (defined $form->find_input('lt')
			&& defined $form->find_input('username')
			&& defined $form->find_input('password')) {
			# Set this as the login form
			$login_form = $form;

			# Do not continue to search the forms
			last FORM;
		}
	}

	if (!defined $login_form) {
		confess 'The login form could not be identified on the login page';
	}

	# The service this form is for
	my $service = $login_form->param('service');

	# Get the username and password
	my ($username, $password) = $self->get_cas_credentials($service);

	# Fill in the form
	$login_form->param(username => $username);
	$login_form->param(password => $password);

	# Get the request to make
	my $request = $login_form->make_request;

	return $request;
}

sub _process_ticket_granting_cookie {
	my ($request, $user_agent, $info) = @_;
	my $self = ${$info->{object_instance}};

	# Clear previous response
	$self->clear_previous_response;

	# Get the service
	my $service = $request->uri->query_param('service');

	if (defined $user_agent->cookie_jar) {
		# Clear all CAS cookies
		$user_agent->cookie_jar->clear($self->cas_url->host);

		# Get the CAS credentials
		my ($username, $password) = $self->get_cas_credentials($service);

		# Get the ticket granting ticket
		my $ticket_granting_cookie = $self->get_cas_ticket_granting_cookie(
			$username,
			$service
		);

		if (defined $ticket_granting_cookie) {
			# Set the cookie for the upcoming request
			$user_agent->cookie_jar->set_cookie(
				undef,
				'CASTGC',
				$ticket_granting_cookie,
				$self->cas_url->path,
				$self->cas_url->host,
				$self->cas_url->port,
				1,
				$self->cas_url->scheme eq 'https',
				undef,
				0
			);

			# Add cookies due to HTTP::Config handling
			$user_agent->cookie_jar->add_cookie_header($request);
		}
	}

	return;
}

sub _remove_user_agent_handlers {
	my ($self, %args) = @_;

	# Get the arguments
	my ($user_agent, $cas_url) = @args{qw(user_agent cas_url)};

	# Default arguments
	$cas_url    ||= $self->cas_url;
	$user_agent ||= $self->user_agent;

	# Remove the handlers in the user agent
	$user_agent->remove_handler(undef,
		m_host => $cas_url->host,
		owner  => $self->_handler_owner_name,
	);

	return;
}

sub _user_agent_trigger {
	my ($self, $user_agent, $previous_user_agent) = @_;

	if (defined $previous_user_agent) {
		# Remove the handlers from the previous user agent
		$self->_remove_user_agent_handlers(
			user_agent => $previous_user_agent,
		);
	}

	# Now add the handlers to the new user agent
	$self->_add_user_agent_handlers(
		user_agent => $user_agent,
	);

	return;
}

#
# CONSTRUCTOR-RELATED METHODS
#

sub BUILD {
	my ($self) = @_;

	# Hook the respose handler
	$self->_add_user_agent_handlers();

	return;
}

sub DEMOLISH {
	my ($self) = @_;

	# Remove the handlers from the user agent
	$self->_remove_user_agent_handlers;

	return;
}

sub FOREIGNBUILDARGS {
	my ($class, @args) = @_;

	# According to LWP::UserAgent, takes straight hash
	if (@args % 2 == 1) {
		confess 'Invalid arguments passed';
	}

	# The defaults for WWW::Mechanize
	my %args = (
		autocheck   => 0,
		noproxy     => 1,
		stack_depth => 1,
		@args,
	);

	# Return the args to the super class
	return %args;
}

1;

__END__

=head1 NAME

Authen::CAS::External::UserAgent - UserAgent role for CAS session managers.

=head1 VERSION

This documentation refers to version 0.08.

=head1 SYNOPSIS

  package MyCAS::Session;

  use Moose;

  # Use this role
  with 'Authen::CAS::External::UserAgent';

  sub get_cas_credentials {
    my ($self, $service) = @_;

    # Do something

    return $username, $password;
  }

  sub get_cas_ticket_granting_cookie {
    my ($self, $username, $service) = @_;

    # Do something

    return $TGC;
  }

  1;

=head1 DESCRIPTION

Provides a way to authenticate with a CAS server just as a browser
would. This is useful with web scrapers needing to login to a CAS
site.

=head1 ROLE REQUIRES

This is a L<Moose::Role|Moose::Role> and for this role to be used, the user
MUST provide the following two methods:

=head2 get_cas_credentials

This is called as a method with the first argument being a string that is the
URL of the service that is about to be logged in to. If no service is being
logged in to, then it will be undefined. This function is expected to return
a username string and a password string, both of which are optional, but MUST
be returned in that order.

=head2 get_cas_ticket_granting_cookie

This is called as a method with the first argument being a string that is the
username being used and the second argument being a string that is the URL of
the service that is about to be logged into. This function is expected to
return a string that is the ticket granting cookie for the CAS service, or
nothing.

=head1 ATTRIBUTES

=head2 cas_url

This is a L<URI|URI> object of the base URL of the CAS site. This is typically
the path before C</login>. A string may be supplied and will automatically
be converted to a L<URI|URI> object.

=head2 previous_response

This holds the response object
L<Authen::CAS::External::Response|Authen::CAS::External::Response> from the
last executed CAS navigation.

=head2 redirect_back

This is a Boolean that determines if the L</user_agent> will navigate
outside of the L</cas_url>. The default is C<0>.

=head2 user_agent

This is a L<LWP::UserAgent|LWP::UserAgent> that is used to navigate the CAS
site. The default is L<LWP::UserAgent|LWP::UserAgent> with an in-memory cookie
jar and allows the C<POST> method to be redirectable.

=head1 METHODS

=head2 clear_previous_response

This will clear the L</previous_response> attribute.

=head2 get

This is an alias to the C<get> method of the L</user_agent>.

=head2 has_previous_response

This will return if there is a value present in the L</previous_response>
attribute.

=head2 service_request_url

B<service_request_url(%args)>

This method will return a URI object that is the URL to request for the CAS
login page. All arguments are optional. The following are the possible
arguments:

=over 4

=item * cas_url

B<Added in version 0.06>; be sure to require this version for this feature.

This is the URL of the CAS deployment to use. By default this will use the
L</cas_url> attribute. This can be either a L<URI|URI> object or a string.

=item * service

This is a string of the service URL to log in to.

=item * gateway

This is a Boolean of whether or not to use gateway login mode.

=item * renew

This is a Boolean to whether or not to renew the session.

=back

=head1 DEPENDENCIES

=over 4

=item * L<HTML::Form|HTML::Form> 5.817

=item * L<HTML::TokeParser|HTML::TokeParser> 3.00

=item * L<HTTP::Status|HTTP::Status> 5.817

=item * L<LWP::UserAgent|LWP::UserAgent> 5.819

=item * L<Moose::Role|Moose::Role> 0.89

=item * L<MooseX::Types::Moose|MooseX::Types::Moose>

=item * L<MooseX::Types::URI|MooseX::Types::URI>

=item * L<Scalar::Util|Scalar::Util> 1.14

=item * L<URI|URI> 1.22

=item * L<URI::QueryParam|URI::QueryParam>

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
