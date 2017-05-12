use strict;

use Test;
use Data::ToruCa;

BEGIN {
    plan tests => 2;
}

my $toruca = Data::ToruCa->new
    ({
	version => '1.0',
	type    => 'SNIP',
	url     => 'http://example.jp/toruca_detail.trc',
	data1   => 'data1',
	data2   => 'data2',
	data3   => 'data3',
	cat     => '0001',
    });


ok($toruca->build, 
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

my $mime = "MIME-Version: 1.0\r\n" .
    "Content-Type: multipart/mixed;boundary=\"0986744875\"\r\n" .
    "\r\n" .
    "--0986744875\r\n" .
    "Content-Type: text/html; charset=Shift_JIS\r\n" .
    "Content-Transfer-Encoding: 8bit\r\n" .
    "\r\n" .
    "test\r\n" .
    "--0986744875--";
$toruca->mime($mime);

ok($toruca->detail_build, 
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
