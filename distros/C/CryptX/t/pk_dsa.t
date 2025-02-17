use strict;
use warnings;
use Test::More tests => 66;

use Crypt::PK::DSA qw(dsa_encrypt dsa_decrypt dsa_sign_message dsa_verify_message dsa_sign_hash dsa_verify_hash);
use Crypt::Misc 'decode_b64';

{
  my $k;

  $k = eval { Crypt::PK::DSA->new('t/data/cryptx_priv_dsa1.der') };
  diag("$@") if $@;
  ok($k, 'load cryptx_priv_dsa1.der');
  ok($k->is_private, 'is_private cryptx_priv_dsa1.der');
  is($k->size, 256, 'size');
  is(uc($k->key2hash->{x}), '6C801901AC74E2DC714D75A9F6969483CF0239D142AB7E3F329ED8D49E07', 'key2hash');

  $k = eval { Crypt::PK::DSA->new('t/data/cryptx_priv_dsa2.der') };
  diag("$@") if $@;
  ok($k, 'load cryptx_priv_dsa2.der');
  ok($k->is_private, 'is_private cryptx_priv_dsa2.der');

  $k = eval { Crypt::PK::DSA->new('t/data/cryptx_pub_dsa1.der') };
  diag("$@") if $@;
  ok($k, 'load cryptx_pub_dsa1.der');
  ok(!$k->is_private, 'is_private cryptx_pub_dsa1.der');

  $k = eval { Crypt::PK::DSA->new('t/data/cryptx_pub_dsa2.der') };
  diag("$@") if $@;
  ok($k, 'load cryptx_pub_dsa2.der');
  ok(!$k->is_private, 'is_private cryptx_pub_dsa2.der');

  $k = eval { Crypt::PK::DSA->new('t/data/openssl_dsa1.der') };
  diag("$@") if $@;
  ok($k, 'load openssl_dsa1.der');
  ok($k->is_private, 'is_private openssl_dsa1.der');

  $k = eval { Crypt::PK::DSA->new('t/data/openssl_dsa2.der') };
  diag("$@") if $@;
  ok($k, 'load openssl_dsa2.der');
  ok($k->is_private, 'is_private openssl_dsa2.der');

  $k = eval { Crypt::PK::DSA->new('t/data/cryptx_priv_dsa1.pem') };
  diag("$@") if $@;
  ok($k, 'load cryptx_priv_dsa1.pem');
  ok($k->is_private, 'is_private cryptx_priv_dsa1.pem');

  $k = eval { Crypt::PK::DSA->new('t/data/cryptx_priv_dsa2.pem') };
  diag("$@") if $@;
  ok($k, 'load cryptx_priv_dsa2.pem');
  ok($k->is_private, 'is_private cryptx_priv_dsa2.pem');

  $k = eval { Crypt::PK::DSA->new('t/data/cryptx_pub_dsa1.pem') };
  diag("$@") if $@;
  ok($k, 'load cryptx_pub_dsa1.pem');
  ok(!$k->is_private, 'is_private cryptx_pub_dsa1.pem');

  $k = eval { Crypt::PK::DSA->new('t/data/cryptx_pub_dsa2.pem') };
  diag("$@") if $@;
  ok($k, 'load cryptx_pub_dsa2.pem');
  ok(!$k->is_private, 'is_private cryptx_pub_dsa2.pem');

  $k = eval { Crypt::PK::DSA->new('t/data/openssl_dsa1.pem') };
  diag("$@") if $@;
  ok($k, 'load openssl_dsa1.pem');
  ok($k->is_private, 'is_private openssl_dsa1.pem');

  $k = eval { Crypt::PK::DSA->new('t/data/openssl_dsa2.pem') };
  diag("$@") if $@;
  ok($k, 'load openssl_dsa2.pem');
  ok($k->is_private, 'is_private openssl_dsa2.pem');
}

