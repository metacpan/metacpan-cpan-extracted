use Test::More;

use strict;
use warnings;

use Crypt::HSM;

my $path = $ENV{HSM_PROVIDER} || '/usr/lib/softhsm/libsofthsm2.so';
my $pin = $ENV{HSM_PIN};

plan skip_all => 'No softhsm detected' unless defined $pin && -e $path;

my $provider = Crypt::HSM->load($path);

ok $provider, 'load';

my $info = $provider->info;
note explain $info;

my @slots = $provider->slots;

for my $slot ( @slots ) {
	note 'slotID: ', $slot->id;
	my $slotInfo = $slot->info;
	note explain $slotInfo;

	my $tokenInfo = $slot->token_info;
	note explain $tokenInfo;
}

for my $mechanism ($slots[0]->mechanisms) {
	my $info = $mechanism->info;
	my @flags = $info->flags;
	note $mechanism->name, ': ', join ', ', @flags;
}

my $session = $slots[0]->open_session('rw-session' => 0);

undef $provider;

$session->login('user', $pin) if length $pin;

my $sessionInfo = $session->info;
note explain $sessionInfo;

my %public_key_template = (
	token => 0,
	encrypt => 1,
	verify => 1,
	modulus_bits => 2048,
	public_exponent => 65537,
	label => 'test public key',
	id => 'abc',
);

my %private_key_template = (
	token => 0,
	sensitive => 1,
	extractable => 1,
	decrypt => 1,
	sign => 1,
	label => 'test private key',
	id => 'abc',
);

my ($public_key, $private_key) = $session->generate_keypair('rsa-pkcs-key-pair-gen', \%public_key_template, \%private_key_template);

note $public_key->id;
note $private_key->id;

my $plain_text = 'plain text';
{
my $encrypted_text = $session->encrypt('rsa_pkcs', $public_key, $plain_text);

my $decrypted_text = $session->decrypt('rsa-pkcs', $private_key, $encrypted_text);

is $decrypted_text, $plain_text, 'rsa-pkcs decrypted';
}

{
my $encrypted_text = $session->encrypt('rsa_pkcs_oaep', $public_key, $plain_text, 'sha1');

my $decrypted_text = $session->decrypt('rsa-pkcs-oaep', $private_key, $encrypted_text, 'sha1');

is $decrypted_text, $plain_text, 'rsa-oaep decrypted';
}

{
my $signature = $session->sign('sha256-rsa-pkcs', $private_key, $plain_text);

ok $session->verify('sha256-rsa-pkcs', $public_key, $plain_text, $signature), 'rsa-pkcs verified';
}

{
my $signature = $session->sign('sha256-rsa-pkcs-pss', $private_key, $plain_text);

ok $session->verify('sha256-rsa-pkcs-pss', $public_key, $plain_text, $signature), 'rsa-pss verified';
}

my $attributes = $public_key->get_attributes([ 'modulus', 'public_exponent' ]);

is length($attributes->{modulus}->to_bytes), 256, 'modulus is 2024 bits';
is $attributes->{public_exponent}, 65537, 'public exponent is 65537';

my $modulus = $public_key->get_attribute('modulus');
is($modulus, $attributes->{modulus}, 'modulus is modulus');

my $aes_key = $session->generate_key('aes-key-gen', { 'value-len' => 32, token => 0 });

ok $aes_key, 'aes key successfully generated';

my $iv = "\0" x 16;
my $encoder = $session->open_encrypt('aes-cbc-pad', $aes_key, $iv);

my $tripled = $plain_text x 3;
my $ciphertext = $encoder->add_data($tripled);
$ciphertext .= $encoder->finalize;

is $session->decrypt('aes-cbc-pad', $aes_key, $ciphertext, $iv), $tripled, 'AES decrypts correctly';

{
	my $wrapped = $session->wrap_key('aes-key-wrap', $aes_key, $private_key);
	ok $wrapped;

	my $unwrapped = $session->unwrap_key('aes-key-wrap', $aes_key, $wrapped, { class => 'private-key', key_type => 'rsa', %private_key_template });
	ok $unwrapped;
}

$public_key->destroy_object;
$private_key->destroy_object;

done_testing;
