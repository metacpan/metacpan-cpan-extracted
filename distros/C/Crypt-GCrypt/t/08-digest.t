# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 08-digest.t'

#########################

use strict;
use warnings;
use Test;
use ExtUtils::testlib;
use Crypt::GCrypt;

#########################

# generated this list with the following shell snippet:

# for str in '' a 38 abc "message digest" abcdefghijklmnopqrstuvwxyz ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789 12345678901234567890123456789012345678901234567890123456789012345678901234567890 ; do printf "  '%s' => {\n" "$str"; for digest in md4 md5 ripemd160 sha1 sha224 sha256 sha384 sha512; do printf "    %s => '%s', \n" "$digest" $(printf "%s" "$str" | openssl dgst -"$digest") ; done ; printf "    whirlpool => '%s',\n" $(printf "%s" "$str" | whirlpool) ; printf "  },\n" ; done

# tiger192 digests are not currently tested as it is unclear if gcrypt
# implements tiger properly.  For more details, read:
# http://lists.gnupg.org/pipermail/gcrypt-devel/2009-November/001512.html

my %dgsts = (
  '' => {
    md4 => '31d6cfe0d16ae931b73c59d7e0c089c0',
    md5 => 'd41d8cd98f00b204e9800998ecf8427e',
    ripemd160 => '9c1185a5c5e9fc54612808977ee8f548b2258d31',
    sha1 => 'da39a3ee5e6b4b0d3255bfef95601890afd80709',
    sha224 => 'd14a028c2a3a2bc9476102bb288234c415a2b01f828ea62ac5b3e42f',
    sha256 => 'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',
    sha384 => '38b060a751ac96384cd9327eb1b1e36a21fdb71114be07434c0cc7bf63f6e1da274edebfe76f65fbd51ad2f14898b95b',
    sha512 => 'cf83e1357eefb8bdf1542850d66d8007d620e4050b5715dc83f4a921d36ce9ce47d0d13c5d85f2b0ff8318d2877eec2f63b931bd47417a81a538327af927da3e',
#    tiger192 => '3293ac630c13f0245f92bbb1766e16167a4e58492dde73f3',
    whirlpool => '19fa61d75522a4669b44e39c1d2e1726c530232130d407f89afee0964997f7a73e83be698b288febcf88e3e03c4f0757ea8964e59b63d93708b138cc42a66eb3',
  },
  'a' => {
    md4 => 'bde52cb31de33e46245e05fbdbd6fb24',
    md5 => '0cc175b9c0f1b6a831c399e269772661',
    ripemd160 => '0bdc9d2d256b3ee9daae347be6f4dc835a467ffe',
    sha1 => '86f7e437faa5a7fce15d1ddcb9eaeaea377667b8',
    sha224 => 'abd37534c7d9a2efb9465de931cd7055ffdb8879563ae98078d6d6d5',
    sha256 => 'ca978112ca1bbdcafac231b39a23dc4da786eff8147c4e72b9807785afee48bb',
    sha384 => '54a59b9f22b0b80880d8427e548b7c23abd873486e1f035dce9cd697e85175033caa88e6d57bc35efae0b5afd3145f31',
    sha512 => '1f40fc92da241694750979ee6cf582f2d5d7d28e18335de05abc54d0560e0f5302860c652bf08d560252aa5e74210546f369fbbbce8c12cfc7957b2652fe9a75',
#    tiger192 => '77befbef2e7ef8ab2ec8f93bf587a7fc613e247f5f247809',
    whirlpool => '8aca2602792aec6f11a67206531fb7d7f0dff59413145e6973c45001d0087b42d11bc645413aeff63a42391a39145a591a92200d560195e53b478584fdae231a',
  },
  '38' => {
    md4 => 'ae9c7ebfb68ea795483d270f5934b71d',
    md5 => 'a5771bce93e200c36f7cd9dfd0e5deaa',
    ripemd160 => '6b2d075b1cd34cd1c3e43a995f110c55649dad0e',
    sha1 => '5b384ce32d8cdef02bc3a139d4cac0a22bb029e8',
    sha224 => '4cfca6da32da647198225460722b7ea1284f98c4b179e8dbae3f93d5',
    sha256 => 'aea92132c4cbeb263e6ac2bf6c183b5d81737f179f21efdc5863739672f0f470',
    sha384 => 'c071d202ad950b6a04a5f15c24596a993af8b212467958d570a3ffd4780060638e3a3d06637691d3012bd31122071b2c',
    sha512 => 'caae34a5e81031268bcdaf6f1d8c04d37b7f2c349afb705b575966f63e2ebf0fd910c3b05160ba087ab7af35d40b7c719c53cd8b947c96111f64105fd45cc1b2',
#    tiger192 => 'a8e518a0c62a98f9ac4aa426c3534494fa67a0728b9304d3',
    whirlpool => 'b89f9f0485e8a03e6c8aaa97b29c41479351e4906bdcdef05f0568d3eeed180962bf983c8be65153da0df05b10fa4156d8d8af309245a252a3cb5467faee09d1',
  },
  'abc' => {
    md4 => 'a448017aaf21d8525fc10ae87aa6729d',
    md5 => '900150983cd24fb0d6963f7d28e17f72',
    ripemd160 => '8eb208f7e05d987a9b044a8e98c6b087f15a0bfc',
    sha1 => 'a9993e364706816aba3e25717850c26c9cd0d89d',
    sha224 => '23097d223405d8228642a477bda255b32aadbce4bda0b3f7e36c9da7',
    sha256 => 'ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad',
    sha384 => 'cb00753f45a35e8bb5a03d699ac65007272c32ab0eded1631a8b605a43ff5bed8086072ba1e7cc2358baeca134c825a7',
    sha512 => 'ddaf35a193617abacc417349ae20413112e6fa4e89a97ea20a9eeee64b55d39a2192992a274fc1a836ba3c23a3feebbd454d4423643ce80e2a9ac94fa54ca49f',
#    tiger192 => '2aab1484e8c158f2bfb8c5ff41b57a525129131c957b5f93',
    whirlpool => '4e2448a4c6f486bb16b6562c73b4020bf3043e3a731bce721ae1b303d97e6d4c7181eebdb6c57e277d0e34957114cbd6c797fc9d95d8b582d225292076d4eef5',
  },
  'message digest' => {
    md4 => 'd9130a8164549fe818874806e1c7014b',
    md5 => 'f96b697d7cb7938d525a2f31aaf161d0',
    ripemd160 => '5d0689ef49d2fae572b881b123a85ffa21595f36',
    sha1 => 'c12252ceda8be8994d5fa0290a47231c1d16aae3',
    sha224 => '2cb21c83ae2f004de7e81c3c7019cbcb65b71ab656b22d6d0c39b8eb',
    sha256 => 'f7846f55cf23e14eebeab5b4e1550cad5b509e3348fbc4efa3a1413d393cb650',
    sha384 => '473ed35167ec1f5d8e550368a3db39be54639f828868e9454c239fc8b52e3c61dbd0d8b4de1390c256dcbb5d5fd99cd5',
    sha512 => '107dbf389d9e9f71a3a95f6c055b9251bc5268c2be16d6c13492ea45b0199f3309e16455ab1e96118e8a905d5597b72038ddb372a89826046de66687bb420e7c',
#    tiger192 => 'd981f8cb78201a950dcf3048751e441c517fca1aa55a29f6',
    whirlpool => '378c84a4126e2dc6e56dcc7458377aac838d00032230f53ce1f5700c0ffb4d3b8421557659ef55c106b4b52ac5a4aaa692ed920052838f3362e86dbd37a8903e',
  },
  'abcdefghijklmnopqrstuvwxyz' => {
    md4 => 'd79e1c308aa5bbcdeea8ed63df412da9',
    md5 => 'c3fcd3d76192e4007dfb496cca67e13b',
    ripemd160 => 'f71c27109c692c1b56bbdceb5b9d2865b3708dbc',
    sha1 => '32d10c7b8cf96570ca04ce37f2a19d84240d3a89',
    sha224 => '45a5f72c39c5cff2522eb3429799e49e5f44b356ef926bcf390dccc2',
    sha256 => '71c480df93d6ae2f1efad1447c66c9525e316218cf51fc8d9ed832f2daf18b73',
    sha384 => 'feb67349df3db6f5924815d6c3dc133f091809213731fe5c7b5f4999e463479ff2877f5f2936fa63bb43784b12f3ebb4',
    sha512 => '4dbff86cc2ca1bae1e16468a05cb9881c97f1753bce3619034898faa1aabe429955a1bf8ec483d7421fe3c1646613a59ed5441fb0f321389f77f48a879c7b1f1',
#    tiger192 => '1714a472eee57d30040412bfcc55032a0b11602ff37beee9',
    whirlpool => 'f1d754662636ffe92c82ebb9212a484a8d38631ead4238f5442ee13b8054e41b08bf2a9251c30b6a0b8aae86177ab4a6f68f673e7207865d5d9819a3dba4eb3b',
  },
  'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789' => {
    md4 => '043f8582f241db351ce627e153e7f0e4',
    md5 => 'd174ab98d277d9f5a5611c2c9f419d9f',
    ripemd160 => 'b0e20b6e3116640286ed3a87a5713079b21f5189',
    sha1 => '761c457bf73b14d27e9e9265c46f4b4dda11f940',
    sha224 => 'bff72b4fcb7d75e5632900ac5f90d219e05e97a7bde72e740db393d9',
    sha256 => 'db4bfcbd4da0cd85a60c3c37d3fbd8805c77f15fc6b1fdfe614ee0a7c8fdb4c0',
    sha384 => '1761336e3f7cbfe51deb137f026f89e01a448e3b1fafa64039c1464ee8732f11a5341a6f41e0c202294736ed64db1a84',
    sha512 => '1e07be23c26a86ea37ea810c8ec7809352515a970e9253c26f536cfc7a9996c45c8370583e0a78fa4a90041d71a4ceab7423f19c71b9d5a3e01249f0bebd5894',
#    tiger192 => '8dcea680a17583ee502ba38a3c368651890ffbccdc49a8cc',
    whirlpool => 'dc37e008cf9ee69bf11f00ed9aba26901dd7c28cdec066cc6af42e40f82f3a1e08eba26629129d8fb7cb57211b9281a65517cc879d7b962142c65f5a7af01467',
  },
  '12345678901234567890123456789012345678901234567890123456789012345678901234567890' => {
    md4 => 'e33b4ddc9c38f2199c3e7b164fcc0536',
    md5 => '57edf4a22be3c955ac49da2e2107b67a',
    ripemd160 => '9b752e45573d4b39f4dbd3323cab82bf63326bfb',
    sha1 => '50abf5706a150990a08b2c5ea40fa0e585554732',
    sha224 => 'b50aecbe4e9bb0b57bc5f3ae760a8e01db24f203fb3cdcd13148046e',
    sha256 => 'f371bc4a311f2b009eef952dd83ca80e2b60026c8e935592d0f9c308453c813e',
    sha384 => 'b12932b0627d1c060942f5447764155655bd4da0c9afa6dd9b9ef53129af1b8fb0195996d2de9ca0df9d821ffee67026',
    sha512 => '72ec1ef1124a45b047e8b7c75a932195135bb61de24ec0d1914042246e0aec3a2354e093d76f3048b456764346900cb130d2a4fd5dd16abb5e30bcb850dee843',
#    tiger192 => '1c14795529fd9f207a958f84c52f11e887fa0cabdfd91bfd',
    whirlpool => '466ef18babb0154d25b9d38a6414f5c08784372bccb204d6549c4afadb6014294d5bd8df2a6c44e538cd047b2681a51a2c60481e88c5a20b2c2a80cf3a9a083b',
    nosuchdigest => 'no such digest', # testing digest_algo_available()
  },
);

