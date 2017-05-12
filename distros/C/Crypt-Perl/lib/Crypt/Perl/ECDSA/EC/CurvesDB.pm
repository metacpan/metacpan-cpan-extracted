package Crypt::Perl::ECDSA::EC::CurvesDB;

use strict;
use warnings;

# Extracted from:
# OpenSSL 1.0.2k  26 Jan 2017
# options:  bn(64,64) rc4(ptr,int) des(idx,cisc,16,int) idea(int) blowfish(idx) 
# compiler: /usr/bin/clang -I. -I.. -I../include  -fPIC -fno-common -DOPENSSL_PIC -DZLIB -DOPENSSL_THREADS -D_REENTRANT -DDSO_DLFCN -DHAVE_DLFCN_H -arch x86_64 -O3 -DL_ENDIAN -Wall -DOPENSSL_IA32_SSE2 -DOPENSSL_BN_ASM_MONT -DOPENSSL_BN_ASM_MONT5 -DOPENSSL_BN_ASM_GF2m -DSHA1_ASM -DSHA256_ASM -DSHA512_ASM -DMD5_ASM -DAES_ASM -DVPAES_ASM -DBSAES_ASM -DWHIRLPOOL_ASM -DGHASH_ASM -DECP_NISTZ256_ASM
#----------------------------------------------------------------------
use constant OID_secp112r1 => '1.3.132.0.6';

use constant CURVE_1_3_132_0_6 => (
    'db7c2abf62e35e668076bead208b', # p / prime
    'db7c2abf62e35e668076bead2088', # a
    '659ef8ba043916eede8911702b22', # b
    'db7c2abf62e35e7628dfac6561c5', # n / order
    '9487239995a5ee76b55f9c2f098', # gx / generator-x
    'a89ce5af8724c0a23e0e0ff77500', # gy / generator-y
    '1', # h / cofactor
    'f50b028e4d696e676875615175290472783fb1', # seed
);

#----------------------------------------------------------------------
use constant OID_secp112r2 => '1.3.132.0.7';

use constant CURVE_1_3_132_0_7 => (
    'db7c2abf62e35e668076bead208b', # p / prime
    '6127c24c05f38a0aaaf65c0ef02c', # a
    '51def1815db5ed74fcc34c85d709', # b
    '36df0aafd8b8d7597ca10520d04b', # n / order
    '4ba30ab5e892b4e1649dd0928643', # gx / generator-x
    'adcd46f5882e3747def36e956e97', # gy / generator-y
    '4', # h / cofactor
    '2757a1114d696e6768756151755316c05e0bd4', # seed
);

#----------------------------------------------------------------------
use constant OID_secp128r1 => '1.3.132.0.28';

use constant CURVE_1_3_132_0_28 => (
    'fffffffdffffffffffffffffffffffff', # p / prime
    'fffffffdfffffffffffffffffffffffc', # a
    'e87579c11079f43dd824993c2cee5ed3', # b
    'fffffffe0000000075a30d1b9038a115', # n / order
    '161ff7528b899b2d0c28607ca52c5b86', # gx / generator-x
    'cf5ac8395bafeb13c02da292dded7a83', # gy / generator-y
    '1', # h / cofactor
    'e0d4d696e6768756151750cc03a4473d03679', # seed
);

#----------------------------------------------------------------------
use constant OID_secp128r2 => '1.3.132.0.29';

use constant CURVE_1_3_132_0_29 => (
    'fffffffdffffffffffffffffffffffff', # p / prime
    'd6031998d1b3bbfebf59cc9bbff9aee1', # a
    '5eeefca380d02919dc2c6558bb6d8a5d', # b
    '3fffffff7fffffffbe0024720613b5a3', # n / order
    '7b6aa5d85e572983e6fb32a7cdebc140', # gx / generator-x
    '27b6916a894d3aee7106fe805fc34b44', # gy / generator-y
    '4', # h / cofactor
    '4d696e67687561517512d8f03431fce63b88f4', # seed
);

#----------------------------------------------------------------------
use constant OID_secp160k1 => '1.3.132.0.9';

use constant CURVE_1_3_132_0_9 => (
    'fffffffffffffffffffffffffffffffeffffac73', # p / prime
    '0', # a
    '7', # b
    '100000000000000000001b8fa16dfab9aca16b6b3', # n / order
    '3b4c382ce37aa192a4019e763036f4f5dd4d7ebb', # gx / generator-x
    '938cf935318fdced6bc28286531733c3f03c4fee', # gy / generator-y
    '1', # h / cofactor
    '', # seed
);

#----------------------------------------------------------------------
use constant OID_secp160r1 => '1.3.132.0.8';

use constant CURVE_1_3_132_0_8 => (
    'ffffffffffffffffffffffffffffffff7fffffff', # p / prime
    'ffffffffffffffffffffffffffffffff7ffffffc', # a
    '1c97befc54bd7a8b65acf89f81d4d4adc565fa45', # b
    '100000000000000000001f4c8f927aed3ca752257', # n / order
    '4a96b5688ef573284664698968c38bb913cbfc82', # gx / generator-x
    '23a628553168947d59dcc912042351377ac5fb32', # gy / generator-y
    '1', # h / cofactor
    '1053cde42c14d696e67687561517533bf3f83345', # seed
);

#----------------------------------------------------------------------
use constant OID_secp160r2 => '1.3.132.0.30';

use constant CURVE_1_3_132_0_30 => (
    'fffffffffffffffffffffffffffffffeffffac73', # p / prime
    'fffffffffffffffffffffffffffffffeffffac70', # a
    'b4e134d3fb59eb8bab57274904664d5af50388ba', # b
    '100000000000000000000351ee786a818f3a1a16b', # n / order
    '52dcb034293a117e1f4ff11b30f7199d3144ce6d', # gx / generator-x
    'feaffef2e331f296e071fa0df9982cfea7d43f2e', # gy / generator-y
    '1', # h / cofactor
    'b99b99b099b323e02709a4d696e6768756151751', # seed
);

#----------------------------------------------------------------------
use constant OID_secp192k1 => '1.3.132.0.31';

