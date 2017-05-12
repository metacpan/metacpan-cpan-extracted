package Business::OnlinePayment::CyberSource::Client;

use 5.010;
use strict;
use warnings;

use Moose;
use Module::Runtime qw( use_module );
use MooseX::Aliases;
use MooseX::StrictConstructor;
use Try::Tiny;
use Business::CyberSource::Client 0.007006;
use MooseX::Types::CyberSource qw(AVSResult);
use MooseX::Types::Moose qw(Bool HashRef Int Str);
use MooseX::Types::Common::String qw(NonEmptySimpleStr);

# ABSTRACT:  CyberSource Client object  for Business::OnlinePayment::CyberSource
our $VERSION = '3.000016'; # VERSION

#### Subroutine Definitions ####

# Sends an authorization request to CyberSource
# Accepts:  A hash or reference to a hash of request parameters
# Returns:  1 if the transaction was successful and 0 otherwise

sub authorize {
	my ( $self, @args ) = @_;

	my $class = 'Business::CyberSource::Request::Authorization';

	return $self->_authorize( $class, @args );
}

sub sale {
	my ( $self, @args ) = @_;

	my $class = 'Business::CyberSource::Request::Sale';

	return $self->_authorize( $class, @args );
}

sub _authorize          {
	my ( $self, $class, @args ) = @_;
	my $data            = $self->_parse_input( @args );

	# Validate input
	my $message;

	$message      = 'No request data specified to authorize'
		if scalar keys %$data == 0;

	$message      = 'purchase_totals data must be specified to authorize as a hashref'
		unless $data->{purchase_totals} && ref $data->{purchase_totals} eq 'HASH';

	$message      = 'No payment medium specified to authorize'
		unless $data->{card};

	$message      = 'No reference code specified to authorize'
		unless $data->{reference_code};

	Exception::Base->throw( $message ) if $message;

	unless ( $self->require_avs() ) {
		$data->{business_rules} = { ignore_avs_result => 1 };
	}

	my $request         = try {
		use_module( $class )->new( $data );
	}
	catch {
		$message = shift;

		$self->set_error_message( "$message" );

		return $self->is_success();
	};

	return $request unless $request;

	try {
		my $response = $self->submit( $request );

		if ( $response->is_accept() ) {
			$self->is_success( 1 );
		}
		else {
			$self->set_error_message( $response->reason_text() );
		}

		if ( $response->has_auth ) {
		  $self->authorization( $response->auth->auth_code() )
			  if $response->auth->has_auth_code;

		  $self->cvv2_response( $response->auth->cv_code() )
			  if $response->auth->has_cv_code();

		  $self->avs_code( $response->auth->avs_code() )
			  if $response->auth->has_avs_code;
		}
		$self->_fill_fields( $response );
	}
	catch {
		my $e          = shift;

		# Rethrow if $e is not a string
		$e->throw() if ( ref $e ne '' );

  $self->set_error_message( $e );
	};

	return $self->is_success();
}

# Sends a capture request to CyberSource
# Accepts:  A hash or reference to a hash of request parameters
# Returns:  1 if the transaction was successful and 0 otherwise

sub capture            {
	my ( $self, @args ) = @_;
	my $data            = $self->_parse_input( @args );

	#Validate input
	my $message         = '';

	$message = 'No reference code supplied to capture'
		unless $data->{reference_code};

	$message = 'No service data supplied to capture'
		unless $data->{service};

	$message = 'No purchase totals supplied to capture'
		unless $data->{purchase_totals};

	Exception::Base->throw( $message ) if $message;

	my $request         = try {
		use_module( 'Business::CyberSource::Request::Capture' )->new( $data );
	}
	catch {
		$message          = shift;

		$self->set_error_message( "$message" );

		return $self->is_success();
	};

	return $request unless $request;

	try {
		my $response      = $self->submit( $request );

		if ( $response->is_accept() ) {
			$self->is_success ( 1 );
		}
		else {
			$self->set_error_message( $response->reason_text() );
		}

		$self->_fill_fields( $response );
	}
	catch {
		my $e          = shift;

		# Rethrow if $e is not a string
		$e->throw() if ref $e ne '';

  $self->set_error_message( $e );
	};

	return $self->is_success();
}

