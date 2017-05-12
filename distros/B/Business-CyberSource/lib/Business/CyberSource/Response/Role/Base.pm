package Business::CyberSource::Response::Role::Base;
use strict;
use warnings;
use namespace::autoclean;

our $VERSION = '0.010008'; # VERSION

use Moose::Role;
use MooseX::RemoteHelper;
use Moose::Util::TypeConstraints;
use MooseX::Types::Common::String 0.001005 qw( NonEmptySimpleStr );
use MooseX::Types::CyberSource qw(
	Decision
	RequestID
);

with 'Business::CyberSource::Role::Traceable' => {
	-excludes => [qw( trace )]
},
qw(
	Business::CyberSource::Response::Role::ReasonCode
);

## common
has request_id => (
	isa         => RequestID,
	remote_name => 'requestID',
	is          => 'ro',
	predicate   => 'has_request_id',
	required    => 1,
);

has decision => (
	isa         => Decision,
	remote_name => 'decision',
	is          => 'ro',
	required    => 1,
);

has request_token => (
	isa         => subtype( NonEmptySimpleStr, where { length $_ <= 256 }),
	remote_name => 'requestToken',
	required    => 1,
	is          => 'ro',
);

has reason_text => (
	isa      => 'Str',
	required => 1,
	lazy     => 1,
	is       => 'ro',
	builder  => '_build_reason_text',
);

has is_accept => (
	isa      => 'Bool',
	is       => 'ro',
	lazy     => 1,
	init_arg => undef,
	default  => sub {
		my $self = shift;
		return $self->decision eq 'ACCEPT' ? 1 : 0;
	},
);

has is_reject => (
	isa      => 'Bool',
	is       => 'ro',
	lazy     => 1,
	init_arg => undef,
	default  => sub {
		my $self = shift;
		return $self->decision eq 'REJECT' ? 1 : 0;
	},
);

has is_error => (
	isa      => 'Bool',
	is       => 'ro',
	lazy     => 1,
	init_arg => undef,
	default  => sub {
		my $self = shift;
		return $self->decision eq 'ERROR' ? 1 : 0;
	}
);

sub _build_reason_text {
	my ( $self, $reason_code ) = @_;
	$reason_code //= $self->reason_code;

	my %reason = (
		100 => 'Successful transaction',
		101 => 'The request is missing one or more required fields',
		102 => 'One or more fields in the request contains invalid data',
		110 => 'Only a partial amount was approved',
		150 => 'General system failure',
		151 => 'The request was received but there was a server timeout.',
		152 => 'The request was received, but a service did not finish '
			. 'running in time'
			,
		200 => 'The authorization request was approved by the issuing bank '
			. 'but declined by CyberSource because it did not pass the '
			. 'Address Verification Service (AVS) check'
			,
		201 => 'The issuing bank has questions about the request. You do not '
			. 'receive an authorization code programmatically, but you might '
			. 'receive one verbally by calling the processor'
			,
		202 => 'Expired card. You might also receive this if the expiration '
			. 'date you provided does not match the date the issuing bank '
			. 'has on file'
			,
		203 => 'General decline of the card. No other information provided '
			. 'by the issuing bank'
			,
		204 => 'Insufficient funds in the account',
		205 => 'Stolen or lost card',
		207 => 'Issuing bank unavailable',
		208 => 'Inactive card or card not authorized for card-not-present '
			. 'transactions'
			,
		209 => 'American Express Card Identification Digits (CID) did not '
			. 'match'
			,
		210 => 'The card has reached the credit limit',
		211 => 'Invalid CVN',
		221 => 'The customer matched an entry on the processor\'s negative '
			. 'file'
			,
		230 => 'The authorization request was approved by the issuing bank '
			. 'but declined by CyberSource because it did not pass the CVN '
			. 'check'
			,
		231 => 'Invalid account number',
		232 => 'The card type is not accepted by the payment processor',
		233 => 'General decline by the processor',
		234 => 'There is a problem with your CyberSource merchant '
			. 'configuration'
			,
		235 => 'The requested amount exceeds the originally authorized '
			. 'amount'
			,
		236 => 'Processor failure',
		237 => 'The authorization has already been reversed',
		238 => 'The authorization has already been captured',
		239 => 'The requested transaction amount must match the previous '
			. 'transaction amount'
			,
		240 => 'The card type sent is invalid or does not correlate with '
			. 'the credit card number'
			,
		241 => 'The request ID is invalid',
		242 => 'You requested a capture, but there is no corresponding, '
			. 'unused authorization record'
			,
		243 => 'The transaction has already been settled or reversed',
		246 => 'The capture or credit is not voidable because the capture or '
			. 'credit information has already been submitted to your '
			. 'processor. Or, you requested a void for a type of '
			. 'transaction that cannot be voided'
			,
		247 => 'You requested a credit for a capture that was previously '
			. 'voided'
			,
		250 => 'The request was received, but there was a timeout at the '
			. 'payment processor'
			,
		600 => 'Address verification failed',
	);

	return $reason{$reason_code};
}

1;

# ABSTRACT: common to normal and exception (ERROR) responses

__END__

=pod

=encoding UTF-8

=head1 NAME

Business::CyberSource::Response::Role::Base - common to normal and exception (ERROR) responses

=head1 VERSION

version 0.010008

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
