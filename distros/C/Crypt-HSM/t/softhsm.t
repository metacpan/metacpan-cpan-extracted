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
	my $slotInfo = $provider->info;
	note explain $slotInfo;

	my $tokenInfo = $slot->token_info;
	note explain $tokenInfo;
}

my $session = $provider->open_session($slots[0]);

undef $provider;

my $sessionInfo = $session->info;
note explain $sessionInfo;

$session->login('user', $pin) if length $pin;

my %public_key_template = (
	class => 'public-key',
	'key-type' => 'rsa',
	token => 0,
	encrypt => 1,
	verify => 1,
	wrap => 1,
	'modulus-bits' => 2096,
	'public-exponent' => [ 1, 0, 1 ],
	label => 'test_pub',
	id => [ 1, 2, 3 ],
);

my %private_key_template = (
	class => 'private-key',
	'key-type' => 'rsa',
	token => 0,
	private => 1,
	sensitive => 1,
	decrypt => 1,
	sign => 1,
	unwrap => 1,
	label => 'test',
	id => [ 4, 5, 6 ],
);

my ($public_key, $private_key) = $session->generate_keypair('rsa-pkcs-key-pair-gen', \%public_key_template, \%private_key_template);

note $public_key;
note $private_key;

my $plain_text = 'plain text';
my $encrypted_text = $session->encrypt('rsa-pkcs', $public_key, $plain_text);
note unpack('H*', $encrypted_text);

my $decrypted_text = $session->decrypt('rsa-pkcs', $private_key, $encrypted_text);

is $decrypted_text, $plain_text, 'decrypt: "plain text"';

{
my $signature = $session->sign('sha256-rsa-pkcs', $private_key, $plain_text);
note unpack('H*', $signature);

ok $session->verify('sha256-rsa-pkcs', $public_key, $plain_text, $signature);
}

{
my $signature = $session->sign('sha256-rsa-pkcs-pss', $private_key, $plain_text);
note unpack('H*', $signature);

ok $session->verify('sha256-rsa-pkcs-pss', $public_key, $plain_text, $signature);
}

my $attributes = $session->get_attributes($public_key, [ 'modulus', 'public-exponent' ]);

note 'modulus: ', unpack('H*', $attributes->{modulus});
note 'exponent: ', unpack('H*', $attributes->{'public-exponent'});

$session->destroy_object($public_key);
$session->destroy_object($private_key);

my $aes_key = $session->generate_key('aes-key-gen', { 'value-len' => 32, token => 0 });

ok $aes_key;

my $iv = "\0" x 16;
my $encoder = $session->open_encrypt('aes-cbc-pad', $aes_key, $iv);

my $ciphertext = $encoder->add_data($plain_text x 3);
$ciphertext .= $encoder->finalize;

is $session->decrypt('aes-cbc-pad', $aes_key, $ciphertext, $iv), $plain_text x 3;

done_testing;