# Sends a credit request to CyberSource
# Accepts:  A hash or reference to a hash of request parameters
# Returns:  1 if the transaction was successful and 0 otherwise

sub credit             {
	my ( $self, @args ) = @_;
	my $data            = $self->_parse_input( @args );

	#Validate input
	my $message         = '';

	$message = 'No reference code supplied to credit'
		unless $data->{reference_code};

	unless ( $data->{service} && $data->{service}->{request_id} ) {
			$message = 'No bill_to supplied to credit'
			unless $data->{bill_to};
	}

	$message = 'No purchase totals supplied to credit'
		unless $data->{purchase_totals};

	Exception::Base->throw( $message ) if $message;

	my $request         = try {
		use_module( 'Business::CyberSource::Request::Credit' )->new( $data );
	}
	catch {
		$message          = shift;

		$self->set_error_message( "$message" );

		return $self->is_success();
	};

	return $request unless $request;

	try {
		my $response      = $self->submit( $request );


		if ( $response->is_accept() ) {
			$self->is_success ( 1 );
		}
		else {
			$self->set_error_message( $response->reason_text() );
		}

		$self->_fill_fields( $response );
	}
	catch {
		my $e          = shift;

		# Rethrow if $e is not a string
		$e->throw() if ref $e ne '';

  $self->set_error_message( $e );
	};

	return $self->is_success();
}

# Sends a AuthReversal request to CyberSource
# Accepts: a hash or hashref of request parameters
# Returns: 1 if success or 0

sub auth_reversal {
	my ( $self, @args ) = @_;
	my $data            = $self->_parse_input( @args );

	#Validate input
	my $message;

	$message = 'No reference code supplied to void'
		unless $data->{reference_code};

	$message = 'No service data supplied to void'
		unless $data->{service};

	$message = 'No purchase totals supplied to void'
		unless $data->{purchase_totals};

	Exception::Base->throw( $message ) if $message;

	my $request         = try {
		use_module( 'Business::CyberSource::Request::AuthReversal' )->new( $data );
	}
	catch {
		$self->set_error_message( "$_" );

		return $self->is_success();
	};

	try {
		my $response        = $self->submit( $request );

		if ( $response->is_accept() ) {
			$self->is_success ( 1 );
		}
		else {
			$self->set_error_message( $response->reason_text() );
		}

		$self->_fill_fields( $response );
	}
	catch {
		my $e          = shift;

  # Rethrow if $e is not a string
  $e->throw() if ref $e ne '';

		$self->set_error_message( $e );
	};

	return $self->is_success();
}

# Sets various response fields
# Accepts:  Nothing
# Returns:  Nothing

sub _fill_fields {
	my ( $self, $response ) = @_;
	my $res                 = {};

	return unless ( $response and $response->isa( 'Business::CyberSource::Response' ) );

	my $trace               = $response->trace();

	if ( $trace ) {
		$res                  = $trace->response();
	}
	else {
		Exception::Base->throw( 'No trace found' );
	}

	my $h                   = $res->headers();
	my $names               = [ $h->header_field_names() ];
	my $headers             = { map { $_ => $h->header( $_ ) } @$names }; ## no critic ( BuiltinFunctions::ProhibitVoidMap )

	$self->order_number( $response->request_id() );
	$self->response_code( $res->code() );
	$self->response_page( $res->content() );
	$self->response_headers( $headers );
	$self->result_code( $response->reason_code() );

	return;
}

# Resets all transaction fields
# Accepts:  Nothing
# Returns:  Nothing

sub _clear_fields      {
	my ( $self ) = @_;

	my $attributes = [ qw(
		success authorization order_number card_token fraud_score fraud_transaction_id
		response_code response_headers response_page result_code avs_code
		cvv2_response
	) ];

	$self->$_() foreach ( map { "clear_$_" } @$attributes );

	return;
}

