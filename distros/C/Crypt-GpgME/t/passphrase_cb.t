#!perl

use strict;
use warnings;
use Test::More tests => 48;
use Test::Exception;
use IO::Scalar;

BEGIN {
	use_ok( 'Crypt::GpgME' );
}

delete $ENV{GPG_AGENT_INFO};
$ENV{GNUPGHOME} = 't/gpg';

my $ctx;
lives_ok (sub {
        $ctx = Crypt::GpgME->new;
}, 'create new context');

isa_ok ($ctx, 'Crypt::GpgME');

my $plain = IO::Scalar->new(\q/test test test/);

my $called = 0;

sub pass_cb {
    is (@_, 4, 'cb got 4 params');

    my ($c, $uid_hint, $passphrase_info, $prev_was_bad) = @_;

    isa_ok ($c, 'Crypt::GpgME');
    ok($c == $ctx, 'context references are equal');

    like ($uid_hint, qr/^[A-F0-9]{16}\s+[^<]+\s+<[^>]+>$/, 'uid hint looks sane');
    like ($passphrase_info, qr/^[A-F0-9]/, 'passphrase info looks sane');
    is ($prev_was_bad, ! !$called % 3, 'prev_was_bad looks sane');

    ++$called;
}

lives_ok (sub {
        $ctx->set_passphrase_cb(\&pass_cb);
}, 'setting passphrase cb without user data');

is ($called, 0, 'just setting the cb doesn\'t call it');

eval {
    $ctx->sign($plain, 'clear');
};

ok ($called > 0, 'signing calls the cb');

$called = 0;

sub pass_cb_ud {
    is (@_, 5, 'cb got 5 params');

    my ($c, $uid_hint, $passphrase_info, $prev_was_bad, $user_data) = @_;

    isa_ok ($c, 'Crypt::GpgME');
    ok($c == $ctx, 'context references are equal');

    like ($uid_hint, qr/^[A-F0-9]{16}\s+[^<]+\s+<[^>]+>$/, 'uid hint looks sane');
    like ($passphrase_info, qr/^[A-F0-9]/, 'passphrase info looks sane');
    is ($prev_was_bad, ! !$called % 3, 'prev_was_bad looks sane');
    is ($user_data, 'foo', 'user data looks sane');

    ++$called;
}

lives_ok (sub {
        $ctx->set_passphrase_cb(\&pass_cb_ud, 'foo');
}, 'setting passphrase cb with user data');

is ($called, 0, 'just setting the cb doesn\'t call it');

eval {
    $ctx->sign($plain, 'clear');
};

ok ($called > 0, 'signing calls the cb');
