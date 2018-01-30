=encoding utf-8

=head1 NAME

Business::cXML::ItemIn - cXML line item, from seller to buyer

=head1 SYNOPSIS

	use Business::cXML::ItemIn;

=head1 DESCRIPTION

Object representation of cXML C<ItemIn>.

=head1 METHODS

See L<Business::cXML::Object/COMMON METHODS>.

=head1 PROPERTY METHODS

See L<Business::cXML::Object/PROPERTY METHODS> for how the following operate.

=over

=cut

use 5.014;
use strict;

package Business::cXML::ItemIn;
use base qw(Business::cXML::Object);

use constant NODENAME => 'ItemIn';
use constant PROPERTIES => (
	sku             => '',
	qty             => 0,
	qty_open        => undef,
	qty_promised    => undef,
	i               => undef,
	i_parent        => undef,
	is_group        => undef,
	is_parent_group => undef,
	is_service      => undef,
	price           => undef,
	descriptions    => [],
	unit            => 'EA',
	class_domain    => 'UNSPSC',
	class           => '',
	manu_part       => undef,
	manu_name       => undef,
	manu_lang       => 'en-US',
	delay           => undef,
	chars           => [],
	url             => undef,
	shipping        => undef,
	tax             => undef,
);
use constant OBJ_PROPERTIES => (
	price           => [ 'Business::cXML::Amount', 'UnitPrice' ],
	descriptions    => 'Business::cXML::Description',
	chars           => 'Business::cXML::Characteristic',
	shipping        => [ 'Business::cXML::Amount', 'Shipping' ],
	tax             => [ 'Business::cXML::Amount', 'Tax'      ],
);

use Business::cXML::Amount;
use XML::LibXML::Ferry;

sub _bool {
	my ($self, $val) = @_;
	return 1 if $val =~ /^(composite|groupLevel|service)$/;
	return 0;  # DTD guarantees: item|itemLevel|material
}

sub from_node {
	my ($self, $el) = @_;

	$el->ferry($self, {
		quantity           => 'qty',
		openQuantity       => 'qty_open',
		promisedQuantity   => 'qty_promised',
		lineNumber         => 'i',
		parentLineNumber   => 'i_parent',
		itemType           => [ 'is_group',        \&_bool ],
		compositeItemType  => [ 'is_parent_group', \&_bool ],
		itemClassification => [ 'is_service',      \&_bool ],
		itemCategory       => '__UNIMPLEMENTED',
		ItemID             => {
			# UNIMPLEMENTED SupplierPartID.revisionID
			SupplierPartID          => 'sku',
			SupplierPartAuxiliaryID => '__UNIMPLEMENTED',
			BuyerPartID             => '__UNIMPLEMENTED',
			IdReference             => '__UNIMPLEMENTED',
		},
		Path       => '__UNIMPLEMENTED',
		ItemDetail => {
			UnitPrice             => [ 'price',        'Business::cXML::Amount'      ],
			Description           => [ 'descriptions', 'Business::cXML::Description' ],
			OverallLimit          => '__UNIMPLEMENTED',
			ExpectedLimit         => '__UNIMPLEMENTED',
			UnitOfMeasure         => 'unit',
			PriceBasisQuantity    => '__UNIMPLEMENTED',
			Classification        => {
				# We only keep the last one that will be processed
				domain => 'class_domain',
				code   => '__UNIMPLEMENTED',
				__text => 'class',
			},
			ManufacturerPartID    => 'manu_part',
			ManufacturerName      => {
				'xml:lang' => 'manu_lang',
				__text     => 'manu_name',
			},
			# URL is implicit
			LeadTime              => 'delay',
			Dimension             => '__UNIMPLEMENTED',
			ItemDetailIndustry    => {
				# Attribute isConfigurableMaterial is implied from the presence of characteristics
				ItemDetailRetail => {
					EANID                  => '__OBSOLETE',
					EuropeanWasteCatalogID => '__UNIMPLEMENTED',
					Characteristic         => [ 'chars', 'Business::cXML::Characteristic' ],
				},
			},
			AttachmentReference   => '__UNIMPLEMENTED',
			PlannedAcceptanceDays => '__UNIMPLEMENTED',
		},
		SupplierID   => '__UNIMPLEMENTED',
		SupplierList => '__UNIMPLEMENTED',
		ShipTo       => '__UNIMPLEMENTED',
		Shipping     => [ 'shipping', 'Business::cXML::Amount' ],
		Tax          => [ 'tax',      'Business::cXML::Amount' ],
		SpendDetail  => '__UNIMPLEMENTED',
		Distribution => '__UNIMPLEMENTED',
		Contact      => '__UNIMPLEMENTED',
		Comments     => '__UNIMPLEMENTED',
		ScheduleLine => '__UNIMPLEMENTED',
		BillTo       => '__UNIMPLEMENTED',
		Batch        => '__UNIMPLEMENTED',
		DateInfo     => '__UNIMPLEMENTED',
	});
}

