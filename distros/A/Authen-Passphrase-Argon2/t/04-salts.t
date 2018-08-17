use Test::More;
use Authen::Passphrase::Argon2;

my $error = qr/ß is not a valid raw salt/;
is(build('salt', 'abcdef'), 'abcdef', 'set salt');

eval { build('salt', 'ß') };
like($@, $error, 'k is not a valid raw salt');
BEGIN { 
	*Data::GUID::as_string = sub { return 'abcdef' };
}
is(build('salt', 'random'), 'abcdef', 'set random salt');

# these other salt methods are fairly redundent and are only for people who want to add a dummy 
# step so that they do not store the salt in readable text.
is(build('salt_hex', unpack 'H*', 'abcdef'), 'abcdef', 'set salt hex'); 
eval { build('salt_hex', unpack 'H*', 'ß') };
like($@, $error, 'ß is not a valid raw salt');

use MIME::Base64 qw/encode_base64/;
is(build('salt_base64', encode_base64 'abcdef'), 'abcdef', 'set salt hex'); 
eval { build('salt_base64', encode_base64 'ß') };
like($@, $error, 'ß is not a valid raw salt');

eval {
	Authen::Passphrase::Argon2->new( salt => 'abcdef', salt_random => 1 );
};
like($@, qr/salt specified redundantly/);

my $pp = Authen::Passphrase::Argon2->new( salt => 'abcdef' );

sub build {
	my $method = shift;
	my $ppr = Authen::Passphrase::Argon2->new();
	$ppr->$method(shift);
	$ppr->$method();
	$ppr->salt;
}

done_testing();
