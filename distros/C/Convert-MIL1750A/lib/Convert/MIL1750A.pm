=head1 NAME

Convert::MIL1750A - Conversion routines between decimal floating/integer values and
hexadecimal values in the MIL-STD-1750A format.

=head1 SYNOPSIS

    use MIL1750A;

    # Convert to MIL-STD-1750A hex from decimal
    $hex16i = I16_to_1750A( $dec_value );
    $hex16f = F16_to_1750A( $dec_value );
    $hex32f = F32_to_1750A( $dec_value );
    $hex48f = F48_to_1750A( $dec_value );
    
    # Convert MIL-STD-1750A hex to decimal
    $dec_value = M1750A_to_16int( $hex16i );
    $dec_value = M1750A_to_16flt( $hex16f );
    $dec_value = M1750A_to_32flt( $hex32f );
    $dec_value = M1750A_to_48flt( $hex48f );
    
or ...
    
    use MIL1750A qw( i16_to_mil f16_to_mil f32_to_mil f48_to_mil
                        mil_to_32f mil_to_48f mil_to_16f mil_to_16i );

    # Convert to MIL-STD-1750A hex from decimal
    $hex16i = i16_to_mil( $dec_value );
    $hex16f = f16_to_mil( $dec_value );
    $hex32f = f32_to_mil( $dec_value );
    $hex48f = f48_to_mil( $dec_value );
    
    # Convert MIL-STD-1750A hex to decimal
    $dec_value = mil_to_16i( $hex16i );
    $dec_value = mil_to_16f( $hex16f );
    $dec_value = mil_to_32f( $hex32f );
    $dec_value = mil_to_48f( $hex48f );

=head1 DESCRIPTION

Convert::MIL1750A features routines to convert between 16I/16F/32F/48F decimal values
and their equivalent in MIL-STD-1750A hexadecimal.  The 1750A standard describes
a microprocessor that is used as the backbone of many modern and legacy avionics systems.  
The 1750A stores data as an 8-bit exponent and n-bit mantissa (where n is the number of 
bits remaining in the value).  It is important to treat 16-bit values as 16-bit, 32-bit as 32-bit
 and 48-bit as 48-bit.  Crossing bit structures will create unexpected results as 1750A hex values are
 structured differently, depending on their size.  Additionally, the 16F format is not a formal member of
 the 1750A standard; it is used, however, in certain applications and is provided for reference.  The 
 1750A standard allows positive and negative values using the 2's complement arrangement.
 
This module is extremely useful for ingesting data output by or for a 1750A flight processor.  I would like
to thank and acknowledge Dave Niklewski for helping me to find the standard documentation.


=head1 AUTHOR

Jared Clarke, ASRC Aerospace

=head1 FUNCTIONS

=cut
package Convert::MIL1750A;
#
use strict;
use POSIX qw/ceil/;
use Bit::Vector;
#
require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw( I16_to_1750A F16_to_1750A F32_to_1750A F48_to_1750A 
                  M1750A_to_32flt M1750A_to_48flt M1750A_to_16flt M1750A_to_16int );
our @EXPORT_OK = qw( i16_to_mil f16_to_mil f32_to_mil f48_to_mil
                        mil_to_32f mil_to_48f mil_to_16f mil_to_16i );
our $VERSION = '0.1';
#
sub round;
sub i16_to_mil;
sub f16_to_mil;
sub f32_to_mil;
sub f48_to_mil;
sub mil_to_16i;
sub mil_to_16f;
sub mil_to_32f;
sub mil_to_48f;

sub round{  # This function will not be exported
        my($number) = shift;
        return int($number + .5 * ($number <=> 0));
}


# Routines to convert to decimal values
sub M1750A_to_16int{
        $_[0] =~ s/^0x//;
        my $input = $_[0];
        my $vec = Bit::Vector->new_Hex( 16, $input );
        return $vec->to_Dec();
}
*mil_to_16i = \&M1750A_to_16int;

=item B<M1750A_to_16i> I<(mil_to_16i)>

        $hex = '0x83CA';
        $int = M1750A_to_16int( $hex );
        # $dec is -994
        print( "$int\n" );
        
