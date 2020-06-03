use strict;
use warnings;
use Test::More;
use MIME::Base64 qw(decode_base64url);
use Crypt::PK::ECC;
use Crypt::PRNG qw(random_bytes random_bytes_b64u);
use Crypt::RFC8188 qw(ece_encrypt_aes128gcm ece_decrypt_aes128gcm derive_key);

# modified port of github.com/web-push-libs/encrypted-content-encoding/python tests

my @DK_EXCEPTION_CASES = (
  [ [ 1 ], qr/must be 16 octets/ ],
  [ [ 2, 3 ], qr/DH requires a private_key/ ],
  [ [ 2, 3, 4 ], qr/Unable to determine the secret/ ],
);
subtest 'derive_key exceptions' => sub {
  for my $case (@DK_EXCEPTION_CASES) {
    my $private_key = gen_key();
    my @args = (
      'encrypt',
      random_bytes(16),
      random_bytes(16),
      $private_key,
      $private_key->export_key_raw('public'),
    );
    $args[$_] = undef for @{ $case->[0] };
    eval { derive_key(@args) };
    like $@, $case->[1];
  }
};

my @DK_CASES = (
  [["decrypt", "qtIFfTNTt_83veQq4dUP2g==", "ZMcOZKclVRRR8gjfuqC5cg==", undef, undef, undef], ["qYWpkVCDVZW7l_LpBS9afg==", "Brc0TQQMob40Dyw1"]],
  [["decrypt", "qtIFfTNTt_83veQq4dUP2g==", "ZMcOZKclVRRR8gjfuqC5cg==", undef, undef, undef], ["qYWpkVCDVZW7l_LpBS9afg==", "Brc0TQQMob40Dyw1"]],
  [["decrypt", "qtIFfTNTt_83veQq4dUP2g==", "ZMcOZKclVRRR8gjfuqC5cg==", undef, undef, undef], ["qYWpkVCDVZW7l_LpBS9afg==", "Brc0TQQMob40Dyw1"]],
  [["decrypt", "dKdaWSgXpZBv0uPeMtIWjQ==", "uAyCGPbsBtMkaE3RpqY-IQ==", undef, undef, undef], ["dUm1w62FlUX_TAsgbNindw==", "SoclDc9_KtBmYEZF"]],
  [["encrypt", "Aq8ZmNVGKYJrAiD4LQITew==", "VydnrnVNbVzSh8cUK_fHgQ==", undef, undef, undef], ["tuU6Z1adaAeRM4PjP8xaYA==", "tqO89snEcEr88dV7"]],
  [["encrypt", "nkaMAXr7KZ8kA_VmLSMjBQ==", "bgOhe7mh7D-VM6h8o78_4g==", undef, undef, undef, undef], ["DV_4-biUdWnyNnTAK7TgFA==", "2uILAcmqv8WBn9Ms"]],
  [["decrypt", "qtIFfTNTt_83veQq4dUP2g==", "ZMcOZKclVRRR8gjfuqC5cg==", undef, undef, undef, ""], ["qYWpkVCDVZW7l_LpBS9afg==", "Brc0TQQMob40Dyw1"]],
);
subtest 'derive_key' => sub {
  for my $case (@DK_CASES) {
    my ($in, $out) = @$case;
    my @args = ($in->[0], map decode_base64url($_), @$in[1..5]);
    my ($got_key, $got_nonce) = derive_key(@args);
    is $got_key, decode_base64url($out->[0]), 'right key';
    is $got_nonce, decode_base64url($out->[1]), 'right nonce';
  }
};

# my ($m_key, $m_input, $m_header) = test_init();
sub test_init {
  my $m_key = random_bytes(16);
  my $m_input = random_bytes(5);
  # This header is specific to the padding tests, but can be used
  # elsewhere
  my $m_header = "\xaa\xd2\x05}3S\xb7\xff7\xbd\xe4*\xe1\xd5\x0f\xda";
  $m_header .= pack('L>', 32) . "\0";
  ($m_key, $m_input, $m_header);
}

subtest 'encrypt exceptions' => sub {
  my ($m_key, $m_input, $m_header) = test_init();
  eval { ece_encrypt_aes128gcm($m_input, undef, $m_key, (undef) x 4, 1) };
  like $@, qr/too small/;
#$content, $salt, $key, $private_key, $dh, $auth_secret, $keyid, $rs,
  eval { ece_encrypt_aes128gcm(
    $m_input, undef, $m_key, (undef) x 3,
    random_bytes_b64u(192), # 256 bytes
  ) };
  like $@, qr/keyid is too long/;
};