use constant CURVE_1_3_132_0_31 => (
    'fffffffffffffffffffffffffffffffffffffffeffffee37', # p / prime
    '0', # a
    '3', # b
    'fffffffffffffffffffffffe26f2fc170f69466a74defd8d', # n / order
    'db4ff10ec057e9ae26b07d0280b7f4341da5d1b1eae06c7d', # gx / generator-x
    '9b2f2f6d9c5628a7844163d015be86344082aa88d95e2f9d', # gy / generator-y
    '1', # h / cofactor
    '', # seed
);

#----------------------------------------------------------------------
use constant OID_secp224k1 => '1.3.132.0.32';

use constant CURVE_1_3_132_0_32 => (
    'fffffffffffffffffffffffffffffffffffffffffffffffeffffe56d', # p / prime
    '0', # a
    '5', # b
    '10000000000000000000000000001dce8d2ec6184caf0a971769fb1f7', # n / order
    'a1455b334df099df30fc28a169a467e9e47075a90f7e650eb6b7a45c', # gx / generator-x
    '7e089fed7fba344282cafbd6f7e319f7c0b0bd59e2ca4bdb556d61a5', # gy / generator-y
    '1', # h / cofactor
    '', # seed
);

#----------------------------------------------------------------------
use constant OID_secp224r1 => '1.3.132.0.33';

use constant CURVE_1_3_132_0_33 => (
    'ffffffffffffffffffffffffffffffff000000000000000000000001', # p / prime
    'fffffffffffffffffffffffffffffffefffffffffffffffffffffffe', # a
    'b4050a850c04b3abf54132565044b0b7d7bfd8ba270b39432355ffb4', # b
    'ffffffffffffffffffffffffffff16a2e0b8f03e13dd29455c5c2a3d', # n / order
    'b70e0cbd6bb4bf7f321390b94a03c1d356c21122343280d6115c1d21', # gx / generator-x
    'bd376388b5f723fb4c22dfe6cd4375a05a07476444d5819985007e34', # gy / generator-y
    '1', # h / cofactor
    'bd71344799d5c7fcdc45b59fa3b9ab8f6a948bc5', # seed
);

#----------------------------------------------------------------------
use constant OID_secp256k1 => '1.3.132.0.10';

use constant CURVE_1_3_132_0_10 => (
    'fffffffffffffffffffffffffffffffffffffffffffffffffffffffefffffc2f', # p / prime
    '0', # a
    '7', # b
    'fffffffffffffffffffffffffffffffebaaedce6af48a03bbfd25e8cd0364141', # n / order
    '79be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798', # gx / generator-x
    '483ada7726a3c4655da4fbfc0e1108a8fd17b448a68554199c47d08ffb10d4b8', # gy / generator-y
    '1', # h / cofactor
    '', # seed
);

#----------------------------------------------------------------------
use constant OID_secp384r1 => '1.3.132.0.34';

use constant CURVE_1_3_132_0_34 => (
    'fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffeffffffff0000000000000000ffffffff', # p / prime
    'fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffeffffffff0000000000000000fffffffc', # a
    'b3312fa7e23ee7e4988e056be3f82d19181d9c6efe8141120314088f5013875ac656398d8a2ed19d2a85c8edd3ec2aef', # b
    'ffffffffffffffffffffffffffffffffffffffffffffffffc7634d81f4372ddf581a0db248b0a77aecec196accc52973', # n / order
    'aa87ca22be8b05378eb1c71ef320ad746e1d3b628ba79b9859f741e082542a385502f25dbf55296c3a545e3872760ab7', # gx / generator-x
    '3617de4a96262c6f5d9e98bf9292dc29f8f41dbd289a147ce9da3113b5f0b8c00a60b1ce1d7e819d7a431d7c90ea0e5f', # gy / generator-y
    '1', # h / cofactor
    'a335926aa319a27a1d00896a6773a4827acdac73', # seed
);

#----------------------------------------------------------------------
use constant OID_secp521r1 => '1.3.132.0.35';

use constant CURVE_1_3_132_0_35 => (
    '1ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff', # p / prime
    '1fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc', # a
    '51953eb9618e1c9a1f929a21a0b68540eea2da725b99b315f3b8b489918ef109e156193951ec7e937b1652c0bd3bb1bf073573df883d2c34f1ef451fd46b503f00', # b
    '1fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffa51868783bf2f966b7fcc0148f709a5d03bb5c9b8899c47aebb6fb71e91386409', # n / order
    'c6858e06b70404e9cd9e3ecb662395b4429c648139053fb521f828af606b4d3dbaa14b5e77efe75928fe1dc127a2ffa8de3348b3c1856a429bf97e7e31c2e5bd66', # gx / generator-x
    '11839296a789a3bc0045c8a5fb42c7d1bd998f54449579b446817afbd17273e662c97ee72995ef42640c550b9013fad0761353c7086a272c24088be94769fd16650', # gy / generator-y
    '1', # h / cofactor
    'd09e8800291cb85396cc6717393284aaa0da64ba', # seed
);

#----------------------------------------------------------------------
use constant OID_prime192v1 => '1.2.840.10045.3.1.1';

use constant CURVE_1_2_840_10045_3_1_1 => (
    'fffffffffffffffffffffffffffffffeffffffffffffffff', # p / prime
    'fffffffffffffffffffffffffffffffefffffffffffffffc', # a
    '64210519e59c80e70fa7e9ab72243049feb8deecc146b9b1', # b
    'ffffffffffffffffffffffff99def836146bc9b1b4d22831', # n / order
    '188da80eb03090f67cbf20eb43a18800f4ff0afd82ff1012', # gx / generator-x
    '7192b95ffc8da78631011ed6b24cdd573f977a11e794811', # gy / generator-y
    '1', # h / cofactor
    '3045ae6fc8422f64ed579528d38120eae12196d5', # seed
);

#----------------------------------------------------------------------
use constant OID_prime192v2 => '1.2.840.10045.3.1.2';

