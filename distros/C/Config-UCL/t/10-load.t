#!perl
# libucl-0.8.1/python/tests/test_load.py

use strict;
use warnings;
use Test::More;
use Test::Exception;
use Test::Differences;

use Config::UCL;

use JSON::PP;
sub true  { JSON::PP::true(@_) }
sub false { JSON::PP::false(@_) }

dies_ok { ucl_load() };
dies_ok { ucl_load(0,0) };
{
    no warnings;
    is( ucl_load(undef), undef );
}

is_deeply ucl_load("a: null"), { a => undef };
is_deeply ucl_load("a: 1"), { a => 1 };
is_deeply ucl_load("{ a: 1 }"), { a => 1 };
is_deeply ucl_load("a : { b : 1 }"), { a => { b => 1 } };
is_deeply ucl_load("a : 1.1"), { a => 1.1 };
eq_or_diff ucl_load("a : True;b : False"), { a => true, b => false };
is_deeply ucl_load("{}"), {};
is_deeply ucl_load("{"), {};
is_deeply ucl_load("}"), {};
is_deeply ucl_load("["), [];

throws_ok { ucl_load('{ "var"') } qr/unfinished key/;

is_deeply ucl_load("{/*1*/}"), {};

sub slurp { open my $fh, "<", $_[0] or die $!; local $/; <$fh> }
is_deeply ucl_load(slurp("libucl-0.8.1/tests/basic/1.in")), { key1 => 'value' };

my $ucl = <<'UCL';
{
    "key1": value;
    "key2": value2;
    "key3": "value;"
    "key4": 1.0,
    "key5": -0xdeadbeef
    "key6": 0xdeadbeef.1
    "key7": 0xreadbeef
    "key8": -1e-10,
    "key9": 1
    "key10": true
    "key11": no
    "key12": yes
}
UCL
is_deeply +ucl_load($ucl), {
        key1  => 'value',
        key2  => 'value2',
        key3  => 'value;',
        key4  => 1.0,
        key5  => -3735928559,
        key6  => '0xdeadbeef.1',
        key7  => '0xreadbeef',
        key8  => -1e-10,
        key9  => 1,
        key10 => true,
        key11 => false,
        key12 => true,
    };

{
    use Encode;
    my $hash = { decode_utf8("key") => decode_utf8("val") };
    my ($key) = keys %$hash;
    my ($val) = values %$hash;
    ok  utf8::is_utf8($key);
    ok  utf8::is_utf8($val);
}
{
    my $hash = ucl_load("key : val");
    my ($key) = keys %$hash;
    my ($val) = values %$hash;
    ok !utf8::is_utf8($key);
    ok !utf8::is_utf8($val);
}
{
    my $hash = ucl_load("key : val", { utf8 => 1 });
    my ($key) = keys %$hash;
    my ($val) = values %$hash;
    ok  utf8::is_utf8($key);
    ok  utf8::is_utf8($val);
}
{
    my $hash = ucl_load("キー : 値");
    my ($key) = keys %$hash;
    my ($val) = values %$hash;
    ok !utf8::is_utf8($key);
    ok !utf8::is_utf8($val);
    is $key, "キー";
    is $val, "値";
}
{
    use utf8;
    my $hash = ucl_load("キー : 値", { utf8 => 1 });
    my ($key) = keys %$hash;
    my ($val) = values %$hash;
    ok  utf8::is_utf8($key);
    ok  utf8::is_utf8($val);
    is $key, "キー";
    is $val, "値";
}
{
    use utf8;
    my $hash = ucl_load("キー : 値");
    my ($key) = keys %$hash;
    my ($val) = values %$hash;
    ok !utf8::is_utf8($key);
    ok !utf8::is_utf8($val);
    isnt $key, "キー";
    isnt $val, "値";
}

use Test::LeakTrace;
no_leaks_ok {
    ucl_load("A: 1");
};

{
    eq_or_diff ucl_load('keyvar = "${ABI}$ABI${ABI}${$ABI}"'), { keyvar => '${ABI}$ABI${ABI}${$ABI}' };
}

{
    my $opt = { ucl_parser_register_variables => [ ABI => "unknown" ] };
    eq_or_diff ucl_load('keyvar = "${ABI}$ABI${ABI}${$ABI}"', $opt), { keyvar => 'unknownunknownunknown${unknown}' };
}

done_testing;

__END__
