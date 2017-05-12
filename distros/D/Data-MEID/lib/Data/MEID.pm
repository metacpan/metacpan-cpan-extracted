package Data::MEID;

use 5.006;
use strict;
use warnings;

use Exporter;
use Carp;
use Digest::SHA qw( sha1_hex );
use Math::BigInt;

use vars qw(@ISA @EXPORT_OK);

#  base class Exporter
our @ISA = qw(Exporter);

our @EXPORT_OK = qw(
    meid_to_hex
    meid_to_dec
    meid_is_valid
    meid_is_hex
    meid_is_dec
    meid_check_digit
    meid_to_pesn
    manu_code_dec
    manu_code_hex
    serial_num_dec
    serial_num_hex
);



=head1 NAME

Data::MEID - Convert, check, and inspect mobile MEID values.

=head1 VERSION

Version 0.06

=cut

our $VERSION = '0.06';


=head1 SYNOPSIS

Quick summary of what the module does.

    use Data::MEID qw(
        meid_to_hex
        meid_to_dec
        meid_is_valid
        meid_is_hex
        meid_is_dec
        meid_check_digit
        meid_to_pesn
        manu_code_dec
        manu_code_hex
        serial_num_dec
        serial_num_hex
    );

    #  convert Decimal MEID to Hex
    my $hex_meid = meid_to_hex( '270113177609606898' );

    #  convert Hex MEID to Decimal
    my $decimal_meid = meid_to_dec( 'A10000009296F2' );

    #  check to see if a MEID is a valid in Hex or Decimal form
    return 1 if meid_is_valid( 'A10000009296F2' );

    #  check to see if a MEID is in proper Hex form
    print "Hex MEID Detected" if meid_is_hex( 'A10000009296F2' );

    #  check to see if a MEID is in proper Decimal form
    print "Decimal MEID Detected" if meid_is_dec( '270113177609606898' );

    #  calculate the MEID check digit using 3GPP2 X.S0008-0 v3.0
    my $hex_cd = meid_check_digit( 'A10000009296F2' );
    my $dec_cd = meid_check_digit( '270113177609606898' );

    #  calculate Pseudo ESN
    my $pseudo_esn = meid_to_pesn( 'A10000009296F2' );

    #  get Decimal manufacturers code
    my $manufacturer_code = manu_code_dec( 'A10000009296F2' );

    #  get Hex manufacturers code
    my $manufacturers_code = manu_code_hex( 'A10000009296F2' );

    #  get Decimal serial number
    my $serial_number = serial_num_dec( 'A10000009296F2' );

    #  get Hex serial number
    my $serial_number = serial_num_hex( 'A10000009296F2' );

=head1 EXPORT

    meid_to_hex
    meid_to_dec
    meid_is_valid
    meid_is_hex
    meid_is_dec
    meid_check_digit
    meid_to_pesn
    manu_code_dec
    manu_code_hex
    serial_num_dec
    serial_num_hex

=head1 SUBROUTINES/METHODS

=head2 meid_to_hex

Convert a Decimal MEID to Hex.  If an invalid Decimal MEID is used, it will throw
a warning and return 0.

=cut

sub meid_to_hex {

    my $meid = shift;

    unless ( meid_is_dec($meid) ) {
        $meid = 'undef' if not defined $meid;
        carp "invalid MEID ($meid) used for decimal to hex conversion 'meid_to_hex";
        return 0;
    }


    #  take first 10 digits, convert to hex.  Take next 8 digits and convert to hex
    $meid =~ m/^(.{10})(.{8})$/;

    my $manufacturer = sprintf("%08x", $1);
    my $serial       = sprintf("%06x", $2);

    return $manufacturer . $serial;

}

=head2 meid_to_dec

Convert a Hex MEID to Decimal.  If an invalid Hex MEID is used, it will throw
a warning and return 0.

=cut

sub meid_to_dec {

    my $meid = shift;

    unless ( meid_is_hex($meid) ) {
        $meid = 'undef' if not defined $meid;
        carp "invalid MEID ($meid) used for decimal to hex conversion 'meid_to_dec";
        return 0;
    }

    #  take first 8 digits, convert to hex, then next 6
    $meid =~ m/^(.{8})(.{6})$/;

    my $n = Math::BigInt->new("0x$1");
    my $manufacturer = sprintf("%010s", $n->bstr );
    my $serial       = sprintf("%08d" , hex $2);

    return $manufacturer . $serial;

}

=head2 meid_is_valid

Check to see if a MEID is valid, either Decimal or Hex.  If it
looks like a Decimal MEID, it returns "dec".  If it looks like a Hex ESN it
returns "hex".  If it doesn't match either it returns 0

