=encoding utf-8

=head1 NAME

Business::cXML::ShipTo - cXML ship-to address

=head1 SYNOPSIS

	use Business::cXML::ShipTo;

=head1 DESCRIPTION

Object representation of a cXML ship-to address with transport details.

=head1 METHODS

See L<Business::cXML::Object/COMMON METHODS>.

=head1 PROPERTY METHODS

See L<Business::cXML::Object/PROPERTY METHODS> for how the following operate.

=over

=cut

use 5.014;
use strict;

package Business::cXML::ShipTo;
use base qw(Business::cXML::Object);

use Business::cXML::Address;
use Business::cXML::Carrier;
use Business::cXML::Transport;
use XML::LibXML::Ferry;

use constant NODENAME => 'ShipTo';
use constant PROPERTIES => (
	address    => Business::cXML::Address->new(),
	carriers   => [],
	transports => [],
);
use constant OBJ_PROPERTIES => (
	address    => 'Business::cXML::Address',
	carriers   => 'Business::cXML::Carrier',
	transports => 'Business::cXML::Transport',
);

sub from_node {
	my ($self, $el) = @_;

	$el->ferry($self, {
			Address              => [ 'address',    'Business::cXML::Address'   ],
			CarrierIdentifier    => [ 'carriers',   'Business::cXML::Carrier'   ],
			TransportInformation => [ 'transports', 'Business::cXML::Transport' ],
			IdReference          => '__UNIMPLEMENTED',
		}
	);
}

sub to_node {
	my ($self, $doc) = @_;
	my $node = $doc->create($self->{_nodeName});

	$node->add($self->{address}->to_node($node));
	$node->add($_->to_node($node)) foreach (@{ $self->{carriers} });
	$node->add($_->to_node($node)) foreach (@{ $self->{transports} });
	# UNIMPLEMENTED: IdReference*

	return $node;
}

=item C<B<address>>

Optional, L<Business::cXML::Address> object

=item C<B<carriers>[]>

Optional, L<Business::cXML::Carrier> objects

=item C<B<transports>[]>

Optional, L<Business::cXML::Transport> objects

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
