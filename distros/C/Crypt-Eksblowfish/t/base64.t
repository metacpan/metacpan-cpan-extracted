use warnings;
use strict;

use Test::More tests => 49;

BEGIN { use_ok "Crypt::Eksblowfish::Bcrypt", qw(en_base64 de_base64); }

is en_base64(""), "";
is de_base64(""), "";

while(<DATA>) {
	my($hex, $base64) = (/([^ \n]+) ([^ \n]+)/);
	my $bytes = pack("H*", $hex);
	is en_base64($bytes), $base64;
	is de_base64($base64), $bytes;
}

1;

__DATA__
25 HO
6b11 YvC
54e019 TM.X
b7f42420 r9OiG.
ee98fbf36c 5nh560u
fc4f0a3d7822 9C6INVeg
724b0d7bd5aeda aiqLc7Us0e
e4580effb833ab56 3DeM95exozW
67f8868799d147cb86 X9gEf3lPP6sE
695e827fb15247956d57 YT4Ad5DQP3TrTu
a3339ba92b27fd07c286c9 mxMZoQql9OdAfqi
ae1fa7c6e2907627516dfc8e pf8lvsIObgbPZdwM
aaab0dcc66982daa236e7dacae ooqLxEYWJYmhZl0qpe
71c57d5a841b24dd8caae0c6e3d1 aaT7UmOZHL0KosBE27C
b96da52272a5b5a4fd1b55ac943cc1 sU0jGlIjrYR7EzUqjBx/
21c4142be6baddf2b47bee16ae7bf273 GaOSI8Y41dIyc82Upltwau
003ff4216a5843f59e7345bde105881b94 .B9yGUnWO9UcayU72OUGE3O
89c4461e18e325d61acc842cb11191132d61 gaPEFfhhHbWYxGOqqPEPCwzf
2b3794afc652601592033f366434a6f0c96dfa IxcSp6XQW/UQ.x60XBQk6Kjr8e
4e22dc36a3d66f141b56b626723b23a13f6f2faa RgJaLoNUZvOZTpWkahqhmR7tJ4m
18426b5e6bff02889c7fcbb5b70e9cdb5a26792a6d ECHpVkt9.mgad6szru4a0zmkcQnr
4c3c8d04abf2b19cbcb533e124f30a696cccecf5d421 RBwL/ItwqXw6rRNfHNKIYUxK5NVSGO
e12a5202eb8a40855fbadb131e949bb95554e99c879cbf 2QnQ.ssIOGTdsrqRFnQZsTTS4XwFlJ6
