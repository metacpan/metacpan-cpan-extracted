=encoding utf-8

=head1 NAME

Business::cXML::Message::PunchOutOrder - cXML punch-out order

=head1 SYNOPSIS

	use Business::cXML;
	my $cxml = new Business::cXML;
	my $poom = $cxml->new_message('PunchOutOrder');

=head1 DESCRIPTION

Object representation of a cXML punch-out order.

=head1 METHODS

See L<Business::cXML::Object/COMMON METHODS>.

=head1 PROPERTY METHODS

See L<Business::cXML::Object/PROPERTY METHODS> for how the following operate.

=over

=cut

use 5.014;
use strict;

package Business::cXML::Message::PunchOutOrder;
use base qw(Business::cXML::Object);

use constant {
	CXML_POOM_STATUS_PENDING => 1,
	CXML_POOM_STATUS_FINAL   => 2,
};

use constant NODENAME => 'PunchOutOrderMessage';
use constant PROPERTIES => (
	buyer_cookie      => ' ',
	highest_operation => 'create',
	status            => undef,
	total             => undef,
	shipto            => undef,
	shipping          => undef,
	tax               => undef,
	items             => [],
	id                => undef,
);
use constant OBJ_PROPERTIES => (
	total    => [ 'Business::cXML::Amount', 'Total'    ],
	shipto   => 'Business::cXML::ShipTo',
	shipping => [ 'Business::cXML::Amount', 'Shipping' ],
	tax      => [ 'Business::cXML::Amount', 'Tax'      ],
	items    => 'Business::cXML::ItemIn',
);

use Business::cXML::Amount;
use Business::cXML::ItemIn;
use Business::cXML::ShipTo;
use XML::LibXML::Ferry;

sub _from_status {
	my ($self, $val) = @_;
	return CXML_POOM_STATUS_FINAL if $val eq 'final';
	return CXML_POOM_STATUS_PENDING;
}

sub from_node {
	my ($self, $el) = @_;

	$el->ferry($self, {
			BuyerCookie                => 'buyer_cookie',
			PunchOutOrderMessageHeader => {
				operationAllowed  => 'highest_operation',
				quoteStatus       => [ 'status', \&_from_status ],
				SourcingStatus    => '__UNIMPLEMENTED',
				Total             => [ 'total',    'Business::cXML::Amount' ],
				ShipTo            => [ 'shipto',   'Business::cXML::ShipTo' ],
				Shipping          => [ 'shipping', 'Business::cXML::Amount' ],
				Tax               => [ 'tax',      'Business::cXML::Amount' ],
				SupplierOrderInfo => {
					orderID   => 'id',
					orderDate => '__UNIMPLEMENTED',
				},
			},
			ItemIn => [ 'items', 'Business::cXML::ItemIn' ],
		}
	);
}

sub to_node {
	my ($self, $doc) = @_;
	my $node = $doc->create($self->{_nodeName});

	$node->add('BuyerCookie', $self->{buyer_cookie});

	my $head = $node->add('PunchOutOrderMessageHeader', undef,
		operationAllowed => $self->{highest_operation},
	);
	$head->{quoteStatus} = ($self->is_final ? 'final' : 'pending') if defined $self->{status};

	# UNIMPLEMENTED: SourcingStatus
	$self->total({}) unless defined $self->{total};
	$head->add($self->{total}->to_node($node));
	$head->add($self->{shipto}->to_node($node))   if defined $self->{shipto};
	$head->add($self->{shipping}->to_node($node)) if defined $self->{shipping};
	$head->add($self->{tax}->to_node($node))      if defined $self->{tax};
	$head->add('SupplierOrderInfo', undef, orderID => $self->{id}) if defined $self->{id};

	$node->add($_->to_node($node)) foreach (@{ $self->{items} });

	return $node;
}

=item C<B<is_pending>( [I<$bool>] )>

=item C<B<is_final>( [I<$bool>] )>

Respectively gets or sets whether the order is in pending or final status.
There is no status at all by default.

=cut

sub is_pending {
	my ($self, $bool) = @_;
	$self->{status} = CXML_POOM_STATUS_PENDING if $bool;
	return $self->{status} == CXML_POOM_STATUS_PENDING;
}

sub is_final {
	my ($self, $bool) = @_;
	$self->{status} = CXML_POOM_STATUS_FINAL if $bool;
	return $self->{status} == CXML_POOM_STATUS_FINAL;
}

=item C<B<buyer_cookie>>

Mandatory, cookie from original punch-out setup request

=item C<B<highest_operation>>

Mandatory, highest operation that we allow on this order.  One of: C<create>
(default), C<inspect>, C<edit>

=item C<B<total>>

Mandatory, L<Business::cXML::Amount> object of type C<Total>

=item C<B<shipto>>

Optional, L<Business::cXML::ShipTo> object

=item C<B<shipping>>

Optional, L<Business::cXML::Amount> object of C<Shipping> type (includes
tracking information)

=item B<tax>

Optional, L<Business::cXML::Amount> object of type C<Tax>

=item C<B<items>[]>

Optional, L<Business::cXML::ItemIn> objects

=item C<B<id>>

Optional, supplier sales order ID for this order, if one was created.  The
buyer can later cancel the sales order by sending an C<OrderRequest> of type
C<delete> that refers to this ID.

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

