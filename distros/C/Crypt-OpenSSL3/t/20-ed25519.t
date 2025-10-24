#! perl

use strict;
use warnings;

use Test::More;

use Crypt::OpenSSL3;
use version;

plan skip_all => 'Requires OpenSSL 3.4+' if Crypt::OpenSSL3::version() <= version->new('v3.4.0');

my $ctx = Crypt::OpenSSL3::PKey::Context->new_from_name("ED25519");
ok $ctx;
ok $ctx->keygen_init;

my $pkey = $ctx->generate;
ok $pkey;
ok $pkey->is_a('ED25519');

my $ctx1 = Crypt::OpenSSL3::PKey::Context->new_from_pkey($pkey);
ok $ctx1;
ok $ctx1->sign_init;

my $ctx2 = Crypt::OpenSSL3::PKey::Context->new_from_pkey($pkey);
ok $ctx2;

my $payload = "0123456789ABCDEF" x 4;

my $signer = Crypt::OpenSSL3::Signature->fetch("Ed25519ph");
ok $signer;
ok $signer->is_a('Ed25519ph');

ok $ctx2->sign_init($signer, { 'context-string' => 'This is some name' });

ok open my $fh, '<', $0;
my $content = do { local $/; <$fh> };

my $signature = $ctx2->sign($payload);
ok $signature or do {
	my $error = Crypt::OpenSSL3::get_error();
	diag $error->error_string;
};

my $ctx3 = Crypt::OpenSSL3::PKey::Context->new_from_pkey($pkey);
ok $ctx3;
ok $ctx3->verify_init($signer, { 'context-string' => 'This is some name' });
Crypt::OpenSSL3::clear_error();
ok $ctx3->verify($signature, $payload) or do {
	my $error = Crypt::OpenSSL3::get_error();
	diag $error->error_string;
};


done_testing;
