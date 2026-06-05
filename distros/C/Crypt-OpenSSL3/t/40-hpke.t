#! perl

use strict;
use warnings;

use Crypt::OpenSSL3;

use Test::More Crypt::OpenSSL3::version() <= version->new('v3.2.0') ? (skip_all => 'Requires OpenSSL 3.2+') : ();

my $suite = Crypt::OpenSSL3::HPKE->from_string("x25519,hkdf-sha256,aes-128-gcm");

ok $suite, 'Could instantiate suite';
is $suite->kem_id, Crypt::OpenSSL3::HPKE::KEM_ID_X25519;
is $suite->kdf_id, Crypt::OpenSSL3::HPKE::KDF_ID_HKDF_SHA256;
is $suite->aead_id, Crypt::OpenSSL3::HPKE::AEAD_ID_AES_GCM_128;
ok $suite->check, 'Suite is supported';

my ($public, $private) = $suite->keygen;
ok $public, 'public key is defined';
ok $private, 'private key is defined';

my ($enc, $ct) = $suite->get_grease_value(128);
ok $enc;
is length $enc, $suite->get_public_encap_size;
ok $ct;
is length $ct, $suite->get_ciphertext_size(128);

my $info = 'info';
my $original = '1234';
my $psk = 'ABCDEFGH' x 4;

{
	my $sender = Crypt::OpenSSL3::HPKE::Context->new($suite, Crypt::OpenSSL3::HPKE::ROLE_SENDER);
	my $receiver = Crypt::OpenSSL3::HPKE::Context->new($suite, Crypt::OpenSSL3::HPKE::ROLE_RECEIVER);

	ok $sender;
	ok $receiver;

	my $cap = $sender->encapsulate($public, $info);
	ok $cap;
	ok $receiver->decapsulate($cap, $private, $info);

	my $cipher = $sender->seal($original, '');
	my $plain = $receiver->open($cipher, '');
	is $plain, $original;

	ok $_->get_seq for $sender, $receiver;
	is $receiver->get_seq, $sender->get_seq;
}

{
	my $sender = Crypt::OpenSSL3::HPKE::Context->new($suite, Crypt::OpenSSL3::HPKE::ROLE_SENDER, Crypt::OpenSSL3::HPKE::MODE_PSK);
	my $receiver = Crypt::OpenSSL3::HPKE::Context->new($suite, Crypt::OpenSSL3::HPKE::ROLE_RECEIVER, Crypt::OpenSSL3::HPKE::MODE_PSK);

	ok $sender;
	ok $receiver;

	ok $sender->set_psk('id', $psk);
	ok $receiver->set_psk('id', $psk);

	my $cap = $sender->encapsulate($public, $info);
	ok $cap;
	ok $receiver->decapsulate($cap, $private, $info);

	my $cipher = $sender->seal($original, '');
	my $plain = $receiver->open($cipher, '');
	is $plain, $original;

	ok $_->get_seq for $sender, $receiver;
	is $receiver->get_seq, $sender->get_seq;
}

{
	my ($public2, $private2) = $suite->keygen;

	ok $public2;
	ok $private2;

	my $sender = Crypt::OpenSSL3::HPKE::Context->new($suite, Crypt::OpenSSL3::HPKE::ROLE_SENDER, Crypt::OpenSSL3::HPKE::MODE_AUTH);
	my $receiver = Crypt::OpenSSL3::HPKE::Context->new($suite, Crypt::OpenSSL3::HPKE::ROLE_RECEIVER, Crypt::OpenSSL3::HPKE::MODE_AUTH);

	ok $sender;
	ok $receiver;

	ok $sender->set_authpriv($private2);
	ok $receiver->set_authpub($public2);

	my $cap = $sender->encapsulate($public, $info);
	ok $cap;
	ok $receiver->decapsulate($cap, $private, $info);

	my $cipher1 = $sender->seal($original, '');
	my $plain = $receiver->open($cipher1, '');
	is $plain, $original;

	ok $_->get_seq for $sender, $receiver;
	is $receiver->get_seq, $sender->get_seq;
}

{
	my ($public2, $private2) = $suite->keygen;

	ok $public2;
	ok $private2;

	my $sender = Crypt::OpenSSL3::HPKE::Context->new($suite, Crypt::OpenSSL3::HPKE::ROLE_SENDER, Crypt::OpenSSL3::HPKE::MODE_PSKAUTH);
	my $receiver = Crypt::OpenSSL3::HPKE::Context->new($suite, Crypt::OpenSSL3::HPKE::ROLE_RECEIVER, Crypt::OpenSSL3::HPKE::MODE_PSKAUTH);

	ok $sender;
	ok $receiver;

	ok $sender->set_psk('id', $psk);
	ok $receiver->set_psk('id', $psk);

	ok $sender->set_authpriv($private2);
	ok $receiver->set_authpub($public2);

	my $cap = $sender->encapsulate($public, $info);
	ok $cap;
	ok $receiver->decapsulate($cap, $private, $info);

	my $cipher1 = $sender->seal($original, '');
	my $plain = $receiver->open($cipher1, '');
	is $plain, $original;

	ok $_->get_seq for $sender, $receiver;
	is $receiver->get_seq, $sender->get_seq;
}

{
	my $sender = Crypt::OpenSSL3::HPKE::Context->new($suite, Crypt::OpenSSL3::HPKE::ROLE_SENDER);
	my $receiver = Crypt::OpenSSL3::HPKE::Context->new($suite, Crypt::OpenSSL3::HPKE::ROLE_RECEIVER);

	ok $sender;
	ok $receiver;

	my $cap = $sender->encapsulate($public, $info);
	ok $cap;
	ok $receiver->decapsulate($cap, $private, $info);

	my $secret = $receiver->export(32, '');
	ok $secret;
	is length $secret, 32;
}

done_testing;
