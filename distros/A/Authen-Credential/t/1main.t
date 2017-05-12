#!perl

use strict;
use warnings;
use Test::More tests => 37;

use Authen::Credential;

my($cred, $string);

#
# parsing not ok
#

foreach $string (
    "*",
    " , ",
    "key=value",
    "scheme =value",
    "scheme key==",
    "scheme key=1 key=2",
    ) {
    $@ = "";
    eval { Authen::Credential->parse($string) };
    ok($@, "parse '$string'");
}

#
# parsing ok but checking not ok
#

foreach $string (
    "none foo=bar",
    "plain",
    "plain name=joe password=sekret",
    "f00bar",
    ) {
    $@ = "";
    eval { Authen::Credential->parse($string) };
    ok($@, "parse '$string'");
}

#
# parsing ok and checking ok
#

foreach $string (
    "",
    "none",
    "plain name=anonymous pass=",
    "plain name=joe pass=sekret",
    "plain name=joe,pass=sekret",
    "plain name=joe, pass=sekret",
    "x509",
    "x509 cert=/foo/cert.pem key=/foo/key.pem",
    "x509 cert=/foo/cert.pem key=/foo/key.pem ca=/foo pass=%20",
    ) {
    $cred = Authen::Credential->parse($string);
    ok($cred, "parse '$string'");
    ok($cred->check() ? 1 : 0, "check '$string'");
}

#
# new ok and preparing ok
#

$string = "HTTP.Basic";
$cred = Authen::Credential->new(
    scheme => "plain",
    name   => "system",
    pass   => "manager",
);
ok($cred, "new(plain)");
ok($cred->prepare($string), "prepare $string");

$string = "IO::Socket::SSL";
$cred = Authen::Credential->new(
    scheme => "x509",
    cert   => "/foo/cert.pem",
    key    => "/foo/key.pem",
    ca     => "/bar",
);
ok($cred, "new(x509)");
ok($cred->prepare($string), "prepare $string");

#
# stringification
#

foreach $string (
    "none",
    "plain name= pass=sekret",
    "x509 pass=x%20y",
    ) {
    $cred = Authen::Credential->parse($string);
    is($cred->string(), $string, "parse+string '$string'");
}

#
# accessors and decoding
#

$cred = Authen::Credential->parse("plain name=%25%3d%2f pass=%00%3d%ff");
is($cred->name(), "%=/", "attribute %=/");
is($cred->pass(), "\x00=\xff", "attribute \\x00=\\xff");
