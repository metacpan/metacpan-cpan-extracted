#!perl

use strict;
use warnings;
use Test::More tests => 14;
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
    my $include_certs;

    lives_ok (sub {
            $include_certs = $ctx->get_include_certs;
    }, 'getting include_certs');

    is ($include_certs, -256, 'default include_certs');
}

lives_ok (sub {
        $ctx->set_include_certs(12);
}, 'setting protocol to 12');

{
    my $include_certs;

    lives_ok (sub {
            $include_certs = $ctx->get_include_certs;
    }, 'getting include_certs');

    is ($include_certs, 12, 'setting include_certs worked');
}

lives_ok (sub {
        $ctx->set_include_certs(0);
}, 'setting include_certs to 0');

{
    my $include_certs;

    lives_ok (sub {
            $include_certs = $ctx->get_include_certs;
    }, 'getting include_certs');

    is ($include_certs, 0, 'setting include_certs worked');
}

lives_ok (sub {
        $ctx->set_include_certs;
}, 'calling set_include_certs without arguments works');

{
    my $include_certs;

    lives_ok (sub {
            $include_certs = $ctx->get_include_certs;
    }, 'getting include_certs');

    is ($include_certs, -256, 'calling set_include_certs without arguments sets to default');
}
