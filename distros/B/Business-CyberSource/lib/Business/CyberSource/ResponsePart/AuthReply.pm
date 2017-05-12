package Business::CyberSource::ResponsePart::AuthReply;
use strict;
use warnings;
use namespace::autoclean;
use Module::Runtime  qw( use_module );

our $VERSION = '0.010008'; # VERSION

use Moose;
extends 'Business::CyberSource::MessagePart';
with qw(
	Business::CyberSource::Response::Role::AuthCode
	Business::CyberSource::Response::Role::ReconciliationID
	Business::CyberSource::Response::Role::ReasonCode
	Business::CyberSource::Response::Role::Amount
	Business::CyberSource::Response::Role::ProcessorResponse
	Business::CyberSource::Response::Role::ElectronicVerification
);

use MooseX::Types::CyberSource   qw(
	_VarcharTen
	AVSResult
	CvResults
	DateTimeFromW3C
);


has auth_record => (
	isa         => 'Str',
	remote_name => 'authRecord',
	predicate   => 'has_auth_record',
	is          => 'ro',
);

has datetime => (
	isa         => DateTimeFromW3C,
	remote_name => 'authorizedDateTime',
	is          => 'ro',
	coerce      => 1,
	predicate   => 'has_datetime',
);

has cv_code => (
	isa         => CvResults,
	remote_name => 'cvCode',
	predicate   => 'has_cv_code',
	is          => 'ro',
);

has cv_code_raw => (
	isa         => _VarcharTen,
	remote_name => 'cvCodeRaw',
	predicate   => 'has_cv_code_raw',
	is          => 'ro',
);

has avs_code => (
	isa         => AVSResult,
	remote_name => 'avsCode',
	predicate   => 'has_avs_code',
	is          => 'ro',
);

has avs_code_raw => (
	isa         => _VarcharTen,
	remote_name => 'avsCodeRaw',
	predicate   => 'has_avs_code_raw',
	is          => 'ro',
);

__PACKAGE__->meta->make_immutable;
1;
# ABSTRACT: Reply section for Authorizations

__END__

=pod

=encoding UTF-8

=head1 NAME

Business::CyberSource::ResponsePart::AuthReply - Reply section for Authorizations

=head1 VERSION

version 0.010008

=head1 ATTRIBUTES

=head2 datetime

	$response->auth->datetime if $response->auth->has_datetime;

B<Type:> L<DateTime>

Time of authorization.

=head2 avs_code

	$response->auth->avs_code if $response->auth->has_avs_code;

B<Type:> Varying character 1

=head2 avs_code_raw

	$response->auth->avs_code_raw if $response->auth->has_avs_code_raw;

B<Type:> Varying character 10

=head2 auth_record

	$response->auth->auth_record if $response->auth->has_auth_record;

B<Type:> String

=head2 auth_code

	$response->auth->auth_code if $response->auth->has_auth_code;

B<Type:> Varying character 7

Authorization code. Returned only if a value is returned by the processor.

=head2 cv_code

	$response->auth->cv_code if $response->auth->has_cv_code;

B<Type:> Single Char

=head2 cv_code_raw

	$response->auth->cv_code_raw if $response->auth->has_cv_code_raw;

B<Type:> Varying character 10

=head2 processor_response

	$response->auth->processor_response
		if $response->auth->has_processor_response;

Type: Varying character 10

=head2 reconciliation_id

	$response->auth->reconciliation_id
		if $response->auth->has_reconciliation_id

Type: Int

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
