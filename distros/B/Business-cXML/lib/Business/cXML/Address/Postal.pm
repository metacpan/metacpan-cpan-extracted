=encoding utf-8

=head1 NAME

Business::cXML::Address::Postal - cXML postal address

=head1 SYNOPSIS

	use Business::cXML::Address::Postal;

=head1 DESCRIPTION

Object representation of a cXML C<PostalAddress>.

=head1 METHODS

See L<Business::cXML::Object/COMMON METHODS>.

=head1 PROPERTY METHODS

See L<Business::cXML::Object/PROPERTY METHODS> for how the following operate.

=over

=cut

use 5.014;
use strict;

package Business::cXML::Address::Postal;
use base qw(Business::cXML::Object);

use constant NODENAME => 'PostalAddress';
use constant PROPERTIES => (
	name        => undef,
	delivertos  => [],
	streets     => [],
	city        => '',
	muni        => undef,
	state       => undef,
	code        => undef,
	country_iso => '',
	country     => '',
);

use XML::LibXML::Ferry;

sub from_node {
	my ($self, $el) = @_;

	$el->ferry($self, {
			Municipality => 'muni',
			PostalCode   => 'code',
			Country      => {
				isoCountryCode => 'country_iso',
				__text         => 'country',
			},
		}
	);
}

sub to_node {
	my ($self, $doc) = @_;
	my $node = $doc->create($self->{_nodeName});
	$node->{name} = $self->{name} if $self->{name};

	$node->add('DeliverTo', $_) foreach (@{ $self->{delivertos} });
	$node->add('Street', $_) foreach (@{ $self->{streets} });
	$node->add('Street', ' ') unless scalar(@{ $self->{streets} });  # At least one required
	$node->add('City', $self->{city});
	$node->add('Municipality', $self->{muni}) if $self->{muni};
	$node->add('State', $self->{state}) if $self->{state};
	$node->add('PostalCode', $self->{code}) if $self->{code};
	$node->add('Country', $self->{country}, isoCountryCode => $self->{country_iso});
	return $node;
}

=item C<B<name>>

Optional, name of this address (i.e. C<billing department>)

=item C<B<delivertos>[]>

Optional

=item C<B<streets>[]>

Mandatory (at least one)

=item C<B<city>>

Mandatory

=item C<B<muni>>

Optional

=item C<B<state>>

Optional

=item C<B<code>>

Optional postal code

=item C<B<country_iso>>

Mandatory 2-letter ISO country code

=item C<B<country>>

Mandatory

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
