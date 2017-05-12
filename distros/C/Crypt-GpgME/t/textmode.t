#!perl

use strict;
use warnings;
use Test::More tests => 11;
use Test::Exception;

BEGIN {
	use_ok( 'Crypt::GpgME' );
}

my $ctx;
lives_ok (sub {
    $ctx = Crypt::GpgME->new;
}, 'create new context');

isa_ok ($ctx, 'Crypt::GpgME');

{
    my $textmode;

    lives_ok (sub {
            $textmode = $ctx->get_textmode;
    }, 'getting textmode');

    ok (!$textmode, 'default textmode is off');
}

lives_ok (sub {
        $ctx->set_textmode(1);
}, 'setting protocol to on');

{
    my $textmode;

    lives_ok (sub {
            $textmode = $ctx->get_textmode;
    }, 'getting textmode');

    ok ($textmode, 'setting textmode worked');
}

lives_ok (sub {
        $ctx->set_textmode(0);
}, 'setting textmode to off');

{
    my $textmode;

    lives_ok (sub {
            $textmode = $ctx->get_textmode;
    }, 'getting textmode');

    ok (!$textmode, 'setting textmode worked');
}