{
  my $pr1 = Crypt::PK::DSA->new;
  my $i_pr1 = eval { $pr1->import_key('t/data/cryptx_priv_dsa1.der') };
  diag("$@") if $@;
  ok($i_pr1, 'import_key cryptx_priv_dsa1.der');
  my $pu1 = Crypt::PK::DSA->new;
  my $i_pu1 = eval { $pu1->import_key('t/data/cryptx_pub_dsa1.der') };
  diag("$@") if $@;
  ok($i_pu1, 'import_key cryptx_pub_dsa1.der');

  my $ct = eval { $pu1->encrypt("secret message") };
  diag("$@") if $@;
  ok(length $ct > 200, 'encrypt ' . length($ct));
  my $pt = eval { $pr1->decrypt($ct) };
  diag("$@") if $@;
  is($pt, "secret message", 'decrypt');
  #XXX-FIXME somwhere here a crash happens on solaris - http://ppm4.activestate.com/sun4-solaris/5.14/1400/M/MI/MIK/CryptX-0.017.d/log-20130924T103600.txt
  my $sig = eval { $pr1->sign_message("message") };
  diag("$@") if $@;
  ok(length $sig > 60, 'sign_message ' . length($sig));
  my $ver = eval { $pu1->verify_message($sig, "message") };
  diag("$@") if $@;
  ok($ver, 'verify_message');

  my $hash = pack("H*","04624fae618e9ad0c5e479f62e1420c71fff34dd");
  $sig = eval { $pr1->sign_hash($hash) };
  diag("$@") if $@;
  ok(length $sig > 60, 'sign_hash ' . length($sig));
  $ver = eval { $pu1->verify_hash($sig, $hash) };
  diag("$@") if $@;
  ok($ver, 'verify_hash');

  my $pr2 = Crypt::PK::DSA->new;
  my $i_pr2 = eval { $pr2->import_key('t/data/cryptx_priv_dsa2.der') };
  diag("$@") if $@;
  ok($i_pr2, 'import cryptx_priv_dsa2.der');
  my $pu2 = Crypt::PK::DSA->new;
  my $i_pu2 = eval { $pu2->import_key('t/data/cryptx_pub_dsa2.der') };
  diag("$@") if $@;
  ok($i_pu2, 'import cryptx_pub_dsa2.der');

  #my $ss1 = $pr1->shared_secret($pu2);
  #my $ss2 = $pr2->shared_secret($pu1);
  #is(unpack("H*",$ss1), unpack("H*",$ss2), 'shared_secret');
}

{
  my $k = Crypt::PK::DSA->new;
  my $gen = eval { $k->generate_key(\<<"MARKER") };
-----BEGIN DSA PARAMETERS-----
MIICLAKCAQEA3dZSaDnP5LgH44CDYc2wfGLtq4rbBgtOVvLkvh4j29CTiOUDRC1H
ivkTdtGrI3DdrAFeKieFYDJ1RJFbru+8/RYE7YfaR5Y3OUI4Vdf26guMViLLVjSL
W43Td50ZZziLmmYzn3cliokShe9f5/mtuLJ0uJRq7QxgHj7bgmvJvORvi4QXSCOn
nmCOgEfhoU1Vj/PePjtjeZWbLyGFXHC7vpvqePrsFtbUlBzIr2mr7JuHB3rAl7A4
1VL6lexqONRa4rQuVxiX0vp3iit9Cx02EwrZODdlifssd9Kceu2UsvifjmCBPyv8
6nmmEOtxh/xduuOBtVWXeZHSwIDUQvSJFwIhAK/ZDSl9iNuZ/TRwqQ3JRU3MjXCU
/US6/LU1qqjQATk7AoIBACoqauphNZmUZYOilArBfYCMtUwS0FNG6wfUMWDMd46z
/hv7equa9b75sT1uHyiUVuPD2hRhR3xNYkKSX9Kx8NGKj/bGDyaEW+Ud852N6BTo
9vzZ4GjKVBGe44Wa8eynVgVE5/r0z6OfHkV7uOxlGEdYgIooUbIsY7w0DmaR2FVZ
AMjGMg+L6CpulfvdETYi9LQafY4jRkgGWTc9h/2RYGhQUti1PheY1AlDYpubO8am
ZBG6vMBaANLx6Pv+lle4ltVvDVhwTK5APyfN1vVdEvVmU1/6zHZEnuiDAT8XI1rH
S1+SGX11RIn6uPVL1c0RjgW8/JZ6EeM8NvLdBiYYBuI=
-----END DSA PARAMETERS-----
MARKER
  diag("$@") if $@;
  ok($gen, 'generate_key PEM');
  ok($k->is_private, 'is_private');
  my $exp;
  $exp = eval { $k->export_key_pem('private') };
  diag("$@") if $@;
  ok($exp, 'export_key_pem pri');
  $exp = eval { $k->export_key_pem('public') };
  diag("$@") if $@;
  ok($exp, 'export_key_pem pub');
  $exp = eval { $k->export_key_der('private') };
  diag("$@") if $@;
  ok($exp, 'export_key_der pri');
  $exp = eval { $k->export_key_der('public') };
  diag("$@") if $@;
  ok($exp, 'export_key_der pub');
}

