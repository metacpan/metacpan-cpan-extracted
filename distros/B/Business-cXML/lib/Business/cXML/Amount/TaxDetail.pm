=encoding utf-8

=head1 NAME

Business::cXML::Amount::TaxDetail - cXML tax details

=head1 SYNOPSIS

	use Business::cXML::Amount;

=head2 DESCRIPTION

Object representation of a cXML tax details, part of a
L<Business::cXML::Amount> of type C<Tax>.

Only small subset of the possible attributes are currently implemented.

=head1 METHODS

See L<Business::cXML::Object/COMMON METHODS>.

=head1 PROPERTY METHODS

See L<Business::cXML::Object/PROPERTY METHODS> for how the following operate.

=over

=cut

use 5.014;
use strict;

package Business::cXML::Amount::TaxDetail;
use base qw(Business::cXML::Object);

use constant NODENAME => 'TaxDetail';
use constant PROPERTIES => (
	category    => '',
	percent     => undef,
	basis       => undef,
	tax         => (Business::cXML::Amount->new()),
	description => undef,
	purpose     => undef,
);
use constant OBJ_PROPERTIES => (
	basis       => [ 'Business::cXML::Amount', 'TaxableAmount' ],
	tax         => [ 'Business::cXML::Amount', 'TaxAmount' ],
	description => 'Business::cXML::Description',
);

use Business::cXML::Amount;
use XML::LibXML::Ferry;

sub from_node {
	my ($self, $el) = @_;

	$el->ferry($self, {
		percentageRate     => 'percent',
		isVatRecoverable   => '__UNIMPLEMENTED',
		taxPointDate       => '__UNIMPLEMENTED',
		paymentDate        => '__UNIMPLEMENTED',
		isTriangularTransaction => '__UNIMPLEMENTED',
		exemptDetail       => '__UNIMPLEMENTED',
		isWithholdingTax   => '__UNIMPLEMENTED',
		taxRateType        => '__UNIMPLEMENTED',
		basePercentageRate => '__UNIMPLEMENTED',
		isIncludedInPrice  => '__UNIMPLEMENTED',
		TaxableAmount      => [ 'basis', 'Business::cXML::Amount' ],
		TaxAmount          => [ 'tax',   'Business::cXML::Amount' ],
		TaxLocation        => '__UNIMPLEMENTED',
		TriangularTransactionLawReference => '__UNIMPLEMENTED',
		TaxRegime    => '__UNIMPLEMENTED',
		TaxExemption => '__UNIMPLEMENTED',
		Description  => [ 'description', 'Business::cXML::Description' ],
	});
}

sub to_node {
	my ($self, $doc) = @_;
	my $node = $doc->create($self->{_nodeName}, undef,
		purpose        => $self->{purpose},
		category       => $self->{category},
		percentageRate => $self->{percent},
	);

	$node->add($self->{basis}->to_node($node)) if defined $self->{basis};
	$node->add($self->{tax}->to_node($node));
	# TaxLocation
	$node->add($self->{description}->to_node($node)) if defined $self->{description};
	# TriangularTransactionLawReference
	# TaxRegime
	# TaxExemption

	return $node;
}

=item C<B<category>>

Mandatory, i.e. C<gst>

=item C<B<percent>>

Optional, i.e. C<8>

=item C<B<basis>>

Optional, L<Business::cXML::Amount> of type C<TaxableAmount>

=item C<B<tax>>

Mandatory, L<Business::cXML::Amount> of type C<TaxAmount>

=item C<B<description>>

Optional, L<Business::cXML::Description> object

=item C<B<purpose>>

Optional, i.e. C<tax>, C<custom duty>, C<shippingTax>, C<specialHandlingTax>

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