# builds the Business::CyberSource client
# Accepts:  Nothing
# Returns:  A reference to a Business::CyberSource::Client object

sub _build_client { ## no critic ( Subroutines::ProhibitUnusedPrivateSubroutines )
	my ( $self )             = @_;
	my $username             = $self->login();
	my $password             = $self->password();
	my $test                 = $self->test_transaction();

	my $data                 = {
		user => $username,
		pass => $password,
		test => $test,
	};

	my $client               = Business::CyberSource::Client->new( $data );

	return $client;
}

#### Object Attributes ####

has is_success => (
	isa       => Bool,
	is        => 'rw',
	default   => 0,
	required  => 0,
	clearer   => 'clear_success',
	init_arg  => undef,
	lazy      => 1,
);

# Authorization code
has authorization => (
	isa       => Str,
	is        => 'rw',
	required  => 0,
	predicate => 'has_authorization',
	clearer   => 'clear_authorization',
	init_arg  => undef,
	lazy      => 0,
);

# Number identifying the specific request
has order_number => (
	isa       => Str,
	is        => 'rw',
	required  => 0,
	predicate => 'has_order_number',
	clearer   => 'clear_order_number',
	init_arg  => undef,
	lazy      => 0,
);

# Used in stead of card number (not yet supported)
has card_token => (
	isa       => Str,
	is        => 'rw',
	required  => 0,
	predicate => 'has_card_token',
	clearer   => 'clear_card_token',
	init_arg  => undef,
	lazy      => 0,
);

# score assigned by ... (not yet supported)
has fraud_score => (
	isa       => Str,
	is        => 'rw',
	required  => 0,
	predicate => 'has_fraud_score',
	clearer   => 'clear_fraud_score',
	init_arg  => undef,
	lazy      => 0,
);

# Transaction id assigned by ... (not yet supported)
has fraud_transaction_id => (
	isa       => Str,
	is        => 'rw',
	required  => 0,
	predicate => 'has_fraud_transaction_id',
	clearer   => 'clear_fraud_transaction_id',
	init_arg  => undef,
	lazy      => 0,
);

# HTTP response code
has response_code => (
	isa       => Int,
	is        => 'rw',
	required  => 0,
	predicate => 'has_response_code',
	clearer   => 'clear_response_code',
	init_arg  => undef,
	lazy      => 0,
);

# HTTP response headers
has response_headers => (
	isa       => HashRef,
	is        => 'rw',
	required  => 0,
	predicate => 'has_response_headers',
	clearer   => 'clear_response_headers',
	init_arg  => undef,
	lazy      => 0,
);

# HTTP response content
has response_page => (
	isa       => Str,
	is        => 'rw',
	required  => 0,
	predicate => 'has_response_page',
	clearer   => 'clear_response_page',
	init_arg  => undef,
	lazy      => 0,
);

# ...
has result_code => (
	isa       => Str,
	is        => 'rw',
	required  => 0,
	predicate => 'has_result_code',
	clearer   => 'clear_result_code',
	init_arg  => undef,
	lazy      => 0,
);

# address verification response code
has avs_code => (
	isa       => AVSResult,
	is        => 'rw',
	required  => 0,
	predicate => 'has_avs_code',
	clearer   => 'clear_avs_code',
	init_arg  => undef,
	lazy      => 0,
);

# CVV2 response value
has cvv2_response => (
	isa       => Str,
	is        => 'rw',
	required  => 0,
	predicate => 'has_cvv2_response',
	clearer   => 'clear_cvv2_response',
	init_arg  => undef,
	lazy      => 0,
);

# Type of payment
has transaction_type => (
	isa       => Str,
	is        => 'rw',
	required  => 0,
	predicate => 'has_transaction_type',
	clearer   => 'clear_transaction_type',
	init_arg  => undef,
	lazy      => 0,
);

# Business::CyberSource client object
has _client => (
	isa       => 'Business::CyberSource::Client',
	is        => 'bare',
	builder   => '_build_client',
	required  => 0,
	predicate => 'has_client',
	init_arg  => undef,
	handles   => [ qw( submit ) ],
	lazy      => 1,
);

