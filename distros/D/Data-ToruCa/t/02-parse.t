use strict;

use Test;
use Data::ToruCa;

BEGIN {
    plan tests => 18;
}

my $toruca = Data::ToruCa->new
    (
     "ToruCa\r\n" . 
     "Version: 1.0\r\n" . 
     "Type: SNIP\r\n" . 
     "\r\n" . 
     "URL: http://example.jp/toruca_detail.trc\r\n" . 
     "Data1: ZGF0YTE=\r\n" . 
     "Data2: ZGF0YTI=\r\n" . 
     "Data3: ZGF0YTM=\r\n" . 
     "Cat: 0001\r\n" . 
     "\r\n");

ok($toruca->version, '1.0');
ok($toruca->type, 'SNIP');
ok($toruca->url, 'http://example.jp/toruca_detail.trc');
ok($toruca->data1, 'data1');
ok($toruca->data2, 'data2');
ok($toruca->data3, 'data3');
ok($toruca->cat, '0001');
ok($toruca->mime, undef);
ok($toruca->pict, "\xf8\x9f");

my $mime = "MIME-Version: 1.0\r\n" .
    "Content-Type: multipart/mixed;boundary=\"0986744875\"\r\n" .
    "\r\n" .
    "--0986744875\r\n" .
    "Content-Type: text/html; charset=Shift_JIS\r\n" .
    "Content-Transfer-Encoding: 8bit\r\n" .
    "\r\n" .
    "test\r\n" .
    "--0986744875--";

$toruca = Data::ToruCa->new
    (
     "ToruCa\r\n" . 
     "Version: 1.0\r\n" . 
     "Type: CARD\r\n" . 
     "\r\n" . 
     "URL: http://example.jp/toruca_detail.trc\r\n" . 
     "Data1: ZGF0YTE=\r\n" . 
     "Data2: ZGF0YTI=\r\n" . 
     "Data3: ZGF0YTM=\r\n" . 
     "Cat: 0001\r\n" . 
     "\r\n" .
     $mime);

ok($toruca->version, '1.0');
ok($toruca->type, 'CARD');
ok($toruca->url, 'http://example.jp/toruca_detail.trc');
ok($toruca->data1, 'data1');
ok($toruca->data2, 'data2');
ok($toruca->data3, 'data3');
ok($toruca->cat, '0001');
ok($toruca->mime, $mime);
ok($toruca->pict, "\xf8\x9f");

