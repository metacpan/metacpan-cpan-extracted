#!/usr/bin/perl
use Test::More;
use Test::Exception;
use lib './lib';
use lib './t';

use CtrlO::Crypt::XkcdPassword;

subtest 'wordlist from file' => sub {
    my $pwgen =
        CtrlO::Crypt::XkcdPassword->new(
        wordlist => './t/fixtures/aa_wordlist.txt' );

    my $pw = $pwgen->xkcd;
    is( $pw, 'AaAaAaAa', 'a lot of aas' );

    my $pw2 = $pwgen->xkcd( words => 3, digits => 1 );
    like( $pw2, qr/^AaAaAa\d$/, 'less aas, but a digit' );

    my $second =
        CtrlO::Crypt::XkcdPassword->new(
        wordlist => './t/fixtures/aa_wordlist.txt' )->xkcd;
    is( $second, 'AaAaAaAa', 'a lot of aas' );
};

subtest 'wordlist from Wordlist' => sub {
    my $pwgen =
        CtrlO::Crypt::XkcdPassword->new( wordlist => 'fixtures::AaWordlist' );

    my $pw = $pwgen->xkcd;
    is( $pw, 'AaAaAaAa', 'a lot of aas' );

    my $pw2 = $pwgen->xkcd( words => 3, digits => 1 );
    like( $pw2, qr/^AaAaAa\d$/, 'less aas, but a digit' );

    my $second =
        CtrlO::Crypt::XkcdPassword->new( wordlist => 'fixtures::AaWordlist' )
        ->xkcd;
    is( $second, 'AaAaAaAa', 'a lot of aas' );
};

subtest 'wordlist from Crypt::Diceware' => sub {
    my $pwgen =
        CtrlO::Crypt::XkcdPassword->new( wordlist => 'fixtures::AaDiceware' );

    my $pw = $pwgen->xkcd;
    is( $pw, 'AaAaAaAa', 'a lot of aas' );

    my $pw2 = $pwgen->xkcd( words => 3, digits => 1 );
    like( $pw2, qr/^AaAaAa\d$/, 'less aas, but a digit' );

    my $second =
        CtrlO::Crypt::XkcdPassword->new( wordlist => 'fixtures::AaDiceware' )
        ->xkcd;
    is( $second, 'AaAaAaAa', 'a lot of aas' );
};

subtest 'language en-GB' => sub {
    my $pwgen = CtrlO::Crypt::XkcdPassword->new( language => 'en-GB' );

    my $pw = $pwgen->xkcd;
    like(
        $pw,
        qr/^(\p{Uppercase}\p{Lowercase}+){4}$/,
        'looks like a XKCD pwd'
    );
};

subtest 'custom file and language en-GB' => sub {
    my $pwgen = CtrlO::Crypt::XkcdPassword->new(
        language => 'en-GB',
        wordlist => './t/fixtures/aa_wordlist.txt'
    );

    my $pw = $pwgen->xkcd;
    is( $pw, 'AaAaAaAa', 'a lot of aas, so langauge was ignored' );

    my $pw2 = $pwgen->xkcd( words => 3, digits => 1 );
    like( $pw2, qr/^AaAaAa\d$/, 'less aas, but a digit' );
};

subtest 'language de-AT-Fake' => sub {
    my $pwgen = CtrlO::Crypt::XkcdPassword->new( language => 'de-AT-Fake' );

    my $pw = $pwgen->xkcd;
    like( $pw, qr/Heast/,   'Heast' );
    like( $pw, qr/Ur/,      'Ur' );
    like( $pw, qr/Leiwand/, 'Leiwand' );
    like( $pw, qr/Oida/,    'Oida !' );
};

subtest 'failures' => sub {
    throws_ok {
        CtrlO::Crypt::XkcdPassword->new( wordlist => './no/such/file.txt' )
    }
    qr/either a Perl module or a file/, 'no such file';

    throws_ok {
        CtrlO::Crypt::XkcdPassword->new( wordlist => 'No::Such::Module' )
    }
    qr/Cannot load word list module No::Such::Module/, 'no such module';

    throws_ok {
        CtrlO::Crypt::XkcdPassword->new( wordlist => 'fixtures::NotAList' )
    }
    qr{Cannot find word list in Perl module fixtures::NotAList}, 'Not a wordlist-module';

    throws_ok {
        CtrlO::Crypt::XkcdPassword->new( wordlist => 'NotAnInternalWordlist' )
    }
    qr{Cannot load word list module CtrlO::Crypt::XkcdPassword::Wordlist::NotAnInternalWordlist}, 'Not an internal wordlist';
};

done_testing();
