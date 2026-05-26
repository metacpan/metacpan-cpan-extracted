#!/usr/bin/env perl

use v5.36;

use strict;
use warnings;
use Test2::V0;

use Concierge::Auth;
use Concierge::Auth::Generators qw(
    gen_uuid gen_random_id gen_random_token
    gen_random_string gen_word_phrase
);

## Functional interface tests (Generators.pm)

subtest 'gen_uuid - functional' => sub {
    my ($uuid, $msg) = gen_uuid();
    ok(defined $uuid, 'returns a value');
    like($uuid, qr/^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/,
        'matches v4 UUID format');
    like($msg, qr/UUID/, 'message mentions UUID');

    # Scalar context
    my $uuid2 = gen_uuid();
    ok(defined $uuid2, 'scalar context returns value');
    like($uuid2, qr/^[0-9a-f]{8}-/, 'scalar context is a UUID');

    # Uniqueness
    my $uuid3 = gen_uuid();
    isnt($uuid, $uuid3, 'successive UUIDs are different');
};

subtest 'gen_random_id - functional' => sub {
    my ($id, $msg) = gen_random_id();
    ok(defined $id, 'returns a value');
    is(length($id), 40, 'default is 40 hex chars (20 bytes)');
    like($id, qr/^[0-9a-f]+$/, 'hex-only characters');
    like($msg, qr/20 bytes/, 'message mentions byte count');

    # Custom length
    my ($id32, $msg32) = gen_random_id(32);
    is(length($id32), 64, '32 bytes = 64 hex chars');
    like($msg32, qr/32 bytes/, 'message reflects custom byte count');

    my ($id8, $msg8) = gen_random_id(8);
    is(length($id8), 16, '8 bytes = 16 hex chars');

    # Uniqueness
    my $id_a = gen_random_id();
    my $id_b = gen_random_id();
    isnt($id_a, $id_b, 'successive IDs are different');

    # Invalid length falls back to default
    my ($id_bad, $msg_bad) = gen_random_id('abc');
    is(length($id_bad), 40, 'non-numeric length falls back to 20 bytes');
};

subtest 'gen_random_token - functional' => sub {
    my ($token, $msg) = gen_random_token();
    ok(defined $token, 'returns a value');
    is(length($token), 13, 'default length is 13');
    like($msg, qr/13 chars/, 'message mentions length');

    my ($token32, $msg32) = gen_random_token(32);
    is(length($token32), 32, 'custom length works');

    # Uniqueness
    isnt(gen_random_token(), gen_random_token(), 'successive tokens differ');
};

subtest 'gen_random_string - functional' => sub {
    my ($str, $msg) = gen_random_string(20);
    ok(defined $str, 'returns a value');
    is(length($str), 20, 'requested length honoured');

    # With charset
    my ($hex, $msg2) = gen_random_string(16, '0123456789abcdef');
    is(length($hex), 16, 'charset: correct length');
    like($hex, qr/^[0-9a-f]+$/, 'charset: only hex chars');

    # Default length
    my ($def, $msg3) = gen_random_string();
    is(length($def), 13, 'default length is 13');
};

subtest 'gen_word_phrase - functional' => sub {
    my ($phrase, $msg) = gen_word_phrase();
    ok(defined $phrase, 'returns a value');
    ok(length($phrase) > 0, 'non-empty phrase');

    # With separator
    my ($phrase_sep, $msg2) = gen_word_phrase(3, 4, 7, '-');
    ok(defined $phrase_sep, 'separator variant returns a value');
    like($phrase_sep, qr/-/, 'separator is present in phrase');
};

subtest 'gen_random_token - non-numeric length falls back to 13' => sub {
    my ($tok, $msg) = gen_random_token('abc');
    ok( defined $tok, 'returns a value for non-numeric length' );
    is( length($tok), 13, 'falls back to default length of 13' );
};

subtest 'gen_word_phrase - word count with separator' => sub {
    my ($phrase, $msg) = gen_word_phrase(4, 4, 7, '-');
    ok( defined $phrase, 'returns a value' );
    my @words = split /-/, $phrase;
    is( scalar @words, 4, 'exactly 4 words when using hyphen separator' );
    for my $word (@words) {
        ok( length($word) >= 4 && length($word) <= 7,
            "word '$word' length is within 4-7" );
    }
};

