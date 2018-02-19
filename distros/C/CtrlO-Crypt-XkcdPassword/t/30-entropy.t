#!/usr/bin/perl
use Test::More;
use Test::Exception;
use lib './lib';
use lib './t';

use CtrlO::Crypt::XkcdPassword;

my $not_very_entropy =
    Data::Entropy::Source->new(
    IO::File->new( "t/fixtures/nentropy.txt", "r" ) || die($!), "getc" );

my $pwgen =
    CtrlO::Crypt::XkcdPassword->new(
    entropy => $not_very_entropy, wordlist => 'fixtures::XkcdList' );

my @not_random =
    qw(CorrectStapleHorseBattery StapleBatteryCorrectHorse HorseBatteryStapleCorrect);

foreach my $expect (@not_random) {
    is( $pwgen->xkcd, $expect, 'got non-random ' . $expect );
}

done_testing();
