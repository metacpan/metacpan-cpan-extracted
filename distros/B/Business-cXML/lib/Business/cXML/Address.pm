=encoding utf-8

=head1 NAME

Business::cXML::Address - cXML Address

=head1 SYNOPSIS

	use Business::cXML::Address;
	my $addr = new Business::cXML::Address {
		name  => 'Some Company',
		email => 'shipping@example.com',
		url   => 'https://shipping.example.com/',
	};

=head1 DESCRIPTION

Object representation of a cXML C<Address>.

Note that there are only minor differences between an address and a contact,
however they are significant enough to warrant two separate classes.

=head1 METHODS

See L<Business::cXML::Object/COMMON METHODS>.

=head1 PROPERTY METHODS

See L<Business::cXML::Object/PROPERTY METHODS> for how the following operate.

=over

=cut

use 5.014;
use strict;

package Business::cXML::Address;
use base qw(Business::cXML::Object);

use Business::cXML::Address::Number;
use Business::cXML::Address::Postal;
use XML::LibXML::Ferry;

use constant NODENAME => 'Address';
use constant PROPERTIES => (
	lang   => 'en-US',
	name   => '',
	email  => undef,
	url    => undef,
	phone  => undef,
	fax    => undef,
	postal => undef,
);
use constant OBJ_PROPERTIES => (
	phone  => [ 'Business::cXML::Address::Number', 'Phone' ],
	fax    => [ 'Business::cXML::Address::Number', 'Fax'   ],
	postal => 'Business::cXML::Address::Postal',
);

sub from_node {
	my ($self, $el) = @_;

	$self->{_nodeName} = $el->nodeName;

	$el->ferry($self, {
			addressID       => '__UNIMPLEMENTED',
			addressIDDomain => '__UNIMPLEMENTED',
			isoCountryCode  => '__UNIMPLEMENTED',
			Name            => {
				'xml:lang' => 'lang',
				__text     => 'name',
			},
			Phone         => [ 'phone',  'Business::cXML::Address::Number' ],
			Fax           => [ 'fax',    'Business::cXML::Address::Number' ],
			PostalAddress => [ 'postal', 'Business::cXML::Address::Postal' ],
			IdReference   => '__UNIMPLEMENTED',
		}
	);
}

sub to_node {
	my ($self, $doc) = @_;
	my $name = $self->{_nodeName};

	my $node = $doc->create($name);
	# UNIMPLEMENTED: addressID? addressIDDomain? isoCountryCode?

	$node->add('Name', $self->{name}, 'xml:lang' => $self->{lang});
	$node->add($self->{postal}->to_node($node)) if ref $self->{postal};
	$node->add('Email', $self->{email}) if $self->{email};
	$node->add($self->{phone}->to_node($node)) if ref $self->{phone};
	$node->add($self->{fax}->to_node($node)) if ref $self->{fax};
	$node->add('URL', $self->{url}) if $self->{url};
	# UNIMPLEMENTED: IdReference?

	return $node;
}

=item C<B<lang>>

Defaults to C<en-US>

=item C<B<name>>

Mandatory

=item C<B<email>>

Optional

=item C<B<url>>

Optional

=item C<B<phone>>

Optional, L<Business::cXML::Address::Number> object of type C<Phone>

=item C<B<fax>>

Optional, L<Business::cXML::Address::Number> object of type C<Fax>

=item C<B<postal>>

Optional, L<Business::cXML::Address::Postal> object

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