sub to_node {
	my ($self, $doc) = @_;
	my $node = $doc->create($self->{_nodeName}, undef,
		quantity           => $self->{qty},
		openQuantity       => $self->{qty_open},
		promisedQuantity   => $self->{qty_promised},
		lineNumber         => $self->{i},
		parentLineNumber   => $self->{i_parent},
	);
	$node->{itemType}           = ($self->is_group        ? 'composite'  : 'item'     ) if defined $self->{is_group};
	$node->{compositeItemType}  = ($self->is_parent_group ? 'groupLevel' : 'itemLevel') if defined $self->{is_parent_group};
	$node->{itemClassification} = ($self->is_service      ? 'service'    : 'material' ) if defined $self->{is_service};

	$node->add('ItemID')->add('SupplierPartID', $self->{sku});

	my $idet = $node->add('ItemDetail');
	$self->price({}) unless defined $self->{price};
	$idet->add($self->{price}->to_node($doc));
	$self->descriptions({}) unless scalar(@{ $self->{descriptions} } > 0);
	$idet->add($_->to_node($doc)) foreach (@{ $self->{descriptions} });
	$idet->add('UnitOfMeasure', $self->{unit});
	$idet->add('Classification', $self->{class}, domain => $self->{class_domain});
	$idet->add('ManufacturerPartID', $self->{manu_part}) if defined $self->{manu_part};
	$idet->add('ManufacturerName', $self->{manu_name}, 'xml:lang' => $self->{manu_lang}) if defined $self->{manu_name};
	$idet->add('URL', $self->{url}) if defined $self->{url};
	$idet->add('LeadTime', $self->{delay}) if defined $self->{delay};
	if (scalar(@{ $self->{chars} }) > 0) {
		my $ret = $idet->add('ItemDetailIndustry', undef, isConfigurableMaterial => 'yes')->add('ItemDetailRetail');
		$ret->add($_->to_node($doc)) foreach (@{ $self->{chars} });
	};

	$node->add($self->{shipping}->to_node($doc)) if defined $self->{shipping};
	$node->add($self->{tax}->to_node($doc)     ) if defined $self->{tax};

	return $node;
}


=item C<B<sku>>

Mandatory SKU, a string uniquely identifying the product being sold, with the
L</chars> (colors, sizes) selected.

=item C<B<qty>>

Mandatory, how many items.  Default: C<0>

=item C<B<qty_open>>

Optional, the quantity pending to be fulfilled by the seller to ship to the
buyer.

=item C<B<qty_promised>>

Optional, the quantity that has been promised by the selling party.

=item C<B<i>>

=item C<B<i_parent>>

Optional, line number (starting from 1).  I<C<i_parent>> refers to a parent
item's I<C<i>>.  This allows nesting items.

=item C<B<is_group>>

=item C<B<is_parent_group>>

Optional, whether the item (or its parent) contains child items.

The current implementation B<does not set this for you> when you use
I<C<i_parent>>: you must set these according to your structure.

=item C<B<is_service>>

Optional, clarify whether the item is a service (true) or material (false).

=item C<B<price>>

Mandatory, L<Business::cXML::Amount> object of type C<UnitPrice>.

=item C<B<descriptions>>

Mandatory (at least one)

=item C<B<unit>>

Mandatory, UN/CEFACT Recommendation 20 unit of measure.  Default: C<EA>
meaning "each", items are regarded as separate units.  Also common: C<HUR>
means one hour.

See
L<http://www.unece.org/tradewelcome/un-centre-for-trade-facilitation-and-e-business-uncefact/outputs/cefactrecommendationsrec-index/list-of-trade-facilitation-recommendations-n-16-to-20.html>
for more details about UN/CEFACT Recommendation 20 units of measure.

=item C<B<class_domain>>

=item C<B<class>>

Mandatory, name of classification such as C<UNSPSC> (default) and the
classification itself (such as an 8+ digit UNSPSC number).

See L<https://en.wikipedia.org/wiki/UNSPSC> and L<http://www.unspsc.org/> for
more details about UNSPSC classifications, for example, C<53101902> "Men's
suits"

=item C<B<manu_part>>

Optional, ID with which the item's manufacturer identifies the item.

=item C<B<manu_name>>

=item C<B<manu_lang>>

Optional, name of the item's manufacturer and language of that name.
C<manu_lang> defaults to C<en-us> if only C<manu_name> is set.

=item C<B<delay>>

Optional, number of days to receive the item.

=item C<B<chars>>

Optional, list of L<Business::cXML::Characteristic> that define this specific
product item (colors, sizes, etc.)  The item will be deemed "configurable" if
there are any characteristics.

=item C<B<url>>

Optional

=item C<B<shipping>>

Optional, L<Business::cXML::Amount> object of type C<Shipping>

=item C<B<tax>>

Optional, L<Business::cXML::Amount> object of type C<Tax>

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