use constant CURVE_1_2_840_10045_3_1_2 => (
    'fffffffffffffffffffffffffffffffeffffffffffffffff', # p / prime
    'fffffffffffffffffffffffffffffffefffffffffffffffc', # a
    'cc22d6dfb95c6b25e49c0d6364a4e5980c393aa21668d953', # b
    'fffffffffffffffffffffffe5fb1a724dc80418648d8dd31', # n / order
    'eea2bae7e1497842f2de7769cfe9c989c072ad696f48034a', # gx / generator-x
    '6574d11d69b6ec7a672bb82a083df2f2b0847de970b2de15', # gy / generator-y
    '1', # h / cofactor
    '31a92ee2029fd10d901b113e990710f0d21ac6b6', # seed
);

#----------------------------------------------------------------------
use constant OID_prime192v3 => '1.2.840.10045.3.1.3';

use constant CURVE_1_2_840_10045_3_1_3 => (
    'fffffffffffffffffffffffffffffffeffffffffffffffff', # p / prime
    'fffffffffffffffffffffffffffffffefffffffffffffffc', # a
    '22123dc2395a05caa7423daeccc94760a7d462256bd56916', # b
    'ffffffffffffffffffffffff7a62d031c83f4294f640ec13', # n / order
    '7d29778100c65a1da1783716588dce2b8b4aee8e228f1896', # gx / generator-x
    '38a90f22637337334b49dcb66a6dc8f9978aca7648a943b0', # gy / generator-y
    '1', # h / cofactor
    'c469684435deb378c4b65ca9591e2a5763059a2e', # seed
);

#----------------------------------------------------------------------
use constant OID_prime239v1 => '1.2.840.10045.3.1.4';

use constant CURVE_1_2_840_10045_3_1_4 => (
    '7fffffffffffffffffffffff7fffffffffff8000000000007fffffffffff', # p / prime
    '7fffffffffffffffffffffff7fffffffffff8000000000007ffffffffffc', # a
    '6b016c3bdcf18941d0d654921475ca71a9db2fb27d1d37796185c2942c0a', # b
    '7fffffffffffffffffffffff7fffff9e5e9a9f5d9071fbd1522688909d0b', # n / order
    'ffa963cdca8816ccc33b8642bedf905c3d358573d3f27fbbd3b3cb9aaaf', # gx / generator-x
    '7debe8e4e90a5dae6e4054ca530ba04654b36818ce226b39fccb7b02f1ae', # gy / generator-y
    '1', # h / cofactor
    'e43bb460f0b80cc0c0b075798e948060f8321b7d', # seed
);

#----------------------------------------------------------------------
use constant OID_prime239v2 => '1.2.840.10045.3.1.5';

use constant CURVE_1_2_840_10045_3_1_5 => (
    '7fffffffffffffffffffffff7fffffffffff8000000000007fffffffffff', # p / prime
    '7fffffffffffffffffffffff7fffffffffff8000000000007ffffffffffc', # a
    '617fab6832576cbbfed50d99f0249c3fee58b94ba0038c7ae84c8c832f2c', # b
    '7fffffffffffffffffffffff800000cfa7e8594377d414c03821bc582063', # n / order
    '38af09d98727705120c921bb5e9e26296a3cdcf2f35757a0eafd87b830e7', # gx / generator-x
    '5b0125e4dbea0ec7206da0fc01d9b081329fb555de6ef460237dff8be4ba', # gy / generator-y
    '1', # h / cofactor
    'e8b4011604095303ca3b8099982be09fcb9ae616', # seed
);

#----------------------------------------------------------------------
use constant OID_prime239v3 => '1.2.840.10045.3.1.6';

use constant CURVE_1_2_840_10045_3_1_6 => (
    '7fffffffffffffffffffffff7fffffffffff8000000000007fffffffffff', # p / prime
    '7fffffffffffffffffffffff7fffffffffff8000000000007ffffffffffc', # a
    '255705fa2a306654b1f4cb03d6a750a30c250102d4988717d9ba15ab6d3e', # b
    '7fffffffffffffffffffffff7fffff975deb41b3a6057c3c432146526551', # n / order
    '6768ae8e18bb92cfcf005c949aa2c6d94853d0e660bbf854b1c9505fe95a', # gx / generator-x
    '1607e6898f390c06bc1d552bad226f3b6fcfe48b6e818499af18e3ed6cf3', # gy / generator-y
    '1', # h / cofactor
    '7d7374168ffe3471b60a857686a19475d3bfa2ff', # seed
);

#----------------------------------------------------------------------
use constant OID_prime256v1 => '1.2.840.10045.3.1.7';

use constant CURVE_1_2_840_10045_3_1_7 => (
    'ffffffff00000001000000000000000000000000ffffffffffffffffffffffff', # p / prime
    'ffffffff00000001000000000000000000000000fffffffffffffffffffffffc', # a
    '5ac635d8aa3a93e7b3ebbd55769886bc651d06b0cc53b0f63bce3c3e27d2604b', # b
    'ffffffff00000000ffffffffffffffffbce6faada7179e84f3b9cac2fc632551', # n / order
    '6b17d1f2e12c4247f8bce6e563a440f277037d812deb33a0f4a13945d898c296', # gx / generator-x
    '4fe342e2fe1a7f9b8ee7eb4a7c0f9e162bce33576b315ececbb6406837bf51f5', # gy / generator-y
    '1', # h / cofactor
    'c49d360886e704936a6678e1139d26b7819f7e90', # seed
);

#----------------------------------------------------------------------
use constant OID_sect113r1 => '1.3.132.0.4';

# Skipping data for sect113r1:
# Crypt::Perl::X::ECDSA::CharacteristicTwoUnsupported: This library does not support ECDSA curves that use Characteristic-2 fields.
#----------------------------------------------------------------------
use constant OID_sect113r2 => '1.3.132.0.5';

# Skipping data for sect113r2:
# Crypt::Perl::X::ECDSA::CharacteristicTwoUnsupported: This library does not support ECDSA curves that use Characteristic-2 fields.
#----------------------------------------------------------------------
use constant OID_sect131r1 => '1.3.132.0.22';

