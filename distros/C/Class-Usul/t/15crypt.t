use t::boilerplate;

use Test::More;

use_ok 'Class::Usul::Crypt', qw( cipher_list decrypt default_cipher encrypt );

my $plain_text            = 'Hello World';
my $args                  = { cipher => 'Twofish2', salt => 'salt' };
my $base64_encrypted_text = encrypt( $args, $plain_text );

is decrypt( $args, $base64_encrypted_text ), $plain_text, 'Default seed';

$base64_encrypted_text = encrypt( undef, $plain_text );

is decrypt( undef, $base64_encrypted_text), $plain_text, 'Default everything';

$base64_encrypted_text = encrypt( 'test', $plain_text );

is decrypt( 'test', $base64_encrypted_text), $plain_text, 'User password';

is_deeply [ cipher_list() ], [ qw(Blowfish Rijndael Twofish2) ], 'Cipher list';

is default_cipher(), 'Twofish2', 'Default cipher';

use_ok 'Class::Usul::Crypt::Util',
   qw( decrypt_from_config encrypt_for_config get_cipher is_encrypted );

is encrypt_for_config( {}, q() ), q(), 'Encrypts nothing to nothing';

my $encrypted = encrypt_for_config( {}, 'plain text' );

is is_encrypted( $encrypted ), 1, 'Is encrypted';
is is_encrypted( 'plain text' ), 0, 'Is not encrypted';
is get_cipher( $encrypted ), 'Twofish2' , 'Get cipher';

my $plain     = decrypt_from_config( {}, $encrypted );

is $plain, 'plain text', 'Encrypt / decrypt round trips';

done_testing;

# Local Variables:
# mode: perl
# tab-width: 3
# End:
