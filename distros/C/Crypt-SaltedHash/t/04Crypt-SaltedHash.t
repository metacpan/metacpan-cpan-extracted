# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Crypt-SaltedHash.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use Test::More tests => 6;
BEGIN { use_ok('Crypt::SaltedHash') }

#########################

my ( $csh, $salted, $valid );

my %known_salts = (
    'MD5'   => '{SMD5}vfwtsKpZn1kZ5WXDKCFqUTEyMzQ=',
    # 'SHA-1' => '{SSHA}kRnWqCDFvZFoV7A6cTGBdq1Xv7cxMjM0',
);

foreach my $alg (keys %known_salts) {

    $csh = Crypt::SaltedHash->new( algorithm => $alg );
    $csh->add('secret');

    $salted = $csh->generate;
    $valid  = Crypt::SaltedHash->validate( $salted, 'secret' );

    ok( $valid, "$alg: default test" );

    $csh = Crypt::SaltedHash->new( algorithm => $alg, salt_len => 32 );
    $csh->add('secret');

    $salted = $csh->generate;
    $valid  = Crypt::SaltedHash->validate( $salted, 'secret', 32 );

    ok( $valid, "$alg: salt_len test" );

    $csh = Crypt::SaltedHash->new( algorithm => $alg );

    $csh->add('secret');
    $salted = $csh->generate;
    $csh->add('secret');
    $salted = $csh->generate;

    $valid = Crypt::SaltedHash->validate( $salted, 'secretsecret' );

    ok( $valid, "$alg: generate test" );

    $csh = Crypt::SaltedHash->new( algorithm => $alg, salt => '1234' );
    $csh->add('secret');

    ok( $csh->generate eq $known_salts{$alg}, "$alg: own bin-salt test" );

    $csh = Crypt::SaltedHash->new( algorithm => $alg, salt => 'HEX{31323334}' );
    $csh->add('secret');

    ok( $csh->generate eq $known_salts{$alg}, "$alg: own hex-salt test" );
}