{
  my $k = Crypt::PK::DSA->new;
  my $gen = eval { $k->generate_key(\decode_b64(<<"MARKER")) };
MIICLAKCAQEA3dZSaDnP5LgH44CDYc2wfGLtq4rbBgtOVvLkvh4j29CTiOUDRC1H
ivkTdtGrI3DdrAFeKieFYDJ1RJFbru+8/RYE7YfaR5Y3OUI4Vdf26guMViLLVjSL
W43Td50ZZziLmmYzn3cliokShe9f5/mtuLJ0uJRq7QxgHj7bgmvJvORvi4QXSCOn
nmCOgEfhoU1Vj/PePjtjeZWbLyGFXHC7vpvqePrsFtbUlBzIr2mr7JuHB3rAl7A4
1VL6lexqONRa4rQuVxiX0vp3iit9Cx02EwrZODdlifssd9Kceu2UsvifjmCBPyv8
6nmmEOtxh/xduuOBtVWXeZHSwIDUQvSJFwIhAK/ZDSl9iNuZ/TRwqQ3JRU3MjXCU
/US6/LU1qqjQATk7AoIBACoqauphNZmUZYOilArBfYCMtUwS0FNG6wfUMWDMd46z
/hv7equa9b75sT1uHyiUVuPD2hRhR3xNYkKSX9Kx8NGKj/bGDyaEW+Ud852N6BTo
9vzZ4GjKVBGe44Wa8eynVgVE5/r0z6OfHkV7uOxlGEdYgIooUbIsY7w0DmaR2FVZ
AMjGMg+L6CpulfvdETYi9LQafY4jRkgGWTc9h/2RYGhQUti1PheY1AlDYpubO8am
ZBG6vMBaANLx6Pv+lle4ltVvDVhwTK5APyfN1vVdEvVmU1/6zHZEnuiDAT8XI1rH
S1+SGX11RIn6uPVL1c0RjgW8/JZ6EeM8NvLdBiYYBuI=
MARKER
  diag("$@") if $@;
  ok($gen, 'generate_key DER');
  ok($k->is_private, 'is_private');
  my $exp;
  $exp = eval { $k->export_key_pem('private') };
  diag("$@") if $@;
  ok($exp, 'export_key_pem pri');
  $exp = eval { $k->export_key_pem('public') };
  diag("$@") if $@;
  ok($exp, 'export_key_pem pub');
  $exp = eval { $k->export_key_der('private') };
  diag("$@") if $@;
  ok($exp, 'export_key_der pri');
  $exp = eval { $k->export_key_der('public') };
  diag("$@") if $@;
  ok($exp, 'export_key_der pub');
}