# Account username
has username => (
	isa       => NonEmptySimpleStr,
	is        => 'rw',
	required  => 0,
	predicate => 'has_login',
	alias     => 'login',
	lazy      => 0,
);

# Account API key
has password => (
	isa       => Str,
	is        => 'rw',
	required  => 0,
	predicate => 'has_password',
	lazy      => 0,
);

# Is this a test transaction?
has test_transaction => (
	isa       => Bool,
	is        => 'rw',
	default   => 0,
	required  => 0,
	predicate => 'has_test_transaction',
	trigger   => sub {
		my ( $self, $value ) = @_;

		$self->clear_server() if $value;

		return;
	},
	lazy      => 1,
);

# Require address verification
has require_avs => (
	isa       => Bool,
	is        => 'rw',
	default   => 0,
	required  => 0,
	predicate => 'has_require_avs',
	lazy      => 1,
);

# Remote server
has server => (
	isa       => NonEmptySimpleStr,
	is        => 'rw',
	default   => sub {
		my ( $self ) = @_;

		return ( $self->test_transaction() ) ? 'ics2wstest.ic3.com' : 'ics2ws.ic3.com';
	},
	required  => 0,
	predicate => 'has_server',
	clearer   => 'clear_server',
	lazy      => 1,
);

# Port for remote service
has port => (
	isa       => Int,
	is        => 'rw',
	default   => 443,
	required  => 0,
	predicate => 'has_port',
	lazy      => 1,
);

# Path to remote service
has path => (
	isa       => NonEmptySimpleStr,
	is        => 'rw',
	default   => 'commerce/1.x/transactionProcessor',
	required  => 0,
	predicate => 'has_path',
	lazy      => 1,
);

#### Method Modifiers ####

before qr/^(?:authorize|auth_reversal|capture|credit|sale)$/x, sub {
	my ( $self ) = @_;

	$self->_clear_fields();

	return;
};

around qr/^(?:server|port|path)$/x, sub {
	my ( $orig, $self, @args ) = @_;

	Exception::Base->throw( 'Setting server, port, and or path information is not supported by this module' ) if ( scalar @args > 0 );

	return $self->$orig( @args );
};

#### Consumed Roles ####

with
	'Business::OnlinePayment::CyberSource::Role::InputHandling',
	'Business::OnlinePayment::CyberSource::Role::ErrorReporting';

#### Meta class stuff ####

__PACKAGE__->meta->make_immutable();

1;

__END__

=pod

=head1 NAME

Business::OnlinePayment::CyberSource::Client - CyberSource Client object  for Business::OnlinePayment::CyberSource

=head1 VERSION

version 3.000016

=head1 SYNOPSIS

  use 5.010;
  use Business::OnlinePayment::CyberSource::Client;

  my $client = Business::OnlinePayment::CyberSource::Client->new();

  my $data = {
    invoice_number => 12345678,
    purchase_totals => {
      currency => 'USD',
      total => 9000,
    },
    bill_to => {
	first_name      => 'Tofu',
	last_name       => 'Beast',
	street1         => '123 Anystreet',
	city            => 'Anywhere',
	state           => 'UT',
	postal_code             => '84058',
	country         => 'US',
	email           => 'tofu@beast.org',
    },
    card => {
	account_number     => '4111111111111111',
	expiration      => { month => 12, year => 2012 },
	security_code => 1111,
    },
  };

  $client->authorize( $data );

  if ( $client->is_success() ) {
  	say "Transaction succeeded!";
  }

=head1 DESCRIPTION

Business::OnlinePayment::CyberSource::Client is a wrapper for the Business::CyberSource::Client.  It provides a translation layer between the L<Business::OnlinePayment> API and the L<Business::CyberSource> API.  While the input parameters and method names follow the conventions L<Business::CyberSource> API, the attribute names follow the L<Business::OnlinePayment> API.

=head1 ATTRIBUTES

=head2 is_success

use to determine whether or not the transaction succeeded

=head2 authorization

The authorization code supplied upon a successful authorization

=head2 order_number

