use warnings;
use strict;

use Test::More;

use Crypt::Yescrypt qw/yescrypt yescrypt_check yescrypt_needs_rehash yescrypt_kdf/;
use MIME::Base64 'decode_base64';

sub de_base64($) {
	my($text) = @_;
	$text =~ tr#./A-Za-z0-9#A-Za-z0-9+/#;
	return decode_base64($text);
}

my $password = "Hello World,";
my $salt = "A" x 16;

my $hash1 = yescrypt($password, $salt, 0xb6, 12, 32);

ok($hash1);
ok(yescrypt_check($password, $hash1));
ok(yescrypt_check('PASSWORD', '$y$j9T$SALT$HIA0o5.HmkE9HhZ4H8X1r0aRYrqdcv0IJEZ2PLpqpz6'));

ok(!yescrypt_needs_rehash('$y$j9T$SALT$HIA0o5.HmkE9HhZ4H8X1r0aRYrqdcv0IJEZ2PLpqpz6', 0xb6, 12, 32));
ok(yescrypt_needs_rehash('$y$j9T$SALT$HIA0o5.HmkE9HhZ4H8X1r0aRYrqdcv0IJEZ2PLpqpz6', 0xb6, 12, 16));

ok(yescrypt_kdf($password, $salt, 16, 0xb6, 12, 32));

done_testing;
