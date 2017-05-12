package Business::CyberSource;
use 5.010;
use strict;
use warnings;

our $VERSION = '0.010008'; # VERSION

1;

# ABSTRACT: Perl interface to the CyberSource Simple Order SOAP API

__END__

=pod

=encoding UTF-8

=head1 NAME

Business::CyberSource - Perl interface to the CyberSource Simple Order SOAP API

=head1 VERSION

version 0.010008

=head1 DESCRIPTION

This library is a Perl interface to the CyberSource Simple Order SOAP API built
on L<Moose> and L<XML::Compile::SOAP> technologies. This library aims to
eventually provide a full interface the SOAPI.

You may wish to read the Official CyberSource Documentation on L<Credit Card
Services for the Simpler Order
API|http://apps.cybersource.com/library/documentation/dev_guides/CC_Svcs_SO_API/html/>
as it will provide further information on why what some things are and the
general workflow.

To get started you will want to read the documentation in
L<Business::CyberSource::Client> and L<Business::CyberSource::Request>. If you
find any documentation unclear or outright missing, please file a bug.

If there are features that are part of CyberSource's API but are not
documented, or are missing here, please file a bug. I'll be happy to add them,
but due to the size of the upstream API, I have not had time to cover all the features
and some are currently undocumented.

=head1 ENVIRONMENT

=head2 Debugging

Supports L<MooseY::RemoteHelper::Role::Client>s C<REMOTE_CLIENT_DEBUG>
variable. This can be set to either C<0>, C<1>, C<2>, for varying levels of
verbosity.

=head2 Testing

all environment variables are prefixed with C<PERL_BUSINESS_CYBERSOURCE_>

=head3 Credentials

=head4 USERNAME

=head4 PASSWORD

set's the L<username|Busines::CyberSource::Client/"user"> and
L<password|Busines::CyberSource::Client/"pass"> in the client for running
tests.

=head3 Direct Currency Conversion

=head4 DCC_CC_YYYY

sets the test credit card expiration year for both Visa and MasterCard

=head4 DCC_CC_MM

sets the test credit card expiration month for both Visa and MasterCard

=head4 DCC_MASTERCARD

A test credit card number provided by your your credit card processor

=head4 DCC_VISA

A test credit card number provided by your your credit card processor

=head1 EXAMPLE