# generated HMAC test vectors against openssl with:

# for str in '' a 38 abc "message digest" abcdefghijklmnopqrstuvwxyz ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789 12345678901234567890123456789012345678901234567890123456789012345678901234567890 ; do printf "  '%s' => {\n" "$str"; for digest in md4 md5 ripemd160 sha1 sha224 sha256 sha384 sha512; do printf "    %s => '%s',\n" "$digest" $(printf "%s" "$str" | openssl dgst -"$digest" -hmac "monkey monkey monkey monkey") ; done ; printf "  },\n" ; done

# (i don't have HMAC test vectors for tiger or whirlpool)

my %hmacs = (
  '' => {
    md4 => 'e5183d531f4d6db5ff14e9121c6fccd5',
    md5 => 'e84db42a188813f30a15e611d64c7869',
    ripemd160 => '8ba1e37d3c7b96281469d9e03aa83add3d0b15ef',
    sha1 => 'e6e99434623d60a28c9f6061993af2c4da8a51c5',
    sha224 => 'd12a49ae38177ffeaa548b2148bb523860849772d9391e675b103d89',
    sha256 => '5c780648c90d121c50091c3a0c3afc1f4ab847528005d99d9821ad3f341b651a',
    sha384 => '2c87a2f446b3bab07c595054490f618d33a3bade1f889b4b3502091d76bf93389cd8b77c9162d8717e420c3257ae7b2e',
    sha512 => '34316413c2d6940572d0bbbf099d529d148b424533cf562bc1b365f530e21a31799fc51cef78060cc6f448a8e5d780c26cdf20d4c3e6f27fe5ef576bbd05e855',
  },
  'a' => {
    md4 => 'bda51a1eca0bc702c2cbc44567815520',
    md5 => '123662062e67c2aab371cc49db0df134',
    ripemd160 => '82ad9b8e37b22fe42e730eea14dd07dfc6426dfd',
    sha1 => 'ff563a68ac9d592e5b1c3f266a8decc932af96f2',
    sha224 => 'b04ff8522f904f553970bfa8ad3f0086bce1e8580affd8a12c94e31a',
    sha256 => '6142364c0646b0cfe426866f21d613e055a136a7d9b45d85685e080a09cec463',
    sha384 => '69b97247988d6149bdd74ad4ba6fbae04bf1bbea69e08468e9617a293d69e0a984a0192e84b6c51fadbf43491203af2b',
    sha512 => 'cf1948507378bc3ab58cb6ec87f4d456b90d3298395c29873f1ded1e111b50fec336ed24684bf19716efc309212f37aa715cfb9ecccf3af13691ded167b4b336',
  },
  '38' => {
    md4 => '0ca7953fffdb3d2015fa01e50376ae5c',
    md5 => '0a46cc10a49d4b7025c040c597bf5d76',
    ripemd160 => '72bff3575250411bfba81441664ce249c734142d',
    sha1 => 'bdb97422a2c70e8c7d27976b1415e7e132b3e5f7',
    sha224 => 'afcfb5511f710334f9350f57faec3c08764b4bd126a6840f4347f116',
    sha256 => 'e49aa7839977e130ad87b63da9d4eb7b263cd5a27c54a7604b6044eb35901171',
    sha384 => '321b3a353a11effc1557728022644ed9216f7d9eef4fdaec205d1faf6e7395b805020dd31d9f8550635b5a4414ba1aff',
    sha512 => 'b8201784216ce01b83cdd282616c6e89644c6dfd1269ed8580bbc39b92add364c2b2a2018cffb1915e8625e473b67d0fe54a50e475dfa0e2b1a97bac1383792c',
  },
  'abc' => {
    md4 => '34d8e18874f96e8ed74e3d9d333e2bc6',
    md5 => 'd1f4d89f0e8b2b6ed0623c99ec298310',
    ripemd160 => '7f3a47544440050bd0f81c8d40d503c5aa1b3aeb',
    sha1 => '9b07e65129605e7577fc1953fc9415fb97da2efb',
    sha224 => '9df9907af127900c909376893565c6cf2d7db244fdc4277da1e0b679',
    sha256 => 'e5ef49f545c7af933a9d18c7c562bc9108583fd5cf00d9e0db351d6d8f8e41bc',
    sha384 => '5451e87820025c58f06512db53b576484d5b0a0a311d496f7499f311f4729e76e49b799102cf5fbe9d8b105eea14b048',
    sha512 => 'f097ee08b8c44e847a384f9fd645e35e4816baa9791ba39d3dc611210500b044873ee296bf1047dc06daa201a57671925b73b4ea59c60114881c8287d0699c83',
  },
  'message digest' => {
    md4 => '008791fd0be992b8005c3984e3db57a1',
    md5 => '1627207b9bed5009a4f6e9ca8d2ca01e',
    ripemd160 => '883403138f019b85629b3bedefd06c1774ab452a',
    sha1 => '8f76dfeeec9d71e6217f4fae1f15601859583904',
    sha224 => '254ebf6b8ddd7a3271b3d9aca1699b0c0bfb7df61e8a114922c88d27',
    sha256 => '373b04877180fea27a41a8fb8f88201ca6268411ee3c80b01a424483eb9156e1',
    sha384 => 'ae91a02c88918da8b3215a0ce419736b88744806f33476e8a8fce61fe43a8fad66a0b6dd1c0c21fb0f2c7c3a04b8267b',
    sha512 => '921a441a884b83c76a8526da8e60d60d17ded4eee5c29375e0d93717669a4c3eeba7473e95f7c1a2a85afc24a0adbc4d6c2bdd6ca6cab8b18d19f82d4a6c51bc',
  },
  'abcdefghijklmnopqrstuvwxyz' => {
    md4 => '246dedc8c42870e0fbe230d0bad32420',
    md5 => '922aae6ab3b3a29202e21ce5f916ae9a',
    ripemd160 => 'b639506a560f73cd0f61df738596af65d557946d',
    sha1 => '7c0c34c8be298c229d8cf9c610e8d6ba7947eb03',
    sha224 => '6ec5bffba5880c3234a6cf257816e4d535ab178a7f12929769e378fb',
    sha256 => 'eb5945d56eefbdb41602946ea6448d5386b08d7d801a87f439fab52f8bb9736e',
    sha384 => 'f7398e453013e5af5c40e07cb4a8109b83b60395499b6ca67e4301df0fafff26c39140a8199167d172b131ab1b7ab999',
    sha512 => '640054c96f35815095617d0a8c9560661a6ff46bfb39110333b2c52c8866abfb59d9152c9b0948c1ed65c3fd72a8fb82190acc8830770afe5b0c5b6414c75a77',
  },
  'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789' => {
    md4 => 'dc5f6b13f54f31e7a8276d4540ec6e99',
    md5 => 'ede9cb83679ba82d88fbeae865b3f8fc',
    ripemd160 => '94964ed4c1155b62b668c241d67279e58a711676',
    sha1 => 'c7b5a631e3aac975c4ededfcd346e469dbc5f2d1',
    sha224 => '5f768179dbb29ca722875d0f461a2e2f597d0210340a84df1a8e9c63',
    sha256 => '3798f363c57afa6edaffe39016ca7badefd1e670afb0e3987194307dec3197db',
    sha384 => 'd218680a6032d33dccd9882d6a6a716464f26623be257a9b2919b185294f4a499e54b190bfd6bc5cedd2cd05c7e65e82',
    sha512 => '835a4f5b3750b4c1fccfa88da2f746a4900160c9f18964309bb736c13b59491b8e32d37b724cc5aebb0f554c6338a3b594c4ba26862b2dadb59b7ede1d08d53e',
  },
  '12345678901234567890123456789012345678901234567890123456789012345678901234567890' => {
    md4 => 'aa8a5a5bbe444c106e46b6314409e231',
    md5 => '939dd45512ee3a594b6654f6b8de27f7',
    ripemd160 => '619dddf49f3584da4f7d17da8bb606dc8d69f3e1',
    sha1 => '095f08d37e4b726e049e989f1f29e0fa2407b18e',
    sha224 => 'c7667b0d7e56b2b4f6fcc1d8da9e22daa1556f44c47132a87303c6a2',
    sha256 => 'c89a7039a62985ff813fe4509b918a436d7b1ffd8778e2c24dec464849fb6128',
    sha384 => '5197498af7797baf158c2cfe0dcfc7fea5a5065cfb4009524b55293c56758f8810da4750c21d0a2a3986d09030751f83',
    sha512 => 'fdf83dc879e3476c8e8aceff2bf6fece2e4f39c7e1a167845465bb549dfa5ffe997e6c7cf3720eae51ed2b00ad2a8225375092290edfa9d48ec7e4bc8e276088',
    nosuchdigest => 'no such digest', # testing digest_algo_available()
  },
);

