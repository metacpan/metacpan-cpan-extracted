=encoding utf-8

=head1 NAME

Business::cXML::Amount - cXML amounts

=head1 SYNOPSIS

	use Business::cXML::Amount;
	my $charge = new Business::cXML::Amount 'Charge' {
		currency => 'CAD',
		amount   => '17.99',
	};

=head1 DESCRIPTION

Object representation of the common cXML amounts:

=over

C<AdditionalCost>
C<AvailablePrice>
C<Charge>
C<DeductedPrice>
C<DeductionAmount>
C<DepositAmount>
C<DiscountAmount>
C<DiscountBasis>
C<DueAmount>
C<ExactAmount>
C<ExpectedLimit>
C<Fee>
C<FeeAmount>
C<FixedAmount>
C<GoodsAndServiceAmount>
C<GrossAmount>
C<GrossProgressPaymentAmount>
C<InformationalAmount>
C<InformationalPrice>
C<InformationalPriceExclTax>
C<MaxAmount>
C<MaxReleaseAmount>
C<MinAmount>
C<MinReleaseAMount>
C<NetAmount>
C<OriginalPrice>
C<OverallLimit>
C<PartialAmount>
C<Penalty>
C<Shipping>
C<ShippingAmount>
C<SpecialHandlingAmount>
C<SubtotalAmount>
C<Tax>
C<TaxableAmount>
C<TaxAdjustment>
C<TaxAdjustmentDetail>
C<TaxAmount>
C<TotalAllowances>
C<TotalAmountInBillingCurrency>
C<TotalAmountInPostedCurrency>
C<TotalAmountWithoutTax>
C<TotalCharges>
C<TotalRetailAmount>
C<TotalReturnableItemsDepositAmount>
C<UnitGrossPrice>
C<UnitNetPriceCorrection>

=back

Not all variations allow the same attributes, but since they overwhelmingly
share the same basic function and structure, they were grouped into a single
object.

Specifically B<NOT> implemented are:

=over

=item * C<Distribution> sub-section

=item * C<Modifications> sub-section

=item * C<PriceBasisQuantity> sub-section

=item * C<AdditionalCost> with a C<Percentage> sub-section (only its C<Money> is implemented)

=back

=head1 METHODS

See L<Business::cXML::Object/COMMON METHODS>.

=head1 PROPERTY METHODS

See L<Business::cXML::Object/PROPERTY METHODS> for how the following operate.

=over

=cut

use 5.014;
use strict;

package Business::cXML::Amount;
use base qw(Business::cXML::Object);

use Business::cXML::Amount::TaxDetail;
use XML::LibXML::Ferry;

use constant NODENAME => 'Amount';
use constant PROPERTIES => (
	currency        => 'USD',
	amount          => '0.00',
	description     => undef,
	type            => undef,
	fees            => [],
	tracking_domain => undef,
	tracking_id     => undef,
	tax_details     => [],
	taxadj_details  => [],
	category        => '',
	region          => undef,
);
use constant OBJ_PROPERTIES => (
	fees           => 'Business::cXML::Amount',
	tax_details    => 'Business::cXML::Amount::TaxDetail',
	taxadj_details => 'Business::cXML::Amount',
	description    => 'Business::cXML::Description',
);

sub from_node {
	my ($self, $el) = @_;

	$el->ferry($self, {
		trackingDomain      => 'tracking_domain',
		trackingId          => 'tracking_id',
		tracking            => '__OBSOLETE',
		Money               => { __text => 'amount' },
		Fee                 => [ 'fees', 'Business::cXML::Amount'],
		Percentage          => '__UNIMPLEMENTED',
		PriceBasisQuantity  => '__UNIMPLEMENTED',
		TaxDetail           => [ 'tax_details',    'Business::cXML::Amount::TaxDetail' ],
		TaxAdjustmentDetail => [ 'taxadj_details', 'Business::cXML::Amount'            ],
		Description         => [ 'description',    'Business::cXML::Description'       ],
		Distribution        => '__UNIMPLEMENTED',
		Modifications       => '__UNIMPLEMENTED',
	});
}

sub to_node {
	my ($self, $doc) = @_;
	my $node = $doc->create($self->{_nodeName});

	$self->{type} = 'other' if $self->{_nodeName} eq 'AvailablePrice' && !defined $self->{type};
	$node->{type} = $self->{type} if defined $self->{type} && $self->{_nodeName} =~ /^(AvailablePrice|Fee|OriginalPrice)$/;
	if ($self->{_nodeName} eq 'TaxAdjustmentDetail') {
		$node->{category} = $self->{category};
		$node->{region} = $self->{region} if defined $self->{region};
	};

	if ($self->{_nodeName} eq 'Shipping') {
		$node->{trackingDomain} = $self->{tracking_domain} if defined $self->{tracking_domain};
		$node->{trackingId} = $self->{tracking_id} if defined $self->{tracking_id};
	};

	$node->add('Money', $self->{amount}, currency => $self->{currency});

	if ($self->{_nodeName} eq 'FeeAmount') {
		$node->add($_->to_node($node)) foreach (@{ $self->{fees} });
	};

	$node->add($self->{description}->to_node($node))
		if defined $self->{description}
			&& $self->{_nodeName} =~ /^(AvailablePrice|Penalty|Shipping|SpecialHandlingAmount|Tax)$/
	;

	if ($self->{_nodeName} eq 'Tax') {
		$node->add($_->to_node($node)) foreach (@{ $self->{tax_details} });
	};
	if ($self->{_nodeName} eq 'TaxAdjustment') {
		$node->add($_->to_node($node)) foreach (@{ $self->{taxadj_details} });
	};

	return $node;
}

=item C<B<currency>>

Mandatory, i.e. C<USD> (default)

=item C<B<amount>>

Mandatory, i.e C<0.0> (default).  Use a string if you want control over formatting.

=back

=head3 C<AvailablePrice>, C<Penalty>, C<Shipping>, C<SpecialHandlingAmount>, C<Tax> add:

=over

=item C<B<description>>

Optional, L<Business::cXML::Description> object

=back

=head3 C<AvailablePrice>, C<Fee>, C<OriginalPrice> add:

=over

=item C<B<type>>

Optional.  For C<AvailablePrice>, it is expected to be one of: C<lowest>,
C<lowestCompliant>, C<highestCompliant>, C<highest>, C<other> (default)

=back

=head3 C<FeeAmount> adds:

=over

=item C<B<fees>[]>

Optional, L<Business::cXML::Amount> objects of C<Fee> type

=back

=head3 C<Shipping> adds:

=over

=item C<B<tracking_domain>>

Optional, logistics supplier, i.e. C<FedEx>, C<UPS>

=item C<B<tracking_id>>

Optional, logistics supplier tracking number

=back

=head3 C<Tax> adds:

=over

=item C<B<tax_details>[]>

Optional, L</Business::cXML::Amount::TaxDetail> objects

=back

=head3 C<TaxAdjustment> adds:

=over

=item C<B<taxadj_details>[]>

Optional, L<Business::cXML::Amount> objects named C<TaxAdjustmentDetail>

=back

=head3 C<TaxAdjustmentDetail> adds:

=over

=item C<B<category>>

Mandatory

=item C<B<region>>

Optional

=back

=head1 AUTHOR

Stéphane Lavergne L<https://github.com/vphantom>

=head1 ACKNOWLEDGEMENTS

Graph X Design Inc. L<https://www.gxd.ca/> sponsored this project.

=head1 COPYRIGHT & LICENSE

Copyright (c) 2017-2018 Stéphane Lavergne L<https://github.com/vphantom>

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

=cut

1;