In the example, C<carp> means you should log something C<Dumper> means you should
log it with lots of detail. L<Safe::Isa> is used because you should either use
it or check for C<blessed> it is always possible that somewhere in the stack
someone is using C<die> on a string.

	use 5.010;
	use Carp;
	use Try::Tiny;
	use Safe::Isa;
	use Data::Printer alias => 'Dumper';

	use Business::CyberSource::Client;
	use Business::CyberSource::Request::Authorization;
	use Business::CyberSource::Request::Capture;
	# exception namepsace
	my $e_ns = 'Business::CyberSource::Exception';

	my $client = Business::CyberSource::Client->new({
		user  => 'Merchant ID',
		pass  => 'API Key',
		test  => 1,
		debug => 1, # do not set in production as it prints sensative
                         # information
	});

	my $auth_request;
	try {
		$auth_request
			= Business::CyberSource::Request::Authorization->new({
				reference_code => '42',
				bill_to => {
					first_name  => 'Caleb',
					last_name   => 'Cushing',
					street1     => '100 somewhere st',
					city        => 'Houston',
					state       => 'TX',
					postal_code => '77064',
					country     => 'US',
					email       => 'xenoterracide@gmail.com',
				},
				purchase_totals => {
					currency => 'USD',
					total    => 5.00,
					discount => 0.03, # optional and may depend on processor
					duty     => 0.01, # optional and may depend on processor
				},
				card => {
					account_number => '4111111111111111',
					expiration => {
						month => 9,
						year  => 2025,
					},
				},
			});
	}
	catch {
		my $e = $_;
		if ( $e->$_does('Business::CyberSource::Response::Role::Base')) {
			carp $e->reason_code . $e->reason_text;
		}
		elsif ( $e->$_isa( $e_ns . '::SOAPFault'  ) ) {
			carp $e->faultcode . $e->faultstring;
		}
		elsif ( $e->$_isa( $e_ns ) || $e->$_isa( 'Moose::Exception' ) ) {
			Dumper( $e );
			## probably your payload was bad, check type more
			## specifically and feed good error messages to your
			## customer
		}
		else { # probably a coding error
			Dumper( $e );
		}
	};
	return unless $auth_request;

	my $auth_response;
	try {
		$auth_response = $client->submit( $auth_request );
	}
	catch {
		carp $_;
	};
	return unless $auth_response;

	unless( $auth_response->is_accept ) {
		carp $auth_response->reason_text;
	}
	else {
		my $capture_request
			= Business::CyberSource::Request::Capture->new({
				reference_code => $auth_response->reference_code,
				service => {
					request_id => $auth_response->request_id,
				},
				purchase_totals => {
					total    => $auth_response->auth->amount,
					discount => '0.05', # optional and may depend on processor
					duty     => '0.01', # optional and may depend on processor
					currency => $auth_response->purchase_totals->currency,
				},
			});

		my $capture_response;
		try {
			$capture_response = $client->submit( $capture_request );
		}
		catch {
			my $e = $_;
			if ( $e->$_does('Business::CyberSource::Response::Role::Base') )
				carp $e->reason_code . $e->reason_text;
			}
			elsif ( $e->$_isa( $e_ns . '::SOAPFault'  ) ) {
				carp $e->faultcode . $e->faultstring;
			}
			elsif ( $e->$_isa( $e_ns ) || $e->$_isa( 'Moose::Exception' ) ) {
				Dumper( $e );
				## probably your payload was bad, check type more
				## specifically and feed good error messages to your
				## customer
			}
			else { # probably a coding error
				Dumper( $e );
			}
		};
		return unless $capture_response;

		if ( $capture_response->is_accept ) {
			# you probably want to record this
			say $capture_response->capture->reconciliation_id;
		}
	}

This code is not meant to be DRY, but more of a top to bottom example. Also
note that if you really want to do Authorization and Capture at one time use a
L<Sale|Business::CyberSource::Request::Sale>. Most common Reasons for
Exceptions would be bad input into the request object (which validates things)
or CyberSource just randomly throwing an ERROR, in which case you can usually
just retry later. You don't have to print the response on error during
development, you can easily just use the C<REMOTE_CLIENT_DEBUG> Environment
variable.

=head1 ACKNOWLEDGMENTS

=over

=item * Mark Overmeer

for the help with getting L<XML::Compile::SOAP::WSS> working.

=item * L<HostGator|http://hostgator.com>

funding initial development.

=item * L<GüdTech|http://gudtech.com>

funding further development.

=back

=head1 SEE ALSO

=over

=item * L<Checkout::CyberSource::SOAP>

=item * L<Business::OnlinePayment::CyberSource>

=back

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
https://github.com/hostgator/business-cybersource/issues

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 CONTRIBUTORS

=for stopwords bvoskr Carl Carstenson Lantz dmaestro irinatodeva Jonathan William Taylor Robert Stone Rummy

=over 4

=item *

bvoskr <boris.voskresenskiy@endurance.com>

=item *

Carl Carstenson <ccarstenson@hostgator.com>

=item *

Carl Lantz <carl.lantz@endurance.com>

=item *

dmaestro <dmaestro@users.noreply.github.com>

=item *

irinatodeva <irinatodeva@users.noreply.github.com>

=item *

Jonathan William Taylor <elderling@gmail.com>

=item *

Jonathan William Taylor <jonathan.taylor@endurance.com>

=item *

Robert Stone <robertstone@hostgator.com>

=item *

Rummy <cerealbh@gmail.com>

=back

=head1 AUTHOR

Caleb Cushing <xenoterracide@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2017 by Caleb Cushing <xenoterracide@gmail.com>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
