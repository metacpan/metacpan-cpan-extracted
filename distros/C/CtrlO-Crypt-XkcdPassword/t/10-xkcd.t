#!/usr/bin/perl
use Test::More;
use lib 'lib';

use CtrlO::Crypt::XkcdPassword;

my $pwgen = CtrlO::Crypt::XkcdPassword->new;

subtest 'all defaults' => sub {
    my $pw = $pwgen->xkcd;

    like(
        $pw,
        qr/^(\p{Uppercase}\p{Lowercase}+){4}$/,
        'looks like a XKCD pwd'
    );
};

subtest 'words=>3' => sub {
    my $pw = $pwgen->xkcd( words => 3 );

    like(
        $pw,
        qr/^(\p{Uppercase}\p{Lowercase}+){3}$/,
        'looks like a XKCD pwd with 3 words'
    );
};

subtest 'words=>3, digits=>3' => sub {
    my $pw = $pwgen->xkcd( words => 3, digits => 3 );

    like(
        $pw,
        qr/^(\p{Uppercase}\p{Lowercase}+){3}\d{3}$/,
        'looks like a XKCD pwd with 3 words and 3 digits'
    );
};

done_testing();
