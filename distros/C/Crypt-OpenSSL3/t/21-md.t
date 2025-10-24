#! perl

use strict;
use warnings;

use Test::More;

use Crypt::OpenSSL3;

my @digests = Crypt::OpenSSL3::MD->list_all_provided;
ok @digests, 'Got digests';

my $has_sha256 = grep { $_->get_name eq 'SHA2-256' } @digests;
ok $has_sha256, 'Has SHA-256';

my $md = Crypt::OpenSSL3::MD->fetch('SHA2-256');
ok $md;

my $context = Crypt::OpenSSL3::MD::Context->new;
$context->init($md);

$context->update("Hello, World!");
my $hash = $context->final;
my $expected = pack 'H*', 'dffd6021bb2bd5b0af676290809ec3a53191dd81c7f70a4b28688a362182986f';
is $hash, $expected;

my $ctx = Crypt::OpenSSL3::PKey::Context->new_from_name("RSA");
ok $ctx;
ok $ctx->keygen_init;
ok $ctx->set_params({ bits => 2048, primes => 2, e => 65537 });

my $pkey = $ctx->generate;
ok $pkey;

my $context2 = Crypt::OpenSSL3::MD::Context->new;
ok $context2->sign_init($md, $pkey);
ok $context2->sign_update("Hello, World!");
my $signature = $context2->sign_final;
ok $signature;

my $context3 = Crypt::OpenSSL3::MD::Context->new;
ok $context3->verify_init($md, $pkey);
ok $context3->verify_update("Hello, World!");
ok $context3->verify_final($signature);

done_testing;