{
  my $k = Crypt::PK::DSA->new;
  my $gen = eval { $k->generate_key({
   p => "A5903F7DF15D5C0769797820".
        "6CFEED0113CD1C15298198E9".
        "1F2231135A7BC42568BE8F8D".
        "357B7EE9AD4E99F9F628EA2C".
        "9294425FA1C7732253D478CD".
        "1E242FA81B12C2A9ADB46D14".
        "AC83875A2D8BF6A1DCF57EC6".
        "4668DB3751358EB4F5A620A9".
        "0F28C3D5F62DC1E85E3CC724".
        "A12018B038FFA4B917AABC66".
        "543BDD11784134CB",
   q => "B3CA2D8B0823160915E6B73E".
        "DD3B0015DFE1E897",
   g => "5C9F25D69C86E8002BE04F56".
        "90230BD008A816E7C8E9A96E".
        "C0DBC630C62A8B42E41C8504".
        "E682F52C02CDA74740CFA1A4".
        "A608B8D827C5762EB69FED68".
        "3D17DBC9050C16DEB9EC5A3E".
        "02DF7B0E338AFFC01F878352".
        "A2C82FB458F95DD60A7E23FE".
        "322173F34F98452B0D16DCE2".
        "23B15840F82B6AFCDFC6D848".
        "9C5859DA0E4BE8B9",
  }) };
  diag("$@") if $@;
  ok($gen, 'generate_key HASH');
  ok($k->is_private, 'is_private');
  my $exp;
  $exp = eval { $k->export_key_pem('private') };
  diag("$@") if $@;
  ok($exp, 'export_key_pem pri');
  $exp = eval { $k->export_key_pem('public') };
  diag("$@") if $@;
  ok($exp, 'export_key_pem pub');
  $exp = eval { $k->export_key_der('private') };
  diag("$@") if $@;
  ok($exp, 'export_key_der pri');
  $exp = eval { $k->export_key_der('public') };
  diag("$@") if $@;
  ok($exp, 'export_key_der pub');
}

{
  my $k = Crypt::PK::DSA->new;
  my $gen = eval { $k->generate_key(20, 128) };
  diag("$@") if $@;
  ok($gen, 'generate_key size');
  ok($k->is_private, 'is_private');
  my $exp;
  $exp = eval { $k->export_key_pem('private') };
  diag("$@") if $@;
  ok($k->export_key_pem('private'), 'export_key_pem pri');
  $exp = eval { $k->export_key_pem('public') };
  diag("$@") if $@;
  ok($k->export_key_pem('public'), 'export_key_pem pub');
  $exp = eval { $k->export_key_der('private') };
  diag("$@") if $@;
  ok($k->export_key_der('private'), 'export_key_der pri');
  $exp = eval { $k->export_key_der('public') };
  diag("$@") if $@;
  ok($k->export_key_der('public'), 'export_key_der pub');
}

{
  my $ct = eval { dsa_encrypt('t/data/cryptx_pub_dsa1.der', 'test string') };
  diag("$@") if $@;
  ok($ct, 'dsa_encrypt');
  my $pt = eval { dsa_decrypt('t/data/cryptx_priv_dsa1.der', $ct) };
  diag("$@") if $@;
  ok($pt, 'dsa_decrypt');
  my $sig = eval { dsa_sign_message('t/data/cryptx_priv_dsa1.der', 'test string') };
  diag("$@") if $@;
  ok($sig, 'dsa_sign_message');
  my $ver = eval { dsa_verify_message('t/data/cryptx_pub_dsa1.der', $sig, 'test string') };
  diag("$@") if $@;
  ok($ver, 'dsa_verify_message');
  my $hash = pack("H*","04624fae618e9ad0c5e479f62e1420c71fff34dd");
  $sig = eval { dsa_sign_hash('t/data/cryptx_priv_dsa1.der', $hash) };
  diag("$@") if $@;
  ok($sig, 'dsa_sign_hash');
  $ver = eval { dsa_verify_hash('t/data/cryptx_pub_dsa1.der', $sig, $hash) };
  diag("$@") if $@;
  ok($ver, 'dsa_verify_hash');
}
