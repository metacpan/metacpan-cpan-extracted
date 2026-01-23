package Business::US::USPS::IMB;

use 5.010001;
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

our @EXPORT_OK = qw(
	usps4cb
);

our @EXPORT = qw(
	encode_IMB
);

our $VERSION = '0.04';

require XSLoader;
XSLoader::load('Business::US::USPS::IMB', $VERSION);


# Preloaded methods

sub encode_IMB {
	my $track_num = pack("Z21", shift);
	my $route_num = pack("Z12", shift);
	my $bar_string = pack("Z66","");

	my $result_code = Business::US::USPS::IMB::usps4cb($track_num,$route_num,$bar_string);

	return unpack("Z66",$bar_string), $result_code;
}

1;
__END__

=head1 NAME

Business::US::USPS::IMB - Perl Binding for usps4cb

=head1 SYNOPSIS

  use Business::US::USPS::IMB;

  my ($bar_string, $result_code) = encode_IMB($track_code, $route_code);

=head1 DESCRIPTION

This module is an interface to usps4cb, providing access to USPS Intelligent Mail Barcode encoder functionality
provided by this library. You will need the correct fonts in order to create actual barcodes. This module only
provides a correctly formatted encoding string, not the actual barcode.

For more information on this library see the following documentation:

=over 4

=item L<Encoder Software and Fonts|https://ribbs.usps.gov/onecodesolution/download.cfm>

Encoder software libraries, examples and fonts made available by the USPS.

=back

=head2 EXPORT

=over 4

=item C<encode_IMB>

This function takes a tracking number and routing number as parameters and returns a barcode string and result code.
If something went wrong, the barcode string will be undef.

Possible result codes and their explaintions are

=back

=over 4

=item *
SUCCESS                           0

=item *
SELFTEST_FAILED                   1

=item *
BAR_STRING_IS_NULL                2

=item *
BYTE_CONVERSION_FAILED            3

=item *
RETRIEVE_TABLE_FAILED             4

=item *
CODEWORD_CONVERSION_FAILED        5

=item *
CHARACTER_RANGE_ERROR             6

=item *
TRACK_STRING_IS_NULL              7

=item *
ROUTE_STRING_IS_NULL              8

=item *
TRACK_STRING_BAD_LENGTH           9

=item *
TRACK_STRING_HAS_INVALID_DATA    10

=item *
TRACK_STRING_HAS_INVALID_DIGIT2  11

=item *
ROUTE_STRING_BAD_LENGTH          12

=item *
ROUTE_STRING_HAS_INVALID_DATA    13

=back

=over 4

For further information on result code descriptions please refer to the USPS documentation on the usps4cb library
available at the link to Encoder Software and Fonts above.

=back

=head1 SEE ALSO

=over 4

=item L<Intelligent Mail Barcode Specification|https://ribbs.usps.gov/intelligentmail_mailpieces/documents/tech_guides/SPUSPSG.pdf>

Learn about the data content to be encoded, encoding rules to produce bars from data fields, physical dimensions 
of printed barcodes, and physical limitations on printing. The specification document (USPS-B-3200) also covers
how the encoding and decoding algorithms work and provides sample programming code.

=item L<List of Intelligent Mail Barcode Resources|https://ribbs.usps.gov/intelligentmail_mailpieces/documents/tech_guides/USPSIMB_Resources_List.pdf>

Get information about the tools and applications available to you from the Postal Service™ as well as from vendors
for creating and validating the Intelligent Mail barcode.

=back

=head1 AUTHOR

Chris Nighswonger, E<lt>cnighswonger@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 by Chris Nighswonger

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.1 or,
at your option, any later version of Perl 5 you may have available.

The usps4cb library is licensed in accordance with the terms outlined
in the accompanying USPS_LICENSE.txt file.

=cut
