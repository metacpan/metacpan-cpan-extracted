=encoding utf-8

=head1 NAME

Business::cXML::Characteristic - cXML product item characteristic

=head1 SYNOPSIS

	use Business::cXML::Characteristic;

=head1 DESCRIPTION

Object representation of a cXML C<Characteristic>.

A group of one or more characteristics would specify a configurable product
item (for example with colors, sizes, etc.)

=head1 METHODS

See L<Business::cXML::Object/COMMON METHODS>.

=head1 PROPERTY METHODS

See L<Business::cXML::Object/PROPERTY METHODS> for how the following operate.

=over

=cut

use 5.014;
use strict;

package Business::cXML::Characteristic;
use base qw(Business::cXML::Object);

use constant NODENAME => 'Characteristic';
use constant PROPERTIES => (
	domain => 'size',
	value  => '',
	code   => undef,
);

use XML::LibXML::Ferry;

sub from_node {
	my ($self, $el) = @_;
	$el->ferry($self);
}

sub to_node {
	my ($self, $doc) = @_;
	return $doc->create($self->{_nodeName}, undef,
		domain => $self->{domain},
		value  => $self->{value},
		code   => $self->{code},
	);
}

=item C<B<domain>>

Mandatory, type of characteristic.  For example: C<size> (default),
C<sizeCode>, C<color>, C<colorCode>, C<grade>, etc.

=item C<B<value>>

Mandatory, value for the domain.  For example: a size C<70>.

=item C<B<code>>

Optional, additional information such as currency code or unit of measure.
For example, size 70 C<cm>.

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