subtest 'g_success and g_error internal helpers' => sub {
    # Called directly to cover the default-message branches.
    my ($val, $msg) = Concierge::Auth::Generators::g_success('test_value');
    is( $val, 'test_value', 'g_success returns the value' );
    like( $msg, qr/successful/i, 'g_success uses default message when none given' );

    my $scalar_val = Concierge::Auth::Generators::g_success('x');
    is( $scalar_val, 'x', 'g_success scalar context returns the value' );

    my ($undef_val, $err_msg) = Concierge::Auth::Generators::g_error();
    ok( !defined $undef_val, 'g_error returns undef' );
    like( $err_msg, qr/failed/i, 'g_error uses default message when none given' );

    my $scalar_err = Concierge::Auth::Generators::g_error();
    ok( !defined $scalar_err, 'g_error scalar context returns undef' );
};

subtest 'gen_word_phrase - impossible length triggers g_error' => sub {
    # This path is only reachable when the dictionary file opens successfully
    # but yields no words matching the length criteria. On systems without
    # /usr/share/dict/web2, the fallback generates random strings instead,
    # so the g_error path cannot be triggered.
    plan skip_all => 'requires /usr/share/dict/web2'
        unless -e '/usr/share/dict/web2';

    # No dictionary word is 999+ chars; wordlist will be empty,
    # causing gen_word_phrase to call g_error and return undef.
    my ($result, $msg) = gen_word_phrase(4, 999, 999);
    ok( !defined $result, 'returns undef when no words match length criteria' );
    like( $msg, qr/No words available/i, 'error message mentions no words available' );
};

subtest 'gen_token deprecated alias - functional' => sub {
    my $tok = Concierge::Auth::Generators::gen_token();
    ok( defined $tok, 'gen_token alias returns a value' );
    is( length($tok), 13, 'default length is 13' );
};

subtest 'gen_crypt_token deprecated alias - functional' => sub {
    my $tok = Concierge::Auth::Generators::gen_crypt_token();
    ok( defined $tok, 'gen_crypt_token alias returns a value' );
    is( length($tok), 13, 'default length is 13' );
};

## OO interface tests (Auth.pm wrappers)

my $auth;
my $w = warnings { $auth = Concierge::Auth->new({ no_file => 1 }) };

subtest 'gen_uuid - OO' => sub {
    my ($ok, $msg) = $auth->gen_uuid();
    ok($ok, 'returns truthy');
    like($ok, qr/^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/,
        'value is a v4 UUID');
};

subtest 'gen_random_id - OO' => sub {
    my ($ok, $msg) = $auth->gen_random_id();
    ok($ok, 'returns truthy');
    is(length($ok), 40, 'default 40 hex chars');
    like($ok, qr/^[0-9a-f]+$/, 'hex-only');

    my ($ok32, $msg32) = $auth->gen_random_id(32);
    is(length($ok32), 64, '32 bytes via OO');
};

subtest 'gen_random_token - OO' => sub {
    my ($ok, $msg) = $auth->gen_random_token(24);
    ok($ok, 'returns truthy');
    is(length($ok), 24, 'length matches request');
};

subtest 'gen_random_string - OO' => sub {
    my ($ok, $msg) = $auth->gen_random_string(16, 'abc');
    ok($ok, 'returns truthy');
    is(length($ok), 16, 'correct length');
    like($ok, qr/^[abc]+$/, 'charset honoured');
};

subtest 'gen_word_phrase - OO' => sub {
    my ($ok, $msg) = $auth->gen_word_phrase();
    ok($ok, 'returns truthy');
    ok(length($ok) > 0, 'non-empty phrase');
};

subtest 'gen_word_phrase - OO custom params' => sub {
    my ($phrase, $msg) = $auth->gen_word_phrase(3, 4, 6, '_');
    ok( $phrase, 'returns truthy' );
    my @words = split /_/, $phrase;
    is( scalar @words, 3, 'correct word count via OO' );
};

subtest 'gen_token deprecated alias - OO' => sub {
    my ($ok, $msg) = $auth->gen_token();
    ok( $ok, 'gen_token OO alias returns truthy' );
    is( length($ok), 13, 'default length 13' );
};

subtest 'gen_crypt_token deprecated alias - OO' => sub {
    my ($ok, $msg) = $auth->gen_crypt_token();
    ok( $ok, 'gen_crypt_token OO alias returns truthy' );
    is( length($ok), 13, 'default length 13' );
};

done_testing;
