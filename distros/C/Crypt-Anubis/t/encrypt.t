use diagnostics;
use strict;
use warnings;
use Test::More tests => 513;
BEGIN {
    use_ok('Crypt::Anubis')
};

BEGIN {
    my $key;
    my $cipher;
    my $plaintext;
    my $ciphertext;
    my $answer;

# Set 1, vector# 000:
    $key = pack "H32", "80000000000000000000000000000000";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "00000000000000000000000000000000";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("b835bdc334829d8371bfa371e4b3c4fd", $answer);

# Set 1, vector# 001:
    $key = pack "H32", "40000000000000000000000000000000";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "00000000000000000000000000000000";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("6eef5fdac4c6e9914828ae9446a460bb", $answer);

# Set 1, vector# 002:
    $key = pack "H32", "20000000000000000000000000000000";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "00000000000000000000000000000000";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("3ecacee372560b9810b5498d5e7791cc", $answer);

# Set 1, vector# 003:
    $key = pack "H32", "10000000000000000000000000000000";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "00000000000000000000000000000000";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("64f244781ee6ddd181bb5934a7a12f4e", $answer);

# Set 1, vector# 004:
    $key = pack "H32", "08000000000000000000000000000000";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "00000000000000000000000000000000";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("4f39939a9f45ef5f1f596e7baba1ec6f", $answer);

# Set 1, vector# 005:
    $key = pack "H32", "04000000000000000000000000000000";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "00000000000000000000000000000000";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("7aa0b4e4873fa354a898230cd6b8f81e", $answer);

# Set 1, vector# 006:
    $key = pack "H32", "02000000000000000000000000000000";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "00000000000000000000000000000000";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("fc4d1bdfe42e22d020b43f21786278a8", $answer);

# Set 1, vector# 007:
    $key = pack "H32", "01000000000000000000000000000000";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "00000000000000000000000000000000";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("4be751dd97f765822fd4e33d76536a65", $answer);

# Set 1, vector# 008:
    $key = pack "H32", "00800000000000000000000000000000";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "00000000000000000000000000000000";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("fc075b3a3a927faf56a96bdbbde7f8d1", $answer);

# Set 1, vector# 009:
    $key = pack "H32", "00400000000000000000000000000000";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "00000000000000000000000000000000";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("433b8e0d1231706621089c106fc32185", $answer);

# Set 1, vector# 010:
    $key = pack "H32", "00200000000000000000000000000000";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "00000000000000000000000000000000";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("499d11a062f28e3b582f946cc7a60df6", $answer);

# Set 1, vector# 011:
    $key = pack "H32", "00100000000000000000000000000000";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "00000000000000000000000000000000";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("ae99469b7d21fc326835f0e37a87db16", $answer);

# Set 1, vector# 012:
    $key = pack "H32", "00080000000000000000000000000000";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "00000000000000000000000000000000";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("c52d8f9cadfda493005f23399244bc2b", $answer);

# Set 1, vector# 013:
    $key = pack "H32", "00040000000000000000000000000000";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "00000000000000000000000000000000";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("43371b0c26756978ccca15dfab85bd6c", $answer);

# Set 1, vector# 014:
    $key = pack "H32", "00020000000000000000000000000000";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "00000000000000000000000000000000";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("85577edfd553da74cb503c63597951b7", $answer);

# Set 1, vector# 015:
    $key = pack "H32", "00010000000000000000000000000000";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "00000000000000000000000000000000";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("33fa55ccd3c7b4cae14428a752998bfa", $answer);

# Set 1, vector# 016:
    $key = pack "H32", "00008000000000000000000000000000";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "00000000000000000000000000000000";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("7d4ee5b48474dac2d410090c9bce6870", $answer);

# Set 1, vector# 017:
    $key = pack "H32", "00004000000000000000000000000000";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "00000000000000000000000000000000";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("3674ba444c0f3dfc902176eaa3b29d9e", $answer);

# Set 1, vector# 018:
    $key = pack "H32", "00002000000000000000000000000000";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "00000000000000000000000000000000";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("1c1edc0b8c82c17d1d57636338831a57", $answer);

# Set 1, vector# 019:
    $key = pack "H32", "00001000000000000000000000000000";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "00000000000000000000000000000000";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("0e2340d34e5a08ccd330c6b49c3ebaf5", $answer);

# Set 1, vector# 020:
    $key = pack "H32", "00000800000000000000000000000000";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "00000000000000000000000000000000";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("abc3335458ff9eadbe4c09a3ca7a57c0", $answer);

# Set 1, vector# 021:
    $key = pack "H32", "00000400000000000000000000000000";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "00000000000000000000000000000000";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("4092ed6f830316257971cc73ebeef26a", $answer);

# Set 1, vector# 022:
    $key = pack "H32", "00000200000000000000000000000000";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "00000000000000000000000000000000";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("4951954c54bf455268c3731d6149b594", $answer);

# Set 1, vector# 023:
    $key = pack "H32", "00000100000000000000000000000000";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "00000000000000000000000000000000";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("d2acb3586a1fd34a51d1754dc2163c53", $answer);

# Set 1, vector# 024:
    $key = pack "H32", "00000080000000000000000000000000";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "00000000000000000000000000000000";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("d47ae862b06ea9a3d815d7194b5b3dd5", $answer);

# Set 1, vector# 025:
    $key = pack "H32", "00000040000000000000000000000000";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "00000000000000000000000000000000";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("eb13521202b0c74db63b68c25090bb15", $answer);

# Set 1, vector# 026:
    $key = pack "H32", "00000020000000000000000000000000";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "00000000000000000000000000000000";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("34570bd530e9b293bdcc3bb4cab5b997", $answer);

# Set 1, vector# 027:
    $key = pack "H32", "00000010000000000000000000000000";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "00000000000000000000000000000000";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("a27a03d02c198cbd360596002e399f72", $answer);

# Set 1, vector# 028:
    $key = pack "H32", "00000008000000000000000000000000";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "00000000000000000000000000000000";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("ebf57248f4cb932a16df7bdf9128266a", $answer);

# Set 1, vector# 029:
    $key = pack "H32", "00000004000000000000000000000000";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "00000000000000000000000000000000";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("6cf530edf810988eb1a4a6de7b30f2fe", $answer);

# Set 1, vector# 030:
    $key = pack "H32", "00000002000000000000000000000000";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "00000000000000000000000000000000";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("eec364fd3494eb16c74fbb11d0d163a7", $answer);

# Set 1, vector# 031:
    $key = pack "H32", "00000001000000000000000000000000";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "00000000000000000000000000000000";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("900d71e97363e352e24c1e3dc819cf87", $answer);

# Set 1, vector# 032:
    $key = pack "H32", "00000000800000000000000000000000";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "00000000000000000000000000000000";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("3376d9ed227ba2c4c5da4b746cf4552e", $answer);

# Set 1, vector# 033:
    $key = pack "H32", "00000000400000000000000000000000";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "00000000000000000000000000000000";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("d7238293a5e59b7729a4406d1b62b793", $answer);

# Set 1, vector# 034:
    $key = pack "H32", "00000000200000000000000000000000";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "00000000000000000000000000000000";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("4be0f8d4facea67c8da81c706a7bfb1f", $answer);

# Set 1, vector# 035:
    $key = pack "H32", "00000000100000000000000000000000";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "00000000000000000000000000000000";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("70029de11920bb12645cf7eac0b58927", $answer);

# Set 1, vector# 036:
    $key = pack "H32", "00000000080000000000000000000000";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "00000000000000000000000000000000";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("38381edad970c6c414210aa2bab6de25", $answer);

# Set 1, vector# 037:
    $key = pack "H32", "00000000040000000000000000000000";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "00000000000000000000000000000000";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("6357bb3348b58d81ae96a36dec8f949a", $answer);

# Set 1, vector# 038:
    $key = pack "H32", "00000000020000000000000000000000";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "00000000000000000000000000000000";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("8ebc706f8a631f42dbd5f54a627e65b8", $answer);

# Set 1, vector# 039:
    $key = pack "H32", "00000000010000000000000000000000";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "00000000000000000000000000000000";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("469015afd0a84832b03d21f4cc0f583e", $answer);

# Set 1, vector# 040:
    $key = pack "H32", "00000000008000000000000000000000";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "00000000000000000000000000000000";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("f2afb0d15ce883e9a74a10a2974ccbde", $answer);

# Set 1, vector# 041:
    $key = pack "H32", "00000000004000000000000000000000";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "00000000000000000000000000000000";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("b1fc6e1eac63deef07d3d2612e2f8e72", $answer);

# Set 1, vector# 042:
    $key = pack "H32", "00000000002000000000000000000000";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "00000000000000000000000000000000";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("a29205a899ce23785127beda3f0a542f", $answer);

# Set 1, vector# 043:
    $key = pack "H32", "00000000001000000000000000000000";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "00000000000000000000000000000000";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("0520f813a4f8e2b6801fd6f89a748136", $answer);

# Set 1, vector# 044:
    $key = pack "H32", "00000000000800000000000000000000";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "00000000000000000000000000000000";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("7bdbcb59b4ae9e10c10444c26e48b214", $answer);

# Set 1, vector# 045:
    $key = pack "H32", "00000000000400000000000000000000";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "00000000000000000000000000000000";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("1f8500ef37b056c702e0279e46ed687f", $answer);

# Set 1, vector# 046:
    $key = pack "H32", "00000000000200000000000000000000";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "00000000000000000000000000000000";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("cc89c583852712afe44724cb44660599", $answer);

# Set 1, vector# 047:
    $key = pack "H32", "00000000000100000000000000000000";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "00000000000000000000000000000000";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("b8664b9e94188ff8d5b7be098ef8bbc1", $answer);

# Set 1, vector# 048:
    $key = pack "H32", "00000000000080000000000000000000";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "00000000000000000000000000000000";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("459bf71bcb15c330c3e195edcb19e398", $answer);

# Set 1, vector# 049:
    $key = pack "H32", "00000000000040000000000000000000";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "00000000000000000000000000000000";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("4fd6985eae10c4d96f22fb7cd4094a67", $answer);

# Set 1, vector# 050:
    $key = pack "H32", "00000000000020000000000000000000";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "00000000000000000000000000000000";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("03b5be238dec5f663fac5089dbef9401", $answer);

# Set 1, vector# 051:
    $key = pack "H32", "00000000000010000000000000000000";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "00000000000000000000000000000000";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("996a3533de8bd49defb364e23328b6ac", $answer);

# Set 1, vector# 052:
    $key = pack "H32", "00000000000008000000000000000000";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "00000000000000000000000000000000";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("667e7e1f13173f00d130e32441cab5f3", $answer);

# Set 1, vector# 053:
    $key = pack "H32", "00000000000004000000000000000000";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "00000000000000000000000000000000";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("6faed81e6ea921dd2fa96902a90596bf", $answer);

# Set 1, vector# 054:
    $key = pack "H32", "00000000000002000000000000000000";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "00000000000000000000000000000000";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("4ec5d4212bede13c1b2a30865cfe088a", $answer);

# Set 1, vector# 055:
    $key = pack "H32", "00000000000001000000000000000000";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "00000000000000000000000000000000";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("736f12403f1f08401763b5caf5cf61ba", $answer);

# Set 1, vector# 056:
    $key = pack "H32", "00000000000000800000000000000000";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "00000000000000000000000000000000";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("6781b5741c4ff9bcaed71bd0162bdc52", $answer);

# Set 1, vector# 057:
    $key = pack "H32", "00000000000000400000000000000000";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "00000000000000000000000000000000";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("c998c1849124e6cd23f602ab2f431a88", $answer);

# Set 1, vector# 058:
    $key = pack "H32", "00000000000000200000000000000000";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "00000000000000000000000000000000";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("9b2dfea756770e7841e64e778a1d2c39", $answer);

# Set 1, vector# 059:
    $key = pack "H32", "00000000000000100000000000000000";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "00000000000000000000000000000000";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("66b62719bb8f3ec7a33597365b55679a", $answer);

# Set 1, vector# 060:
    $key = pack "H32", "00000000000000080000000000000000";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "00000000000000000000000000000000";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("d4513c1f440cfb87a3ee00befcf68fb6", $answer);

# Set 1, vector# 061:
    $key = pack "H32", "00000000000000040000000000000000";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "00000000000000000000000000000000";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("51fb7f5881f7b9d2bbbf3bf2909c9c28", $answer);

# Set 1, vector# 062:
    $key = pack "H32", "00000000000000020000000000000000";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "00000000000000000000000000000000";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("3b1851d3adaed9b6f5204a78331c556f", $answer);

# Set 1, vector# 063:
    $key = pack "H32", "00000000000000010000000000000000";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "00000000000000000000000000000000";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("9420279c95b3e4268779fd42c75d5fbe", $answer);

# Set 1, vector# 064:
    $key = pack "H32", "00000000000000008000000000000000";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "00000000000000000000000000000000";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("27168066cf1c93273bd929dc1d93be0f", $answer);

# Set 1, vector# 065:
    $key = pack "H32", "00000000000000004000000000000000";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "00000000000000000000000000000000";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("bb067b2d696fce71add58f25a84d4302", $answer);

# Set 1, vector# 066:
    $key = pack "H32", "00000000000000002000000000000000";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "00000000000000000000000000000000";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("ce320bf17d52363c2a674bb3fc8db2a9", $answer);

# Set 1, vector# 067:
    $key = pack "H32", "00000000000000001000000000000000";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "00000000000000000000000000000000";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("4b1f738eff2b831a984ceef5a0286ddc", $answer);

# Set 1, vector# 068:
    $key = pack "H32", "00000000000000000800000000000000";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "00000000000000000000000000000000";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("2b0f9df8a3f2768bdf60859749ac9a40", $answer);

# Set 1, vector# 069:
    $key = pack "H32", "00000000000000000400000000000000";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "00000000000000000000000000000000";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("0261976d306d7c1a0e7047f7a173f16d", $answer);

# Set 1, vector# 070:
    $key = pack "H32", "00000000000000000200000000000000";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "00000000000000000000000000000000";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("7899f4f9fda441b23c8c6dcb95d421ec", $answer);

# Set 1, vector# 071:
    $key = pack "H32", "00000000000000000100000000000000";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "00000000000000000000000000000000";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("66cb8cbef1ad429181bbc5b88bb402bc", $answer);

# Set 1, vector# 072:
    $key = pack "H32", "00000000000000000080000000000000";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "00000000000000000000000000000000";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("eb81c9f7b85661239c6b43d835137e3b", $answer);

# Set 1, vector# 073:
    $key = pack "H32", "00000000000000000040000000000000";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "00000000000000000000000000000000";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("379ffba18abc84e396615242d59d3595", $answer);

# Set 1, vector# 074:
    $key = pack "H32", "00000000000000000020000000000000";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "00000000000000000000000000000000";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("a603bac79e3f035b602c98a4c90ffa1d", $answer);

# Set 1, vector# 075:
    $key = pack "H32", "00000000000000000010000000000000";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "00000000000000000000000000000000";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("b2d190c6e62b2528afa5953ef6570321", $answer);

# Set 1, vector# 076:
    $key = pack "H32", "00000000000000000008000000000000";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "00000000000000000000000000000000";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("23d7c04efacd1d28c961c17d34bb20bc", $answer);

# Set 1, vector# 077:
    $key = pack "H32", "00000000000000000004000000000000";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "00000000000000000000000000000000";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("b300d576aed3f55fd4d1a37aad74dde2", $answer);

# Set 1, vector# 078:
    $key = pack "H32", "00000000000000000002000000000000";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "00000000000000000000000000000000";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("c69930b8f818332fa98f8e57fca02811", $answer);

# Set 1, vector# 079:
    $key = pack "H32", "00000000000000000001000000000000";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "00000000000000000000000000000000";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("a893b8a1e5006908df0e786ec7201dc9", $answer);

# Set 1, vector# 080:
    $key = pack "H32", "00000000000000000000800000000000";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "00000000000000000000000000000000";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("0e302038415306a46d6362cb258f0720", $answer);

# Set 1, vector# 081:
    $key = pack "H32", "00000000000000000000400000000000";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "00000000000000000000000000000000";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("dbc11caf892751f29af4e982c1bb66b1", $answer);

# Set 1, vector# 082:
    $key = pack "H32", "00000000000000000000200000000000";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "00000000000000000000000000000000";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("92f5f718cfd92fb9cb65d645180c484e", $answer);

# Set 1, vector# 083:
    $key = pack "H32", "00000000000000000000100000000000";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "00000000000000000000000000000000";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("4db75037a5475b8884cc91c2504e5201", $answer);

# Set 1, vector# 084:
    $key = pack "H32", "00000000000000000000080000000000";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "00000000000000000000000000000000";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("327cfa9c0bf8b42aa520d820a7eda499", $answer);

# Set 1, vector# 085:
    $key = pack "H32", "00000000000000000000040000000000";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "00000000000000000000000000000000";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("1de49c41bc2ea101ef208d9e0123c6b9", $answer);

# Set 1, vector# 086:
    $key = pack "H32", "00000000000000000000020000000000";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "00000000000000000000000000000000";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("568331d24ba4d704ab7855e67c2e911b", $answer);

# Set 1, vector# 087:
    $key = pack "H32", "00000000000000000000010000000000";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "00000000000000000000000000000000";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("1323c1b67d62296c7b5703097935631b", $answer);

# Set 1, vector# 088:
    $key = pack "H32", "00000000000000000000008000000000";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "00000000000000000000000000000000";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("e95179c3a2d7e95890123aec5a32d2ae", $answer);

# Set 1, vector# 089:
    $key = pack "H32", "00000000000000000000004000000000";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "00000000000000000000000000000000";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("1f8ac7d988dd9f7a93a9f9e8c732adfd", $answer);

# Set 1, vector# 090:
    $key = pack "H32", "00000000000000000000002000000000";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "00000000000000000000000000000000";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("1926a0b39ffe0d5233110e828c48a627", $answer);

# Set 1, vector# 091:
    $key = pack "H32", "00000000000000000000001000000000";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "00000000000000000000000000000000";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("2d2284038054ef1178102af0a2ca93cc", $answer);

# Set 1, vector# 092:
    $key = pack "H32", "00000000000000000000000800000000";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "00000000000000000000000000000000";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("8ce6b0c19b87de74e4dcb02794a359e4", $answer);

# Set 1, vector# 093:
    $key = pack "H32", "00000000000000000000000400000000";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "00000000000000000000000000000000";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("c05c65de41d9b3a97cd2a398b722de2b", $answer);

# Set 1, vector# 094:
    $key = pack "H32", "00000000000000000000000200000000";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "00000000000000000000000000000000";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("455c01fd0578fc4f847516052babbeea", $answer);

# Set 1, vector# 095:
    $key = pack "H32", "00000000000000000000000100000000";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "00000000000000000000000000000000";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("4337a126a4876163cb4a69262d766e64", $answer);

# Set 1, vector# 096:
    $key = pack "H32", "00000000000000000000000080000000";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "00000000000000000000000000000000";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("145838bdb0cd08f3e7214e20abf615d1", $answer);

# Set 1, vector# 097:
    $key = pack "H32", "00000000000000000000000040000000";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "00000000000000000000000000000000";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("429958b9d1474143782be510cc87036c", $answer);

# Set 1, vector# 098:
    $key = pack "H32", "00000000000000000000000020000000";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "00000000000000000000000000000000";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("aa64b7cbfaa4239a7b6d6cf88ff81050", $answer);

# Set 1, vector# 099:
    $key = pack "H32", "00000000000000000000000010000000";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "00000000000000000000000000000000";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("e94f0651283d06337821bd75aaebc1ff", $answer);

# Set 1, vector# 100:
    $key = pack "H32", "00000000000000000000000008000000";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "00000000000000000000000000000000";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("74f4e1ff29724df4368f3e7576409183", $answer);

# Set 1, vector# 101:
    $key = pack "H32", "00000000000000000000000004000000";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "00000000000000000000000000000000";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("898c2a84a8c699bf8e523f39426b4c5f", $answer);

# Set 1, vector# 102:
    $key = pack "H32", "00000000000000000000000002000000";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "00000000000000000000000000000000";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("97a95580a273b9917a0a4e310e6efb80", $answer);

# Set 1, vector# 103:
    $key = pack "H32", "00000000000000000000000001000000";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "00000000000000000000000000000000";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("38c6cdeb3912b5e9235656dff1fa482f", $answer);

# Set 1, vector# 104:
    $key = pack "H32", "00000000000000000000000000800000";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "00000000000000000000000000000000";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("cf9bac64a8ba50d028ed499c2aade900", $answer);

# Set 1, vector# 105:
    $key = pack "H32", "00000000000000000000000000400000";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "00000000000000000000000000000000";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("91c0f60ec3028b17d965a7ad0797e0c5", $answer);

# Set 1, vector# 106:
    $key = pack "H32", "00000000000000000000000000200000";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "00000000000000000000000000000000";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("ac3603d04a0644248cff1c8882aa21cc", $answer);

# Set 1, vector# 107:
    $key = pack "H32", "00000000000000000000000000100000";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "00000000000000000000000000000000";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("73b7ffb5b0eab949e0a4d4838c8d834d", $answer);

# Set 1, vector# 108:
    $key = pack "H32", "00000000000000000000000000080000";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "00000000000000000000000000000000";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("c87b33118e17823615a0ddc0de3fd702", $answer);

# Set 1, vector# 109:
    $key = pack "H32", "00000000000000000000000000040000";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "00000000000000000000000000000000";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("9151c0a6ca951c56c8b19b8bd2317175", $answer);

# Set 1, vector# 110:
    $key = pack "H32", "00000000000000000000000000020000";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "00000000000000000000000000000000";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("3b5fdd9b20a36a56ec0d71f55c939202", $answer);

# Set 1, vector# 111:
    $key = pack "H32", "00000000000000000000000000010000";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "00000000000000000000000000000000";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("6445c1758cf232a5fcf042e07f7155be", $answer);

# Set 1, vector# 112:
    $key = pack "H32", "00000000000000000000000000008000";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "00000000000000000000000000000000";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("58e7082503cb66e26c48b164e406a6e0", $answer);

# Set 1, vector# 113:
    $key = pack "H32", "00000000000000000000000000004000";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "00000000000000000000000000000000";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("a673d5b8f36eeecd5c5ad4d44f1cb7eb", $answer);

# Set 1, vector# 114:
    $key = pack "H32", "00000000000000000000000000002000";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "00000000000000000000000000000000";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("7f28bf9147e7e86a818e7a01e2c1429f", $answer);

# Set 1, vector# 115:
    $key = pack "H32", "00000000000000000000000000001000";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "00000000000000000000000000000000";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("1f71621fdd2c9ed336a2bb0094f4a9af", $answer);

# Set 1, vector# 116:
    $key = pack "H32", "00000000000000000000000000000800";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "00000000000000000000000000000000";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("8de6453ef63ee3a3e1bc62aff57a85fd", $answer);

# Set 1, vector# 117:
    $key = pack "H32", "00000000000000000000000000000400";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "00000000000000000000000000000000";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("46b229c5cc494b3035f1e3c2c6d112b4", $answer);

# Set 1, vector# 118:
    $key = pack "H32", "00000000000000000000000000000200";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "00000000000000000000000000000000";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("bad29df650ee00c2b7a06c98ae831633", $answer);

# Set 1, vector# 119:
    $key = pack "H32", "00000000000000000000000000000100";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "00000000000000000000000000000000";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("b200440956ab384971599f924f9f5809", $answer);

# Set 1, vector# 120:
    $key = pack "H32", "00000000000000000000000000000080";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "00000000000000000000000000000000";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("bc31e0433c180b47c4b0e423446e41f6", $answer);

# Set 1, vector# 121:
    $key = pack "H32", "00000000000000000000000000000040";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "00000000000000000000000000000000";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("6aae01cb06fa100506a551d97d7eb662", $answer);

# Set 1, vector# 122:
    $key = pack "H32", "00000000000000000000000000000020";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "00000000000000000000000000000000";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("f423c4214cabe986f5cfd0acbb821744", $answer);

# Set 1, vector# 123:
    $key = pack "H32", "00000000000000000000000000000010";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "00000000000000000000000000000000";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("91150aec3f6844ac312e4a2ab258b1d9", $answer);

# Set 1, vector# 124:
    $key = pack "H32", "00000000000000000000000000000008";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "00000000000000000000000000000000";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("220091f836039a59522dcc0797abf5b2", $answer);

# Set 1, vector# 125:
    $key = pack "H32", "00000000000000000000000000000004";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "00000000000000000000000000000000";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("6b8b0b2878e66169e18aac25a843c57c", $answer);

# Set 1, vector# 126:
    $key = pack "H32", "00000000000000000000000000000002";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "00000000000000000000000000000000";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("06030fe32cd601f812281671d729f4ff", $answer);

# Set 1, vector# 127:
    $key = pack "H32", "00000000000000000000000000000001";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "00000000000000000000000000000000";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("e6141eafebe0593c48e1cdf21bbaa189", $answer);

# Set 2, vector# 000:
    $key = pack "H32", "00000000000000000000000000000000";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "80000000000000000000000000000000";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("753843f8182d1a74346ea255242181e0", $answer);

# Set 2, vector# 001:
    $key = pack "H32", "00000000000000000000000000000000";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "40000000000000000000000000000000";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("741696dc3c9969a64f55db17f5e4522f", $answer);

# Set 2, vector# 002:
    $key = pack "H32", "00000000000000000000000000000000";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "20000000000000000000000000000000";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("d7009a0dfdb7ea99bf4b944284c4ffe0", $answer);

# Set 2, vector# 003:
    $key = pack "H32", "00000000000000000000000000000000";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "10000000000000000000000000000000";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("708eb676b1dae91caac8bfaaf060f1b9", $answer);

# Set 2, vector# 004:
    $key = pack "H32", "00000000000000000000000000000000";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "08000000000000000000000000000000";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("0bef93a942ad81430b8e0ae0cc56c30e", $answer);

# Set 2, vector# 005:
    $key = pack "H32", "00000000000000000000000000000000";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "04000000000000000000000000000000";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("094c7ee830d0c7e1158503247b212b5f", $answer);

# Set 2, vector# 006:
    $key = pack "H32", "00000000000000000000000000000000";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "02000000000000000000000000000000";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("c02f6fe33af60b11dc03be9e1d8341b6", $answer);

# Set 2, vector# 007:
    $key = pack "H32", "00000000000000000000000000000000";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "01000000000000000000000000000000";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("0b832d1062cfb4ad510c567f1096c158", $answer);

# Set 2, vector# 008:
    $key = pack "H32", "00000000000000000000000000000000";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "00800000000000000000000000000000";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("53006654d51e1cbcdba85ca0cfb40ab7", $answer);

# Set 2, vector# 009:
    $key = pack "H32", "00000000000000000000000000000000";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "00400000000000000000000000000000";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("a279ed663d15ed3e6487ac5a55a8317b", $answer);

# Set 2, vector# 010:
    $key = pack "H32", "00000000000000000000000000000000";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "00200000000000000000000000000000";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("81f1b6b3754fef1ff61bfb1b709f9373", $answer);

# Set 2, vector# 011:
    $key = pack "H32", "00000000000000000000000000000000";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "00100000000000000000000000000000";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("3160170c27804b1c96ef513dc037802d", $answer);

# Set 2, vector# 012:
    $key = pack "H32", "00000000000000000000000000000000";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "00080000000000000000000000000000";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("5c26387d62d8b8bb2bff365ba88115ea", $answer);

# Set 2, vector# 013:
    $key = pack "H32", "00000000000000000000000000000000";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "00040000000000000000000000000000";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("de952da2d5c3c3c64aec9d45c96954db", $answer);

# Set 2, vector# 014:
    $key = pack "H32", "00000000000000000000000000000000";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "00020000000000000000000000000000";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("b9dab7e35aef53c44b9720b8746cbdf5", $answer);

# Set 2, vector# 015:
    $key = pack "H32", "00000000000000000000000000000000";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "00010000000000000000000000000000";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("0fca089e6e6030e9be10a1ffe8204e56", $answer);

# Set 2, vector# 016:
    $key = pack "H32", "00000000000000000000000000000000";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "00008000000000000000000000000000";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("24d12fb71f7ae6d5d2f4f806a4b98550", $answer);

# Set 2, vector# 017:
    $key = pack "H32", "00000000000000000000000000000000";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "00004000000000000000000000000000";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("883f59cf39ea23b2a7d01b8b15637d1d", $answer);

# Set 2, vector# 018:
    $key = pack "H32", "00000000000000000000000000000000";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "00002000000000000000000000000000";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("e0d5fd6c8efc1cfe17819da6010e8bcd", $answer);

# Set 2, vector# 019:
    $key = pack "H32", "00000000000000000000000000000000";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "00001000000000000000000000000000";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("547c802e026e719bc20cf82f4ec84ee8", $answer);

# Set 2, vector# 020:
    $key = pack "H32", "00000000000000000000000000000000";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "00000800000000000000000000000000";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("d8cac5eab2b2754f084a41913c55eb9b", $answer);

# Set 2, vector# 021:
    $key = pack "H32", "00000000000000000000000000000000";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "00000400000000000000000000000000";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("e130797a43f47a058da7dff1b7a92439", $answer);

# Set 2, vector# 022:
    $key = pack "H32", "00000000000000000000000000000000";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "00000200000000000000000000000000";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("b295faa65a7f28ad34becd269c4b95d0", $answer);

# Set 2, vector# 023:
    $key = pack "H32", "00000000000000000000000000000000";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "00000100000000000000000000000000";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("e4c3ff78b708724f2f043ecbb9b6d6c5", $answer);

# Set 2, vector# 024:
    $key = pack "H32", "00000000000000000000000000000000";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "00000080000000000000000000000000";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("165dc89b02e844ab0df4a4be5577a6ec", $answer);

# Set 2, vector# 025:
    $key = pack "H32", "00000000000000000000000000000000";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "00000040000000000000000000000000";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("cad403dd1bca84ee410e9341a0c39bee", $answer);

# Set 2, vector# 026:
    $key = pack "H32", "00000000000000000000000000000000";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "00000020000000000000000000000000";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("0ddf38534a87dae4327bca1be81b776a", $answer);

# Set 2, vector# 027:
    $key = pack "H32", "00000000000000000000000000000000";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "00000010000000000000000000000000";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("01cf3298e73ed0695b8895910e6ce54c", $answer);

# Set 2, vector# 028:
    $key = pack "H32", "00000000000000000000000000000000";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "00000008000000000000000000000000";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("98f9ae3513b932d7b5acb7f34d125ecd", $answer);

# Set 2, vector# 029:
    $key = pack "H32", "00000000000000000000000000000000";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "00000004000000000000000000000000";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("e7ae7453e89e1bde0e52cd3d7e1d825d", $answer);

# Set 2, vector# 030:
    $key = pack "H32", "00000000000000000000000000000000";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "00000002000000000000000000000000";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("004b4f89146d871c69815721ad43da19", $answer);

# Set 2, vector# 031:
    $key = pack "H32", "00000000000000000000000000000000";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "00000001000000000000000000000000";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("0c5dbd06da1d3fddf25b8b2c0a6b4f0f", $answer);

# Set 2, vector# 032:
    $key = pack "H32", "00000000000000000000000000000000";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "00000000800000000000000000000000";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("fa2d1f1e47b2760a0708ecd0ca36885b", $answer);

# Set 2, vector# 033:
    $key = pack "H32", "00000000000000000000000000000000";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "00000000400000000000000000000000";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("5bd074fc2a5d91a1816ee7fc58c92b38", $answer);

# Set 2, vector# 034:
    $key = pack "H32", "00000000000000000000000000000000";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "00000000200000000000000000000000";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("3969dd34f1c484ef5da2715625d71b8f", $answer);

# Set 2, vector# 035:
    $key = pack "H32", "00000000000000000000000000000000";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "00000000100000000000000000000000";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("51def1cb4d10787bceb0cc3219c0b96b", $answer);

# Set 2, vector# 036:
    $key = pack "H32", "00000000000000000000000000000000";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "00000000080000000000000000000000";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("a89343e157397e3963c26db47ed4a3a7", $answer);

# Set 2, vector# 037:
    $key = pack "H32", "00000000000000000000000000000000";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "00000000040000000000000000000000";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("dc775617c31d807cd7718edacc7722dd", $answer);

# Set 2, vector# 038:
    $key = pack "H32", "00000000000000000000000000000000";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "00000000020000000000000000000000";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("da2006431d4e30fffeef5bb1167c4129", $answer);

# Set 2, vector# 039:
    $key = pack "H32", "00000000000000000000000000000000";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "00000000010000000000000000000000";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("a5f5858404e74638f928cfa986125ca7", $answer);

# Set 2, vector# 040:
    $key = pack "H32", "00000000000000000000000000000000";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "00000000008000000000000000000000";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("817760c95979274e5bdb817f54ee0692", $answer);

# Set 2, vector# 041:
    $key = pack "H32", "00000000000000000000000000000000";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "00000000004000000000000000000000";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("08906134d62e4a6cfef3114c10778580", $answer);

# Set 2, vector# 042:
    $key = pack "H32", "00000000000000000000000000000000";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "00000000002000000000000000000000";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("5ba5274342ed86e00e1d26a08afb5f0c", $answer);

# Set 2, vector# 043:
    $key = pack "H32", "00000000000000000000000000000000";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "00000000001000000000000000000000";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("497aa2fa6221a670eb3c1e15a436ea7a", $answer);

# Set 2, vector# 044:
    $key = pack "H32", "00000000000000000000000000000000";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "00000000000800000000000000000000";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("43950a7f4dd10e8a04e2f12b3673697c", $answer);

# Set 2, vector# 045:
    $key = pack "H32", "00000000000000000000000000000000";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "00000000000400000000000000000000";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("a1a7b4b1ac4dc57a3cd606883c1272c9", $answer);

# Set 2, vector# 046:
    $key = pack "H32", "00000000000000000000000000000000";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "00000000000200000000000000000000";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("aec39a95ab3e89cc623174eb15606a98", $answer);

# Set 2, vector# 047:
    $key = pack "H32", "00000000000000000000000000000000";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "00000000000100000000000000000000";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("d85c3047098f6180e0f449c860c4c840", $answer);

# Set 2, vector# 048:
    $key = pack "H32", "00000000000000000000000000000000";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "00000000000080000000000000000000";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("4d7464eaf7e60b2c0db876d40203d4ee", $answer);

# Set 2, vector# 049:
    $key = pack "H32", "00000000000000000000000000000000";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "00000000000040000000000000000000";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("8a44a3788ea4cfc46b67cb4a1b12a517", $answer);

# Set 2, vector# 050:
    $key = pack "H32", "00000000000000000000000000000000";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "00000000000020000000000000000000";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("4468fabbd689d93697d107bced46cc59", $answer);

# Set 2, vector# 051:
    $key = pack "H32", "00000000000000000000000000000000";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "00000000000010000000000000000000";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("822664ec48b66e93f34742a742124969", $answer);

# Set 2, vector# 052:
    $key = pack "H32", "00000000000000000000000000000000";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "00000000000008000000000000000000";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("b9ea589c04fc7eba9d91ad7bc1a8a96b", $answer);

# Set 2, vector# 053:
    $key = pack "H32", "00000000000000000000000000000000";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "00000000000004000000000000000000";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("abb7a04650fe020708262450c76c297b", $answer);

# Set 2, vector# 054:
    $key = pack "H32", "00000000000000000000000000000000";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "00000000000002000000000000000000";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("9bce52063c22f46846656106bffa61ff", $answer);

# Set 2, vector# 055:
    $key = pack "H32", "00000000000000000000000000000000";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "00000000000001000000000000000000";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("9805b8fe39ad02aa3caeccc67f64722e", $answer);

# Set 2, vector# 056:
    $key = pack "H32", "00000000000000000000000000000000";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "00000000000000800000000000000000";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("a2ef518a099fd4157a76e1499ae9f7f9", $answer);

# Set 2, vector# 057:
    $key = pack "H32", "00000000000000000000000000000000";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "00000000000000400000000000000000";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("ecfc4fee14e55351cb6fbb94136db2c6", $answer);

# Set 2, vector# 058:
    $key = pack "H32", "00000000000000000000000000000000";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "00000000000000200000000000000000";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("4435079bfd9357d7ba523183609bc8ba", $answer);

# Set 2, vector# 059:
    $key = pack "H32", "00000000000000000000000000000000";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "00000000000000100000000000000000";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("c314d9db8059d8d5a5aaed6c369d43c8", $answer);

# Set 2, vector# 060:
    $key = pack "H32", "00000000000000000000000000000000";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "00000000000000080000000000000000";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("c5086852d7de68f6b6f9a5d3c2c3dcec", $answer);

# Set 2, vector# 061:
    $key = pack "H32", "00000000000000000000000000000000";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "00000000000000040000000000000000";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("bd5ce48c5b98cec569be2e31687afa58", $answer);

# Set 2, vector# 062:
    $key = pack "H32", "00000000000000000000000000000000";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "00000000000000020000000000000000";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("2d6d43fd998be4cf02ffb4ade8e69525", $answer);

# Set 2, vector# 063:
    $key = pack "H32", "00000000000000000000000000000000";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "00000000000000010000000000000000";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("1c6e771fdea022f3aaf9146fa83de0cc", $answer);

# Set 2, vector# 064:
    $key = pack "H32", "00000000000000000000000000000000";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "00000000000000008000000000000000";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("b1067b9d30fb6079ebf38bbb5c0d8c93", $answer);

# Set 2, vector# 065:
    $key = pack "H32", "00000000000000000000000000000000";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "00000000000000004000000000000000";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("9433a06da089017c03cd98206f2f0997", $answer);

# Set 2, vector# 066:
    $key = pack "H32", "00000000000000000000000000000000";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "00000000000000002000000000000000";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("f69b75bce12b66d681b2631e0e424bf3", $answer);

# Set 2, vector# 067:
    $key = pack "H32", "00000000000000000000000000000000";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "00000000000000001000000000000000";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("35810d4e03cbd8028a64eba437a345a9", $answer);

# Set 2, vector# 068:
    $key = pack "H32", "00000000000000000000000000000000";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "00000000000000000800000000000000";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("bc37e4ea287b232be889db7ddc0eb82f", $answer);

# Set 2, vector# 069:
    $key = pack "H32", "00000000000000000000000000000000";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "00000000000000000400000000000000";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("ffcf9d543d7162f6c04ae4035ad7a634", $answer);

# Set 2, vector# 070:
    $key = pack "H32", "00000000000000000000000000000000";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "00000000000000000200000000000000";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("aa0debbbee44baacb74a36761ef1326d", $answer);

# Set 2, vector# 071:
    $key = pack "H32", "00000000000000000000000000000000";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "00000000000000000100000000000000";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("cb093d987348e99ab83689b4292c01cc", $answer);

# Set 2, vector# 072:
    $key = pack "H32", "00000000000000000000000000000000";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "00000000000000000080000000000000";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("921808846740e3c69427b532a6a3f2eb", $answer);

# Set 2, vector# 073:
    $key = pack "H32", "00000000000000000000000000000000";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "00000000000000000040000000000000";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("745efecf9fd0f7d7d04d09b1e23f81d4", $answer);

# Set 2, vector# 074:
    $key = pack "H32", "00000000000000000000000000000000";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "00000000000000000020000000000000";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("d822aba319806d3c4376628d86563a85", $answer);

# Set 2, vector# 075:
    $key = pack "H32", "00000000000000000000000000000000";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "00000000000000000010000000000000";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("f1977434515be244376ff10a006d9622", $answer);

# Set 2, vector# 076:
    $key = pack "H32", "00000000000000000000000000000000";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "00000000000000000008000000000000";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("bf6bb4068485709b46e05e14a710e910", $answer);

# Set 2, vector# 077:
    $key = pack "H32", "00000000000000000000000000000000";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "00000000000000000004000000000000";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("b8d86b02a59bc9a74df41a39a7ce5a51", $answer);

# Set 2, vector# 078:
    $key = pack "H32", "00000000000000000000000000000000";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "00000000000000000002000000000000";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("07d5da10d9d4489be6c89c3b933d1807", $answer);

# Set 2, vector# 079:
    $key = pack "H32", "00000000000000000000000000000000";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "00000000000000000001000000000000";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("ebd6fef5edb3c8506c4ab270e0f98fa1", $answer);

# Set 2, vector# 080:
    $key = pack "H32", "00000000000000000000000000000000";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "00000000000000000000800000000000";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("b51f9be5d6412f58454f47253bb2461b", $answer);

# Set 2, vector# 081:
    $key = pack "H32", "00000000000000000000000000000000";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "00000000000000000000400000000000";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("f824f757294346c8de8653fcebb29c0e", $answer);

# Set 2, vector# 082:
    $key = pack "H32", "00000000000000000000000000000000";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "00000000000000000000200000000000";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("4c50e73dae556fcd317f439be66bdc2f", $answer);

# Set 2, vector# 083:
    $key = pack "H32", "00000000000000000000000000000000";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "00000000000000000000100000000000";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("273fca53653b946ef35c8fba43cf305e", $answer);

# Set 2, vector# 084:
    $key = pack "H32", "00000000000000000000000000000000";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "00000000000000000000080000000000";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("df6b58a1563e1cff921f45c0118940b1", $answer);

# Set 2, vector# 085:
    $key = pack "H32", "00000000000000000000000000000000";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "00000000000000000000040000000000";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("d16990a40768be7cc94c50e6de233d96", $answer);

# Set 2, vector# 086:
    $key = pack "H32", "00000000000000000000000000000000";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "00000000000000000000020000000000";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("189ff5f8cbd22436c8e057225ce6c07a", $answer);

# Set 2, vector# 087:
    $key = pack "H32", "00000000000000000000000000000000";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "00000000000000000000010000000000";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("18d1e895f1cf29698d14d77efb1cbdcc", $answer);

# Set 2, vector# 088:
    $key = pack "H32", "00000000000000000000000000000000";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "00000000000000000000008000000000";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("d4c4e7bc8649972e0569d8628462f16b", $answer);

# Set 2, vector# 089:
    $key = pack "H32", "00000000000000000000000000000000";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "00000000000000000000004000000000";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("2f59b62b558efa35d893449b9513ce67", $answer);

# Set 2, vector# 090:
    $key = pack "H32", "00000000000000000000000000000000";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "00000000000000000000002000000000";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("17cf6111fdcb02d6af44bf76caf13d55", $answer);

# Set 2, vector# 091:
    $key = pack "H32", "00000000000000000000000000000000";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "00000000000000000000001000000000";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("860497c65b5b076614eb3818d4f96750", $answer);

# Set 2, vector# 092:
    $key = pack "H32", "00000000000000000000000000000000";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "00000000000000000000000800000000";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("3f20c8177f64a8f4c44bccec1fbfe88a", $answer);

# Set 2, vector# 093:
    $key = pack "H32", "00000000000000000000000000000000";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "00000000000000000000000400000000";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("71e8cc9159aed88f61a316c860f4b336", $answer);

# Set 2, vector# 094:
    $key = pack "H32", "00000000000000000000000000000000";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "00000000000000000000000200000000";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("158ccae183abe06f4b5ff4afa0a4c127", $answer);

# Set 2, vector# 095:
    $key = pack "H32", "00000000000000000000000000000000";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "00000000000000000000000100000000";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("d1a86ba633d3e79ccb91e2f816f3bd49", $answer);

# Set 2, vector# 096:
    $key = pack "H32", "00000000000000000000000000000000";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "00000000000000000000000080000000";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("1d2fc1f4ecba4bf51ef31a5f14dccc2c", $answer);

# Set 2, vector# 097:
    $key = pack "H32", "00000000000000000000000000000000";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "00000000000000000000000040000000";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("7ab89e29f7c871d0cc0a25d3c65ced97", $answer);

# Set 2, vector# 098:
    $key = pack "H32", "00000000000000000000000000000000";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "00000000000000000000000020000000";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("7c3824abe2f76fe467fad51873e75e7b", $answer);

# Set 2, vector# 099:
    $key = pack "H32", "00000000000000000000000000000000";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "00000000000000000000000010000000";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("59b321857e161d8ded7c1322445e01e6", $answer);

# Set 2, vector# 100:
    $key = pack "H32", "00000000000000000000000000000000";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "00000000000000000000000008000000";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("6ad53ead200f3fc5850381eabdf396e7", $answer);

# Set 2, vector# 101:
    $key = pack "H32", "00000000000000000000000000000000";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "00000000000000000000000004000000";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("ad7e698c7b56b099897ace15d2f468a1", $answer);

# Set 2, vector# 102:
    $key = pack "H32", "00000000000000000000000000000000";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "00000000000000000000000002000000";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("6f040f76a742e6d5d6f87b1e2e7c232d", $answer);

# Set 2, vector# 103:
    $key = pack "H32", "00000000000000000000000000000000";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "00000000000000000000000001000000";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("1af8f08dd99b25cf546805de05a8df8c", $answer);

# Set 2, vector# 104:
    $key = pack "H32", "00000000000000000000000000000000";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "00000000000000000000000000800000";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("9e852f35084e0f267cf5c11fa35eaa81", $answer);

# Set 2, vector# 105:
    $key = pack "H32", "00000000000000000000000000000000";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "00000000000000000000000000400000";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("c6da719d84201d77b49e6e703843c22e", $answer);

# Set 2, vector# 106:
    $key = pack "H32", "00000000000000000000000000000000";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "00000000000000000000000000200000";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("b054b2ce09d6f038c6cec00c17bd9e80", $answer);

# Set 2, vector# 107:
    $key = pack "H32", "00000000000000000000000000000000";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "00000000000000000000000000100000";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("f63a93fb1a8797142dc1b3619efd851e", $answer);

# Set 2, vector# 108:
    $key = pack "H32", "00000000000000000000000000000000";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "00000000000000000000000000080000";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("ded789d3834b6aba8b7d184343043781", $answer);

# Set 2, vector# 109:
    $key = pack "H32", "00000000000000000000000000000000";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "00000000000000000000000000040000";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("a0b20439719b9a36d8b6f4251f46ed99", $answer);

# Set 2, vector# 110:
    $key = pack "H32", "00000000000000000000000000000000";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "00000000000000000000000000020000";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("8cee4f9fbfe5d6f19b41dc070c816379", $answer);

# Set 2, vector# 111:
    $key = pack "H32", "00000000000000000000000000000000";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "00000000000000000000000000010000";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("e30bdf64824b1e9abb1cbde3001b7d8b", $answer);

# Set 2, vector# 112:
    $key = pack "H32", "00000000000000000000000000000000";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "00000000000000000000000000008000";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("1c23d31f9a0a89fa6a57f07cc305786b", $answer);

# Set 2, vector# 113:
    $key = pack "H32", "00000000000000000000000000000000";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "00000000000000000000000000004000";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("10fb85ae2158b378d36fa7263cd8424d", $answer);

# Set 2, vector# 114:
    $key = pack "H32", "00000000000000000000000000000000";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "00000000000000000000000000002000";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("77d268387126cce42c48eedce8d3c255", $answer);

# Set 2, vector# 115:
    $key = pack "H32", "00000000000000000000000000000000";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "00000000000000000000000000001000";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("af00dc8c55ab5fa089234d30c3b09637", $answer);

# Set 2, vector# 116:
    $key = pack "H32", "00000000000000000000000000000000";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "00000000000000000000000000000800";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("0b10f5047a610e668859f7316ab0942c", $answer);

# Set 2, vector# 117:
    $key = pack "H32", "00000000000000000000000000000000";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "00000000000000000000000000000400";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("755d73150c71a286415c87c468e640df", $answer);

# Set 2, vector# 118:
    $key = pack "H32", "00000000000000000000000000000000";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "00000000000000000000000000000200";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("cbf28cdf45425c32214dd5b872d3eafc", $answer);

# Set 2, vector# 119:
    $key = pack "H32", "00000000000000000000000000000000";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "00000000000000000000000000000100";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("5b45a6e6fa43a31cf0db9ca2e8b47c04", $answer);

# Set 2, vector# 120:
    $key = pack "H32", "00000000000000000000000000000000";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "00000000000000000000000000000080";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("e020ab6ef00225831efd4013abb5fc07", $answer);

# Set 2, vector# 121:
    $key = pack "H32", "00000000000000000000000000000000";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "00000000000000000000000000000040";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("539fd1da9718f594487efe989c0ef591", $answer);

# Set 2, vector# 122:
    $key = pack "H32", "00000000000000000000000000000000";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "00000000000000000000000000000020";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("42edcf7e7e3cec9256d982a72e83f188", $answer);

# Set 2, vector# 123:
    $key = pack "H32", "00000000000000000000000000000000";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "00000000000000000000000000000010";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("22b03eb27afe06c836d140d337c83a49", $answer);

# Set 2, vector# 124:
    $key = pack "H32", "00000000000000000000000000000000";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "00000000000000000000000000000008";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("867e2f8695a7b49d0103781a5d8b9795", $answer);

# Set 2, vector# 125:
    $key = pack "H32", "00000000000000000000000000000000";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "00000000000000000000000000000004";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("2adc082af559041b40ed5c4a16853a44", $answer);

# Set 2, vector# 126:
    $key = pack "H32", "00000000000000000000000000000000";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "00000000000000000000000000000002";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("ca80e0bd6f8f55b13c1e96da6751302c", $answer);

# Set 2, vector# 127:
    $key = pack "H32", "00000000000000000000000000000000";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "00000000000000000000000000000001";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("f8285fc6233769ace784ded0765c416a", $answer);

# Set 3, vector#  00:
    $key = pack "H32", "00000000000000000000000000000000";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "00000000000000000000000000000000";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("0a58f9c567657dee8d957b1071da8695", $answer);

# Set 3, vector#  01:
    $key = pack "H32", "01010101010101010101010101010101";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "01010101010101010101010101010101";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("295bd1f12c803ebcce087049ecdf8c79", $answer);

# Set 3, vector#  02:
    $key = pack "H32", "02020202020202020202020202020202";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "02020202020202020202020202020202";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("3fd4a2b593cd9214bb26196db4678587", $answer);

# Set 3, vector#  03:
    $key = pack "H32", "03030303030303030303030303030303";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "03030303030303030303030303030303";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("0e040f70e9c93a76c02fa19bf19b9ccf", $answer);

# Set 3, vector#  04:
    $key = pack "H32", "04040404040404040404040404040404";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "04040404040404040404040404040404";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("90bee6d210452ef185ec908440d0d716", $answer);

# Set 3, vector#  05:
    $key = pack "H32", "05050505050505050505050505050505";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "05050505050505050505050505050505";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("b3836902a3dd98a3fad4bfd3b4d7fb8d", $answer);

# Set 3, vector#  06:
    $key = pack "H32", "06060606060606060606060606060606";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "06060606060606060606060606060606";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("d35a33352565a32deedf3d5a5e9973d5", $answer);

# Set 3, vector#  07:
    $key = pack "H32", "07070707070707070707070707070707";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "07070707070707070707070707070707";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("66e83582cefeecb9cd3c46432e550aca", $answer);

# Set 3, vector#  08:
    $key = pack "H32", "08080808080808080808080808080808";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "08080808080808080808080808080808";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("256c03e938b5532df5c7d3037edc4817", $answer);

# Set 3, vector#  09:
    $key = pack "H32", "09090909090909090909090909090909";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "09090909090909090909090909090909";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("cdecdcfb48d6af61cc3e3fafa9b9bfac", $answer);

# Set 3, vector#  10:
    $key = pack "H32", "0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("80265af501d712c1661c5e0cd94c3e9f", $answer);

# Set 3, vector#  11:
    $key = pack "H32", "0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("5a6c960e88ad9a140ed2539508b57d33", $answer);

# Set 3, vector#  12:
    $key = pack "H32", "0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("baca9f1e19205e6d037bf72c9629b9a4", $answer);

# Set 3, vector#  13:
    $key = pack "H32", "0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("c0aec696d880caf109719d5df81f8c15", $answer);

# Set 3, vector#  14:
    $key = pack "H32", "0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("b5bec399a1bdd5f85f85e56c1ca8641e", $answer);

# Set 3, vector#  15:
    $key = pack "H32", "0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("09e2a712e161fe1a32c38f64e33d863b", $answer);

# Set 3, vector#  16:
    $key = pack "H32", "10101010101010101010101010101010";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "10101010101010101010101010101010";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("f655d240425878594e67381fe2e05eb6", $answer);

# Set 3, vector#  17:
    $key = pack "H32", "11111111111111111111111111111111";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "11111111111111111111111111111111";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("50cadb9b6526c8db763ae4a7b8f5b225", $answer);

# Set 3, vector#  18:
    $key = pack "H32", "12121212121212121212121212121212";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "12121212121212121212121212121212";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("7a026308082c0ed858b3adfdf14488f2", $answer);

# Set 3, vector#  19:
    $key = pack "H32", "13131313131313131313131313131313";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "13131313131313131313131313131313";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("a9bc98f3b2269c55904e2c67879ecca0", $answer);

# Set 3, vector#  20:
    $key = pack "H32", "14141414141414141414141414141414";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "14141414141414141414141414141414";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("2a4ace46a5bb5c877e7ed10e979df688", $answer);

# Set 3, vector#  21:
    $key = pack "H32", "15151515151515151515151515151515";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "15151515151515151515151515151515";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("49cf3178617346894b153b8bd813b3ab", $answer);

# Set 3, vector#  22:
    $key = pack "H32", "16161616161616161616161616161616";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "16161616161616161616161616161616";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("03d9581e2e6f7420f3d8638a58e5c254", $answer);

# Set 3, vector#  23:
    $key = pack "H32", "17171717171717171717171717171717";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "17171717171717171717171717171717";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("06ced6115d9d5fc51adc517e0ccb6700", $answer);

# Set 3, vector#  24:
    $key = pack "H32", "18181818181818181818181818181818";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "18181818181818181818181818181818";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("fcf672d3c4c0ac796d64532f5ed12912", $answer);

# Set 3, vector#  25:
    $key = pack "H32", "19191919191919191919191919191919";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "19191919191919191919191919191919";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("ab7d5dc0072f533b03bd4c2734e9e3ea", $answer);

# Set 3, vector#  26:
    $key = pack "H32", "1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("a44fdca120eb70acb781bec26ee1dabc", $answer);

# Set 3, vector#  27:
    $key = pack "H32", "1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("49c4365ebff555ad8a8e9a3fde04cc88", $answer);

# Set 3, vector#  28:
    $key = pack "H32", "1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("566c37bf4aec4b678d1ff30812b8ac35", $answer);

# Set 3, vector#  29:
    $key = pack "H32", "1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("e2b1f1d767e6732c0465946c3bd6619f", $answer);

# Set 3, vector#  30:
    $key = pack "H32", "1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("24d635d549d777cd488e501e23b062fc", $answer);

# Set 3, vector#  31:
    $key = pack "H32", "1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("3c5f81ab4ae79aa65d8868f7a42a6c9f", $answer);

# Set 3, vector#  32:
    $key = pack "H32", "20202020202020202020202020202020";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "20202020202020202020202020202020";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("6fad0107a788aa7c7136e37acc04ef9f", $answer);

# Set 3, vector#  33:
    $key = pack "H32", "21212121212121212121212121212121";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "21212121212121212121212121212121";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("14ceaadc01ed91b571aeacb1ae52b3d3", $answer);

# Set 3, vector#  34:
    $key = pack "H32", "22222222222222222222222222222222";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "22222222222222222222222222222222";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("e0dc86ba284e620c72c6db8ec94f2949", $answer);

# Set 3, vector#  35:
    $key = pack "H32", "23232323232323232323232323232323";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "23232323232323232323232323232323";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("0db49e1900058a25c81224bd27339591", $answer);

# Set 3, vector#  36:
    $key = pack "H32", "24242424242424242424242424242424";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "24242424242424242424242424242424";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("e1335ffa2d74861f0b71c046d5407790", $answer);

# Set 3, vector#  37:
    $key = pack "H32", "25252525252525252525252525252525";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "25252525252525252525252525252525";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("8254114bce991c82028b4f3f1b263abb", $answer);

# Set 3, vector#  38:
    $key = pack "H32", "26262626262626262626262626262626";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "26262626262626262626262626262626";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("56a7fb16e3b9ba8181c130ff26db53f6", $answer);

# Set 3, vector#  39:
    $key = pack "H32", "27272727272727272727272727272727";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "27272727272727272727272727272727";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("9e1f737210ed5b96f6013cb30b99bb5c", $answer);

# Set 3, vector#  40:
    $key = pack "H32", "28282828282828282828282828282828";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "28282828282828282828282828282828";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("ba0293797046eb65199121443b8833fd", $answer);

# Set 3, vector#  41:
    $key = pack "H32", "29292929292929292929292929292929";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "29292929292929292929292929292929";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("7c20cd58988319a211c7e70e2bec4d27", $answer);

# Set 3, vector#  42:
    $key = pack "H32", "2a2a2a2a2a2a2a2a2a2a2a2a2a2a2a2a";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "2a2a2a2a2a2a2a2a2a2a2a2a2a2a2a2a";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("357d9d07f99cd32321a8cad6cc25d804", $answer);

# Set 3, vector#  43:
    $key = pack "H32", "2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("a972035cfb1e1abdaeac8d13bbf1139e", $answer);

# Set 3, vector#  44:
    $key = pack "H32", "2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("7e1d46c61e0fc72d0fedecffa6b5e803", $answer);

# Set 3, vector#  45:
    $key = pack "H32", "2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("10014901b3738b99ce8525b7d8e1559e", $answer);

# Set 3, vector#  46:
    $key = pack "H32", "2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("b1c782c9264785bbc9e96a210e02e495", $answer);

# Set 3, vector#  47:
    $key = pack "H32", "2f2f2f2f2f2f2f2f2f2f2f2f2f2f2f2f";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "2f2f2f2f2f2f2f2f2f2f2f2f2f2f2f2f";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("a095cb932edbbb884b7c6e833a637830", $answer);

# Set 3, vector#  48:
    $key = pack "H32", "30303030303030303030303030303030";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "30303030303030303030303030303030";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("f5ea053eb72dcdb9d0f763b2d6448bfe", $answer);

# Set 3, vector#  49:
    $key = pack "H32", "31313131313131313131313131313131";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "31313131313131313131313131313131";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("c06b200ede9f791ad1c811ace15e4322", $answer);

# Set 3, vector#  50:
    $key = pack "H32", "32323232323232323232323232323232";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "32323232323232323232323232323232";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("8891c2fbd34ecfaa84103dab05eca711", $answer);

# Set 3, vector#  51:
    $key = pack "H32", "33333333333333333333333333333333";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "33333333333333333333333333333333";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("fdbfba42add4af96970d008797dc30e6", $answer);

# Set 3, vector#  52:
    $key = pack "H32", "34343434343434343434343434343434";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "34343434343434343434343434343434";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("a81940dcd360bdf9c728e8b59ad34603", $answer);

# Set 3, vector#  53:
    $key = pack "H32", "35353535353535353535353535353535";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "35353535353535353535353535353535";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("81ab44ce7c04b96f11be5a90a34fb35a", $answer);

# Set 3, vector#  54:
    $key = pack "H32", "36363636363636363636363636363636";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "36363636363636363636363636363636";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("1fee394747847a9ee40736df2a284e92", $answer);

# Set 3, vector#  55:
    $key = pack "H32", "37373737373737373737373737373737";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "37373737373737373737373737373737";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("337f37e01968c90feaa3180d7145a334", $answer);

# Set 3, vector#  56:
    $key = pack "H32", "38383838383838383838383838383838";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "38383838383838383838383838383838";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("cfe4313ee81de6b2e370242796091777", $answer);

# Set 3, vector#  57:
    $key = pack "H32", "39393939393939393939393939393939";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "39393939393939393939393939393939";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("cc411b9bc866574f8db2e9658d77ca52", $answer);

# Set 3, vector#  58:
    $key = pack "H32", "3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("789203e31eda0d81a73af8cc719cdff5", $answer);

# Set 3, vector#  59:
    $key = pack "H32", "3b3b3b3b3b3b3b3b3b3b3b3b3b3b3b3b";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "3b3b3b3b3b3b3b3b3b3b3b3b3b3b3b3b";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("d11a25d4713d8643457b4111a5dc4fba", $answer);

# Set 3, vector#  60:
    $key = pack "H32", "3c3c3c3c3c3c3c3c3c3c3c3c3c3c3c3c";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "3c3c3c3c3c3c3c3c3c3c3c3c3c3c3c3c";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("d19fe2a7a1e9b6bd3d469a0956188fb3", $answer);

# Set 3, vector#  61:
    $key = pack "H32", "3d3d3d3d3d3d3d3d3d3d3d3d3d3d3d3d";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "3d3d3d3d3d3d3d3d3d3d3d3d3d3d3d3d";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("1506d46df1cc8deab006b290252b2213", $answer);

# Set 3, vector#  62:
    $key = pack "H32", "3e3e3e3e3e3e3e3e3e3e3e3e3e3e3e3e";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "3e3e3e3e3e3e3e3e3e3e3e3e3e3e3e3e";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("6c18a67b727cb488cbdf00d58a4b5c9c", $answer);

# Set 3, vector#  63:
    $key = pack "H32", "3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("8987299dc0707ba2c574e52299fb636c", $answer);

# Set 3, vector#  64:
    $key = pack "H32", "40404040404040404040404040404040";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "40404040404040404040404040404040";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("f6e29274ae83188c10c18c1615e112f2", $answer);

# Set 3, vector#  65:
    $key = pack "H32", "41414141414141414141414141414141";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "41414141414141414141414141414141";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("b49094ca887a78e5cc50106bc0265f03", $answer);

# Set 3, vector#  66:
    $key = pack "H32", "42424242424242424242424242424242";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "42424242424242424242424242424242";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("5a52c7f0568243707ab1be7bdc5e613d", $answer);

# Set 3, vector#  67:
    $key = pack "H32", "43434343434343434343434343434343";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "43434343434343434343434343434343";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("e39b321bca15ea94610284c0c4fa7675", $answer);

# Set 3, vector#  68:
    $key = pack "H32", "44444444444444444444444444444444";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "44444444444444444444444444444444";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("b6215e4d2f8ab7838af269fd2a1f6bbd", $answer);

# Set 3, vector#  69:
    $key = pack "H32", "45454545454545454545454545454545";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "45454545454545454545454545454545";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("eaf12cd5d9a751f66891bd69469fb35e", $answer);

# Set 3, vector#  70:
    $key = pack "H32", "46464646464646464646464646464646";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "46464646464646464646464646464646";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("1459184cd6d834c6b90d7da618e66c8e", $answer);

# Set 3, vector#  71:
    $key = pack "H32", "47474747474747474747474747474747";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "47474747474747474747474747474747";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("43a35c23b3085101f9d14c5f215912e8", $answer);

# Set 3, vector#  72:
    $key = pack "H32", "48484848484848484848484848484848";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "48484848484848484848484848484848";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("c7feeb00f8d6d29f1eaa26089460f6bd", $answer);

# Set 3, vector#  73:
    $key = pack "H32", "49494949494949494949494949494949";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "49494949494949494949494949494949";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("4400347996d4705bc62a7a6dbeb797c8", $answer);

# Set 3, vector#  74:
    $key = pack "H32", "4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("3d977fe96d81d159611d482b5dd46fd1", $answer);

# Set 3, vector#  75:
    $key = pack "H32", "4b4b4b4b4b4b4b4b4b4b4b4b4b4b4b4b";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "4b4b4b4b4b4b4b4b4b4b4b4b4b4b4b4b";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("03327f6b25f4b879eed12a87da399c0c", $answer);

# Set 3, vector#  76:
    $key = pack "H32", "4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("2ed15e3836f48c9af3406dbf67919b90", $answer);

# Set 3, vector#  77:
    $key = pack "H32", "4d4d4d4d4d4d4d4d4d4d4d4d4d4d4d4d";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "4d4d4d4d4d4d4d4d4d4d4d4d4d4d4d4d";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("0d5373efb1069acddb9d3222860ed38a", $answer);

# Set 3, vector#  78:
    $key = pack "H32", "4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("6605303624148a6dc821717d142ef04e", $answer);

# Set 3, vector#  79:
    $key = pack "H32", "4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("d668556680322bfba5ca609c74d030e2", $answer);

# Set 3, vector#  80:
    $key = pack "H32", "50505050505050505050505050505050";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "50505050505050505050505050505050";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("f6816e307947c86be06415124264ff14", $answer);

# Set 3, vector#  81:
    $key = pack "H32", "51515151515151515151515151515151";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "51515151515151515151515151515151";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("7ed2e66c06a36b701f751d0567d71657", $answer);

# Set 3, vector#  82:
    $key = pack "H32", "52525252525252525252525252525252";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "52525252525252525252525252525252";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("7d6c965ed064b25b6143c269d1a767f2", $answer);

# Set 3, vector#  83:
    $key = pack "H32", "53535353535353535353535353535353";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "53535353535353535353535353535353";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("ce0a3047ed1e46a42fb23c2c35cc4faa", $answer);

# Set 3, vector#  84:
    $key = pack "H32", "54545454545454545454545454545454";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "54545454545454545454545454545454";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("e40e3df2d849a028216a85520de9a32a", $answer);

# Set 3, vector#  85:
    $key = pack "H32", "55555555555555555555555555555555";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "55555555555555555555555555555555";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("03cfc689f99c524eccf44d16f716ae84", $answer);

# Set 3, vector#  86:
    $key = pack "H32", "56565656565656565656565656565656";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "56565656565656565656565656565656";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("c4112d87482cdeb18a198bf11bb2dafa", $answer);

# Set 3, vector#  87:
    $key = pack "H32", "57575757575757575757575757575757";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "57575757575757575757575757575757";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("4f5c21d0c85c94b200e40d75b0103f23", $answer);

# Set 3, vector#  88:
    $key = pack "H32", "58585858585858585858585858585858";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "58585858585858585858585858585858";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("a895a79bce7826bab4f84f8c430aef24", $answer);

# Set 3, vector#  89:
    $key = pack "H32", "59595959595959595959595959595959";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "59595959595959595959595959595959";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("bb23687b87b62185f81b5656342eeec0", $answer);

# Set 3, vector#  90:
    $key = pack "H32", "5a5a5a5a5a5a5a5a5a5a5a5a5a5a5a5a";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "5a5a5a5a5a5a5a5a5a5a5a5a5a5a5a5a";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("775762b3aaca23b5141a935189ffa08d", $answer);

# Set 3, vector#  91:
    $key = pack "H32", "5b5b5b5b5b5b5b5b5b5b5b5b5b5b5b5b";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "5b5b5b5b5b5b5b5b5b5b5b5b5b5b5b5b";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("968f7888d77e5c3df987836b35c81ff8", $answer);

# Set 3, vector#  92:
    $key = pack "H32", "5c5c5c5c5c5c5c5c5c5c5c5c5c5c5c5c";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "5c5c5c5c5c5c5c5c5c5c5c5c5c5c5c5c";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("0cca2962a9749fbcee5b8570947db37d", $answer);

# Set 3, vector#  93:
    $key = pack "H32", "5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("a5b8467b42e7d7f0885c11cc24cd8cd8", $answer);

# Set 3, vector#  94:
    $key = pack "H32", "5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("ea61df32364a7b6bdbcf1bfa3f35b677", $answer);

# Set 3, vector#  95:
    $key = pack "H32", "5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("b291a3bf3dacc15f8aac0e7d022b258b", $answer);

# Set 3, vector#  96:
    $key = pack "H32", "60606060606060606060606060606060";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "60606060606060606060606060606060";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("939e6d2bbd5676815ac1c0ae05d40be4", $answer);

# Set 3, vector#  97:
    $key = pack "H32", "61616161616161616161616161616161";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "61616161616161616161616161616161";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("917ef5a4cdfe4f721a6cdb8362e130f7", $answer);

# Set 3, vector#  98:
    $key = pack "H32", "62626262626262626262626262626262";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "62626262626262626262626262626262";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("e21a663161965b179387801da3e84eac", $answer);

# Set 3, vector#  99:
    $key = pack "H32", "63636363636363636363636363636363";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "63636363636363636363636363636363";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("d0efba0099a0cc711b55a760697b072b", $answer);

# Set 3, vector#  100:
    $key = pack "H32", "64646464646464646464646464646464";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "64646464646464646464646464646464";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("4ba8272e1a11c0d6e1c8ec173cd2f33f", $answer);

# Set 3, vector#  101:
    $key = pack "H32", "65656565656565656565656565656565";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "65656565656565656565656565656565";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("990a01df3b3738e62c3014de6a43ef8b", $answer);

# Set 3, vector#  102:
    $key = pack "H32", "66666666666666666666666666666666";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "66666666666666666666666666666666";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("1af278f475534174d2f952ca0856d938", $answer);

# Set 3, vector#  103:
    $key = pack "H32", "67676767676767676767676767676767";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "67676767676767676767676767676767";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("6341894da35c8397ba0134e8c8dd8f70", $answer);

# Set 3, vector#  104:
    $key = pack "H32", "68686868686868686868686868686868";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "68686868686868686868686868686868";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("6d3d0375a0ce6ce8eaa2a950b8d94565", $answer);

# Set 3, vector#  105:
    $key = pack "H32", "69696969696969696969696969696969";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "69696969696969696969696969696969";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("f6631e595c961add50e2566c59e577ab", $answer);

# Set 3, vector#  106:
    $key = pack "H32", "6a6a6a6a6a6a6a6a6a6a6a6a6a6a6a6a";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "6a6a6a6a6a6a6a6a6a6a6a6a6a6a6a6a";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("73a209a8dd6aa71bc4c65e38d7e1ade2", $answer);

# Set 3, vector#  107:
    $key = pack "H32", "6b6b6b6b6b6b6b6b6b6b6b6b6b6b6b6b";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "6b6b6b6b6b6b6b6b6b6b6b6b6b6b6b6b";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("215423cc1bcda3897302111d6318e26d", $answer);

# Set 3, vector#  108:
    $key = pack "H32", "6c6c6c6c6c6c6c6c6c6c6c6c6c6c6c6c";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "6c6c6c6c6c6c6c6c6c6c6c6c6c6c6c6c";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("d4587d1b31272ff2f7af10f84a01f261", $answer);

# Set 3, vector#  109:
    $key = pack "H32", "6d6d6d6d6d6d6d6d6d6d6d6d6d6d6d6d";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "6d6d6d6d6d6d6d6d6d6d6d6d6d6d6d6d";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("1031990f770599a5d2588185786302d4", $answer);

# Set 3, vector#  110:
    $key = pack "H32", "6e6e6e6e6e6e6e6e6e6e6e6e6e6e6e6e";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "6e6e6e6e6e6e6e6e6e6e6e6e6e6e6e6e";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("1e06ee82292558cf1ce7e7577b265bbc", $answer);

# Set 3, vector#  111:
    $key = pack "H32", "6f6f6f6f6f6f6f6f6f6f6f6f6f6f6f6f";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "6f6f6f6f6f6f6f6f6f6f6f6f6f6f6f6f";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("a273fa41a080dab64b4cbee14da2aef6", $answer);

# Set 3, vector#  112:
    $key = pack "H32", "70707070707070707070707070707070";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "70707070707070707070707070707070";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("ead97bf285eb6a6cc7ed201ca670e6ca", $answer);

# Set 3, vector#  113:
    $key = pack "H32", "71717171717171717171717171717171";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "71717171717171717171717171717171";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("6766b4833d1e75dd9ce542f590db09c3", $answer);

# Set 3, vector#  114:
    $key = pack "H32", "72727272727272727272727272727272";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "72727272727272727272727272727272";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("c05147b5d2b289e5d690711e9b61f324", $answer);

# Set 3, vector#  115:
    $key = pack "H32", "73737373737373737373737373737373";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "73737373737373737373737373737373";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("d3381db98dadb09f366a2f2f819b8307", $answer);

# Set 3, vector#  116:
    $key = pack "H32", "74747474747474747474747474747474";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "74747474747474747474747474747474";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("4adf77b29b10b527f7d3fb4bf6967e66", $answer);

# Set 3, vector#  117:
    $key = pack "H32", "75757575757575757575757575757575";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "75757575757575757575757575757575";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("f9f71fe91792d9273c44bd2cd32fc733", $answer);

# Set 3, vector#  118:
    $key = pack "H32", "76767676767676767676767676767676";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "76767676767676767676767676767676";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("a428ce20eeb472474b27b49b2122981e", $answer);

# Set 3, vector#  119:
    $key = pack "H32", "77777777777777777777777777777777";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "77777777777777777777777777777777";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("d6394a5cfc66c541847b6c5c18335ae6", $answer);

# Set 3, vector#  120:
    $key = pack "H32", "78787878787878787878787878787878";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "78787878787878787878787878787878";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("f6e0fcb78f14ce1c71920aae03c7a324", $answer);

# Set 3, vector#  121:
    $key = pack "H32", "79797979797979797979797979797979";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "79797979797979797979797979797979";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("e4e45e904785a87cccd5e57cc117cc5b", $answer);

# Set 3, vector#  122:
    $key = pack "H32", "7a7a7a7a7a7a7a7a7a7a7a7a7a7a7a7a";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "7a7a7a7a7a7a7a7a7a7a7a7a7a7a7a7a";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("67525d87cb80da766a07b41af0e812a5", $answer);

# Set 3, vector#  123:
    $key = pack "H32", "7b7b7b7b7b7b7b7b7b7b7b7b7b7b7b7b";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "7b7b7b7b7b7b7b7b7b7b7b7b7b7b7b7b";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("1f108599cdaac420ada467620614cff3", $answer);

# Set 3, vector#  124:
    $key = pack "H32", "7c7c7c7c7c7c7c7c7c7c7c7c7c7c7c7c";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "7c7c7c7c7c7c7c7c7c7c7c7c7c7c7c7c";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("b61588c08bc2dc40f5f2de207cd47ccc", $answer);

# Set 3, vector#  125:
    $key = pack "H32", "7d7d7d7d7d7d7d7d7d7d7d7d7d7d7d7d";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "7d7d7d7d7d7d7d7d7d7d7d7d7d7d7d7d";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("144430fd0f7be085a9491ee6dea5ef68", $answer);

# Set 3, vector#  126:
    $key = pack "H32", "7e7e7e7e7e7e7e7e7e7e7e7e7e7e7e7e";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "7e7e7e7e7e7e7e7e7e7e7e7e7e7e7e7e";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("acbb72f470e93eaa5bab54211c76dd9b", $answer);

# Set 3, vector#  127:
    $key = pack "H32", "7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("3385238adf6349f659afd0c98049d977", $answer);

# Set 3, vector#  128:
    $key = pack "H32", "80808080808080808080808080808080";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "80808080808080808080808080808080";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("781ad83cbb018d0d863290d51371088f", $answer);

# Set 3, vector#  129:
    $key = pack "H32", "81818181818181818181818181818181";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "81818181818181818181818181818181";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("20d70895b274d33ef9920aff71c2b51e", $answer);

# Set 3, vector#  130:
    $key = pack "H32", "82828282828282828282828282828282";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "82828282828282828282828282828282";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("94fcf84bc8718be165634ff3ddad92af", $answer);

# Set 3, vector#  131:
    $key = pack "H32", "83838383838383838383838383838383";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "83838383838383838383838383838383";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("f18254ee6e2d2d379f446a8f8a2990d6", $answer);

# Set 3, vector#  132:
    $key = pack "H32", "84848484848484848484848484848484";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "84848484848484848484848484848484";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("1e844e535a09824b3939709d444a4840", $answer);

# Set 3, vector#  133:
    $key = pack "H32", "85858585858585858585858585858585";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "85858585858585858585858585858585";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("8e80290415c631bd10569dd5cfb5ece3", $answer);

# Set 3, vector#  134:
    $key = pack "H32", "86868686868686868686868686868686";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "86868686868686868686868686868686";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("051c47e3d361db5e89fd3c37d02873c3", $answer);

# Set 3, vector#  135:
    $key = pack "H32", "87878787878787878787878787878787";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "87878787878787878787878787878787";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("f154242e815b4aa55f17bf45f4d6d448", $answer);

# Set 3, vector#  136:
    $key = pack "H32", "88888888888888888888888888888888";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "88888888888888888888888888888888";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("66b4e541853a443cc428fba56af94db7", $answer);

# Set 3, vector#  137:
    $key = pack "H32", "89898989898989898989898989898989";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "89898989898989898989898989898989";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("fa0b6f9a9f898389bd52db9be1b27e20", $answer);

# Set 3, vector#  138:
    $key = pack "H32", "8a8a8a8a8a8a8a8a8a8a8a8a8a8a8a8a";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "8a8a8a8a8a8a8a8a8a8a8a8a8a8a8a8a";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("03bfb987a0bd1b926bf36b2d2f17bb94", $answer);

# Set 3, vector#  139:
    $key = pack "H32", "8b8b8b8b8b8b8b8b8b8b8b8b8b8b8b8b";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "8b8b8b8b8b8b8b8b8b8b8b8b8b8b8b8b";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("2e265b52f4515ef58b85a575c46bda5d", $answer);

# Set 3, vector#  140:
    $key = pack "H32", "8c8c8c8c8c8c8c8c8c8c8c8c8c8c8c8c";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "8c8c8c8c8c8c8c8c8c8c8c8c8c8c8c8c";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("97c70a4de92fea7b20959bde0d73633e", $answer);

# Set 3, vector#  141:
    $key = pack "H32", "8d8d8d8d8d8d8d8d8d8d8d8d8d8d8d8d";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "8d8d8d8d8d8d8d8d8d8d8d8d8d8d8d8d";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("acd36f051c642ca50456c658ea3766d9", $answer);

# Set 3, vector#  142:
    $key = pack "H32", "8e8e8e8e8e8e8e8e8e8e8e8e8e8e8e8e";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "8e8e8e8e8e8e8e8e8e8e8e8e8e8e8e8e";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("d3a84ae919e98516e322576587455e74", $answer);

# Set 3, vector#  143:
    $key = pack "H32", "8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("dca515d07bda8d446adf66c048e65368", $answer);

# Set 3, vector#  144:
    $key = pack "H32", "90909090909090909090909090909090";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "90909090909090909090909090909090";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("dfcb66a57b4b29dcb0fa723391eb78f5", $answer);

# Set 3, vector#  145:
    $key = pack "H32", "91919191919191919191919191919191";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "91919191919191919191919191919191";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("afe81be31cfe62839cf848919b367ead", $answer);

# Set 3, vector#  146:
    $key = pack "H32", "92929292929292929292929292929292";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "92929292929292929292929292929292";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("76201386eede7e19cb5ed29e6d32ad2a", $answer);

# Set 3, vector#  147:
    $key = pack "H32", "93939393939393939393939393939393";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "93939393939393939393939393939393";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("da71de7d09949882c3f19d24b4299db7", $answer);

# Set 3, vector#  148:
    $key = pack "H32", "94949494949494949494949494949494";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "94949494949494949494949494949494";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("f4df0a4301a2edc293c266d5d41bc95e", $answer);

# Set 3, vector#  149:
    $key = pack "H32", "95959595959595959595959595959595";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "95959595959595959595959595959595";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("50707361e73c6eb6220962ce9afa000e", $answer);

# Set 3, vector#  150:
    $key = pack "H32", "96969696969696969696969696969696";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "96969696969696969696969696969696";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("c1056573fed79cf13e80c9a0ba83dbcd", $answer);

# Set 3, vector#  151:
    $key = pack "H32", "97979797979797979797979797979797";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "97979797979797979797979797979797";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("3cda1e7c975ac7ab2dce24a0a09333cc", $answer);

# Set 3, vector#  152:
    $key = pack "H32", "98989898989898989898989898989898";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "98989898989898989898989898989898";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("4c368a96480e08b44c6c1d6ab95d9bb9", $answer);

# Set 3, vector#  153:
    $key = pack "H32", "99999999999999999999999999999999";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "99999999999999999999999999999999";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("b05a6ac6b4b5e2c30eabf66d8f417c09", $answer);

# Set 3, vector#  154:
    $key = pack "H32", "9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("9143a83f99ff7b5b2f8198fd13ba1e81", $answer);

# Set 3, vector#  155:
    $key = pack "H32", "9b9b9b9b9b9b9b9b9b9b9b9b9b9b9b9b";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "9b9b9b9b9b9b9b9b9b9b9b9b9b9b9b9b";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("54a6cbfa91d557e89e2eac8bf58a2344", $answer);

# Set 3, vector#  156:
    $key = pack "H32", "9c9c9c9c9c9c9c9c9c9c9c9c9c9c9c9c";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "9c9c9c9c9c9c9c9c9c9c9c9c9c9c9c9c";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("ffba32df2cb8bf5ed9a596669a4cffe2", $answer);

# Set 3, vector#  157:
    $key = pack "H32", "9d9d9d9d9d9d9d9d9d9d9d9d9d9d9d9d";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "9d9d9d9d9d9d9d9d9d9d9d9d9d9d9d9d";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("11dbc1e701c20c0c7a5788f3391557a2", $answer);

# Set 3, vector#  158:
    $key = pack "H32", "9e9e9e9e9e9e9e9e9e9e9e9e9e9e9e9e";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "9e9e9e9e9e9e9e9e9e9e9e9e9e9e9e9e";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("6382991dd92cc29c99d801bddb4ca6c3", $answer);

# Set 3, vector#  159:
    $key = pack "H32", "9f9f9f9f9f9f9f9f9f9f9f9f9f9f9f9f";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "9f9f9f9f9f9f9f9f9f9f9f9f9f9f9f9f";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("275f42d7eb88ccc61a736100475fabad", $answer);

# Set 3, vector#  160:
    $key = pack "H32", "a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("2fba29dbd0702592cf1b563d8a08bef0", $answer);

# Set 3, vector#  161:
    $key = pack "H32", "a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("8f8591652d3d36450087a9b3cf0d63a1", $answer);

# Set 3, vector#  162:
    $key = pack "H32", "a2a2a2a2a2a2a2a2a2a2a2a2a2a2a2a2";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "a2a2a2a2a2a2a2a2a2a2a2a2a2a2a2a2";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("430138b7dc2bd7e3bd784743ea3d4e0e", $answer);

# Set 3, vector#  163:
    $key = pack "H32", "a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("c3a9ef47b1048979927c26431aec0e9f", $answer);

# Set 3, vector#  164:
    $key = pack "H32", "a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("4ceda5a0d0963dd49ba1fecddf70e71c", $answer);

# Set 3, vector#  165:
    $key = pack "H32", "a5a5a5a5a5a5a5a5a5a5a5a5a5a5a5a5";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "a5a5a5a5a5a5a5a5a5a5a5a5a5a5a5a5";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("4d355c0445d4b0ae29d229dfa7fb9247", $answer);

# Set 3, vector#  166:
    $key = pack "H32", "a6a6a6a6a6a6a6a6a6a6a6a6a6a6a6a6";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "a6a6a6a6a6a6a6a6a6a6a6a6a6a6a6a6";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("8c448212dd1c4bb85d77410b2677670e", $answer);

# Set 3, vector#  167:
    $key = pack "H32", "a7a7a7a7a7a7a7a7a7a7a7a7a7a7a7a7";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "a7a7a7a7a7a7a7a7a7a7a7a7a7a7a7a7";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("ee454350af5075159a288f689f192b91", $answer);

# Set 3, vector#  168:
    $key = pack "H32", "a8a8a8a8a8a8a8a8a8a8a8a8a8a8a8a8";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "a8a8a8a8a8a8a8a8a8a8a8a8a8a8a8a8";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("cbcbcfbd50dcce84436b9775fec5b3fe", $answer);

# Set 3, vector#  169:
    $key = pack "H32", "a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("24a57885c052fc11b24d3fe98c33b9f8", $answer);

# Set 3, vector#  170:
    $key = pack "H32", "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("d2af9ac1d7d9e88ec804522ca5b28da0", $answer);

# Set 3, vector#  171:
    $key = pack "H32", "abababababababababababababababab";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "abababababababababababababababab";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("49f393bd13b37d91a8fe68b0d12828e5", $answer);

# Set 3, vector#  172:
    $key = pack "H32", "acacacacacacacacacacacacacacacac";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "acacacacacacacacacacacacacacacac";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("dc8833ece1d4f6a6a07d8671e9c32c37", $answer);

# Set 3, vector#  173:
    $key = pack "H32", "adadadadadadadadadadadadadadadad";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "adadadadadadadadadadadadadadadad";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("1f39617599ee17ba7ab7675210aafe7f", $answer);

# Set 3, vector#  174:
    $key = pack "H32", "aeaeaeaeaeaeaeaeaeaeaeaeaeaeaeae";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "aeaeaeaeaeaeaeaeaeaeaeaeaeaeaeae";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("cb421ada21ef5487400614c0ccd2a401", $answer);

# Set 3, vector#  175:
    $key = pack "H32", "afafafafafafafafafafafafafafafaf";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "afafafafafafafafafafafafafafafaf";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("2eb4010cd7969bdd302e47d5ce018450", $answer);

# Set 3, vector#  176:
    $key = pack "H32", "b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("8c21d27b466787dd0302fcc360e10c85", $answer);

# Set 3, vector#  177:
    $key = pack "H32", "b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("d261e89e94baa644f1cfcd74093f3fba", $answer);

# Set 3, vector#  178:
    $key = pack "H32", "b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("40b8974aa53d28f11a8da300438bbfaf", $answer);

# Set 3, vector#  179:
    $key = pack "H32", "b3b3b3b3b3b3b3b3b3b3b3b3b3b3b3b3";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "b3b3b3b3b3b3b3b3b3b3b3b3b3b3b3b3";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("08d45754d27f1cdd8a9d6d7a8ae6c4ef", $answer);

# Set 3, vector#  180:
    $key = pack "H32", "b4b4b4b4b4b4b4b4b4b4b4b4b4b4b4b4";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "b4b4b4b4b4b4b4b4b4b4b4b4b4b4b4b4";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("5ed78b25b3e4031a50dfb2d1067c9343", $answer);

# Set 3, vector#  181:
    $key = pack "H32", "b5b5b5b5b5b5b5b5b5b5b5b5b5b5b5b5";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "b5b5b5b5b5b5b5b5b5b5b5b5b5b5b5b5";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("df55d33bfda28de02b673972e2774102", $answer);

# Set 3, vector#  182:
    $key = pack "H32", "b6b6b6b6b6b6b6b6b6b6b6b6b6b6b6b6";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "b6b6b6b6b6b6b6b6b6b6b6b6b6b6b6b6";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("647635dcb73b36deb8950d00e1b3651d", $answer);

# Set 3, vector#  183:
    $key = pack "H32", "b7b7b7b7b7b7b7b7b7b7b7b7b7b7b7b7";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "b7b7b7b7b7b7b7b7b7b7b7b7b7b7b7b7";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("49109c8e1fa26f55c72460022da7f124", $answer);

# Set 3, vector#  184:
    $key = pack "H32", "b8b8b8b8b8b8b8b8b8b8b8b8b8b8b8b8";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "b8b8b8b8b8b8b8b8b8b8b8b8b8b8b8b8";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("23fa5398fc30fa5a901c00bd9d670316", $answer);

# Set 3, vector#  185:
    $key = pack "H32", "b9b9b9b9b9b9b9b9b9b9b9b9b9b9b9b9";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "b9b9b9b9b9b9b9b9b9b9b9b9b9b9b9b9";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("61533ce09a3eca032485077c89394c7b", $answer);

# Set 3, vector#  186:
    $key = pack "H32", "babababababababababababababababa";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "babababababababababababababababa";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("0f6b009ff29aabcab196091fce5e9416", $answer);

# Set 3, vector#  187:
    $key = pack "H32", "bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("62da100c184977cfd562ed2cbd4af939", $answer);

# Set 3, vector#  188:
    $key = pack "H32", "bcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbc";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "bcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbc";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("c99ba84264a533c2f97dbe7b0d7f4d34", $answer);

# Set 3, vector#  189:
    $key = pack "H32", "bdbdbdbdbdbdbdbdbdbdbdbdbdbdbdbd";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "bdbdbdbdbdbdbdbdbdbdbdbdbdbdbdbd";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("d4216b37fb9302253637b538541a0962", $answer);

# Set 3, vector#  190:
    $key = pack "H32", "bebebebebebebebebebebebebebebebe";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "bebebebebebebebebebebebebebebebe";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("e3be3609bb61e2b7b8b59a2ec501ce30", $answer);

# Set 3, vector#  191:
    $key = pack "H32", "bfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbf";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "bfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbf";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("2d68795b033c6afded5db1d35381143f", $answer);

# Set 3, vector#  192:
    $key = pack "H32", "c0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c0";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "c0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c0";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("cc0d2c94e46bb6a541cebe0e2d6d8641", $answer);

# Set 3, vector#  193:
    $key = pack "H32", "c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("7fbca57d61ad6f43581a1f891ec24ebd", $answer);

# Set 3, vector#  194:
    $key = pack "H32", "c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("ecb5358535ec98fb7c16bafd5aa7c75a", $answer);

# Set 3, vector#  195:
    $key = pack "H32", "c3c3c3c3c3c3c3c3c3c3c3c3c3c3c3c3";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "c3c3c3c3c3c3c3c3c3c3c3c3c3c3c3c3";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("54f1b40f841da0abc229fa8520506fd4", $answer);

# Set 3, vector#  196:
    $key = pack "H32", "c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("88d21d6a69db734c38e3f0d97f6d86ed", $answer);

# Set 3, vector#  197:
    $key = pack "H32", "c5c5c5c5c5c5c5c5c5c5c5c5c5c5c5c5";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "c5c5c5c5c5c5c5c5c5c5c5c5c5c5c5c5";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("2fac93f651e1c7f2397a26102112b48b", $answer);

# Set 3, vector#  198:
    $key = pack "H32", "c6c6c6c6c6c6c6c6c6c6c6c6c6c6c6c6";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "c6c6c6c6c6c6c6c6c6c6c6c6c6c6c6c6";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("b9f28667456806a8253957bd034143e5", $answer);

# Set 3, vector#  199:
    $key = pack "H32", "c7c7c7c7c7c7c7c7c7c7c7c7c7c7c7c7";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "c7c7c7c7c7c7c7c7c7c7c7c7c7c7c7c7";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("c337525512b54050e632c66adb186833", $answer);

# Set 3, vector#  200:
    $key = pack "H32", "c8c8c8c8c8c8c8c8c8c8c8c8c8c8c8c8";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "c8c8c8c8c8c8c8c8c8c8c8c8c8c8c8c8";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("e6800aaa8e8d00bfb298784377e8d23b", $answer);

# Set 3, vector#  201:
    $key = pack "H32", "c9c9c9c9c9c9c9c9c9c9c9c9c9c9c9c9";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "c9c9c9c9c9c9c9c9c9c9c9c9c9c9c9c9";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("1e35df8bbf3b87af166d0bbb854fe54d", $answer);

# Set 3, vector#  202:
    $key = pack "H32", "cacacacacacacacacacacacacacacaca";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "cacacacacacacacacacacacacacacaca";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("f44fd6d1ee4ab6d2986800cfe130dee0", $answer);

# Set 3, vector#  203:
    $key = pack "H32", "cbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcb";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "cbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcb";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("dfbd5298f8b839ebff31a58a212173e4", $answer);

# Set 3, vector#  204:
    $key = pack "H32", "cccccccccccccccccccccccccccccccc";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "cccccccccccccccccccccccccccccccc";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("c8ccb143ca6040e3c3f3048c3ffd68c7", $answer);

# Set 3, vector#  205:
    $key = pack "H32", "cdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcd";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "cdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcd";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("9561ea8ae86f71032eb4ac5cd76fc655", $answer);

# Set 3, vector#  206:
    $key = pack "H32", "cececececececececececececececece";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "cececececececececececececececece";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("e1891e08287006098abcc53d12c798a8", $answer);

# Set 3, vector#  207:
    $key = pack "H32", "cfcfcfcfcfcfcfcfcfcfcfcfcfcfcfcf";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "cfcfcfcfcfcfcfcfcfcfcfcfcfcfcfcf";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("8b3b747ba177d5bd91f413bf4f05b377", $answer);

# Set 3, vector#  208:
    $key = pack "H32", "d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("461a055f11188ed78ee7beaecd53fd29", $answer);

# Set 3, vector#  209:
    $key = pack "H32", "d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("b63fe78e42b6d465d64e2d3663d5f101", $answer);

# Set 3, vector#  210:
    $key = pack "H32", "d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("6db1b1f352a204f38ff6b88e6db4896c", $answer);

# Set 3, vector#  211:
    $key = pack "H32", "d3d3d3d3d3d3d3d3d3d3d3d3d3d3d3d3";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "d3d3d3d3d3d3d3d3d3d3d3d3d3d3d3d3";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("67f4ffdc5d87d5ca3e089f370425f3d9", $answer);

# Set 3, vector#  212:
    $key = pack "H32", "d4d4d4d4d4d4d4d4d4d4d4d4d4d4d4d4";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "d4d4d4d4d4d4d4d4d4d4d4d4d4d4d4d4";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("9b89539b252fa833a3d13ff825fa6358", $answer);

# Set 3, vector#  213:
    $key = pack "H32", "d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("f1d8a7f3635b23a9bdf29c1b1ef21382", $answer);

# Set 3, vector#  214:
    $key = pack "H32", "d6d6d6d6d6d6d6d6d6d6d6d6d6d6d6d6";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "d6d6d6d6d6d6d6d6d6d6d6d6d6d6d6d6";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("0bd990f4f25b57f2048d6850bf700e92", $answer);

# Set 3, vector#  215:
    $key = pack "H32", "d7d7d7d7d7d7d7d7d7d7d7d7d7d7d7d7";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "d7d7d7d7d7d7d7d7d7d7d7d7d7d7d7d7";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("93eac1b05448f2f8aeb999b34387cf12", $answer);

# Set 3, vector#  216:
    $key = pack "H32", "d8d8d8d8d8d8d8d8d8d8d8d8d8d8d8d8";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "d8d8d8d8d8d8d8d8d8d8d8d8d8d8d8d8";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("4b245d3e73d0ffd6ba9812ba2dcd4365", $answer);

# Set 3, vector#  217:
    $key = pack "H32", "d9d9d9d9d9d9d9d9d9d9d9d9d9d9d9d9";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "d9d9d9d9d9d9d9d9d9d9d9d9d9d9d9d9";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("14359542c70e1718d232e96d6333ddee", $answer);

# Set 3, vector#  218:
    $key = pack "H32", "dadadadadadadadadadadadadadadada";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "dadadadadadadadadadadadadadadada";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("b61622c1441542d7725aa6f6bbc1d7a1", $answer);

# Set 3, vector#  219:
    $key = pack "H32", "dbdbdbdbdbdbdbdbdbdbdbdbdbdbdbdb";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "dbdbdbdbdbdbdbdbdbdbdbdbdbdbdbdb";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("77ac059e0b4527c303a9dbc151c0acfc", $answer);

# Set 3, vector#  220:
    $key = pack "H32", "dcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdc";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "dcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdc";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("1ac94639bf4a99a7a12356c6758e7910", $answer);

# Set 3, vector#  221:
    $key = pack "H32", "dddddddddddddddddddddddddddddddd";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "dddddddddddddddddddddddddddddddd";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("f8acce5cba00bef598e5b01e1d5c2dcc", $answer);

# Set 3, vector#  222:
    $key = pack "H32", "dededededededededededededededede";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "dededededededededededededededede";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("57c340c1025dc5534f2ea5dea5d80b0b", $answer);

# Set 3, vector#  223:
    $key = pack "H32", "dfdfdfdfdfdfdfdfdfdfdfdfdfdfdfdf";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "dfdfdfdfdfdfdfdfdfdfdfdfdfdfdfdf";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("9af7f91799ab1114a3bf901eb0e304dd", $answer);

# Set 3, vector#  224:
    $key = pack "H32", "e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("d93988102e450b069fe11c4895d021ea", $answer);

# Set 3, vector#  225:
    $key = pack "H32", "e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("42f38fd7c54ce79f987e8e74e71454fb", $answer);

# Set 3, vector#  226:
    $key = pack "H32", "e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("71e93a1d54d8e233d3ea503fe4df613f", $answer);

# Set 3, vector#  227:
    $key = pack "H32", "e3e3e3e3e3e3e3e3e3e3e3e3e3e3e3e3";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "e3e3e3e3e3e3e3e3e3e3e3e3e3e3e3e3";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("12ef48bb9e4da7b5dd9c2e4d485c00e7", $answer);

# Set 3, vector#  228:
    $key = pack "H32", "e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("90b1b48dc9fefcb409efd9f29fec1689", $answer);

# Set 3, vector#  229:
    $key = pack "H32", "e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("74bb1d011a8d8227f3e6744aedfc9aef", $answer);

# Set 3, vector#  230:
    $key = pack "H32", "e6e6e6e6e6e6e6e6e6e6e6e6e6e6e6e6";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "e6e6e6e6e6e6e6e6e6e6e6e6e6e6e6e6";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("bc8fad20468a3b1821ee541426a5eff2", $answer);

# Set 3, vector#  231:
    $key = pack "H32", "e7e7e7e7e7e7e7e7e7e7e7e7e7e7e7e7";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "e7e7e7e7e7e7e7e7e7e7e7e7e7e7e7e7";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("0469d30283f9251d839a025033df6099", $answer);

# Set 3, vector#  232:
    $key = pack "H32", "e8e8e8e8e8e8e8e8e8e8e8e8e8e8e8e8";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "e8e8e8e8e8e8e8e8e8e8e8e8e8e8e8e8";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("1256e2ed82d53de27df1953965fe26bf", $answer);

# Set 3, vector#  233:
    $key = pack "H32", "e9e9e9e9e9e9e9e9e9e9e9e9e9e9e9e9";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "e9e9e9e9e9e9e9e9e9e9e9e9e9e9e9e9";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("0fa2ed27996234ba37ed18e1fb30d2b8", $answer);

# Set 3, vector#  234:
    $key = pack "H32", "eaeaeaeaeaeaeaeaeaeaeaeaeaeaeaea";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "eaeaeaeaeaeaeaeaeaeaeaeaeaeaeaea";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("ac642cc11dd2db28268e0b3f21506f3f", $answer);

# Set 3, vector#  235:
    $key = pack "H32", "ebebebebebebebebebebebebebebebeb";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "ebebebebebebebebebebebebebebebeb";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("fc4621f93e489e8328c7bde9c1008c0e", $answer);

# Set 3, vector#  236:
    $key = pack "H32", "ecececececececececececececececec";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "ecececececececececececececececec";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("b8ccda0ddb56e19c14eb69c18487b04c", $answer);

# Set 3, vector#  237:
    $key = pack "H32", "edededededededededededededededed";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "edededededededededededededededed";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("383c164dd7b05f1f3fa2e0d45dfcf3e4", $answer);

# Set 3, vector#  238:
    $key = pack "H32", "eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("c9859d87b376fb6fc4c72a5a173681ab", $answer);

# Set 3, vector#  239:
    $key = pack "H32", "efefefefefefefefefefefefefefefef";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "efefefefefefefefefefefefefefefef";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("d4b5bccbe1d606b9927037e0d9649a11", $answer);

# Set 3, vector#  240:
    $key = pack "H32", "f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("64dc45e6c6b42a4b6127d3e7e10d6859", $answer);

# Set 3, vector#  241:
    $key = pack "H32", "f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("76799bfb26c3cc228b169125cd563947", $answer);

# Set 3, vector#  242:
    $key = pack "H32", "f2f2f2f2f2f2f2f2f2f2f2f2f2f2f2f2";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "f2f2f2f2f2f2f2f2f2f2f2f2f2f2f2f2";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("dae0ee6878dfc0589ed1665cd176cb86", $answer);

# Set 3, vector#  243:
    $key = pack "H32", "f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("279e9fbaab18a4fd5eb4827580718f19", $answer);

# Set 3, vector#  244:
    $key = pack "H32", "f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("cb213296f9caf60a56aa31f057feb2d2", $answer);

# Set 3, vector#  245:
    $key = pack "H32", "f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("fef2b16c3687a9dc6911ef3b700a4d2e", $answer);

# Set 3, vector#  246:
    $key = pack "H32", "f6f6f6f6f6f6f6f6f6f6f6f6f6f6f6f6";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "f6f6f6f6f6f6f6f6f6f6f6f6f6f6f6f6";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("7c9945109222fd0fd865c6b3eff5c93e", $answer);

# Set 3, vector#  247:
    $key = pack "H32", "f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("2daeed82a8d7a38cad24b186fcae5a2d", $answer);

# Set 3, vector#  248:
    $key = pack "H32", "f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("c8baa93bd0d5725f1f67d9e26c3e79ce", $answer);

# Set 3, vector#  249:
    $key = pack "H32", "f9f9f9f9f9f9f9f9f9f9f9f9f9f9f9f9";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "f9f9f9f9f9f9f9f9f9f9f9f9f9f9f9f9";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("dca5a31e7772c669ff8a35b865932ede", $answer);

# Set 3, vector#  250:
    $key = pack "H32", "fafafafafafafafafafafafafafafafa";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "fafafafafafafafafafafafafafafafa";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("3e1abbe354f62e1be5d9bd0599f5b2ed", $answer);

# Set 3, vector#  251:
    $key = pack "H32", "fbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfb";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "fbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfb";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("41d56a158893b1a5fe7d355090dbe924", $answer);

# Set 3, vector#  252:
    $key = pack "H32", "fcfcfcfcfcfcfcfcfcfcfcfcfcfcfcfc";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "fcfcfcfcfcfcfcfcfcfcfcfcfcfcfcfc";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("cbee419760f1db34d553208a18416a85", $answer);

# Set 3, vector#  253:
    $key = pack "H32", "fdfdfdfdfdfdfdfdfdfdfdfdfdfdfdfd";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "fdfdfdfdfdfdfdfdfdfdfdfdfdfdfdfd";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("5c78e97ecaea5003ec59a9295da3dda9", $answer);

# Set 3, vector#  254:
    $key = pack "H32", "fefefefefefefefefefefefefefefefe";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "fefefefefefefefefefefefefefefefe";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("6dc5daa2267d626f08b7528e6e6e8690", $answer);

# Set 3, vector#  255:
    $key = pack "H32", "ffffffffffffffffffffffffffffffff";
    $cipher = new Crypt::Anubis $key;
    $plaintext = pack "H32", "ffffffffffffffffffffffffffffffff";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("65b4ce4647be798fc4390d2bcf43bf99", $answer);

};
