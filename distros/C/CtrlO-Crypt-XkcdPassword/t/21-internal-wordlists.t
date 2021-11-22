#!/usr/bin/perl
use Test::More;
use Test::Exception;
use lib './lib';
use lib './t';

use CtrlO::Crypt::XkcdPassword;

my $not_very_entropy =
    Data::Entropy::Source->new( IO::File->new( "t/fixtures/moreentropy.txt", "r" ) || die($!),
    "getc" );

subtest 'eff_short_1' => sub {
    my $pwgen = CtrlO::Crypt::XkcdPassword->new(
        entropy  => $not_very_entropy,
        wordlist => 'eff_short_1',
    );

    my $pw = $pwgen->xkcd( words => 3 );
    is( $pw, 'BrokeDartUpper', 'got password' );
};

subtest 'eff_short_2_0' => sub {
    my $pwgen = CtrlO::Crypt::XkcdPassword->new(
        entropy  => $not_very_entropy,
        wordlist => 'eff_short_2_0',
    );

    my $pw = $pwgen->xkcd( words => 3 );
    is( $pw, 'AlphabetMyriadNetting', 'got password' );
};

subtest 'eff_large' => sub {
    my $pwgen = CtrlO::Crypt::XkcdPassword->new(
        entropy  => $not_very_entropy,
        wordlist => 'eff_large',
    );

    my $pw = $pwgen->xkcd( words => 3 );
    is( $pw, 'ReoccupyUnhappilyBackache', 'got password' );
};

subtest 'eff_short_1 via full module name' => sub {
    my $pwgen = CtrlO::Crypt::XkcdPassword->new(
        entropy  => $not_very_entropy,
        wordlist => 'CtrlO::Crypt::XkcdPassword::Wordlist::eff_short_1',
    );

    my $pw = $pwgen->xkcd( words => 3 );
    is( $pw, 'CrushSmirkFloss', 'got password' );
};

done_testing();
