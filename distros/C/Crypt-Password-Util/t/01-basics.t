#!perl

use 5.010;
use strict;
use warnings;

use Config;
use Crypt::Password::Util qw(crypt_type looks_like_crypt crypt);
use Sort::Versions;
use Test::More 0.98;

is( crypt_type('$$.Pw5vNt/...'), "CRYPT");
is( crypt_type('_9G..8147mpcfKT8g0U.'), "EXT-DES");
is( crypt_type('$1$$oXYGukVGYa16SN.Pw5vNt/'), "MD5-CRYPT");
is( crypt_type('$apr1$x$A8hldSzKARXWgJiwY6zTC.'), "MD5-CRYPT");
is( crypt_type('$apr1$12345678$A8hldSzKARXWgJiwY6zTC.'), "MD5-CRYPT");
is( crypt_type('$5$123456789$'.("a" x 43)), "SSHA256");
is( crypt_type('$5$rounds=5000$123456789$'.("a" x 43)), "SSHA256", "SSHA256 + rounds");
is( crypt_type('$6$12345678$'.("a" x 86)), "SSHA512");
is( crypt_type('$6$rounds=999999999$12345678$'.("a" x 86)), "SSHA512", "SSHA512 + rounds");
is( crypt_type('1a1dc91c907325c69271ddf0c944bc72'), "PLAIN-MD5");
is( crypt_type('$2a$08$TTSynMjJTrXiv3qEZFyM1.H9tjv71i57p2r63QEJe/2p0p/m1GIy2'), "BCRYPT");
ok(!crypt_type('foo'));

is_deeply( crypt_type('$$.Pw5vNt/...', 1), {type=>"CRYPT", salt=>'$$', hash=>'.Pw5vNt/...'});
is_deeply( crypt_type('_9G..8147mpcfKT8g0U.', 1), {type=>"EXT-DES", salt=>'_9G..8147', hash=>'mpcfKT8g0U.'});
is_deeply( crypt_type('$1$$oXYGukVGYa16SN.Pw5vNt/', 1), {type=>"MD5-CRYPT", header=>'$1$', salt=>'', hash=>'oXYGukVGYa16SN.Pw5vNt/'});
is_deeply( crypt_type('$apr1$x$A8hldSzKARXWgJiwY6zTC.', 1), {type=>"MD5-CRYPT", header=>'$apr1$', salt=>'x', hash=>'A8hldSzKARXWgJiwY6zTC.'});
is_deeply( crypt_type('$apr1$12345678$A8hldSzKARXWgJiwY6zTC.', 1), {type=>"MD5-CRYPT", header=>'$apr1$', salt=>'12345678', hash=>'A8hldSzKARXWgJiwY6zTC.'});
is_deeply( crypt_type('$5$123456789$'.("a" x 43), 1), {type=>"SSHA256", header=>'$5$', salt=>'123456789', hash=>('a'x43)});
is_deeply( crypt_type('$6$12345678$'.("a" x 86), 1), {type=>"SSHA512", header=>'$6$', salt=>'12345678', hash=>('a'x86)});
is_deeply( crypt_type('1a1dc91c907325c69271ddf0c944bc72', 1), {type=>"PLAIN-MD5", hash=>'1a1dc91c907325c69271ddf0c944bc72'});
is_deeply( crypt_type('$2a$08$TTSynMjJTrXiv3qEZFyM1.H9tjv71i57p2r63QEJe/2p0p/m1GIy2', 1), {type=>"BCRYPT", header=>'$2a$', cost=>'08', salt=>'TTSynMjJTrXiv3qEZFyM1.', hash=>'H9tjv71i57p2r63QEJe/2p0p/m1GIy2'});
ok(!crypt_type('foo', 1));

ok( looks_like_crypt('$6$12345678$'.("a" x 86)));
ok(!looks_like_crypt('foo'));

ok(crypt_type(crypt("foo")), "crypt() succeeds");
if ($Config{gnulibc_version} &&
        versioncmp("v$Config{gnulibc_version}", "v2.7") >= 0) {
    note "we are running under glibc 2.7+, SSHA512 should be available";
    like(crypt("foo"), qr/^\$6\$/, "crypt() produces SSHA512");
} else {
    note "can't detect glibc 2.7+, skipping SSHA512 test";
}

# just some sanity checks, print several crypts
{
    diag "Some crypt() results on this system: ",
        explain [map {crypt(rand())} 1..5];
}

done_testing();