# Skipping data for sect131r1:
# Crypt::Perl::X::ECDSA::CharacteristicTwoUnsupported: This library does not support ECDSA curves that use Characteristic-2 fields.
#----------------------------------------------------------------------
use constant OID_sect131r2 => '1.3.132.0.23';

# Skipping data for sect131r2:
# Crypt::Perl::X::ECDSA::CharacteristicTwoUnsupported: This library does not support ECDSA curves that use Characteristic-2 fields.
#----------------------------------------------------------------------
use constant OID_sect163k1 => '1.3.132.0.1';

# Skipping data for sect163k1:
# Crypt::Perl::X::ECDSA::CharacteristicTwoUnsupported: This library does not support ECDSA curves that use Characteristic-2 fields.
#----------------------------------------------------------------------
use constant OID_sect163r1 => '1.3.132.0.2';

# Skipping data for sect163r1:
# Crypt::Perl::X::ECDSA::CharacteristicTwoUnsupported: This library does not support ECDSA curves that use Characteristic-2 fields.
#----------------------------------------------------------------------
use constant OID_sect163r2 => '1.3.132.0.15';

# Skipping data for sect163r2:
# Crypt::Perl::X::ECDSA::CharacteristicTwoUnsupported: This library does not support ECDSA curves that use Characteristic-2 fields.
#----------------------------------------------------------------------
use constant OID_sect193r1 => '1.3.132.0.24';

# Skipping data for sect193r1:
# Crypt::Perl::X::ECDSA::CharacteristicTwoUnsupported: This library does not support ECDSA curves that use Characteristic-2 fields.
#----------------------------------------------------------------------
use constant OID_sect193r2 => '1.3.132.0.25';

# Skipping data for sect193r2:
# Crypt::Perl::X::ECDSA::CharacteristicTwoUnsupported: This library does not support ECDSA curves that use Characteristic-2 fields.
#----------------------------------------------------------------------
use constant OID_sect233k1 => '1.3.132.0.26';

# Skipping data for sect233k1:
# Crypt::Perl::X::ECDSA::CharacteristicTwoUnsupported: This library does not support ECDSA curves that use Characteristic-2 fields.
#----------------------------------------------------------------------
use constant OID_sect233r1 => '1.3.132.0.27';

# Skipping data for sect233r1:
# Crypt::Perl::X::ECDSA::CharacteristicTwoUnsupported: This library does not support ECDSA curves that use Characteristic-2 fields.
#----------------------------------------------------------------------
use constant OID_sect239k1 => '1.3.132.0.3';

# Skipping data for sect239k1:
# Crypt::Perl::X::ECDSA::CharacteristicTwoUnsupported: This library does not support ECDSA curves that use Characteristic-2 fields.
#----------------------------------------------------------------------
use constant OID_sect283k1 => '1.3.132.0.16';

# Skipping data for sect283k1:
# Crypt::Perl::X::ECDSA::CharacteristicTwoUnsupported: This library does not support ECDSA curves that use Characteristic-2 fields.
#----------------------------------------------------------------------
use constant OID_sect283r1 => '1.3.132.0.17';

# Skipping data for sect283r1:
# Crypt::Perl::X::ECDSA::CharacteristicTwoUnsupported: This library does not support ECDSA curves that use Characteristic-2 fields.
#----------------------------------------------------------------------
use constant OID_sect409k1 => '1.3.132.0.36';

# Skipping data for sect409k1:
# Crypt::Perl::X::ECDSA::CharacteristicTwoUnsupported: This library does not support ECDSA curves that use Characteristic-2 fields.
#----------------------------------------------------------------------
use constant OID_sect409r1 => '1.3.132.0.37';

# Skipping data for sect409r1:
# Crypt::Perl::X::ECDSA::CharacteristicTwoUnsupported: This library does not support ECDSA curves that use Characteristic-2 fields.
#----------------------------------------------------------------------
use constant OID_sect571k1 => '1.3.132.0.38';

# Skipping data for sect571k1:
# Crypt::Perl::X::ECDSA::CharacteristicTwoUnsupported: This library does not support ECDSA curves that use Characteristic-2 fields.
#----------------------------------------------------------------------
use constant OID_sect571r1 => '1.3.132.0.39';

# Skipping data for sect571r1:
# Crypt::Perl::X::ECDSA::CharacteristicTwoUnsupported: This library does not support ECDSA curves that use Characteristic-2 fields.
#----------------------------------------------------------------------
use constant OID_c2pnb163v1 => '1.2.840.10045.3.0.1';

# Skipping data for c2pnb163v1:
# Crypt::Perl::X::ECDSA::CharacteristicTwoUnsupported: This library does not support ECDSA curves that use Characteristic-2 fields.
#----------------------------------------------------------------------
use constant OID_c2pnb163v2 => '1.2.840.10045.3.0.2';

# Skipping data for c2pnb163v2:
# Crypt::Perl::X::ECDSA::CharacteristicTwoUnsupported: This library does not support ECDSA curves that use Characteristic-2 fields.
#----------------------------------------------------------------------
use constant OID_c2pnb163v3 => '1.2.840.10045.3.0.3';

# Skipping data for c2pnb163v3:
# Crypt::Perl::X::ECDSA::CharacteristicTwoUnsupported: This library does not support ECDSA curves that use Characteristic-2 fields.
#----------------------------------------------------------------------
use constant OID_c2pnb176v1 => '1.2.840.10045.3.0.4';

# Skipping data for c2pnb176v1:
# Crypt::Perl::X::ECDSA::CharacteristicTwoUnsupported: This library does not support ECDSA curves that use Characteristic-2 fields.
#----------------------------------------------------------------------
use constant OID_c2tnb191v1 => '1.2.840.10045.3.0.5';

# Skipping data for c2tnb191v1:
# Crypt::Perl::X::ECDSA::CharacteristicTwoUnsupported: This library does not support ECDSA curves that use Characteristic-2 fields.
#----------------------------------------------------------------------
use constant OID_c2tnb191v2 => '1.2.840.10045.3.0.6';

