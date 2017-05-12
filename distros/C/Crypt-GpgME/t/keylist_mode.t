#!perl

use strict;
use warnings;
use Test::More tests => 25;
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
    my $keylist_mode;

    lives_ok (sub {
            $keylist_mode = $ctx->get_keylist_mode;
    }, 'getting keylist_mode');

    is_deeply ($keylist_mode, ['local'], 'default keylist_mode is local');
}

for my $mode (qw/extern sigs sig-notations validate local/) {
    lives_ok (sub {
            $ctx->set_keylist_mode([$mode]);
    }, "setting keylist_mode to $mode");

    {
        my $keylist_mode;

        lives_ok (sub {
                $keylist_mode = $ctx->get_keylist_mode;
        }, 'getting keylist_mode');

        is_deeply ($keylist_mode, [$mode], 'setting keylist_mode worked');
    }
}

throws_ok(sub {
        $ctx->set_keylist_mode(['opengpg']);
}, qr/^unknown keylist mode/, 'setting invalid keylist_mode');

throws_ok(sub {
        $ctx->set_keylist_mode({});
}, qr/not an array reference/, 'calling with non-array-ref');

lives_ok (sub {
        $ctx->set_keylist_mode;
}, 'setting keylist_mode without argument works');

{
    my $keylist_mode;

    lives_ok (sub {
            $keylist_mode = $ctx->get_keylist_mode;
    }, 'getting keylist_mode');

    is_deeply ($keylist_mode, ['local'], 'calling set_keylist_mode without arguments sets to local');
}
