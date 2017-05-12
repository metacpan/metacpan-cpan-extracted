#!perl -T

use Test::More tests => 127;
use Test::Warn;
use strict;

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



#  known MEID equivalents from 3GPP2 X.S0008v2.0
my $hex_meid = 'A10000009296F2';
my $hex_manufacturer_code = '000000';
my $hex_serial_number = '9296F2';
my $hex_pesn = '8075B7ED';
my $hex_check_digit ='F';

my $dec_meid = '270113177609606898';
my $dec_manufacturer_code = '2701131776';
my $dec_serial_number = '09606898';
my $dec_pesn = '1287714797';
my $dec_check_digit = '4';



#  bad MEID lists
my @hex_bad_meids = ( 0, undef, 'A10000009296Z2', '09000000000000', 'A00000000000000' );
my @dec_bad_meids = ( 0, undef, '268435455916777215', '295279001616777215', '268435456016777216' );




#  test that we can convert a MEID from Decimal to Hex
is(
    uc(meid_to_hex($dec_meid)), uc($hex_meid),
    "Convert decimal MEID to Hex: got " . meid_to_hex($dec_meid) . ", expected $hex_meid"
);

#  test that when we put in bad DEC MEID's that the converion to HEX fails
foreach my $bad_dec_meid ( @dec_bad_meids, $hex_meid ) {
    warning_like {
        is(
            meid_to_hex($bad_dec_meid), '0', "invaid HEX MEID properly detected: " . passed_value( $bad_dec_meid )
        )
    } qr/invalid MEID/i, "invalid MEID warning detected for " . passed_value( $bad_dec_meid );
}



#  test that we can convert a MEID from Hex to Decimal
is(
    meid_to_dec($hex_meid), $dec_meid,
    "Convert Hex MEID to Dec: got " . meid_to_dec($hex_meid) . ", expected $dec_meid"
);

#  test that when we put in bad HEX MEID's that the converion to DEC fails
foreach my $bad_hex_meid ( @hex_bad_meids, $dec_meid ) {
    warning_like {
        is(
            meid_to_dec($bad_hex_meid), '0', "invaid DEC MEID properly detected: " . passed_value( $bad_hex_meid )
        )
    } qr/invalid MEID/i, "invalid MEID warning detected for " . passed_value( $bad_hex_meid );
}


#  test meid_is_valid
is( meid_is_valid($hex_meid), 'hex', "HEX MEID detected $hex_meid" );
is( meid_is_valid($dec_meid), 'dec', "DEC MEID detected $dec_meid" );

#  test that invalid MEID's are detected
foreach my $invalid_meid ( @hex_bad_meids, @dec_bad_meids ) {
    is( meid_is_valid($invalid_meid), '0', "invalid MEID detected: " . passed_value($invalid_meid) );
}


#  test meid_is_hex
ok( meid_is_hex($hex_meid), "HEX MEID detected $hex_meid");

foreach my $bad_hex_meid ( @dec_bad_meids, @hex_bad_meids, '910000009296F2', $dec_meid ) {
    is( meid_is_hex($bad_hex_meid), '0', "HEX MEID not detected: " . passed_value($bad_hex_meid) );
}


#  test meid_is_dec
ok( meid_is_dec($dec_meid), "DEC MEID detected $dec_meid");

foreach my $bad_dec_meid ( @dec_bad_meids, @hex_bad_meids, $hex_meid ) {
    is( meid_is_dec($bad_dec_meid), '0', "DEC MEID not detected: " . passed_value($bad_dec_meid) );
}


#  calculate MEID HEX check digit
is( uc( meid_check_digit( $hex_meid ) ), uc($hex_check_digit), "Calculated dec check digit from hex MEID");
is( meid_check_digit( $dec_meid ), $dec_check_digit, "Calculated decimal check digit from decimal MEID");
is( meid_check_digit( '293608736500703710' ), '0', "Calculated decimal check digit from decimal MEID");
is( uc(meid_check_digit( 'AF0123450ABCDE' )), 'C', "Calculated hex check digit from hex MEID");

    
is( manu_code_dec($hex_meid), $dec_manufacturer_code, "got $dec_manufacturer_code  code from hex MEID" );
is( manu_code_dec($dec_meid), $dec_manufacturer_code, "got $dec_manufacturer_code  code from dec MEID" );
is( manu_code_hex($hex_meid), $hex_manufacturer_code, "got $hex_manufacturer_code  code from hex MEID" );
is( manu_code_hex($dec_meid), $hex_manufacturer_code, "got $hex_manufacturer_code  code from dec MEID" );
is( serial_num_dec($hex_meid), $dec_serial_number, "got $dec_serial_number  code from hex MEID" );
is( serial_num_dec($dec_meid), $dec_serial_number, "got $dec_serial_number  code from dec MEID" );
is( serial_num_hex($hex_meid), $hex_serial_number, "got $hex_serial_number  code from hex MEID" );
is( uc(serial_num_hex($dec_meid)), uc($hex_serial_number), "got $hex_serial_number  code from dec MEID" );


foreach my $bad_meid ( @hex_bad_meids, @dec_bad_meids ) {
    is( manu_code_dec($bad_meid),  '0', "manu_code_dec returned 0 on " . passed_value($bad_meid ) );
    is( manu_code_hex($bad_meid),  '0', "manu_code_hex returned 0 on " . passed_value($bad_meid ) );
    is( serial_num_dec($bad_meid), '0', "serial_num_dec returned 0 on " . passed_value($bad_meid ) );
    is( serial_num_hex($bad_meid), '0', "serial_num_hex returned 0 on " . passed_value($bad_meid ) );
}


#  check meid_to_pesn
is( uc(meid_to_pesn($hex_meid)), uc($hex_pesn), "$hex_meid to pesn: $hex_pesn converted correctly");
is( uc(meid_to_pesn($dec_meid)), uc($hex_pesn), "$hex_meid to pesn: $hex_pesn converted correctly");
foreach my $bad_meid ( @hex_bad_meids, @dec_bad_meids ) {
    is( meid_to_pesn($bad_meid),  '0', "meid_to_pesn returned 0 on " . passed_value($bad_meid ) );
}

#  pass back a printable output for what we want to display in the test script
sub passed_value {
    my ( $value ) = @_;
    if ( not defined $value ) {
        return 'undef';
    } elsif ( $value eq '0') {
        return 0;
    } else {
        return $value;
    }
}





