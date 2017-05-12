#!perl

use strict;
use warnings;

#
# Same tests as 01-cases.t except use bignum first.
#
# On perl < 5.18 or bignum < 0.33 the overrides of
# hex and oct were not scoped properly and would
# interfere with certain uses of hex.
# From perl5180delta:
# "Using any of these three pragmata would cause hex
# and oct anywhere else in the program to evaluate their
# arguments in list context and prevent them from
# inferring $_ when called without arguments."
#

use Authen::OATH ();
use Digest::SHA  ();
use Test::More;
use Test::Needs 'bignum';

my $pwd  = '12345678901234567890';
my $oath = Authen::OATH->new();
my $OATH = Authen::OATH->new( 'digits' => 8 );
ok( defined $oath,              'successfully created new object' );
ok( $oath->isa('Authen::OATH'), 'correct class.' );
ok( $oath->digits == 6,         'default digits set to 6' );
ok(
    $oath->digest eq 'Digest::SHA',
    'default digest set to Digest::SHA'
);
ok( $oath->{'timestep'} == 30, 'default timestep set to 30' );

print "Checking test vectors for totp()...\n";
ok( $OATH->totp( $pwd, 59 ) eq '94287082' );
ok( $OATH->totp( $pwd, 1111111109 ) eq '07081804' );
ok( $OATH->totp( $pwd, 1111111111 ) eq '14050471' );
ok( $OATH->totp( $pwd, 1234567890 ) eq '89005924' );
ok( $OATH->totp( $pwd, 2000000000 ) eq '69279037' );

print "Checking test vectors for hotp()...\n";
ok( $oath->hotp( $pwd, 0 ) eq '755224' );
ok( $oath->hotp( $pwd, 1 ) eq '287082' );
ok( $oath->hotp( $pwd, 2 ) eq '359152' );
ok( $oath->hotp( $pwd, 3 ) eq '969429' );
ok( $oath->hotp( $pwd, 4 ) eq '338314' );
ok( $oath->hotp( $pwd, 5 ) eq '254676' );
ok( $oath->hotp( $pwd, 6 ) eq '287922' );
ok( $oath->hotp( $pwd, 7 ) eq '162583' );
ok( $oath->hotp( $pwd, 8 ) eq '399871' );
ok( $oath->hotp( $pwd, 9 ) eq '520489' );

done_testing();
