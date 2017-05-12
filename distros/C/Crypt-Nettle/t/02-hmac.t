# -*- cperl -*-
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 02-hmac.t'

#########################

use strict;
use warnings;
use Test;
use ExtUtils::testlib;
use Crypt::Nettle::Hash;


my $algo;
my $data;

# generated HMAC test vectors against openssl with:

# for str in '' a 38 abc "message digest" abcdefghijklmnopqrstuvwxyz ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789 12345678901234567890123456789012345678901234567890123456789012345678901234567890 ; do printf "  '%s' => {\n" "$str"; for digest in md4 md5 ripemd160 sha1 sha224 sha256 sha384 sha512; do printf "    %s => '%s',\n" "$digest" $(printf "%s" "$str" | openssl dgst -"$digest" -hmac "monkey monkey monkey monkey") ; done ; printf "  },\n" ; done

# (i don't have HMAC test vectors for tiger or whirlpool)

my %hmacs = (
  '' => {
    md4 => 'e5183d531f4d6db5ff14e9121c6fccd5',
    md5 => 'e84db42a188813f30a15e611d64c7869',
    #ripemd160 => '8ba1e37d3c7b96281469d9e03aa83add3d0b15ef',
    sha1 => 'e6e99434623d60a28c9f6061993af2c4da8a51c5',
    sha224 => 'd12a49ae38177ffeaa548b2148bb523860849772d9391e675b103d89',
    sha256 => '5c780648c90d121c50091c3a0c3afc1f4ab847528005d99d9821ad3f341b651a',
    sha384 => '2c87a2f446b3bab07c595054490f618d33a3bade1f889b4b3502091d76bf93389cd8b77c9162d8717e420c3257ae7b2e',
    sha512 => '34316413c2d6940572d0bbbf099d529d148b424533cf562bc1b365f530e21a31799fc51cef78060cc6f448a8e5d780c26cdf20d4c3e6f27fe5ef576bbd05e855',
  },
  'a' => {
    md4 => 'bda51a1eca0bc702c2cbc44567815520',
    md5 => '123662062e67c2aab371cc49db0df134',
    #ripemd160 => '82ad9b8e37b22fe42e730eea14dd07dfc6426dfd',
    sha1 => 'ff563a68ac9d592e5b1c3f266a8decc932af96f2',
    sha224 => 'b04ff8522f904f553970bfa8ad3f0086bce1e8580affd8a12c94e31a',
    sha256 => '6142364c0646b0cfe426866f21d613e055a136a7d9b45d85685e080a09cec463',
    sha384 => '69b97247988d6149bdd74ad4ba6fbae04bf1bbea69e08468e9617a293d69e0a984a0192e84b6c51fadbf43491203af2b',
    sha512 => 'cf1948507378bc3ab58cb6ec87f4d456b90d3298395c29873f1ded1e111b50fec336ed24684bf19716efc309212f37aa715cfb9ecccf3af13691ded167b4b336',
  },
  '38' => {
    md4 => '0ca7953fffdb3d2015fa01e50376ae5c',
    md5 => '0a46cc10a49d4b7025c040c597bf5d76',
    #ripemd160 => '72bff3575250411bfba81441664ce249c734142d',
    sha1 => 'bdb97422a2c70e8c7d27976b1415e7e132b3e5f7',
    sha224 => 'afcfb5511f710334f9350f57faec3c08764b4bd126a6840f4347f116',
    sha256 => 'e49aa7839977e130ad87b63da9d4eb7b263cd5a27c54a7604b6044eb35901171',
    sha384 => '321b3a353a11effc1557728022644ed9216f7d9eef4fdaec205d1faf6e7395b805020dd31d9f8550635b5a4414ba1aff',
    sha512 => 'b8201784216ce01b83cdd282616c6e89644c6dfd1269ed8580bbc39b92add364c2b2a2018cffb1915e8625e473b67d0fe54a50e475dfa0e2b1a97bac1383792c',
  },
  'abc' => {
    md4 => '34d8e18874f96e8ed74e3d9d333e2bc6',
    md5 => 'd1f4d89f0e8b2b6ed0623c99ec298310',
    #ripemd160 => '7f3a47544440050bd0f81c8d40d503c5aa1b3aeb',
    sha1 => '9b07e65129605e7577fc1953fc9415fb97da2efb',
    sha224 => '9df9907af127900c909376893565c6cf2d7db244fdc4277da1e0b679',
    sha256 => 'e5ef49f545c7af933a9d18c7c562bc9108583fd5cf00d9e0db351d6d8f8e41bc',
    sha384 => '5451e87820025c58f06512db53b576484d5b0a0a311d496f7499f311f4729e76e49b799102cf5fbe9d8b105eea14b048',
    sha512 => 'f097ee08b8c44e847a384f9fd645e35e4816baa9791ba39d3dc611210500b044873ee296bf1047dc06daa201a57671925b73b4ea59c60114881c8287d0699c83',
  },
  'message digest' => {
    md4 => '008791fd0be992b8005c3984e3db57a1',
    md5 => '1627207b9bed5009a4f6e9ca8d2ca01e',
    #ripemd160 => '883403138f019b85629b3bedefd06c1774ab452a',
    sha1 => '8f76dfeeec9d71e6217f4fae1f15601859583904',
    sha224 => '254ebf6b8ddd7a3271b3d9aca1699b0c0bfb7df61e8a114922c88d27',
    sha256 => '373b04877180fea27a41a8fb8f88201ca6268411ee3c80b01a424483eb9156e1',
    sha384 => 'ae91a02c88918da8b3215a0ce419736b88744806f33476e8a8fce61fe43a8fad66a0b6dd1c0c21fb0f2c7c3a04b8267b',
    sha512 => '921a441a884b83c76a8526da8e60d60d17ded4eee5c29375e0d93717669a4c3eeba7473e95f7c1a2a85afc24a0adbc4d6c2bdd6ca6cab8b18d19f82d4a6c51bc',
  },
  'abcdefghijklmnopqrstuvwxyz' => {
    md4 => '246dedc8c42870e0fbe230d0bad32420',
    md5 => '922aae6ab3b3a29202e21ce5f916ae9a',
    #ripemd160 => 'b639506a560f73cd0f61df738596af65d557946d',
    sha1 => '7c0c34c8be298c229d8cf9c610e8d6ba7947eb03',
    sha224 => '6ec5bffba5880c3234a6cf257816e4d535ab178a7f12929769e378fb',
    sha256 => 'eb5945d56eefbdb41602946ea6448d5386b08d7d801a87f439fab52f8bb9736e',
    sha384 => 'f7398e453013e5af5c40e07cb4a8109b83b60395499b6ca67e4301df0fafff26c39140a8199167d172b131ab1b7ab999',
    sha512 => '640054c96f35815095617d0a8c9560661a6ff46bfb39110333b2c52c8866abfb59d9152c9b0948c1ed65c3fd72a8fb82190acc8830770afe5b0c5b6414c75a77',
  },
  'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789' => {
    md4 => 'dc5f6b13f54f31e7a8276d4540ec6e99',
    md5 => 'ede9cb83679ba82d88fbeae865b3f8fc',
    #ripemd160 => '94964ed4c1155b62b668c241d67279e58a711676',
    sha1 => 'c7b5a631e3aac975c4ededfcd346e469dbc5f2d1',
    sha224 => '5f768179dbb29ca722875d0f461a2e2f597d0210340a84df1a8e9c63',
    sha256 => '3798f363c57afa6edaffe39016ca7badefd1e670afb0e3987194307dec3197db',
    sha384 => 'd218680a6032d33dccd9882d6a6a716464f26623be257a9b2919b185294f4a499e54b190bfd6bc5cedd2cd05c7e65e82',
    sha512 => '835a4f5b3750b4c1fccfa88da2f746a4900160c9f18964309bb736c13b59491b8e32d37b724cc5aebb0f554c6338a3b594c4ba26862b2dadb59b7ede1d08d53e',
  },
  '12345678901234567890123456789012345678901234567890123456789012345678901234567890' => {
    md4 => 'aa8a5a5bbe444c106e46b6314409e231',
    md5 => '939dd45512ee3a594b6654f6b8de27f7',
    #ripemd160 => '619dddf49f3584da4f7d17da8bb606dc8d69f3e1',
    sha1 => '095f08d37e4b726e049e989f1f29e0fa2407b18e',
    sha224 => 'c7667b0d7e56b2b4f6fcc1d8da9e22daa1556f44c47132a87303c6a2',
    sha256 => 'c89a7039a62985ff813fe4509b918a436d7b1ffd8778e2c24dec464849fb6128',
    sha384 => '5197498af7797baf158c2cfe0dcfc7fea5a5065cfb4009524b55293c56758f8810da4750c21d0a2a3986d09030751f83',
    sha512 => 'fdf83dc879e3476c8e8aceff2bf6fece2e4f39c7e1a167845465bb549dfa5ffe997e6c7cf3720eae51ed2b00ad2a8225375092290edfa9d48ec7e4bc8e276088',
  },
);

plan tests => (2*scalar(map({ keys(%$_) } values(%hmacs))));

my $key = 'monkey monkey monkey monkey';

for $data (sort keys %hmacs) {
  for $algo (sort keys %{$hmacs{$data}}) {
    my $hmac = Crypt::Nettle::Hash->new_hmac($algo, $key);
    die "failed to create HMAC digest object with algorithm $algo" unless defined $hmac;
    $hmac->update($data);
    my $result = unpack('H*', $hmac->digest());
    warn sprintf("HMAC (%s) '%s': %s != %s\n", $algo, $data, $result, $hmacs{$data}{$algo}) unless ($result eq $hmacs{$data}{$algo});
    ok($result eq $hmacs{$data}{$algo});
    ok(pack('H*', $hmacs{$data}{$algo}) eq Crypt::Nettle::Hash::hmac_data($algo, $data, $key));
  }
}

