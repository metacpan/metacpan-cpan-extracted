#!perl

use strict;
use warnings;
use Test::More;
use Test::Exception;
use IO::Scalar;

BEGIN {
    eval 'use Scalar::Util qw/looks_like_number/';
    plan skip_all => 'Scalar::Util required' if $@;

    plan tests => 24;
}

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

$ctx->set_passphrase_cb(sub { return 'abc' });

my $called = 0;

sub progress_cb {
    return if $called;

    is (@_, 5, 'cb got 5 params');

    my ($c, $what, $type, $current, $total) = @_;

    isa_ok ($c, 'Crypt::GpgME');
    ok($c == $ctx, 'context references are equal');
    ok ($what, 'what looks sane');
    like ($type, qr/^.$/, 'type looks sane'); #FIXME: what chars are valid?
    ok (looks_like_number($current), 'current looks sane');
    ok (looks_like_number($total), 'total looks sane');

    ++$called;
}

lives_ok (sub {
        $ctx->set_progress_cb(\&progress_cb);
}, 'setting progress cb without user data');

is ($called, 0, 'just setting the cb doesn\'t call it');

$ctx->sign($plain, 'clear');

ok ($called > 0, 'signing calls the cb');

$called = 0;

sub progress_cb_ud {
    return if $called;

    is (@_, 6, 'cb got 6 params');

    my ($c, $what, $type, $current, $total, $user_data) = @_;

    isa_ok ($c, 'Crypt::GpgME');
    ok($c == $ctx, 'context references are equal');
    ok ($what, 'what looks sane');
    like ($type, qr/^.$/, 'type looks sane'); #FIXME: what chars are valid?
    ok (looks_like_number($current), 'current looks sane');
    ok (looks_like_number($total), 'total looks sane');
    is ($user_data, 'foo', 'user data looks sane');

    ++$called;
}

lives_ok (sub {
        $ctx->set_progress_cb(\&progress_cb_ud, 'foo');
}, 'setting progress cb with user data');

is ($called, 0, 'just setting the cb doesn\'t call it');

eval {
    $ctx->sign($plain, 'clear');
};

ok ($called > 0, 'signing calls the cb');
