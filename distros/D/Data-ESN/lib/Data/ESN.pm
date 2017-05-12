package Data::ESN;

use 5.006;
use strict;
use warnings;

use Exporter;
use Carp;


use vars qw(@ISA @EXPORT_OK);

#  base class Exporter
our @ISA = qw(Exporter);

our @EXPORT_OK = qw(esn_to_hex esn_to_dec esn_valid esn_is_hex esn_is_dec);



=head1 NAME

Data::ESN - Manipulate mobile ESN values

=head1 VERSION

Version 0.04

=cut

our $VERSION = '0.04';


=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    use Data::ESN qw( esn_to_hex esn_to_dec esn_valid esn_is_hex esn_is_dec );

    my $esn_hex = '2df812ca';

    #  if we have a Hex ESN, convert it to Decimal
    my $esn_dec = esn_to_dec( $esn_hex ) if esn_is_hex( $esn_hex );

    #  if we have a Decimal ESN, convert it to Hex
    $esn_hex = esn_to_hex( $esn_dec ) if esn_is_dec( $esn_dec );

    print "valid esn found" if esn_valid( $esn_hex );

    #  print if we have a 'dec' or 'hex' ESN
    print "our ESN is a " . esn_valid( $esn_hex ) . " esn.";
    

=head1 EXPORT

    esn_to_hex
    esn_to_dec
    esn_valid
    esn_is_hex
    esn_is_dec

=head1 SUBROUTINES/METHODS

=head2 esn_to_hex

Converts a Decimal ESN to Hex.  If an invalid ESN is used, it will throw
a warning and return to 0.

=cut

sub esn_to_hex {

    my $esn = shift;

    unless ( esn_is_dec($esn) ) {
        carp "invalid ESN ($esn) used for decimal to hex conversion 'esn_to_hex";
        return 0;
    }

    #  take first three digits, convert to hex
    $esn =~ m/^(.{3})(.{8})$/;

    my $manufacturer = sprintf("%02x", $1);
    my $device       = sprintf("%06x", $2);

    return $manufacturer . $device;

}

=head2 esn_to_dec

Convert a Hex ESN to Decimal.  If an invalid Hex ESN is used, it will throw
a warning and return 0. 

=cut

sub esn_to_dec {

    my $esn = shift;

    unless ( esn_is_hex($esn) ) {
        carp "invalid ESN ($esn) used for decimal to hex conversion 'esn_to_dec";
        return 0;
    }

    #  take first two digits, convert to hex
    $esn =~ m/^(.{2})(.{6})$/;

    my $manufacturer = sprintf("%03d", hex $1);
    my $device       = sprintf("%08d", hex $2);

    return $manufacturer . $device;

}

=head2 esn_valid

Check to see if the ESN looks like a valid ESN, either Decimal or Hex.  If it
looks like a Decimal ESN, it returns "dec".  If it looks like a Hex ESN it
returns "hex".  If it doesn't match either it returns 0

=cut

sub esn_valid {

    my $esn = shift;

    return 'hex' if esn_is_hex($esn);
    return 'dec' if esn_is_dec($esn);
    return 0;

}

=head2 esn_is_hex

If ESN appears to be Hex, return 1, else return 0.  A valid Hex ESN is 8 digits
in length, 00000000 to FFFFFFFF inclusive.

=cut

sub esn_is_hex {

    my $esn = shift;

    #  a valid esn is defined, 8 digits in length, and digit / a thru f characters
    if ( defined $esn and $esn =~ /^[0-9a-f]{8}$/i ) { 
        return 1;
    } else {
        return 0;
    }

}

=head2 esn_is_dec

If ESN appears to be Decimal, return 1, else return 0.  A valid Decimal ESN is
11 digits in length, with the first three digits between 0 and 255 inclusive
and the last 8 digits between 00000000 and 16777215 inclusive.

=cut

sub esn_is_dec {

    my $esn = shift;

    if ( defined $esn and $esn =~ /^[0-9]{11}$/ ) {
        $esn =~ m/^(\d{3})(\d{8})$/;
        my $manufacturer = $1;
        my $device       = $2;

        #  manufacturer ID can be 0x00 to 0xFF
        return 0 if $manufacturer > 255;

        #  devcie ID can be 0x000000 to 0xFFFFFF
        return 0 if $device > 16777215;
        
        #  if we got here, we have a valid decimal ESN
        return 1;                

    } else {

        return 0;

    }

}


=head1 AUTHOR

Adam Wohld, C<< <adam at spatialsystems.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-data-esn at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Data-ESN>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Data::ESN


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Data-ESN>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Data-ESN>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Data-ESN>

=item * Search CPAN

L<http://search.cpan.org/dist/Data-ESN/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2012 Adam Wohld.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of Data::ESN
