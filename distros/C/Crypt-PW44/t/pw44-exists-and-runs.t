#!/usr/bin/perl -w

use Test::Simple tests => 4;

use Crypt::PW44 qw(generate);

$foo=generate(pack(Ll,int(rand(2**32)),int(rand(2**16))),3);
ok (length($foo),'generate returns something');
ok ($foo =~ /^\S+ \S+ \S+ \S+$/,'generate produces 4 simple words, space delimited');
ok ($foo =~ /^[A-Z ]+$/,'generate produces words in the upper case');

$bar=generate(pack(Ll,int(rand(2**32)),int(rand(2**16))),3);

ok ($foo ne $bar, 'successive runs produce different random password strings');