=cut

sub M1750A_to_16flt{
        $_[0] =~ s/^0x//;
        my $input = $_[0];
        my $vec = Bit::Vector->new_Hex( 16, $input );
        my $mantissa_vec = Bit::Vector->new( 10 );
        my $exponent_vec = Bit::Vector->new( 6 );
        my ( $mantissa, $exponent );
        
        $mantissa_vec->Interval_Copy( $vec, 0, 6, 10 );
        $exponent_vec->Interval_Copy( $vec, 0, 0, 6 );
        
        $mantissa = $mantissa_vec->to_Dec(); # This method converts values assuming a 2's complement format
        $exponent = $exponent_vec->to_Dec();
        # There is an implied decimal in front of the mantissa.  The 2^-23 factor converts the integer to the fraction.
        return $mantissa*( 2.0**( $exponent - 9 ) ); 
}
*mil_to_16f = \&M1750A_to_16flt;

=item B<M1750A_to_16flt> I<(mil_to_16f)>

        $hex = '0x6344';
        $dec = M1750A_to_16flt( $hex );
        # $dec is 12.4
        print( "$dec\n" );
        
=cut

sub M1750A_to_32flt{
        $_[0] =~ s/^0x//;
        my $input = $_[0];
        my $vec = Bit::Vector->new_Hex( 32, $input );
        my $mantissa_vec = Bit::Vector->new( 24 );
        my $exponent_vec = Bit::Vector->new( 8 );
        my ( $mantissa, $exponent );
        
        $mantissa_vec->Interval_Copy( $vec, 0, 8, 24 ); # Separate the data into the 24-bit mantissa...
        $exponent_vec->Interval_Copy( $vec, 0, 0, 8 ); # ...and the 8-bit exponent
        
        $mantissa = $mantissa_vec->to_Dec(); # This method converts values assuming a 2's complement format
        $exponent = $exponent_vec->to_Dec();
        # There is an implied decimal in front of the mantissa.  The 2^-23 factor converts the integer to the fraction.
        return $mantissa*( 2.0**( $exponent - 23 ) ); 
}
*mil_to_32f = \&M1750A_to_32flt;

=item B<M1750A_to_32flt> I<(mil_to_32f)>

        $hex = '0x997AE105';
        $dec = M1750A_to_32flt( $hex );
        # $dec is -25.63
        print( "$dec\n" );
        
=cut

sub M1750A_to_48flt{
        $_[0] =~ s/^0x//;
        my $input = $_[0];
        my $vec = Bit::Vector->new_Hex( 48, $input );
        my $mantissa_vec1 = Bit::Vector->new( 24 );
        my $mantissa_vec2 = Bit::Vector->new( 16 );
        my $exponent_vec = Bit::Vector->new( 8 );
        my ( $mantissa1, $mantissa2, $exponent );
        
        $mantissa_vec1->Interval_Copy( $vec, 0, 24, 24 );
        $mantissa_vec2->Interval_Copy( $vec, 0, 0, 16 );
        $exponent_vec->Interval_Copy( $vec, 0, 16, 8 );
        
        $mantissa1 = $mantissa_vec1->to_Dec(); # This method converts values assuming a 2's complement format
        $mantissa2 = $mantissa_vec2->to_Dec();
        $exponent = $exponent_vec->to_Dec();
        return ( $mantissa1*( 2.0**( $exponent - 23 ) ) ) + ( $mantissa2*( 2.0**( $exponent - 39 ) ) );
}
*mil_to_48f = \&M1750A_to_48flt;

=item B<M1750A_to_48flt> I<(mil_to_48f)>

        $hex = '0x69A3B50754AB';
        $dec = M1750A_to_48flt( $hex );
        # $dec is 105.639485637361
        print( "$dec\n" );
        
=cut

# Routines to convert to 1750A values
sub I16_to_1750A{
        my $input = $_[0];
        my $vec = Bit::Vector->new_Dec( 16, $input );
        my $HEX = $vec->to_Hex();
               
        return '0x' . $HEX;
}
*i16_to_mil = \&I16_to_1750A;

