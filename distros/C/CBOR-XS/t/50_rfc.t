BEGIN { $| = 1; print "1..78\n"; }

# examples from rfc7049

use Data::Dumper;
use CBOR::XS;

binmode DATA;
binmode STDOUT, ":utf8";

my $test;

sub ok($;$) {
   print $_[0] ? "" : "not ", "ok ", ++$test, " - $_[1]\n";
}

$Data::Dumper::Terse     = 1;
$Data::Dumper::Sortkeys  = 1;
$Data::Dumper::Pair      = ',';
$Data::Dumper::Useqq     = 1;
$Data::Dumper::Indent    = 0;
$Data::Dumper::Quotekeys = 1;

while (<DATA>) {
   next unless /^([<>\+*])\s*(.*?)\s*0x([0-9a-f]+)$/;
   my ($dir, $val, $hex) = ($1, $2, $3);

   my $src = $val;
   $src =~ y/_//d;
   utf8::decode $src if $src =~ /[\x80-\xff]/;

   my $bin = pack "H*", $hex;

   if ($dir eq "+") {
      my $dec = decode_cbor $bin;
      my $str = $dec;
      ok ($str eq $src, "<$dir,$val,$hex> dec <$str> eq <$src>");
      my $enc = unpack "H*", encode_cbor $dec;
      ok ($enc eq $hex, "<$dir,$val,$hex> enc <$enc> eq <$hex>");
   }

   if ($dir eq "<") {
      my $dec = decode_cbor $bin;
      my $str = $dec;

      $str = Dumper $str if ref $str;

      ok ($str eq $src, "<$dir,$val,$hex> dec <$str> eq <$src>");
   }
   #$src = eval $src if $src =~ /^[\[\{]/;

   if ($dir eq "*") {
      my $dec = decode_cbor $bin;
      my $enc = unpack "H*", encode_cbor $dec;
      ok ($enc eq $hex, "<$dir,$val,$hex> enc <$enc> eq <$hex>");
   }

}

# first char
# < decode, check
# + decode, check, encode, check
# * decode, encode, check

__DATA__
+  0                             0x00
+  1                             0x01
+  10                            0x0a
+  23                            0x17
+  24                            0x1818
+  25                            0x1819
+  100                           0x1864
+  1000                          0x1903e8
+  1000000                       0x1a000f4240
   1000000000000                 0x1b000000e8d4a51000
   18446744073709551615          0x1bffffffffffffffff
   18446744073709551616          0xc249010000000000000000
   -18446744073709551616         0x3bffffffffffffffff
   -18446744073709551617         0xc349010000000000000000
+  -1                            0x20
+  -10                           0x29
+  -100                          0x3863
+  -1000                         0x3903e7
<  0                             0xf90000
   -0                            0xf98000
<  1                             0xf93c00
*  1.1                           0xfb3ff199999999999a
<  1.5                           0xf93e00
<  65504                         0xf97bff
<  100000                        0xfa47c35000
*  3.4028234663852886e+38        0xfa7f7fffff
*  1e+300                        0xfb7e37e43c8800759c
   5.960464477539063e-8          0xf90001
   0.00006103515625              0xf90400
<  -4                            0xf9c400
*  -4.1                          0xfbc010666666666666
   Infinity                      0xf97c00
   NaN                           0xf97e00
   -Infinity                     0xf9fc00
*  Infinity                      0xfa7f800000
   NaN                           0xfa7fc00000
*  -Infinity                     0xfaff800000
   Infinity                      0xfb7ff0000000000000
*  NaN                           0xfb7ff8000000000000
   -Infinity                     0xfbfff0000000000000
*  false                         0xf4
*  true                          0xf5
*  null                          0xf6
*  undefined                     0xf7
   simple(16)                    0xf0
   simple(24)                    0xf818
   simple(255)                   0xf8ff
   0("2013-03-21T20:04:00Z")     0xc074323031332d30332d32315432303a30343a30305a
*  1(1363896240)                 0xc11a514b67b0
*  1(1363896240.5)               0xc1fb41d452d9ec200000
   23(h'01020304')               0xd74401020304
*  24(h'6449455446')             0xd818456449455446
   32("http://www.example.com")  0xd82076687474703a2f2f7777772e6578616d706c652e636f6d
*  h''                           0x40
*  h'01020304'                   0x4401020304
*  ""                            0x60
+  a                             0x6161
+  IETF                          0x6449455446
+  "\                            0x62225c
+  ü                             0x62c3bc
+  水                            0x63e6b0b4
+  𐅑                             0x64f0908591
*  []                            0x80
*  [1,2,3]                       0x83010203
*  [1,[2,3],[4,5]]               0x8301820203820405
*  [1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25]0x98190102030405060708090a0b0c0d0e0f101112131415161718181819
*  {}                            0xa0
   {1,2,3,4}                     0xa201020304 # fails because of broken data::dumper
<  {"a",1,"b",[2,3]}             0xa26161016162820203
<  ["a",{"b","c"}]               0x826161a161626163
<  {"a","A","b","B","c","C","d","D","e","E"}0xa56161614161626142616361436164614461656145
   (_h'0102',h'030405')          0x5f42010243030405ff
<  streaming                     0x7f657374726561646d696e67ff
<  [_]                           0x9fff
<  [_1,[2,3],[_4,5]]             0x9f018202039f0405ffff
<  [_1,[2,3],[4,5]]              0x9f01820203820405ff
<  [1,[2,3],[_4,5]]              0x83018202039f0405ff
<  [1,[_2,3],[4,5]]              0x83019f0203ff820405
<  [_1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25]0x9f0102030405060708090a0b0c0d0e0f101112131415161718181819ff
<  {_"a",1,"b",[_2,3]}           0xbf61610161629f0203ffff
<  ["a",{_"b","c"}]              0x826161bf61626163ff
   {_"Fun",true,"Amt",-2}        0xbf6346756ef563416d7421ff
   
