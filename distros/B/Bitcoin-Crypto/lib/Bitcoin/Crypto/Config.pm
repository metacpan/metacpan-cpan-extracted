package Bitcoin::Crypto::Config;

our $VERSION = "0.996";

use v5.10;
use warnings;
use Exporter qw(import);

our @EXPORT = qw(
	%config
);

# DO NOT change these values unless you want to experiment with algorithms
our %config = (
	curve_name => "secp256k1",
	max_child_keys => 2 << 30,
	key_max_length => 32,
	wif_compressed_byte => "\x01",
	compress_public_point => 1,
	witness_version => 0,
	max_witness_version => 16,
);

1;
