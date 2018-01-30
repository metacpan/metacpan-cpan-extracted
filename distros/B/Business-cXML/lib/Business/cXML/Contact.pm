=encoding utf-8

=head1 NAME

Business::cXML::Contact - cXML Contact

=head1 SYNOPSIS

	use Business::cXML::Contact;
	my $contact = new Business::cXML::Contact {
		name   => 'Some Person',
		emails => 'some.person@example.com',
		urls   => 'https://www.example.com/',
	};

=head1 DESCRIPTION

Object representation of a cXML C<Contact>.

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

package Business::cXML::Contact;
use base qw(Business::cXML::Object);

use Business::cXML::Address::Number;
use Business::cXML::Address::Postal;
use XML::LibXML::Ferry;

use constant NODENAME => 'Contact';
use constant PROPERTIES => (
	role    => undef,
	lang    => 'en-US',
	name    => '',
	emails  => [],
	urls    => [],
	phones  => [],
	faxes   => [],
	postals => [],
);
use constant OBJ_PROPERTIES => (
	phones  => [ 'Business::cXML::Address::Number', 'Phone' ],
	faxes   => [ 'Business::cXML::Address::Number', 'Fax'   ],
	postals => 'Business::cXML::Address::Postal',
);

sub from_node {
	my ($self, $el) = @_;

	$self->{_nodeName} = $el->nodeName;

	$el->ferry($self, {
			addressID       => '__UNIMPLEMENTED',
			addressIDDomain => '__UNIMPLEMENTED',
			Name            => {
				'xml:lang' => 'lang',
				__text     => 'name',
			},
			Phone         => [ 'phones',  'Business::cXML::Address::Number' ],
			Fax           => [ 'faxes',   'Business::cXML::Address::Number' ],
			PostalAddress => [ 'postals', 'Business::cXML::Address::Postal' ],
			IdReference   => '__UNIMPLEMENTED',
		}
	);
}

sub to_node {
	my ($self, $doc) = @_;
	my $name = $self->{_nodeName};

	my $node = $doc->create($name);
	$node->{role} = $self->{role} if defined $self->{role};
	# UNIMPLEMENTED: addressID? addressIDDomain?

	$node->add('Name', $self->{name}, 'xml:lang' => $self->{lang});
	$node->add($_->to_node($node)) foreach (@{ $self->{postals} });
	$node->add('Email', $_) foreach (@{ $self->{emails} });
	$node->add($_->to_node($node)) foreach (@{ $self->{phones} });
	$node->add($_->to_node($node)) foreach (@{ $self->{faxes} });
	$node->add('URL', $_) foreach (@{ $self->{urls} });
	# UNIMPLEMENTED: IdReference*

	return $node;
}

=item C<B<role>>

Optional

=item C<B<lang>>

Defaults to C<en-US>

=item C<B<name>>

Mandatory

=item C<B<emails>[]>

Optional, strings

=item C<B<urls>[]>

Optional, strings

=item C<B<phones>[]>

Optional, L<Business::cXML::Address::Number> objects of type C<Phone>

=item C<B<faxes>[]>

Optional, L<Business::cXML::Address::Number> objects of type C<Fax>

=item C<B<postals>[]>

Optional, L<Business::cXML::Address::Postal> objects

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
