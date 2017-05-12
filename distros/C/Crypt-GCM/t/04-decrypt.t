use Test::More tests => 10;
use strict;
use warnings;

use Crypt::GCM;
use Crypt::Rijndael;

my @TESTS = (
    [ '00000000000000000000000000000000', # key
      '00000000000000000000000000000000', # plain
      '',                                 # aad
      '000000000000000000000000',         # iv
      '0388dace60b6a392f328c2b971b2fe78', # cipher
      'ab6e47d42cec13bdf53a67b21257bddf', # tag
    ],
    [ 'feffe9928665731c6d6a8f9467308308',
      'd9313225f88406e5a55909c5aff5269a86a7a9531534f7da2e4c303d8a318a721c3c0c95956809532fcf0e2449a6b525b16aedf5aa0de657ba637b391aafd255',
      '',
      'cafebabefacedbaddecaf888',
      '42831ec2217774244b7221b784d0d49ce3aa212f2c02a4e035c17e2329aca12e21d514b25466931c7d8f6a5aac84aa051ba30b396a0aac973d58e091473f5985',
      '4d5c2af327cd64a62cf35abd2ba6fab4',
    ],
    ['feffe9928665731c6d6a8f9467308308',
     'd9313225f88406e5a55909c5aff5269a86a7a9531534f7da2e4c303d8a318a721c3c0c95956809532fcf0e2449a6b525b16aedf5aa0de657ba637b39',
     'feedfacedeadbeeffeedfacedeadbeefabaddad2',
     'cafebabefacedbaddecaf888',
     '42831ec2217774244b7221b784d0d49ce3aa212f2c02a4e035c17e2329aca12e21d514b25466931c7d8f6a5aac84aa051ba30b396a0aac973d58e091',
     '5bc94fbc3221a5db94fae95ae7121a47',
    ],
    [ 'feffe9928665731c6d6a8f9467308308',
      'd9313225f88406e5a55909c5aff5269a86a7a9531534f7da2e4c303d8a318a721c3c0c95956809532fcf0e2449a6b525b16aedf5aa0de657ba637b39',
      'feedfacedeadbeeffeedfacedeadbeefabaddad2',
      'cafebabefacedbad',
      '61353b4c2806934a777ff51fa22a4755699b2a714fcdc6f83766e5f97b6c742373806900e49f24b22b097544d4896b424989b5e1ebac0f07c23f4598',
      '3612d2e79e3b0785561be14aaca2fccb',
    ],
    [ 'feffe9928665731c6d6a8f9467308308',
      'd9313225f88406e5a55909c5aff5269a86a7a9531534f7da2e4c303d8a318a721c3c0c95956809532fcf0e2449a6b525b16aedf5aa0de657ba637b39',
      'feedfacedeadbeeffeedfacedeadbeefabaddad2',
      '9313225df88406e555909c5aff5269aa6a7a9538534f7da1e4c303d2a318a728c3c0c95156809539fcf0e2429a6b525416aedbf5a0de6a57a637b39b',
      '8ce24998625615b603a033aca13fb894be9112a5c3a211a8ba262a3cca7e2ca701e4a9a4fba43c90ccdcb281d48c7c6fd62875d2aca417034c34aee5',
      '619cc5aefffe0bfa462af43c1699d050',
    ],
);


for my $t (@TESTS) {
    my $gcm = Crypt::GCM->new(
        -key => pack('H*', $t->[0]),
        -cipher => 'Crypt::Rijndael',
    );
    $gcm->set_iv(pack 'H*', $t->[3]);
    $gcm->aad(pack 'H*', $t->[2]);
    $gcm->tag(pack 'H*', $t->[5]);
    my $pt = $gcm->decrypt(pack 'H*', $t->[4]);
    ok($pt);
    ok($pt && $pt eq pack('H*', $t->[1]));
}
