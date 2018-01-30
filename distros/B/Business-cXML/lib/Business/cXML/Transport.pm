=encoding utf-8

=head1 NAME

Business::cXML::Transport - cXML transport information

=head1 SYNOPSIS

	use Business::cXML::Transport;

=head1 DESCRIPTION

Object representation of a cXML transport information.

=head1 METHODS

See L<Business::cXML::Object/COMMON METHODS>.

=head1 PROPERTY METHODS

See L<Business::cXML::Object/PROPERTY METHODS> for how the following operate.

=over

=cut

use 5.014;
use strict;

package Business::cXML::Transport;
use base qw(Business::cXML::Object);

use constant NODENAME => 'TransportInformation';
use constant PROPERTIES => (
	method       => 'unknown',
	means        => undef,
	start        => undef,
	end          => undef,
	contacts     => [],
	contract     => undef,
	instructions => undef,
);
use constant OBJ_PROPERTIES => (
	contacts     => 'Business::cXML::Contact',
	instructions => 'Business::cXML::Description',
);

use Business::cXML::Contact;
use XML::LibXML::Ferry;

sub from_node {
	my ($self, $el) = @_;

	$el->ferry($self, {
			Route => {
				startDate => 'start',
				endDate   => 'end',
				Contact   => [ 'contacts', 'Business::cXML::Contact' ],
			},
			ShippingContractNumber => 'contract',
			ShippingInstructions   => {
				Description => [ 'instructions', 'Business::cXML::Description' ],
			},
		}
	);
}

sub to_node {
	my ($self, $doc) = @_;
	my $node = $doc->create($self->{_nodeName});
	my $route = $node->add('Route', undef,
		method    => $self->{method},
		means     => $self->{means},
		startDate => $self->{start},
		endDate   => $self->{end},
	);
	$route->add($_->to_node($node)) foreach (@{ $self->{contacts} });
	$node->add('ShippingContractNumber', $self->{contract}) if defined $self->{contract};
	$node->add('ShippingInstructions')->add($self->{instructions}->to_node($node)) if defined $self->{instructions};

	return $node;
}

=item C<B<method>>

Mandatory, one of: C<air>, C<motor>, C<rail>, C<ship>, C<mail>, C<multimodal>,
C<fixedTransport>, C<inlandWater>, C<unknown> (default), C<custom>

=item C<B<means>>

Optional, particular vessel

=item C<B<start>>

Optional, start date with timezone

=item C<B<stop>>

Optional, end date with timezone

=item C<B<contacts>[]>

Optional, L<Business::cXML::Contact> objects

=item C<B<contract>>

Optional, number or description of shipping contract

=item C<B<instructions>>

Optional, shipping instructions in a L<Business::cXML::Description> object

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
