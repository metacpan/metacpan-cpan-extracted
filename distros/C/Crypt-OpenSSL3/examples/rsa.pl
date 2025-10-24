use 5.036;

use Crypt::OpenSSL3;
use Data::Dumper;

my $ctx = Crypt::OpenSSL3::PKey::Context->new_from_name("RSA") or die;
$ctx->keygen_init or die;
$ctx->set_params({ bits => 2048, primes => 2, e => 65537 }) or die;

my $pkey = $ctx->generate or die;

say $pkey;

my $ctx2 = Crypt::OpenSSL3::PKey::Context->new_from_pkey($pkey);
$ctx2->encapsulate_init or die;
my ($wrapped, $gen) = $ctx2->encapsulate or die;

say unpack "H*", $wrapped;
say unpack "H*", $gen;

my $ctx3 = Crypt::OpenSSL3::PKey::Context->new_from_pkey($pkey);
$ctx3->decapsulate_init or die;
my $unwrapped = $ctx3->decapsulate($wrapped) or die;

say unpack "H*", $unwrapped;

say $pkey->get_param('max-size');
