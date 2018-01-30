=encoding utf-8

=head1 NAME

Business::cXML::Utils - Utilities for the cXML suite

=head1 SYNOPSIS

	use Business::cXML::Utils;

=head1 DESCRIPTION

Various utilities not specific to any one cXML module.

=cut

use 5.014;
use strict;

package Business::cXML::Utils;
use base 'Exporter';

our @EXPORT_OK = qw(to_numeric current_datetime cxml_timestamp);

use DateTime;
use Sys::Hostname;

=head1 FUNCTIONS

=over

=item C<B<to_numeric>( I<$string> )>

Returns purely numbers from I<C<$string>>.  (i.e. C<1 234,567.88> becomes
C<123456788>)

=cut

sub to_numeric {
	my ($str) = @_;
	$str =~ tr/0123456789//dc;  # Strip any character we don't know/need
	return $str;
}

=item C<B<current_datetime>()>

Returns a L<DateTime> object for current time in local timezone.

=cut

sub current_datetime {
	return DateTime->now(time_zone => DateTime::TimeZone->new( name => 'local' ));
}

=item C<B<cxml_timestamp>( I<$datetime> )>

Returns the ISO 8601 timestamp from I<C<$datetime>> (such as returned by
L</now()>).  Example: C<2017-01-01T01:01:01-0800>

=cut

sub cxml_timestamp {
	my ($dt) = @_;
	return $dt->strftime('%FT%T%z');
}

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
