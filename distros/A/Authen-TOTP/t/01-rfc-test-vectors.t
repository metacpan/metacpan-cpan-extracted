use strict;
use warnings;
use Test::More tests => 19;

BEGIN {
use_ok( 'Authen::TOTP' );
}

my $otp = new Authen::TOTP;

ok ( $otp->validate_otp(secret => "12345678901234567890", when => 59, digits => 8, otp => "94287082", tolerance => 1) == 1 );

ok ( $otp->validate_otp(secret => "12345678901234567890", when => 1111111109, digits => 8, otp => "07081804", tolerance => 1) == 1 );

ok ( $otp->validate_otp(secret => "12345678901234567890", when => 1111111111, digits => 8, otp => "14050471", tolerance => 1) == 1 );

ok ( $otp->validate_otp(secret => "12345678901234567890", when => 1234567890, digits => 8, otp => "89005924", tolerance => 1) == 1 );

ok ( $otp->validate_otp(secret => "12345678901234567890", when => 2000000000, digits => 8, otp => "69279037", tolerance => 1) == 1 );

ok ( $otp->validate_otp(secret => "12345678901234567890", when => 20000000000, digits => 8, otp => "65353130", tolerance => 1) == 1 );

$otp->algorithm("SHA256");

ok ( $otp->validate_otp(secret => "12345678901234567890123456789012", when => 59, digits => 8, otp => "46119246", tolerance => 1) == 1 );

ok ( $otp->validate_otp(secret => "12345678901234567890123456789012", when => 1111111109, digits => 8, otp => "68084774", tolerance => 1) == 1 );

ok ( $otp->validate_otp(secret => "12345678901234567890123456789012", when => 1111111111, digits => 8, otp => "67062674", tolerance => 1) == 1 );

ok ( $otp->validate_otp(secret => "12345678901234567890123456789012", when => 1234567890, digits => 8, otp => "91819424", tolerance => 1) == 1 );

ok ( $otp->validate_otp(secret => "12345678901234567890123456789012", when => 2000000000, digits => 8, otp => "90698825", tolerance => 1) == 1 );

ok ( $otp->validate_otp(secret => "12345678901234567890123456789012", when => 20000000000, digits => 8, otp => "77737706", tolerance => 1) == 1 );

$otp->algorithm("SHA512");

ok ( $otp->validate_otp(secret => "1234567890123456789012345678901234567890123456789012345678901234", when => 59, digits => 8, otp => "90693936", tolerance => 1) == 1 );

ok ( $otp->validate_otp(secret => "1234567890123456789012345678901234567890123456789012345678901234", when => 1111111109, digits => 8, otp => "25091201", tolerance => 1) == 1 );

ok ( $otp->validate_otp(secret => "1234567890123456789012345678901234567890123456789012345678901234", when => 1111111111, digits => 8, otp => "99943326", tolerance => 1) == 1 );

ok ( $otp->validate_otp(secret => "1234567890123456789012345678901234567890123456789012345678901234", when => 1234567890, digits => 8, otp => "93441116", tolerance => 1) == 1 );

ok ( $otp->validate_otp(secret => "1234567890123456789012345678901234567890123456789012345678901234", when => 2000000000, digits => 8, otp => "38618901", tolerance => 1) == 1 );

ok ( $otp->validate_otp(secret => "1234567890123456789012345678901234567890123456789012345678901234", when => 20000000000, digits => 8, otp => "47863826", tolerance => 1) == 1 );
