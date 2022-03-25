
use Test::More ;
use Crypt::OpenSSL::EVP::MD;

my $hash_name = 'SHA256';
my $md = Crypt::OpenSSL::EVP::MD->new( $hash_name );
my $block_size = $md->block_size();
my $size = $md->size();
is($block_size, 64, "$hash_name block size: $block_size");
is($size, 32, "$hash_name size: $size");

my $msg = 'abc';
my $dgst = $md->digest($msg);
my $dgst_hex = unpack("H*", $dgst);
is($dgst_hex, 'ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad', "msg: $msg, $hash_name digest: $dgst_hex");

done_testing;

1;