subtest 'decrypt exceptions' => sub {
  my ($m_key, $m_input, $m_header) = test_init();
#$content, $key, $private_key, $dh, $auth_secret,
  eval { ece_decrypt_aes128gcm(
    ('x' x 16) . pack('L> C', 2, 0) . $m_input,
    $m_key,
  ) };
  like $@, qr/too small/;
  eval { ece_decrypt_aes128gcm(
    $m_header .
      "\xbb\xc7\xb9ev\x0b\xf0f+\x93\xf4" .
      "\xe5\xd6\x94\xb7e\xf0\xcd\x15\x9b(\x01\xa5",
    "d\xc7\x0ed\xa7%U\x14Q\xf2\x08\xdf\xba\xa0\xb9r",
  ) };
  like $@, qr/all zero/;
  eval { ece_decrypt_aes128gcm(
    $m_header .
      "\xb9\xc7\xb9ev\x0b\xf0\x9eB\xb1\x08C8u" .
      "\xa3\x06\xc9x\x06\n\xfc|}\xe9R\x85\x91" .
      "\x8bX\x02`\xf3" .
      "E8z(\xe5%f/H\xc1\xc32\x04\xb1\x95\xb5N\x9ep\xd4\x0e<\xf3" .
      "\xef\x0cg\x1b\xe0\x14I~\xdc",
    "d\xc7\x0ed\xa7%U\x14Q\xf2\x08\xdf\xba\xa0\xb9r",
  ) };
  like $@, qr/record delimiter != 1/;
  eval { ece_decrypt_aes128gcm(
    $m_header .
      "\xba\xc7\xb9ev\x0b\xf0\x9eB\xb1\x08Ji" .
      "\xe4P\x1b\x8dI\xdb\xc6y#MG\xc2W\x16",
    "d\xc7\x0ed\xa7%U\x14Q\xf2\x08\xdf\xba\xa0\xb9r",
  ) };
  like $@, qr/last record delimiter != 2/;
  eval { ece_decrypt_aes128gcm(
    $m_header .
      "\xbb\xc6\xb1\x1dF:~\x0f\x07+\xbe\xaaD" .
      "\xe0\xd6.K\xe5\xf9]%\xe3\x86q\xe0}",
    "d\xc7\x0ed\xa7%U\x14Q\xf2\x08\xdf\xba\xa0\xb9r",
  ) };
  like $@, qr/Decryption error/;
};

sub maybe_decode_base64url { defined($_[0]) ? decode_base64url $_[0] : undef }