# Skipping data for c2tnb191v2:
# Crypt::Perl::X::ECDSA::CharacteristicTwoUnsupported: This library does not support ECDSA curves that use Characteristic-2 fields.
#----------------------------------------------------------------------
use constant OID_c2tnb191v3 => '1.2.840.10045.3.0.7';

# Skipping data for c2tnb191v3:
# Crypt::Perl::X::ECDSA::CharacteristicTwoUnsupported: This library does not support ECDSA curves that use Characteristic-2 fields.
#----------------------------------------------------------------------
use constant OID_c2pnb208w1 => '1.2.840.10045.3.0.10';

# Skipping data for c2pnb208w1:
# Crypt::Perl::X::ECDSA::CharacteristicTwoUnsupported: This library does not support ECDSA curves that use Characteristic-2 fields.
#----------------------------------------------------------------------
use constant OID_c2tnb239v1 => '1.2.840.10045.3.0.11';

# Skipping data for c2tnb239v1:
# Crypt::Perl::X::ECDSA::CharacteristicTwoUnsupported: This library does not support ECDSA curves that use Characteristic-2 fields.
#----------------------------------------------------------------------
use constant OID_c2tnb239v2 => '1.2.840.10045.3.0.12';

# Skipping data for c2tnb239v2:
# Crypt::Perl::X::ECDSA::CharacteristicTwoUnsupported: This library does not support ECDSA curves that use Characteristic-2 fields.
#----------------------------------------------------------------------
use constant OID_c2tnb239v3 => '1.2.840.10045.3.0.13';

# Skipping data for c2tnb239v3:
# Crypt::Perl::X::ECDSA::CharacteristicTwoUnsupported: This library does not support ECDSA curves that use Characteristic-2 fields.
#----------------------------------------------------------------------
use constant OID_c2pnb272w1 => '1.2.840.10045.3.0.16';

# Skipping data for c2pnb272w1:
# Crypt::Perl::X::ECDSA::CharacteristicTwoUnsupported: This library does not support ECDSA curves that use Characteristic-2 fields.
#----------------------------------------------------------------------
use constant OID_c2pnb304w1 => '1.2.840.10045.3.0.17';

# Skipping data for c2pnb304w1:
# Crypt::Perl::X::ECDSA::CharacteristicTwoUnsupported: This library does not support ECDSA curves that use Characteristic-2 fields.
#----------------------------------------------------------------------
use constant OID_c2tnb359v1 => '1.2.840.10045.3.0.18';

# Skipping data for c2tnb359v1:
# Crypt::Perl::X::ECDSA::CharacteristicTwoUnsupported: This library does not support ECDSA curves that use Characteristic-2 fields.
#----------------------------------------------------------------------
use constant OID_c2pnb368w1 => '1.2.840.10045.3.0.19';

# Skipping data for c2pnb368w1:
# Crypt::Perl::X::ECDSA::CharacteristicTwoUnsupported: This library does not support ECDSA curves that use Characteristic-2 fields.
#----------------------------------------------------------------------
use constant OID_c2tnb431r1 => '1.2.840.10045.3.0.20';

# Skipping data for c2tnb431r1:
# Crypt::Perl::X::ECDSA::CharacteristicTwoUnsupported: This library does not support ECDSA curves that use Characteristic-2 fields.
#----------------------------------------------------------------------
use constant OID_wap_wsg_idm_ecid_wtls1 => '2.23.43.1.4.1';

# Skipping data for wap-wsg-idm-ecid-wtls1:
# Crypt::Perl::X::ECDSA::CharacteristicTwoUnsupported: This library does not support ECDSA curves that use Characteristic-2 fields.
#----------------------------------------------------------------------
use constant OID_wap_wsg_idm_ecid_wtls3 => '2.23.43.1.4.3';

# Skipping data for wap-wsg-idm-ecid-wtls3:
# Crypt::Perl::X::ECDSA::CharacteristicTwoUnsupported: This library does not support ECDSA curves that use Characteristic-2 fields.
#----------------------------------------------------------------------
use constant OID_wap_wsg_idm_ecid_wtls4 => '2.23.43.1.4.4';

# Skipping data for wap-wsg-idm-ecid-wtls4:
# Crypt::Perl::X::ECDSA::CharacteristicTwoUnsupported: This library does not support ECDSA curves that use Characteristic-2 fields.
#----------------------------------------------------------------------
use constant OID_wap_wsg_idm_ecid_wtls5 => '2.23.43.1.4.5';

# Skipping data for wap-wsg-idm-ecid-wtls5:
# Crypt::Perl::X::ECDSA::CharacteristicTwoUnsupported: This library does not support ECDSA curves that use Characteristic-2 fields.
#----------------------------------------------------------------------
use constant OID_wap_wsg_idm_ecid_wtls6 => '2.23.43.1.4.6';

use constant CURVE_2_23_43_1_4_6 => (
    'db7c2abf62e35e668076bead208b', # p / prime
    'db7c2abf62e35e668076bead2088', # a
    '659ef8ba043916eede8911702b22', # b
    'db7c2abf62e35e7628dfac6561c5', # n / order
    '9487239995a5ee76b55f9c2f098', # gx / generator-x
    'a89ce5af8724c0a23e0e0ff77500', # gy / generator-y
    '1', # h / cofactor
    'f50b028e4d696e676875615175290472783fb1', # seed
);

#----------------------------------------------------------------------
use constant OID_wap_wsg_idm_ecid_wtls7 => '2.23.43.1.4.7';

use constant CURVE_2_23_43_1_4_7 => (
    'fffffffffffffffffffffffffffffffeffffac73', # p / prime
    'fffffffffffffffffffffffffffffffeffffac70', # a
    'b4e134d3fb59eb8bab57274904664d5af50388ba', # b
    '100000000000000000000351ee786a818f3a1a16b', # n / order
    '52dcb034293a117e1f4ff11b30f7199d3144ce6d', # gx / generator-x
    'feaffef2e331f296e071fa0df9982cfea7d43f2e', # gy / generator-y
    '1', # h / cofactor
    'b99b99b099b323e02709a4d696e6768756151751', # seed
);

