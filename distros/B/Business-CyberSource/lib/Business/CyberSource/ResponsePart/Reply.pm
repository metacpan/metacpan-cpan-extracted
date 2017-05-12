package Business::CyberSource::ResponsePart::Reply;
use strict;
use warnings;
use namespace::autoclean;

our $VERSION = '0.010008'; # VERSION

use Moose;
extends 'Business::CyberSource::MessagePart';
with qw(
	Business::CyberSource::Response::Role::AuthCode
	Business::CyberSource::Response::Role::ReasonCode
	Business::CyberSource::Response::Role::ReconciliationID
	Business::CyberSource::Response::Role::Amount
	Business::CyberSource::Response::Role::ProcessorResponse
	Business::CyberSource::Response::Role::RequestDateTime
);

__PACKAGE__->meta->make_immutable;
1;
# ABSTRACT: Generic Reply part of response

__END__

=pod

=encoding UTF-8

=head1 NAME

Business::CyberSource::ResponsePart::Reply - Generic Reply part of response

=head1 VERSION

version 0.010008

=head1 EXTENDS

L<Business::CyberSource::MessagePart>

=head1 WITH

=over

=item L<Business::CyberSource::Response::Role::ReasonCode>

=item L<Business::CyberSource::Response::Role::ReconciliationID>

=item L<Business::CyberSource::Response::Role::Amount>

=item L<Business::CyberSource::Response::Role::ProcessorResponse>

=item L<Business::CyberSource::Response::Role::RequestDateTime>

=back

=head1 ATTRIBUTES

=head2 amount

=head2 reason_code

=head2 reconciliation_id

=head2 processor_response

=head2 datetime

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