This is the CyberSource-generated transaction identifier.  It should be used to identify subsequent transactions to authorizations.

	$client->capture( { ... service => { request_id => $client->order_number() }, ... } );

=head2 card_token

this is currently not supported.

=head2 fraud_score

This is currently not supported

=head2 fraud_transaction_id

This is currently not supported.

=head2 response_code

The HTTP response code

=head2 response_headers

A hash of the HTTP response headers

=head2 response_page

The HTTP response content

=head2 result_code

The processor response value

=head2 avs_code

The code returned for the Address Verification Service

=head2 cvv2_response

The CVV2 code value

=head2 transaction_type

This is the type value supplied to the content method of L<Business::OnlinePayment::CyberSource>

=head2 username

The CyberSource account username

=head2 password

The CyberSource account API key

=head2 test_transaction

Boolean value determining whether transactions should be sent as test transactions or not.

This method should be called after construction but before transactions are performed, unless it is supplied to the constructor.

=head2 require_avs

Boolean determining whether or not address verification should be done

=head2 server

This holds the value of the CyberSource server to which requests are being made.

=head2 port

This holds the port number on which the remote server is communicating.

=head2 path

This holds the path component of the remote service URI.

=head1 METHODS

=head2 authorize

This method should be used to perform an "Authorization Only" transaction.

Parameters:

  {
    reference_code  => 44544,
    bill_to         => {
      first_name    => 'John",
      last_name     => 'Doe',
      email         => 'john.doe@example.com',
      street1       => '101 Main Street',
      city          => 'Friendship',
      state         => 'AR',
      zip           => 12345,
      country       => 'US',
    },
    purchase_totals => {
      total         => 9000,
      currency      => 'USD',
    },
  }

Returns:

1 on success and 0 otherwise

=head2 sale

This method performs the "Normal Authorization" transaction.  It combines "Authorization Only" and "Post Authorization".

Parameters:

  {
    reference_code  => 44544,
    bill_to         => {
      first_name    => 'John",
      last_name     => 'Doe',
      email         => 'john.doe@example.com',
      street1       => '101 Main Street',
      city          => 'Friendship',
      state         => 'AR',
      zip           => 12345,
      country       => 'US',
    },
    purchase_totals => {
      total         => 9000,
      currency      => 'USD',
    },
  }

Returns:

1 on success and 0 otherwise

=head2 credit

this method performs a "Credit" transaction.

Parameters:

(For typical credits)

{
    reference_code  => 44544,
    bill_to         => {
      first_name    => 'John",
      last_name     => 'Doe',
      email         => 'john.doe@example.com',
      street1       => '101 Main Street',
      city          => 'Friendship',
      state         => 'AR',
      zip           => 12345,
      country       => 'US',
    },
    purchase_totals => {
      total         => 9000,
      currency      => 'USD',
    },
}

(For follow-on credits)

{
    reference_code  => 44544,
    service         => { request_id => 1010101 }, # Generated by CyberSource
    purchase_totals => {
      total         => 9000,
      currency      => 'USD',
    },
}

Returns:

1 on success and 0 otherwise

=head2 capture

This method performs a "Post Authorization" transaction.

Parameters:

{
    reference_code  => 44544,
    service         => { request_id => 1010101 }, # Generated by CyberSource
    purchase_totals => {
      total         => 9000,
      currency      => 'USD',
    },
}

Returns:

1 on success and 0 otherwise

=head2 auth_reversal

This method performs a "Void" transaction

Parameters:

{
    reference_code  => 44544,
    service         => { request_id => 1010101 }, # Generated by CyberSource
    purchase_totals => {
      total         => 9000,
      currency      => 'USD',
    },
}

Returns:

1 on success and 0 otherwise

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
https://github.com/xenoterracide/business-onlinepayment-cybersource/issues

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHORS

=over 4

=item *

Jad Wauthier <Jadrien dot Wauthier at GMail dot com>

=item *

Caleb Cushing <xenoterracide@gmail.com>

=item *

Peter Bowen <peter@bowenfamily.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by L<HostGator.com|http://www.hostgator.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
