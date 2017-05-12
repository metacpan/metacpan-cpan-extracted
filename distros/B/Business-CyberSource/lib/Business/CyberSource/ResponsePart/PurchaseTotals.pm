package Business::CyberSource::ResponsePart::PurchaseTotals;
use strict;
use warnings;
use namespace::autoclean;

our $VERSION = '0.010008'; # VERSION

use Moose;
extends 'Business::CyberSource::MessagePart';
with qw(
	Business::CyberSource::Role::Currency
	Business::CyberSource::Role::ForeignCurrency
);

__PACKAGE__->meta->make_immutable;
1;
# ABSTRACT: PurchaseTotals part of response

__END__

=pod

=encoding UTF-8

=head1 NAME

Business::CyberSource::ResponsePart::PurchaseTotals - PurchaseTotals part of response

=head1 VERSION

version 0.010008

=head1 EXTENDS

L<Business::CyberSource::MessagePart>

=head1 WITH

=over

=item L<Business::CyberSource::Role::Currency>

=item L<Business::CyberSource::Role::ForeignCurrency>

=back

=head1 ATTRIBUTES

=head2 currency

=head2 foreign_currency

Billing currency returned by the DCC service. For the possible values, see the ISO currency codes

=head2 foreign_amount

=head2 exchange_rate

=head2 exchange_rate_timestamp

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
