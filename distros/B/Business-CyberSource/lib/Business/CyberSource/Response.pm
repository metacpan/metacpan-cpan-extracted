package Business::CyberSource::Response;
use strict;
use warnings;
use namespace::autoclean;
use Module::Load 'load';

our $VERSION = '0.010008'; # VERSION

use Moose;
extends 'Business::CyberSource::Message';
with qw(
	Business::CyberSource::Response::Role::Base
);

use MooseX::Types::CyberSource qw(
	ResPurchaseTotals
	AuthReply
	Reply
	TaxReply
	DCCReply
);

has '+reference_code' => ( required => 0 );

has purchase_totals => (
	isa         => ResPurchaseTotals,
	remote_name => 'purchaseTotals',
	is          => 'ro',
	predicate   => 'has_purchase_totals',
	coerce      => 1,
	handles     => [ qw( currency ) ],
);


has auth => (
	isa         => AuthReply,
	remote_name => 'ccAuthReply',
	is          => 'ro',
	predicate   => 'has_auth',
	coerce      => 1,
);

has capture => (
	isa         => Reply,
	remote_name => 'ccCaptureReply',
	is          => 'ro',
	predicate   => 'has_capture',
	coerce      => 1,
);

has credit => (
	isa         => Reply,
	remote_name => 'ccCreditReply',
	is          => 'ro',
	predicate   => 'has_credit',
	coerce      => 1,
);

has auth_reversal=> (
	isa         => Reply,
	remote_name => 'ccAuthReversalReply',
	is          => 'ro',
	predicate   => 'has_auth_reversal',
	coerce      => 1,
);

has dcc => (
	isa         => DCCReply,
	remote_name => 'ccDCCReply',
	is          => 'ro',
	predicate   => 'has_dcc',
	coerce      => 1,
);

has tax => (
	isa         => TaxReply,
	remote_name => 'taxReply',
	is          => 'ro',
	predicate   => 'has_tax',
	coerce      => 1,
);

__PACKAGE__->meta->make_immutable;
1;

# ABSTRACT: Response Object

__END__

=pod

=encoding UTF-8

=head1 NAME

Business::CyberSource::Response - Response Object

=head1 VERSION

version 0.010008

=head1 SYNOPSIS

	use Try::Tiny;

	my $response
		= try {
			$client->run_transaction( $request )
		}
		catch {
			if ( blessed $_
				&& $_->isa('Business::CyberSource::Response::Exception')
			) {
				if ( $_->is_error ) {
					# probably a temporary error on cybersources problem retry
				}
			}
			else {
				# log it and investigate
			}
		};

	if ( $response->is_accept ) {
		if ( $response->has_auth ) {
			# pass to next request or store
			$response->request_id;
			$response->reference_code;
		}
	}
	elsif ( $response->is_reject ) {
		# log it
		$response->request_id;
		$response->reason_text;
	}
	else {
		# throw exception
	}

=head1 DESCRIPTION

This response can be used to determine the success of a transaction,
as well as receive a follow up C<request_id> in case you need to do further
actions with this.

=head1 EXTENDS

L<Business::CyberSource::Message>

=head1 WITH

=over

=item L<Business::CyberSource::Role::RequestID>

=back

=head1 ATTRIBUTES

=head2 is_accept

boolean way of determining whether the transaction was accepted

=head2 is_reject

boolean way of determining whether the transaction was rejected

=head2 is_error

boolean way of determining whether the transaction was error. Note this is used
internally as a response that is an error will throw an exception.

=head2 decision

Summarizes the result of the overall request. This is the text, you can check
L<is_accept|/"is_accept">, L<is_reject|/"is_reject"> for a more boolean way.

=head2 reason_code

Numeric value corresponding to the result of the credit card authorization
request.

=head2 reason_text

official description of returned reason code.

I<warning:> reason codes are returned by CyberSource and occasionally do not
reflect the real reason for the error please inspect the
L<trace|Business::Cybersource::Message/"trace"> request/response for issues

=head2 request_token

Request token data created by CyberSource for each reply. The field is an
encoded string that contains no confidential information, such as an account
or card verification number. The string can contain up to 256 characters.

=head2 reference_code

B<Type:> Varying character 50

The merchant reference code originally sent

=head2 auth

	$response->auth if $response->has_auth;

B<Type:> L<Business::CyberSource::ResponsePart::AuthReply>

=head2 purchase_totals

	$response->purchase_totals if $response->has_purchase_totals;

B<Type:> L<Business::CyberSource::ResponsePart::PurchaseTotals>

=head2 capture

	$response->capture if $response->has_capture;

B<Type:> L<Business::CyberSource::ResponsePart::Reply>

=head2 credit

	$response->credit if $response->has_credit;

B<Type:> L<Business::CyberSource::ResponsePart::Reply>

=head2 auth_reversal

	$response->auth_reversal if $response->has_auth_reversal;

B<Type:> L<Business::CyberSource::ResponsePart::Reply>

=head2 dcc

	$response->dcc if $response->has_dcc;

B<Type:> L<Business::CyberSource::ResponsePart::DCCReply>

=head2 tax

	$response->tax if $response->has_tax;

B<Type:> L<Business::CyberSource::ResponsePart::TaxReply>

=for test_synopsis my ( $request, $client );

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
https://github.com/hostgator/business-cybersource/issues

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

Caleb Cushing <xenoterracide@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2017 by Caleb Cushing <xenoterracide@gmail.com>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
