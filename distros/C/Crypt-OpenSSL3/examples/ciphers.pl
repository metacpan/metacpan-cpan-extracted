use 5.036;

use Crypt::OpenSSL3;
use Data::Dumper;

say $_->get_name for Crypt::OpenSSL3::Cipher->list_all_provided;

my $key = "0123456789ABCDEF";
my $iv = $key;

my $cipher = Crypt::OpenSSL3::Cipher->fetch("AES-128-CTR");

say "Block size is ", $cipher->get_param('blocksize');

my $context = Crypt::OpenSSL3::Cipher::Context->new;
$context->init($cipher, $key, $iv, 1, { padding => 0 }) or die;

my $plain = "Hello, World!";

my $enc1 = $context->update($plain) // die;
my $enc2 = $context->final // die;
my $ciphertext = $enc1 . $enc2;
say length $ciphertext;

say "IV is ", $context->get_param('iv');

my $context2 = Crypt::OpenSSL3::Cipher::Context->new;
$context2->init($cipher, $key, $iv, 0) or die;

my $dec1 = $context2->update($ciphertext) // die;
my $dec2 = $context2->final // die;

my $decoded = $dec1 . $dec2;

say $decoded;

say "Padding was ", $context->get_param('padding');
$context->set_params({ padding => 1 });
say "Padding is now ", $context->get_param('padding');
