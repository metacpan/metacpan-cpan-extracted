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
    my $armor;

    lives_ok (sub {
            $armor = $ctx->get_armor;
    }, 'getting armor');

    ok (!$armor, 'default armor is off');
}

lives_ok (sub {
        $ctx->set_armor(1);
}, 'setting protocol to on');

{
    my $armor;

    lives_ok (sub {
            $armor = $ctx->get_armor;
    }, 'getting armor');

    ok ($armor, 'setting armor worked');
}

lives_ok (sub {
        $ctx->set_armor(0);
}, 'setting armor to off');

{
    my $armor;

    lives_ok (sub {
            $armor = $ctx->get_armor;
    }, 'getting armor');

    ok (!$armor, 'setting armor worked');
}
