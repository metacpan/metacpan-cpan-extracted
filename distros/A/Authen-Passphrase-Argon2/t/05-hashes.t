use Test::More;
use Authen::Passphrase::Argon2;

my $error = qr/not a valid raw hash/;
is(build('hash', '$argon2id$v=19$m=32768,t=3,p=1$YWJjZGVmZzEyMw$FmPc1Fhq0MKi1wcuQ1v4ow'), '$argon2id$v=19$m=32768,t=3,p=1$YWJjZGVmZzEyMw$FmPc1Fhq0MKi1wcuQ1v4ow', 'set hash');

eval { build('hash', 'a$argon2id$v=19$m=32768,t=3,p=1$YWJjZGVmZzEyMw$FmPc1Fhq0MKi1wcuQ1v4ow') };
like($@, $error, 'not a valid raw hash');

# these other hash methods are fairly redundent and are only for people who want to add a dummy 
# step so that they do not store the hash in readable text.
is(build('hash_hex', unpack 'H*', '$argon2id$v=19$m=32768,t=3,p=1$YWJjZGVmZzEyMw$FmPc1Fhq0MKi1wcuQ1v4ow'), '$argon2id$v=19$m=32768,t=3,p=1$YWJjZGVmZzEyMw$FmPc1Fhq0MKi1wcuQ1v4ow', 'hash hex'); 
eval { build('hash_hex', unpack 'H*', 'ß$argon2id$v=19$m=32768,t=3,p=1$YWJjZGVmZzEyMw$FmPc1Fhq0MKi1wcuQ1v4ow') };
like($@, $error, 'not a valid hash hex');

use MIME::Base64 qw/encode_base64/;
is(build('hash_base64', encode_base64 '$argon2id$v=19$m=32768,t=3,p=1$YWJjZGVmZzEyMw$FmPc1Fhq0MKi1wcuQ1v4ow'), '$argon2id$v=19$m=32768,t=3,p=1$YWJjZGVmZzEyMw$FmPc1Fhq0MKi1wcuQ1v4ow', 'set hash hex'); 
eval { build('hash_base64', encode_base64 '£S$argon2id$v=19$m=32768,t=3,p=1$YWJjZGVmZzEyMw$FmPc1Fhq0MKi1wcuQ1v4ow') };
like($@, $error, 'is not a valid hash base64');

eval {
	Authen::Passphrase::Argon2->new( hash => '$argon2id$v=19$m=32768,t=3,p=1$YWJjZGVmZzEyMw$FmPc1Fhq0MKi1wcuQ1v4ow', hash_base64 => encode_base64 '$argon2id$v=19$m=32768,t=3,p=1$YWJjZGVmZzEyMw$FmPc1Fhq0MKi1wcuQ1v4ow' );
};
like($@, qr/hash specified redundantly/);



sub build {
	my $method = shift;
	my $ppr = Authen::Passphrase::Argon2->new();
	$ppr->$method(shift);
	$ppr->$method();
	$ppr->hash;
}

done_testing();