#----------------------------------------------------------------------
use constant OID_wap_wsg_idm_ecid_wtls8 => '2.23.43.1.4.8';

use constant CURVE_2_23_43_1_4_8 => (
    'fffffffffffffffffffffffffde7', # p / prime
    '0', # a
    '3', # b
    '100000000000001ecea551ad837e9', # n / order
    '1', # gx / generator-x
    '2', # gy / generator-y
    '1', # h / cofactor
    '', # seed
);

#----------------------------------------------------------------------
use constant OID_wap_wsg_idm_ecid_wtls9 => '2.23.43.1.4.9';

use constant CURVE_2_23_43_1_4_9 => (
    'fffffffffffffffffffffffffffffffffffc808f', # p / prime
    '0', # a
    '3', # b
    '100000000000000000001cdc98ae0e2de574abf33', # n / order
    '1', # gx / generator-x
    '2', # gy / generator-y
    '1', # h / cofactor
    '', # seed
);

#----------------------------------------------------------------------
use constant OID_wap_wsg_idm_ecid_wtls10 => '2.23.43.1.4.10';

# Skipping data for wap-wsg-idm-ecid-wtls10:
# Crypt::Perl::X::ECDSA::CharacteristicTwoUnsupported: This library does not support ECDSA curves that use Characteristic-2 fields.
#----------------------------------------------------------------------
use constant OID_wap_wsg_idm_ecid_wtls11 => '2.23.43.1.4.11';

# Skipping data for wap-wsg-idm-ecid-wtls11:
# Crypt::Perl::X::ECDSA::CharacteristicTwoUnsupported: This library does not support ECDSA curves that use Characteristic-2 fields.
#----------------------------------------------------------------------
use constant OID_wap_wsg_idm_ecid_wtls12 => '2.23.43.1.4.12';

use constant CURVE_2_23_43_1_4_12 => (
    'ffffffffffffffffffffffffffffffff000000000000000000000001', # p / prime
    'fffffffffffffffffffffffffffffffefffffffffffffffffffffffe', # a
    'b4050a850c04b3abf54132565044b0b7d7bfd8ba270b39432355ffb4', # b
    'ffffffffffffffffffffffffffff16a2e0b8f03e13dd29455c5c2a3d', # n / order
    'b70e0cbd6bb4bf7f321390b94a03c1d356c21122343280d6115c1d21', # gx / generator-x
    'bd376388b5f723fb4c22dfe6cd4375a05a07476444d5819985007e34', # gy / generator-y
    '1', # h / cofactor
    '', # seed
);

#----------------------------------------------------------------------
use constant OID_brainpoolP160r1 => '1.3.36.3.3.2.8.1.1.1';

use constant CURVE_1_3_36_3_3_2_8_1_1_1 => (
    'e95e4a5f737059dc60dfc7ad95b3d8139515620f', # p / prime
    '340e7be2a280eb74e2be61bada745d97e8f7c300', # a
    '1e589a8595423412134faa2dbdec95c8d8675e58', # b
    'e95e4a5f737059dc60df5991d45029409e60fc09', # n / order
    'bed5af16ea3f6a4f62938c4631eb5af7bdbcdbc3', # gx / generator-x
    '1667cb477a1a8ec338f94741669c976316da6321', # gy / generator-y
    '1', # h / cofactor
    '', # seed
);

#----------------------------------------------------------------------
use constant OID_brainpoolP160t1 => '1.3.36.3.3.2.8.1.1.2';

use constant CURVE_1_3_36_3_3_2_8_1_1_2 => (
    'e95e4a5f737059dc60dfc7ad95b3d8139515620f', # p / prime
    'e95e4a5f737059dc60dfc7ad95b3d8139515620c', # a
    '7a556b6dae535b7b51ed2c4d7daa7a0b5c55f380', # b
    'e95e4a5f737059dc60df5991d45029409e60fc09', # n / order
    'b199b13b9b34efc1397e64baeb05acc265ff2378', # gx / generator-x
    'add6718b7c7c1961f0991b842443772152c9e0ad', # gy / generator-y
    '1', # h / cofactor
    '', # seed
);

#----------------------------------------------------------------------
use constant OID_brainpoolP192r1 => '1.3.36.3.3.2.8.1.1.3';

use constant CURVE_1_3_36_3_3_2_8_1_1_3 => (
    'c302f41d932a36cda7a3463093d18db78fce476de1a86297', # p / prime
    '6a91174076b1e0e19c39c031fe8685c1cae040e5c69a28ef', # a
    '469a28ef7c28cca3dc721d044f4496bcca7ef4146fbf25c9', # b
    'c302f41d932a36cda7a3462f9e9e916b5be8f1029ac4acc1', # n / order
    'c0a0647eaab6a48753b033c56cb0f0900a2f5c4853375fd6', # gx / generator-x
    '14b690866abd5bb88b5f4828c1490002e6773fa2fa299b8f', # gy / generator-y
    '1', # h / cofactor
    '', # seed
);

#----------------------------------------------------------------------
use constant OID_brainpoolP192t1 => '1.3.36.3.3.2.8.1.1.4';

use constant CURVE_1_3_36_3_3_2_8_1_1_4 => (
    'c302f41d932a36cda7a3463093d18db78fce476de1a86297', # p / prime
    'c302f41d932a36cda7a3463093d18db78fce476de1a86294', # a
    '13d56ffaec78681e68f9deb43b35bec2fb68542e27897b79', # b
    'c302f41d932a36cda7a3462f9e9e916b5be8f1029ac4acc1', # n / order
    '3ae9e58c82f63c30282e1fe7bbf43fa72c446af6f4618129', # gx / generator-x
    '97e2c5667c2223a902ab5ca449d0084b7e5b3de7ccc01c9', # gy / generator-y
    '1', # h / cofactor
    '', # seed
);

#----------------------------------------------------------------------
use constant OID_brainpoolP224r1 => '1.3.36.3.3.2.8.1.1.5';

