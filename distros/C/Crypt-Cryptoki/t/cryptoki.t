use strict;
use warnings;

use Test::More;
use Try::Tiny;

use_ok 'Crypt::Cryptoki';
use_ok 'Crypt::Cryptoki::Template::RSAPublicKey';
use_ok 'Crypt::Cryptoki::Template::RSAPrivateKey';

my $c = Crypt::Cryptoki->new(module=>'/usr/lib64/softhsm/libsofthsm.so');

my $info = $c->info;
my @slots = $c->slots( token => 1 );

for ( @slots ) {
	diag explain $_->info;
	diag explain $_->token_info;
}

my $session = $slots[0]->open_session(
	serial => 1,
	rw => 1
);

diag $session->login_user('1234');

# or
# diag $session->login_so('1234');

my $t_public = Crypt::Cryptoki::Template::RSAPublicKey->new(
	token => 1,
	encrypt => 1,
	verify => 1,
	wrap => 1,
	modulus_bits => 4096,
	public_exponent => '0x010001',
	label => 'test',
	id => '0x123456',
);

my $t_private = Crypt::Cryptoki::Template::RSAPrivateKey->new(
	token => 1,
	decrypt => 1,
	sign => 1,
	unwrap => 1,
	label => 'test',
	id => pack('C*', 0x01, 0x02, 0x03)
);

my ( $public_key, $private_key ) = $session->generate_key_pair($t_public,$t_private);

try {
	my $plain_text = 'plain text';
	my ( $encrypted_text_ref, $len ) = $public_key->encrypt(\$plain_text, length($plain_text));

	( $encrypted_text_ref ) = $private_key->decrypt($encrypted_text_ref, $len);
	diag $$encrypted_text_ref;

	diag explain $public_key->get_attributes(1);
	diag $public_key->export_as_string;

	diag explain $private_key->get_attributes(1);

} catch { diag $_; 0 };

ok $public_key->destroy;
ok $private_key->destroy;

done_testing();