=item B<I16_to_1750A> I<(i16_to_mil)>

        $int = -994;
        $hex = I16_to_1750A( $int );
        # $hex is '0x83CA'
        print( "$hex\n" );
        
=cut

sub F16_to_1750A{
        my $input = $_[0];
        my ( $mantissa, $exponent, $complete );
        my $total;
        
        $exponent = int( ceil( log( abs( $input ) ) / log( 2. ) ) );
        
        $mantissa = round( $input /( 2**( $exponent - 9 ) ) );
        
        # Boundary check
        if ( $mantissa == 32768 ) {
                    $mantissa = $mantissa / 2;
                    $exponent++;
        }
        
        my $mantissa_vec = Bit::Vector->new_Dec( 10, $mantissa );
        my $exponent_vec = Bit::Vector->new_Dec( 6, $exponent );
        my ( $MSH, $LSH );
        $MSH = $mantissa_vec->to_Bin();
        $LSH = $exponent_vec->to_Bin();
        $complete = Bit::Vector->new_Bin( 16, "$MSH$LSH" );
        $total = $complete->to_Hex();
        
        return '0x' . $total;
}
*f16_to_mil = \&F16_to_1750A;

=item B<F16_to_1750A> I<(f16_to_mil)>

        $dec = 12.4;
        $hex = M1750A_to_16flt( $dec );
        # $hex is '0x6344'
        print( "$hex\n" );
        
=cut

sub F32_to_1750A{
        my $input = $_[0];
        my ( $mantissa, $exponent );
        
        $exponent = int( ceil( log( abs( $input ) ) / log( 2. ) ) );
        
        $mantissa = round( $input /( 2**( $exponent - 23 ) ) );
        
        # Boundary check
        if ( $mantissa == 8388608 ) {
                    $mantissa = $mantissa / 2;
                    $exponent++;
        }
        
        my $mantissa_vec = Bit::Vector->new_Dec( 24, $mantissa );
        my $exponent_vec = Bit::Vector->new_Dec( 8, $exponent );
        my ( $MSH, $LSH );
        $MSH = $mantissa_vec->to_Hex();
        $LSH = $exponent_vec->to_Hex();
        
        return '0x' . $MSH . $LSH;
}
*f32_to_mil = \&F32_to_1750A;

=item B<F32_to_1750A> I<(f32_to_mil)>

        $dec = -25.63;
        $hex = F32_to_1750A( $dec );
        # $hex is '0x997AE105'
        print( "$hex\n" );
        
=cut

sub F48_to_1750A{
        my $input = $_[0];
        my ( $mantissa, $exponent, $mantissa1, $mantissa2 );
        my ( $MSH, $EXP, $LSH );
        my $mantissa1_vec = Bit::Vector->new( 24 );
        my $mantissa2_vec = Bit::Vector->new( 16 );
        
        $exponent = int( ceil( log( abs( $input ) ) / log( 2. ) ) );
        $mantissa = round( $input/( 2**( $exponent - 39 ) ) );
        
        # Boundary check
        if( $mantissa == 549755813888 ){
                $mantissa = $mantissa / 2;
                $exponent++;
        }
        
        my $mantissa_vec = Bit::Vector->new_Dec( 40, $mantissa );
        my $exponent_vec = Bit::Vector->new_Dec( 8, $exponent );
        $mantissa2_vec->Interval_Copy( $mantissa_vec, 0, 0, 16 );
        $mantissa1_vec->Interval_Copy( $mantissa_vec, 0, 16, 24 );
        $MSH = $mantissa1_vec->to_Hex();
        $EXP = $exponent_vec->to_Hex();
        $LSH = $mantissa2_vec->to_Hex();

        return '0x' . $MSH . $EXP . $LSH;
}
*f48_to_mil = \&F48_to_1750A;

=item B<F48_to_1750A> I<(f48_to_mil)>

        $dec = 105.639485637361;
        $hex = M1750A_to_48flt( $dec );
        # $hex is '0x69A3B50754AB'
        print( "$hex\n" );
        
=cut

1;