use constant CURVE_1_3_36_3_3_2_8_1_1_5 => (
    'd7c134aa264366862a18302575d1d787b09f075797da89f57ec8c0ff', # p / prime
    '68a5e62ca9ce6c1c299803a6c1530b514e182ad8b0042a59cad29f43', # a
    '2580f63ccfe44138870713b1a92369e33e2135d266dbb372386c400b', # b
    'd7c134aa264366862a18302575d0fb98d116bc4b6ddebca3a5a7939f', # n / order
    'd9029ad2c7e5cf4340823b2a87dc68c9e4ce3174c1e6efdee12c07d', # gx / generator-x
    '58aa56f772c0726f24c6b89e4ecdac24354b9e99caa3f6d3761402cd', # gy / generator-y
    '1', # h / cofactor
    '', # seed
);

#----------------------------------------------------------------------
use constant OID_brainpoolP224t1 => '1.3.36.3.3.2.8.1.1.6';

use constant CURVE_1_3_36_3_3_2_8_1_1_6 => (
    'd7c134aa264366862a18302575d1d787b09f075797da89f57ec8c0ff', # p / prime
    'd7c134aa264366862a18302575d1d787b09f075797da89f57ec8c0fc', # a
    '4b337d934104cd7bef271bf60ced1ed20da14c08b3bb64f18a60888d', # b
    'd7c134aa264366862a18302575d0fb98d116bc4b6ddebca3a5a7939f', # n / order
    '6ab1e344ce25ff3896424e7ffe14762ecb49f8928ac0c76029b4d580', # gx / generator-x
    '374e9f5143e568cd23f3f4d7c0d4b1e41c8cc0d1c6abd5f1a46db4c', # gy / generator-y
    '1', # h / cofactor
    '', # seed
);

#----------------------------------------------------------------------
use constant OID_brainpoolP256r1 => '1.3.36.3.3.2.8.1.1.7';

use constant CURVE_1_3_36_3_3_2_8_1_1_7 => (
    'a9fb57dba1eea9bc3e660a909d838d726e3bf623d52620282013481d1f6e5377', # p / prime
    '7d5a0975fc2c3057eef67530417affe7fb8055c126dc5c6ce94a4b44f330b5d9', # a
    '26dc5c6ce94a4b44f330b5d9bbd77cbf958416295cf7e1ce6bccdc18ff8c07b6', # b
    'a9fb57dba1eea9bc3e660a909d838d718c397aa3b561a6f7901e0e82974856a7', # n / order
    '8bd2aeb9cb7e57cb2c4b482ffc81b7afb9de27e1e3bd23c23a4453bd9ace3262', # gx / generator-x
    '547ef835c3dac4fd97f8461a14611dc9c27745132ded8e545c1d54c72f046997', # gy / generator-y
    '1', # h / cofactor
    '', # seed
);

#----------------------------------------------------------------------
use constant OID_brainpoolP256t1 => '1.3.36.3.3.2.8.1.1.8';

use constant CURVE_1_3_36_3_3_2_8_1_1_8 => (
    'a9fb57dba1eea9bc3e660a909d838d726e3bf623d52620282013481d1f6e5377', # p / prime
    'a9fb57dba1eea9bc3e660a909d838d726e3bf623d52620282013481d1f6e5374', # a
    '662c61c430d84ea4fe66a7733d0b76b7bf93ebc4af2f49256ae58101fee92b04', # b
    'a9fb57dba1eea9bc3e660a909d838d718c397aa3b561a6f7901e0e82974856a7', # n / order
    'a3e8eb3cc1cfe7b7732213b23a656149afa142c47aafbc2b79a191562e1305f4', # gx / generator-x
    '2d996c823439c56d7f7b22e14644417e69bcb6de39d027001dabe8f35b25c9be', # gy / generator-y
    '1', # h / cofactor
    '', # seed
);

#----------------------------------------------------------------------
use constant OID_brainpoolP320r1 => '1.3.36.3.3.2.8.1.1.9';

use constant CURVE_1_3_36_3_3_2_8_1_1_9 => (
    'd35e472036bc4fb7e13c785ed201e065f98fcfa6f6f40def4f92b9ec7893ec28fcd412b1f1b32e27', # p / prime
    '3ee30b568fbab0f883ccebd46d3f3bb8a2a73513f5eb79da66190eb085ffa9f492f375a97d860eb4', # a
    '520883949dfdbc42d3ad198640688a6fe13f41349554b49acc31dccd884539816f5eb4ac8fb1f1a6', # b
    'd35e472036bc4fb7e13c785ed201e065f98fcfa5b68f12a32d482ec7ee8658e98691555b44c59311', # n / order
    '43bd7e9afb53d8b85289bcc48ee5bfe6f20137d10a087eb6e7871e2a10a599c710af8d0d39e20611', # gx / generator-x
    '14fdd05545ec1cc8ab4093247f77275e0743ffed117182eaa9c77877aaac6ac7d35245d1692e8ee1', # gy / generator-y
    '1', # h / cofactor
    '', # seed
);

#----------------------------------------------------------------------
use constant OID_brainpoolP320t1 => '1.3.36.3.3.2.8.1.1.10';

use constant CURVE_1_3_36_3_3_2_8_1_1_10 => (
    'd35e472036bc4fb7e13c785ed201e065f98fcfa6f6f40def4f92b9ec7893ec28fcd412b1f1b32e27', # p / prime
    'd35e472036bc4fb7e13c785ed201e065f98fcfa6f6f40def4f92b9ec7893ec28fcd412b1f1b32e24', # a
    'a7f561e038eb1ed560b3d147db782013064c19f27ed27c6780aaf77fb8a547ceb5b4fef422340353', # b
    'd35e472036bc4fb7e13c785ed201e065f98fcfa5b68f12a32d482ec7ee8658e98691555b44c59311', # n / order
    '925be9fb01afc6fb4d3e7d4990010f813408ab106c4f09cb7ee07868cc136fff3357f624a21bed52', # gx / generator-x
    '63ba3a7a27483ebf6671dbef7abb30ebee084e58a0b077ad42a5a0989d1ee71b1b9bc0455fb0d2c3', # gy / generator-y
    '1', # h / cofactor
    '', # seed
);