plan tests => scalar grep Crypt::GCrypt::digest_algo_available($_), map keys %$_, values %dgsts, values %hmacs;

my $data;
my $algo;

for $data (sort keys %dgsts) {
  for $algo (sort keys %{$dgsts{$data}}) {
    next unless Crypt::GCrypt::digest_algo_available($algo);
    my $md = Crypt::GCrypt->new(
                                type => 'digest',
                                algorithm => $algo,
                               );
    die "failed to create digest object with algorithm $algo" unless defined $md;
    $md->write($data);
    my $result = unpack('H*', $md->read());
    warn sprintf("(%s) '%s': %s != %s\n", $algo, $data, $result, $dgsts{$data}{$algo}) unless ($result eq $dgsts{$data}{$algo});
    ok($result eq $dgsts{$data}{$algo});
  }
}

for $data (sort keys %hmacs) {
  for $algo (sort keys %{$hmacs{$data}}) {
    next unless Crypt::GCrypt::digest_algo_available($algo);
    my $md = Crypt::GCrypt->new(
                                type => 'digest',
                                algorithm => $algo,
                                hmac => 'monkey monkey monkey monkey',
                               );
    die "failed to create HMAC digest object with algorithm $algo" unless defined $md;
    $md->write($data);
    my $result = unpack('H*', $md->read());
    warn sprintf("HMAC (%s) '%s': %s != %s\n", $algo, $data, $result, $hmacs{$data}{$algo}) unless ($result eq $hmacs{$data}{$algo});
    ok($result eq $hmacs{$data}{$algo});
  }
}

