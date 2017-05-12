#!/usr/bin/env perl

use Test::More tests => 4;

use Compress::LZW;
use strictures;

my $testsize = 1024 * 1024 * 4; 

#~ my $testdata = <<'END';
#~ Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.
#~ END

#~ while ( length($testdata) < $testsize ){
  #~ $testdata .= $testdata;
#~ }

#------

#~ my $testdata = '';
#~ my @testwords = split(/\s+/,q[
 #~ Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.
#~ ]);

#----

#~ while ( length($testdata) < $testsize ){
  #~ $testdata .= $testwords[ rand($#testwords) ] . ' ';
#~ }

#~ my $testdata = '';
#~ for ( 1 .. $testsize ){
  #~ $testdata .= chr( rand(127) );
#~ }

my $testdata = '';
seek( DATA, 0, 0 );
$testdata .= $_ while ( <DATA> );
while ( length($testdata) < $testsize ){
  $testdata .= $testdata;
}
close DATA;

ok( my $compdata = compress($testdata), "Compressed large test data" );
cmp_ok( length($compdata), '<', length($testdata), "Data compresses smaller" );

my $decompdata = decompress($compdata);
cmp_ok( length($decompdata), '==', length($testdata), "Large data decompresses to same size" );
is( $decompdata, $testdata, "Data is unchanged" );

__DATA__

IyEvdXNyL2Jpbi9lbnYgcGVybAoKdXNlIFRlc3Q6Ok1vcmUgdGVzdHMgPT4gNDsKCnVzZSBDb21w
cmVzczo6TFpXOwp1c2Ugc3RyaWN0dXJlczsKCm15ICR0ZXN0c2l6ZSA9IDEwMjQgKiAxMDI0ICog
NDsgCgojfiBteSAkdGVzdGRhdGEgPSA8PCdFTkQnOwojfiBMb3JlbSBpcHN1bSBkb2xvciBzaXQg
YW1ldCwgY29uc2VjdGV0dXIgYWRpcGlzaWNpbmcgZWxpdCwgc2VkIGRvIGVpdXNtb2QgdGVtcG9y
IGluY2lkaWR1bnQgdXQgbGFib3JlIGV0IGRvbG9yZSBtYWduYSBhbGlxdWEuIFV0IGVuaW0gYWQg
bWluaW0gdmVuaWFtLCBxdWlzIG5vc3RydWQgZXhlcmNpdGF0aW9uIHVsbGFtY28gbGFib3JpcyBu
aXNpIHV0IGFsaXF1aXAgZXggZWEgY29tbW9kbyBjb25zZXF1YXQuIER1aXMgYXV0ZSBpcnVyZSBk
b2xvciBpbiByZXByZWhlbmRlcml0IGluIHZvbHVwdGF0ZSB2ZWxpdCBlc3NlIGNpbGx1bSBkb2xv
cmUgZXUgZnVnaWF0IG51bGxhIHBhcmlhdHVyLiBFeGNlcHRldXIgc2ludCBvY2NhZWNhdCBjdXBp
ZGF0YXQgbm9uIHByb2lkZW50LCBzdW50IGluIGN1bHBhIHF1aSBvZmZpY2lhIGRlc2VydW50IG1v
bGxpdCBhbmltIGlkIGVzdCBsYWJvcnVtLgojfiBFTkQKCiN+IHdoaWxlICggbGVuZ3RoKCR0ZXN0
ZGF0YSkgPCAkdGVzdHNpemUgKXsKICAjfiAkdGVzdGRhdGEgLj0gJHRlc3RkYXRhOwojfiB9Cgoj
LS0tLS0tCgojfiBteSAkdGVzdGRhdGEgPSAnJzsKI34gbXkgQHRlc3R3b3JkcyA9IHNwbGl0KC9c
cysvLHFbCiAjfiBMb3JlbSBpcHN1bSBkb2xvciBzaXQgYW1ldCwgY29uc2VjdGV0dXIgYWRpcGlz
aWNpbmcgZWxpdCwgc2VkIGRvIGVpdXNtb2QgdGVtcG9yIGluY2lkaWR1bnQgdXQgbGFib3JlIGV0
IGRvbG9yZSBtYWduYSBhbGlxdWEuIFV0IGVuaW0gYWQgbWluaW0gdmVuaWFtLCBxdWlzIG5vc3Ry
dWQgZXhlcmNpdGF0aW9uIHVsbGFtY28gbGFib3JpcyBuaXNpIHV0IGFsaXF1aXAgZXggZWEgY29t
bW9kbyBjb25zZXF1YXQuIER1aXMgYXV0ZSBpcnVyZSBkb2xvciBpbiByZXByZWhlbmRlcml0IGlu
IHZvbHVwdGF0ZSB2ZWxpdCBlc3NlIGNpbGx1bSBkb2xvcmUgZXUgZnVnaWF0IG51bGxhIHBhcmlh
dHVyLiBFeGNlcHRldXIgc2ludCBvY2NhZWNhdCBjdXBpZGF0YXQgbm9uIHByb2lkZW50LCBzdW50
IGluIGN1bHBhIHF1aSBvZmZpY2lhIGRlc2VydW50IG1vbGxpdCBhbmltIGlkIGVzdCBsYWJvcnVt
LgojfiBdKTsKCiMtLS0tCgojfiB3aGlsZSAoIGxlbmd0aCgkdGVzdGRhdGEpIDwgJHRlc3RzaXpl
ICl7CiAgI34gJHRlc3RkYXRhIC49ICR0ZXN0d29yZHNbIHJhbmQoJCN0ZXN0d29yZHMpIF0gLiAn
ICc7CiN+IH0KCiN+IG15ICR0ZXN0ZGF0YSA9ICcnOwojfiBmb3IgKCAxIC4uICR0ZXN0c2l6ZSAp
ewogICN+ICR0ZXN0ZGF0YSAuPSBjaHIoIHJhbmQoMTI3KSApOwojfiB9CgpteSAkdGVzdGRhdGEg
PSAnJzsKc2VlayggREFUQSwgMCwgMCApOwokdGVzdGRhdGEgLj0gJF8gd2hpbGUgKCA8REFUQT4g
KTsKd2hpbGUgKCBsZW5ndGgoJHRlc3RkYXRhKSA8ICR0ZXN0c2l6ZSApewogICR0ZXN0ZGF0YSAu
PSAkdGVzdGRhdGE7Cn0KY2xvc2UgREFUQTsKCm9rKCBteSAkY29tcGRhdGEgPSBjb21wcmVzcygk
dGVzdGRhdGEpLCAiQ29tcHJlc3NlZCBsYXJnZSB0ZXN0IGRhdGEiICk7CmNtcF9vayggbGVuZ3Ro
KCRjb21wZGF0YSksICc8JywgbGVuZ3RoKCR0ZXN0ZGF0YSksICJEYXRhIGNvbXByZXNzZXMgc21h
bGxlciIgKTsKCm15ICRkZWNvbXBkYXRhID0gZGVjb21wcmVzcygkY29tcGRhdGEpOwpjbXBfb2so
IGxlbmd0aCgkZGVjb21wZGF0YSksICc9PScsIGxlbmd0aCgkdGVzdGRhdGEpLCAiTGFyZ2UgZGF0
YSBkZWNvbXByZXNzZXMgdG8gc2FtZSBzaXplIiApOwppcyggJGRlY29tcGRhdGEsICR0ZXN0ZGF0
YSwgIkRhdGEgaXMgdW5jaGFuZ2VkIiApOwoKX19EQVRBX18K