#----------------------------------------------------------------------
use constant OID_brainpoolP384r1 => '1.3.36.3.3.2.8.1.1.11';

use constant CURVE_1_3_36_3_3_2_8_1_1_11 => (
    '8cb91e82a3386d280f5d6f7e50e641df152f7109ed5456b412b1da197fb71123acd3a729901d1a71874700133107ec53', # p / prime
    '7bc382c63d8c150c3c72080ace05afa0c2bea28e4fb22787139165efba91f90f8aa5814a503ad4eb04a8c7dd22ce2826', # a
    '4a8c7dd22ce28268b39b55416f0447c2fb77de107dcd2a62e880ea53eeb62d57cb4390295dbc9943ab78696fa504c11', # b
    '8cb91e82a3386d280f5d6f7e50e641df152f7109ed5456b31f166e6cac0425a7cf3ab6af6b7fc3103b883202e9046565', # n / order
    '1d1c64f068cf45ffa2a63a81b7c13f6b8847a3e77ef14fe3db7fcafe0cbd10e8e826e03436d646aaef87b2e247d4af1e', # gx / generator-x
    '8abe1d7520f9c2a45cb1eb8e95cfd55262b70b29feec5864e19c054ff99129280e4646217791811142820341263c5315', # gy / generator-y
    '1', # h / cofactor
    '', # seed
);

#----------------------------------------------------------------------
use constant OID_brainpoolP384t1 => '1.3.36.3.3.2.8.1.1.12';

use constant CURVE_1_3_36_3_3_2_8_1_1_12 => (
    '8cb91e82a3386d280f5d6f7e50e641df152f7109ed5456b412b1da197fb71123acd3a729901d1a71874700133107ec53', # p / prime
    '8cb91e82a3386d280f5d6f7e50e641df152f7109ed5456b412b1da197fb71123acd3a729901d1a71874700133107ec50', # a
    '7f519eada7bda81bd826dba647910f8c4b9346ed8ccdc64e4b1abd11756dce1d2074aa263b88805ced70355a33b471ee', # b
    '8cb91e82a3386d280f5d6f7e50e641df152f7109ed5456b31f166e6cac0425a7cf3ab6af6b7fc3103b883202e9046565', # n / order
    '18de98b02db9a306f2afcd7235f72a819b80ab12ebd653172476fecd462aabffc4ff191b946a5f54d8d0aa2f418808cc', # gx / generator-x
    '25ab056962d30651a114afd2755ad336747f93475b7a1fca3b88f2b6a208ccfe469408584dc2b2912675bf5b9e582928', # gy / generator-y
    '1', # h / cofactor
    '', # seed
);

#----------------------------------------------------------------------
use constant OID_brainpoolP512r1 => '1.3.36.3.3.2.8.1.1.13';

use constant CURVE_1_3_36_3_3_2_8_1_1_13 => (
    'aadd9db8dbe9c48b3fd4e6ae33c9fc07cb308db3b3c9d20ed6639cca703308717d4d9b009bc66842aecda12ae6a380e62881ff2f2d82c68528aa6056583a48f3', # p / prime
    '7830a3318b603b89e2327145ac234cc594cbdd8d3df91610a83441caea9863bc2ded5d5aa8253aa10a2ef1c98b9ac8b57f1117a72bf2c7b9e7c1ac4d77fc94ca', # a
    '3df91610a83441caea9863bc2ded5d5aa8253aa10a2ef1c98b9ac8b57f1117a72bf2c7b9e7c1ac4d77fc94cadc083e67984050b75ebae5dd2809bd638016f723', # b
    'aadd9db8dbe9c48b3fd4e6ae33c9fc07cb308db3b3c9d20ed6639cca70330870553e5c414ca92619418661197fac10471db1d381085ddaddb58796829ca90069', # n / order
    '81aee4bdd82ed9645a21322e9c4c6a9385ed9f70b5d916c1b43b62eef4d0098eff3b1f78e2d0d48d50d1687b93b97d5f7c6d5047406a5e688b352209bcb9f822', # gx / generator-x
    '7dde385d566332ecc0eabfa9cf7822fdf209f70024a57b1aa000c55b881f8111b2dcde494a5f485e5bca4bd88a2763aed1ca2b2fa8f0540678cd1e0f3ad80892', # gy / generator-y
    '1', # h / cofactor
    '', # seed
);

#----------------------------------------------------------------------
use constant OID_brainpoolP512t1 => '1.3.36.3.3.2.8.1.1.14';

use constant CURVE_1_3_36_3_3_2_8_1_1_14 => (
    'aadd9db8dbe9c48b3fd4e6ae33c9fc07cb308db3b3c9d20ed6639cca703308717d4d9b009bc66842aecda12ae6a380e62881ff2f2d82c68528aa6056583a48f3', # p / prime
    'aadd9db8dbe9c48b3fd4e6ae33c9fc07cb308db3b3c9d20ed6639cca703308717d4d9b009bc66842aecda12ae6a380e62881ff2f2d82c68528aa6056583a48f0', # a
    '7cbbbcf9441cfab76e1890e46884eae321f70c0bcb4981527897504bec3e36a62bcdfa2304976540f6450085f2dae145c22553b465763689180ea2571867423e', # b
    'aadd9db8dbe9c48b3fd4e6ae33c9fc07cb308db3b3c9d20ed6639cca70330870553e5c414ca92619418661197fac10471db1d381085ddaddb58796829ca90069', # n / order
    '640ece5c12788717b9c1ba06cbc2a6feba85842458c56dde9db1758d39c0313d82ba51735cdb3ea499aa77a7d6943a64f7a3f25fe26f06b51baa2696fa9035da', # gx / generator-x
    '5b534bd595f5af0fa2c892376c84ace1bb4e3019b71634c01131159cae03cee9d9932184beef216bd71df2dadf86a627306ecff96dbb8bace198b61e00f8b332', # gy / generator-y
    '1', # h / cofactor
    '', # seed
);

1;
