#!/usr/bin/env perl

use Test::More tests => 13;
use Math::BigInt try => 'GMP,Pari';
use strict;
use warnings;
no strict 'refs';

use lib '../lib';

our $module;
BEGIN {
    our $module = 'Crypt::MagicSignatures::Key';
    use_ok($module, qw/b64url_encode b64url_decode/);   # 1
};

# MiniMe-Test
my $encodedPrivateKey = 'RSA.hkwS0EK5Mg1dpwA4shK5FNtHmo9F7sIP6gKJ5fyFWNotO'.
  'bbbckq4dk4dhldMKF42b2FPsci109MF7NsdNYQ0kXd3jNs9VLCHUujxiafVjhw06hFNWBmv'.
  'ptZud7KouRHz4Eq2sB-hM75MEn3IJElOquYzzUHi7Q2AMalJvIkG26c=.AQAB.JrT8YywoB'.
  'oYVrRGCRcjhsWI2NBUBWfxy68aJilEK-f4ANPdALqPcoLSJC_RTTftBgz6v4pTv2zqiJY9N'.
  'zuPo5mijN4jJWpCA-3HOr9w8Kf8uLwzMVzNJNWD_cCqS5XjWBwWTObeMexrZTgYqhymbfxx'.
  'z6Nqxx352oPh4vycnXOk=';

my $test_msg = '<?xml version="1.0" encoding="UTF-8"?>
<entry xmlns="http://www.w3.org/2005/Atom" xmlns:activity="http://activitystrea.ms/spec/1.0/">
  <id>mimime:12345689</id>
  <title>Tuomas is now following Pamela Anderson</title>
  <content type="text/html">Tuomas is now following Pamela Anderson</content>
  <updated>2010-07-26T06:42:55+02:00</updated>
  <author>
    <uri>http://lobstermonster.org/tuomas</uri>
    <name>Tuomas Koski</name>
  </author>
  <activity:actor>
    <activity:object-type>http://activitystrea.ms/schema/1.0/person</activity:object-type>
    <id>tuomas@lobstermonster.org</id>
    <title>Tuomas Koski</title>
    <link ref="alternate" type="text/html" href="http://identi.ca/tkoski"/>
  </activity:actor>
  <activity:verb>http://activitystrea.ms/schema/1.0/follow</activity:verb>
</entry>
';

my $mkey = Crypt::MagicSignatures::Key->new($encodedPrivateKey);

is($mkey->n, '943066743310294637166748645282057347360756671091156842137084'.
     '35141648141927985088529225709405863492354842374715166239287844430890'.
     '04299402993407490921024495696687088026331904825469176835780456268938'.
     '49274386282190086526533262351511700816722159326410823741996001680552'.
     '36119049012074140202348780844511591714446247', "MiniMe Modulus");
is($mkey->_emLen, 128, 'MiniMe k');
is($mkey->d, '271809629894382644940151596208748969807854078768342487314454'.
     '22149176675051920447033409286738290667975199011489613120739553129607'.
     '42820260664090118498058068890245077295780990608282043243495479227665'.
     '68948318488153478026241124799584980220284065382244666330019163253412'.
     '99059585838510324221094995040115830750141673', 'MiniMe d');

my $emsa = *{"${module}::_emsa_encode"}->(b64url_encode($test_msg),
				       $mkey->_emLen,
				       'sha-256');

is($mkey->size, 1024, 'Correct key size');

is(*{"${module}::_os2ip"}->($emsa), '5486124068793688683255936251187209270'.
     '07439263593233207011200198845619738175967294716517569953636279361328'.
     '47253378721117449581838627446479032241037182456702996144987007100062'.
     '64535421091908069935709303403272242499531581061652193678930299235825'.
     '807389982341969138792568181955265625405564094607923748235797538',
     'MiniMe Emsa');

my $s  = *{"${module}::_rsasp1"}->($mkey, *{"${module}::_os2ip"}->($emsa));

is ($s, '73566588907461886099519843442396193568480155532931162082566271355'.
      '1463198070878875086737348779970249327936945557033384802550845145427'.
      '3939279392302681231072454777631917225158347073586290871595765317421'.
      '4372063208691722812578754298808626514003045898777784320439862473316'.
      '607422581254522605209868208033224632023651', 'MiniMe rsasp1');

my $sig =
  'aMMmGLJd81bgBdU26WjVCT1zIH17ND0dlfArs1Kii_fVYFyz6IEyQzM3GddvzAfJ51vo-'.
  'uN_RY9TEHtoHp12N9Abg9AbCcrPcBGvcP7VBhFWw857v_sYlbD6nek9cX9JKBu-C_Xf20'.
  'QGuE5dPFL0S4kZsuemeQ8p6cJAj_RbumM=';

is (b64url_encode(*{"${module}::_i2osp"}->($s, $mkey->_emLen)),
    $sig, 'MiniMe signature 1');

is (b64url_encode(*{"${module}::_sign_emsa_pkcs1_v1_5"}->($mkey, b64url_encode($test_msg))), $sig, 'MiniMe signature 2');

is($mkey->sign(b64url_encode($test_msg)),
   $sig, 'MiniMe signature 3');

ok($mkey->verify(b64url_encode($test_msg), $sig), 'Signature is valid');
ok(!$mkey->verify(b64url_encode($test_msg.'!'), $sig), 'Signature is not valid');
{
  local $SIG{__WARN__} = sub {};
  ok(!$mkey->verify(b64url_encode($test_msg), 'a' . $sig), 'Signature is not valid');
};
