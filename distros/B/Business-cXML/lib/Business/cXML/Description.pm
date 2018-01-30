=encoding utf-8

=head1 NAME

Business::cXML::Description - cXML description content

=head1 SYNOPSIS

	use Business::cXML::Description;

=head1 DESCRIPTION

Object representation of a cXML C<Description>.

=head1 METHODS

See L<Business::cXML::Object/COMMON METHODS>.

=head1 PROPERTY METHODS

See L<Business::cXML::Object/PROPERTY METHODS> for how the following operate.

=over

=cut

use 5.014;
use strict;

package Business::cXML::Description;
use base qw(Business::cXML::Object);

use constant NODENAME => 'Description';
use constant PROPERTIES => (
	lang  => 'en-US',
	short => undef,
	full  => '',
);

use XML::LibXML::Ferry;

sub from_node {
	my ($self, $el) = @_;

	$el->ferry($self, {
		'xml:lang' => 'lang',
		ShortName  => 'short',
		__text     => 'full',
	});
}

sub to_node {
	my ($self, $doc) = @_;
	my $node = $doc->create($self->{_nodeName}, $self->{full}, 'xml:lang' => $self->lang);
	$node->add('ShortName', $self->{short}) if defined $self->{short};
	return $node;
}

=item C<B<lang>>

Mandatory, language used, default C<en-US>

=item C<B<short>>

Optional, shorter version of the full description

=item C<B<full>>

Mandatory, full description text

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