# generated from encrypt_data.json from the JavaScript library, then:
# perl -Mojo -e 'print r j f(shift)->slurp' file >file.pl
my @CASES = (
  {
    "encrypted" => "hwaB6ajPR3BbJ_EtJ7DPGwAAEAAALeErM5xhsiAHm4Kqh_SuUT8naH0b1dgCaukr-9b7FRfYEBCadps",
    "input" => "wXe3vEnuHqhdGgrwaaT1j2PLt1aK",
    "params" => {
      "decrypt" => {
        "key" => "0MLhZq8sewP4P2h18tlS2A",
        "salt" => "hwaB6ajPR3BbJ_EtJ7DPGw"
      },
      "encrypt" => {
        "key" => "0MLhZq8sewP4P2h18tlS2A",
        "salt" => "hwaB6ajPR3BbJ_EtJ7DPGw"
      }
    },
    "test" => "useExplicitKey aes128gcm"
  },
  {
    "encrypted" => "sj2q-yxtvnEKrtNyfo-lPwAAEAAAPpHyEJGNkL9xmHAxwv_eieKYQWk",
    "input" => "pHFj",
    "params" => {
      "decrypt" => {
        "authSecret" => "GCIe1dcp-nfsQw5nFoVzmw",
        "key" => "297VgT05oFIZfyasTP_B7w",
        "salt" => "sj2q-yxtvnEKrtNyfo-lPw"
      },
      "encrypt" => {
        "authSecret" => "GCIe1dcp-nfsQw5nFoVzmw",
        "key" => "297VgT05oFIZfyasTP_B7w",
        "salt" => "sj2q-yxtvnEKrtNyfo-lPw"
      }
    },
    "test" => "authenticationSecret aes128gcm"
  },
  {
    "encrypted" => "rNEm6--7fMS1FuTr8btW3AAAEAAAnwgL-gYZKP4cme0fyuMKIISSZEBw8e44aiSVlycIOO9-2HOgcuKuLGJf4f4r7mOcP0aJgOLTbfxQYuZAaJlVAbZc5q23vPKzOzxf2VuKgYvdwfjESSA",
    "input" => "olO7J2DXC6DjHuhke8jmBckEFVheWN22Ib0en7B85t9orab9Lhb0_sifeMcEHBxl4O8xfP_FJlJ5A0FCAvqbzZW4e-qd",
    "params" => {
      "decrypt" => {
        "key" => "ZkBfrd75r93uxCpocaMhoA",
        "salt" => "rNEm6--7fMS1FuTr8btW3A"
      },
      "encrypt" => {
        "key" => "ZkBfrd75r93uxCpocaMhoA",
        "salt" => "rNEm6--7fMS1FuTr8btW3A"
      }
    },
    "test" => "exactlyOneRecord aes128gcm"
  },
  {
    "encrypted" => "phSedT69xhtlKvR3lfkMKQAAAGFBBCp3NKi1owBzC8i3Sgkw15WJTuXkhjlcVdv4S0alC0W8VfNhE8DWxlzwXsImQUpM0zxNWotxRbDXt1yAfiP03d0Q4o4LCPfJr9aJAn9eKE7G_681R7-yoDEHilLcfs_OXATkjCpl99aTApG0dFBudoF9PHQftfLcZo-l8H7rA5frvbFvxj09RngrgnrqrPn4Vahmhg1Jn--fYOf02nW8zw",
    "input" => "n9_vFNekfRIXbmXRjb_1SL0XQWPoJSvmYvtb_g6a90qRdRdhmbDIHeg8B19iCbm732X5s_1VOGWBFivjFCmWQkWcE2_uq_MGPU00SgaS",
    "keys" => {
      "decrypt" => <<'EOF',
-----BEGIN EC PRIVATE KEY-----
MHcCAQEEIJnfq/XwOS2/jEBfeL+Pg1zVxwHmrm0mJn77uMlAc8dFoAoGCCqGSM49
AwEHoUQDQgAEGbC8Rb3pRwtVgyBSUXKAzTEB3SoOEm9RgNAWXftPWOBx67fEc30x
ArDfL4pmmZu+/MTpVZku0buyi1Tbqu7hbA==
-----END EC PRIVATE KEY-----
EOF
      "encrypt" => <<'EOF',
-----BEGIN EC PRIVATE KEY-----
MHcCAQEEIJLIfrqKwtDj7SyyrQUwB0ynXFqoN0hzibDDFQOlFb2soAoGCCqGSM49
AwEHoUQDQgAEKnc0qLWjAHMLyLdKCTDXlYlO5eSGOVxV2/hLRqULRbxV82ETwNbG
XPBewiZBSkzTPE1ai3FFsNe3XIB+I/Td3Q==
-----END EC PRIVATE KEY-----
EOF
    },
    "params" => {
      "decrypt" => {
        "authSecret" => "dYwViyw3w5oIIVNpHBddAQ",
        "salt" => "phSedT69xhtlKvR3lfkMKQ"
      },
      "encrypt" => {
        "authSecret" => "dYwViyw3w5oIIVNpHBddAQ",
        "dh" => "BBmwvEW96UcLVYMgUlFygM0xAd0qDhJvUYDQFl37T1jgceu3xHN9MQKw3y-KZpmbvvzE6VWZLtG7sotU26ru4Ww",
        "rs" => 97,
        "salt" => "phSedT69xhtlKvR3lfkMKQ"
      }
    },
    "test" => "useDH aes128gcm"
  },
);
subtest 'test encryption/decryption' => sub {
  for my $case (@CASES) {
    my ($input, $encrypted) = map decode_base64url($_), @$case{qw(input encrypted)};
    my %mode2keys;
    if (my $keys = $case->{keys}) {
      $mode2keys{$_}{private_key} = Crypt::PK::ECC->new(
        \$keys->{$_}
      ) for qw(encrypt decrypt);
    } else {
      $mode2keys{$_}{key} = decode_base64url $case->{params}{$_}{key}
        for qw(encrypt decrypt);
    }
    my %mode2auth_secret;
    $mode2auth_secret{$_} = maybe_decode_base64url $case->{params}{$_}{authSecret}
      for qw(encrypt decrypt);
    my %mode2dh;
    $mode2dh{$_} = maybe_decode_base64url $case->{params}{$_}{dh}
      for qw(encrypt decrypt);
    my $got_encrypted = ece_encrypt_aes128gcm(
      $input,
      decode_base64url($case->{params}{encrypt}{salt}),
      $mode2keys{encrypt}{key},
      $mode2keys{encrypt}{private_key},
      $mode2dh{encrypt},
      $mode2auth_secret{encrypt},
      $case->{keyid},
      $case->{params}{encrypt}{rs} || 4096,
    );
    is $got_encrypted, $encrypted, "$case->{test} encrypted right" or eval {
      require Text::Diff;
      diag Text::Diff::diff(\join('', map "$_\n", split //, $encrypted), \join('', map "$_\n", split //, $got_encrypted));
    };
    my $got_input = ece_decrypt_aes128gcm(
      $encrypted,
      $mode2keys{decrypt}{key},
      $mode2keys{decrypt}{private_key},
      $mode2dh{decrypt},
      $mode2auth_secret{decrypt},
    );
    is $got_input, $input, "$case->{test} decrypted right" or eval {
      require Text::Diff;
      diag Text::Diff::diff(\join('', map "$_\n", split //, $input), \join('', map "$_\n", split //, $got_input));
    };
  }
};

sub gen_key { Crypt::PK::ECC->new->generate_key('prime256v1') }

done_testing;
