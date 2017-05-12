package Business::CyberSource::RequestPart::PurchaseTotals;
use strict;
use warnings;
use namespace::autoclean;

our $VERSION = '0.010008'; # VERSION

use Moose;
extends 'Business::CyberSource::MessagePart';
with    'MooseX::RemoteHelper::CompositeSerialization';

with qw(
	Business::CyberSource::Role::Currency
	Business::CyberSource::Role::ForeignCurrency
);

use MooseX::Types::Common::Numeric qw( PositiveOrZeroNum );

has total => (
	isa         => PositiveOrZeroNum,
	remote_name => 'grandTotalAmount',
	traits      => [ 'SetOnce' ],
	is          => 'rw',
	predicate   => 'has_total',

);

has discount => (
    isa         => PositiveOrZeroNum,
    remote_name => 'discountAmount',
    traits      => ['SetOnce'],
    is          => 'rw',
    predicate   => 'has_discount',

);

has duty => (
    isa         => PositiveOrZeroNum,
    remote_name => 'dutyAmount',
    traits      => ['SetOnce'],
    is          => 'rw',
    predicate   => 'has_duty',

);

__PACKAGE__->meta->make_immutable;
1;
# ABSTRACT: Purchase Totals

__END__

=pod

=encoding UTF-8

=head1 NAME

Business::CyberSource::RequestPart::PurchaseTotals - Purchase Totals

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

=head2 total

Grand total for the order. You must include either this field or
L<Item unit price|Business::CyberSource::RequestPart::Item/"unit_price"> in your
request.

=head2 discount

Total discount applied to the order. This is level II or level III data related
information depending on the payment processor. For more information see
http://apps.cybersource.com/library/documentation/dev_guides/Level_2_3_SO_API/Level_II_III_SO_API.pdf

=head2 duty

Total charges for any import or export duties included in the order. This is
level II or level III data related information depending on the payment
processor.  For more information see
http://apps.cybersource.com/library/documentation/dev_guides/Level_2_3_SO_API/Level_II_III_SO_API.pdf

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