=cut

sub meid_is_valid {

    my $meid = shift;

    return 'hex' if meid_is_hex($meid);
    return 'dec' if meid_is_dec($meid);
    return 0;

}

=head2 meid_is_hex

Return 1 if MEID looks like valid HEX MEID: RRXXXXXXZZZZZZ.  Otherwise return 0.
RR = A0 ~ FF, XXXXXX = 000000 ~ FFFFFF, ZZZZZZ = 000000 ~ FFFFFF

=cut

sub meid_is_hex {

    my $meid = shift;

    if ( defined $meid and $meid =~ /^[0-9a-f]{14}$/i ) {

        #  get RR code, first two digits and make sure they're A0 thru FF
        $meid =~ m/^([0-9a-f]{2})/i;
        my $rr_code = $1;

        #  we're obviously not above FF, but make sure we're not bleow A0
        return 0 if hex($rr_code) < hex('A0');

        return 1;

    } else {

        return 0;

    }

}

=head2 meid_is_dec

Return 1 if MEID looks like valid Decimal MEID.  Otherwise return 0.

=cut

sub meid_is_dec {

    my $meid = shift;

    if ( defined $meid and $meid =~ /^\d{18}$/ ) {

        #  get Manufacturer code, first 10 digits
        #  get Serial Number, last 8 digits
        $meid =~ m/^(\d{10})(\d{8})$/;
        my $reserved_plus_manu_code = $1;
        my $serial = $2;

        #  make sure manu code is in this range 2_684_354_560 ~ 2_952_790_015
        return 0 if not (
            $reserved_plus_manu_code >= 2_684_354_560
            and $reserved_plus_manu_code <= 2_952_790_015
        );

        #  make sure serial number is in this range 00_000_000 ~ 16_777_215
        return 0 if not ( $serial >= 0 and $serial <= 16_777_215 );

        #  if we get here, we're all good
        return 1;

    } else {

        return 0;

    }

}

=head2 meid_check_digit

Calculates the MEID check digit value as described in 3GPP2 X.S0008-0 v3.0.
For testing purposes, per the spec, AF 01 23 45 0A BC DE has a check digit of 'C'.
MEID 293608736500703710 has a check digit of '0'.

If a Hex MEID is passed, a Hex check digit is returned.
If a Decimal MEID is passed, a Decimal check digit is returned.

=cut

sub meid_check_digit {

    my $meid = shift;

    my $wanted = meid_is_valid($meid);

    if ( $wanted eq 'hex' ) {

        #  example MEID: AF 01 23 45 0A BC DE
        #  step 1, double the value of alternating digits beginning with the first
        #  right-hand digit (low order). F 1 3 5 A C E to 1E 2 6 A 14 18 1C
        my ( @right_digits ) = $meid =~ /^\w(\w)\w(\w)\w(\w)\w(\w)\w(\w)\w(\w)\w(\w)$/;
        my ( @left_digits)   = $meid =~ /^(\w)\w(\w)\w(\w)\w(\w)\w(\w)\w(\w)\w(\w)\w$/;

        foreach my $digit ( @right_digits ) {
            $digit = sprintf( "%x", hex($digit) * 2 );
        }

        #  step 2, add individual digits comprising the products obtained in step 1 to each
        #  of the unaffected digits in the origional number.
        @right_digits = split //, ( join "", @right_digits );
        my @all_digits = ( @left_digits, @right_digits);

        my $digit_sum = 0;
        foreach my $digit ( @all_digits ) {
            $digit_sum = $digit_sum + hex($digit);
        }

        #  convert sum total to hex;
        $digit_sum = sprintf("%x", $digit_sum);

        #  calculate check digit, if last digit is zero, check digit is zero
        if ( $digit_sum =~ /0$/ ) {

            return 0;

        } else {

            my $next_higher = $digit_sum;
            #  increment number to next highest ending in zero
            until ( $next_higher =~ /0$/ ) {
                $next_higher = sprintf( "%x", hex($next_higher) + 1 );
            }

            #  subtract the $digit_sum from $next_higher and return it as the check digit
            return sprintf( "%x", hex($next_higher) - hex($digit_sum) );

        }

    } else {

        #  algorythm works just the same for decimal, just uses decimal math
        my ( @right_digits ) = $meid =~ /^\w(\w)\w(\w)\w(\w)\w(\w)\w(\w)\w(\w)\w(\w)\w(\w)\w(\w)$/;
        my ( @left_digits)   = $meid =~ /^(\w)\w(\w)\w(\w)\w(\w)\w(\w)\w(\w)\w(\w)\w(\w)\w(\w)\w$/;

        foreach my $digit ( @right_digits ) {
            $digit = $digit * 2;
        }

        #  step 2, add individual digits comprising the products obtained in step 1 to each
        #  of the unaffected digits in the origional number.
        @right_digits = split //, ( join "", @right_digits );
        my @all_digits = ( @left_digits, @right_digits);

        my $digit_sum = 0;
        foreach my $digit ( @all_digits ) {
            $digit_sum = $digit_sum + $digit;
        }

        #  calculate check digit, if last digit is zero, check digit is zero
        if ( $digit_sum =~ /0$/ ) {

            return 0;

        } else {

            my $next_higher = $digit_sum;
            #  increment number to next highest ending in zero
            until ( $next_higher =~ /0$/ ) {
                $next_higher = $next_higher + 1 ;
            }

            #  subtract the $digit_sum from $next_higher and return it as the check digit
            return ( $next_higher - $digit_sum );

        }

    }

}

