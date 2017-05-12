#!perl

use strict;
use warnings;
use Config::Validator qw(string2hash hash2string is_true is_false is_regexp listof);
use Test::More tests => 29;

our(%hash);

is(hash2string(), "", "hash2string()");
is(hash2string({}), "", "hash2string({})");
is(hash2string({ abc => 123 }), "abc=123", "hash2string({ abc => 123 })");
is(hash2string({ abc => 123, def => "", ghi => "def" }), "abc=123 def= ghi=def");
is(hash2string({ abc => "<%>" }), "abc=%3C%25%3E");

%hash = string2hash("");
is(keys(%hash), 0, "string2hash()");

%hash = string2hash("abc=123");
is(keys(%hash), 1, "string2hash(abc=123)");
is((keys(%hash))[0], "abc");

%hash = string2hash("%3C%25%3E=123 456=");
is(keys(%hash), 2, "string2hash(%3C%25%3E=123 456=)");
is(join("|", sort(keys(%hash))), "456|<%>");
is(join("|", sort(values(%hash))), "|123");

ok(is_true("true"), "is_true yes");
ok(!is_true("TRUE"), "is_true no");
ok(!is_true("false"), "is_true no");
ok(!is_true(undef), "is_true no");
ok(!is_true([]), "is_true no");

ok(is_false("false"), "is_false yes");
ok(!is_false("FALSE"), "is_false no");
ok(!is_false("true"), "is_false no");
ok(!is_false(undef), "is_false no");
ok(!is_false([]), "is_false no");

ok(is_regexp(qr//), "is_regexp yes");
ok(is_regexp(qr/abc/imx), "is_regexp yes");
ok(!is_regexp('qr/abc/imx'), "is_regexp no");

is(join("+", listof(undef)), "", "listof(undef)");
is(join("+", listof([])), "", "listof([])");
is(join("+", listof(123)), "123", "listof(123)");
is(join("+", listof([123])), "123", "listof([123])");
is(join("+", listof([123,456])), "123+456", "listof(123)");
