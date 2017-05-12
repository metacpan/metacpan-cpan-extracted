#!perl

use strict;
use warnings;
use Test::More tests => 15;
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
    my $proto;

    lives_ok (sub {
            $proto = $ctx->get_protocol;
    }, 'getting protocol');

    is ($proto, 'OpenPGP', 'default protocol is OpenPGP');
}

lives_ok (sub {
        $ctx->set_protocol('CMS');
}, 'setting protocol to CMS');

{
    my $proto;

    lives_ok (sub {
            $proto = $ctx->get_protocol;
    }, 'getting protocol');

    is ($proto, 'CMS', 'setting protocol worked');
}

lives_ok (sub {
        $ctx->set_protocol('OpenPGP');
}, 'setting protocol to OpenPGP');

{
    my $proto;

    lives_ok (sub {
            $proto = $ctx->get_protocol;
    }, 'getting protocol');

    is ($proto, 'OpenPGP', 'setting protocol worked');
}

throws_ok(sub {
        $ctx->set_protocol('opengpg');
}, qr/^unknown protocol/, 'setting invalid protocol');

lives_ok (sub {
        $ctx->set_protocol;
}, 'setting protocol without argument works');

{
    my $proto;

    lives_ok (sub {
            $proto = $ctx->get_protocol;
    }, 'getting protocol');

    is ($proto, 'OpenPGP', 'calling set_protocol without arguments sets to OpenPGP');
}