=head2 meid_to_pesn

Calculate the pESN ( Pseudo ESN ) from Decimal or Hex MEID.

Output is in Hex form.  Use Data::ESN if Decimal ESN's are needed.

=cut

sub meid_to_pesn {

    my $meid = shift;

    #  dump out if we see a bad MEID
    return 0 if not meid_is_valid($meid);

    #  convert to hex if not hex
    $meid = meid_to_hex($meid) if meid_is_dec($meid);

    $meid = pack('H*', $meid );
    my $meid_hash = sha1_hex($meid);

    #  take last 6 digits of hash
    $meid_hash = substr $meid_hash, -6;

    #  prepend 80 to 6 digit hash
    return "80$meid_hash";

}

=head2 manu_code_dec

Return the manufacturer code in Decimal form from the MEID.  If we have
a MEID that looks bad, then return 0.

=cut

sub manu_code_dec {
    my $meid = shift;

    #  if code is hex, covnert to decimal and get the first 10 digits
    if ( meid_is_hex($meid) ) {

        $meid = meid_to_dec($meid);
        return substr $meid, 0, 10;

    #  if the code is decimal, return the first 10 digits
    } elsif ( meid_is_dec($meid) ) {

        return substr $meid, 0, 10;

    #  if none if these match, we probably don't have a good MEID and return 0
    } else {

        return 0;

    }

}

=head2 manu_code_hex

Return the manufacturer code in Hex form from the MEID.  If we have
a MEID that looks bad, then return 0.

=cut

sub manu_code_hex {
    my $meid = shift;

    #  if code is dec, covnert to hex and get 8 digits after the frist two
    if ( meid_is_dec($meid) ) {

        $meid = meid_to_hex($meid);
        return substr $meid, 2, 6;

    #  if the code is decimal, return 8 digits after the frist two
    } elsif ( meid_is_hex($meid) ) {

        return substr $meid, 2, 6;

    #  if none if these match, we probably don't have a good MEID and return 0
    } else {

        return 0;

    }

}

=head2 serial_num_dec

Return the serial number in Decimal form from the MEID.  If we have
a MEID that looks bad, then return 0.

=cut

sub serial_num_dec {

    my $meid = shift;

    #  if code is hex, covnert to decimal and get the last 8 digits
    if ( meid_is_hex($meid) ) {

        $meid = meid_to_dec($meid);
        return substr $meid, -8;

    #  if the code is decimal, return last 8 digits
    } elsif ( meid_is_dec($meid) ) {

        return substr $meid, -8;

    #  if none if these match, we probably don't have a good MEID and return 0
    } else {

        return 0;

    }

}

=head2 serial_num_hex

Return the serial number in Hex form from the MEID.  If we have
a MEID that looks bad, then return 0.

=cut

sub serial_num_hex {

    my $meid = shift;

    #  if code is decimal, covnert to hex and get the last 6 digits
    if ( meid_is_dec($meid) ) {

        $meid = meid_to_hex($meid);
        return substr $meid, -6;

    #  if the code is decimal, return last 6 digits
    } elsif ( meid_is_hex($meid) ) {

        return substr $meid, -6;

    #  if none if these match, we probably don't have a good MEID and return 0
    } else {

        return 0;

    }

}

=head1 AUTHOR

Adam Wohld, C<< <adam at spatialsystems.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-data-meid at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Data-MEID>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Data::MEID


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Data-MEID>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Data-MEID>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Data-MEID>

=item * Search CPAN

L<http://search.cpan.org/dist/Data-MEID/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2012 Adam Wohld.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of Data::MEID
