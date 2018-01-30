=encoding utf-8

=head1 NAME

Business::cXML::Address::Number - cXML contact phone/fax number

=head1 SYNOPSIS

	use Business::cXML::Address::Number;

=head1 DESCRIPTION

Object representation of a cXML phone or fax number.  You can specify which
when calling C<new()> by passing I<C<$node>> set to C<Phone> (default) or
C<Fax>.  Alternatively, you can also specify it with a C<_nodeName> in
C<new()>'s I<C<$properties>>.

Specifically B<not> implemented are Faxes containing a URL or e-mail address
instead of a telephone number.

=head1 METHODS

See L<Business::cXML::Object/COMMON METHODS>, plus the following:

=over

=cut

use 5.014;
use strict;

package Business::cXML::Address::Number;
use base qw(Business::cXML::Object);

use constant NODENAME => 'Phone';
use constant PROPERTIES => (
	name         => undef,
	country_iso  => 'US',
	country_code => '1',
	area_code    => '',
	number       => '',
	extension    => undef,
);

use Business::cXML::Utils qw(to_numeric);
use XML::LibXML::Ferry;

sub _numeric {
	my ($self, $val) = @_;
	$val = $val->textContent;
	return to_numeric($val);
}

sub from_node {
	my ($self, $el) = @_;
	
	$el->ferry($self, {
		TelephoneNumber => {
			CountryCode => {
				isoCountryCode => 'country_iso',
				__text         => [ 'country_code', \&_numeric ],
			},
			AreaOrCityCode => [ 'area_code', \&_numeric ],
			Number         => [ 'number',    \&_numeric ],
			Extension      => [ 'extension', \&_numeric ],
		},
		URL   => '__UNIMPLEMENTED',  # Fax only
		Email => '__UNIMPLEMENTED',  # Fax only
	});
}

sub to_node {
	my ($self, $doc) = @_;
	my $node = $doc->create($self->{_nodeName}, undef, name => $self->{name});

	my $el = $node->add('TelephoneNumber');
	$el->add('CountryCode', $self->{country_code}, isoCountryCode => $self->{country_iso});
	$el->add('AreaOrCityCode', $self->{area_code});
	$el->add('Number', $self->{number});
	$el->add('Extension', $self->{extension}) if $self->{extension};

	return $node;
}

=item C<B<toString>()>

Returns the string representation of the phone number in C<C-AAA-NNN-NNNN>
format, without the extension.  Only North-American formatting is currently
implemented.

=cut

sub toString {
	my ($self) = @_;
	my $n = $self->{number};
	$n = join('-', unpack('A3A4', $n)) if (length($self->{number}) == 7);
	return $self->{country_code} . '-' . $self->{area_code} . '-' . $n;
}

=item C<B<fromString>( I<$string> )>

Extracts country code, area code and number from I<C<$string>>.  (Not the
extension.)  Non-numeric characters are safely discarded.  Only North-American
formatting is currently implemented, with the benefit that the initial C<1> is
optional.

Note: processing starts from the left, so any custom extension suffixes are
safely ignored.

=cut

sub fromString {
	my ($self, $str) = @_;
	$str = to_numeric($str);
	my ($area, $number) = $str =~ m/^1?(\d{3})(\d{7})/x;
	$self->{country_code} = '1';
	$self->{area_code} = $area;
	$self->{number} = $number;
}

=back

=head1 PROPERTY METHODS

See L<Business::cXML::Object/PROPERTY METHODS> for how the following operate.

=over

=item C<B<name>>

Optional, name of this phone or fax number (i.e. C<work>).  Without a name,
this represents a C<TelephoneNumber> without a wrapper C<Phone>/C<Fax>.

=item C<B<country_iso>>

2-letter ISO country code

=item C<B<country_code>>

Country code (default: C<1>)

=item C<B<area_code>>

Area code

=item C<B<number>>

Number

=item C<B<extension>>

Optional, extension

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
