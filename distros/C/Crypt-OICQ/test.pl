#!/usr/bin/env perl
# $Id: test.pl,v 1.2 2003/10/01 12:27:33 tans Exp $

# Copyright (c) 2002 Shufeng Tan.  All rights reserved.
# 
# This package is free software and is provided "as is" without express
# or implied warranty.  It may be used, redistributed and/or modified
# under the terms of the Perl Artistic License (see
# http://www.perl.com/perl/misc/Artistic.html)

use strict;
use Test;
BEGIN { plan tests => 30 };

use Crypt::OICQ;

sub test_encrypt_decrypt {
    my ($key, $plain) = @_;
    my $crypt = Crypt::OICQ::encrypt("", $plain, $key);
    my $plain2 = Crypt::OICQ::decrypt("", $crypt, $key);
    if ($plain ne $plain2) {
        die "encrypt-decrypt test failed using key: ", unpack("H*", $key),
            "\nplain:\n", $plain ? unpack("H*", $plain) : "empty", 
            "\nplain2:\n", $plain2 ? unpack("H*", $plain2) : "empty", "\n";
    }
    return 1;
}

sub random_test {
    my $max_k = 16;
    my $max_len = 1024;
    my $t0 = time;
    print "Begin crypt tests on $max_k random keys and $max_len random texts \n";
    for (my $k = 0;  $k < $max_k; $k++) {
        my $key = Crypt::OICQ::rand_str(16);
        for (my $len  = 0; $len <= $max_len; $len++) {
            test_encrypt_decrypt($key, $len ? Crypt::OICQ::rand_str($len) : "");
        }
    }
    my $t = time - $t0;
    print $max_k * (1+$max_len), " runs of encrypt/decrypt: $t seconds\n";
    return 1;
}

sub test_decrypt_encrypt_decrypt {
    my ($crypt, $key) = @_;
    my $plain  = Crypt::OICQ::decrypt("", $crypt, $key);
    my $crypt2 = Crypt::OICQ::encrypt("", $plain, $key);
    my $plain2 = Crypt::OICQ::decrypt("", $crypt2, $key);
    return(1) if $plain2 eq $plain;
    print "Error:\n";
    print "Crypt:  ", unpack("H*", $crypt), "\n";
    print "Plain:  ", unpack("H*", $plain), "\n";
    print "Crypt2: ", unpack("H*", $crypt2), "\n";
    print "Plain2: ", unpack("H*", $plain2), "\n";
    return(0);
}

my $key = "AbCdEfGh01234567";

# Test 1: empty string

ok(test_encrypt_decrypt($key, ""));

# Tests 2..17: null strings of length 1 to 16

foreach my $len (1..16) {
    ok(test_encrypt_decrypt($key, "\0" x $len));
}

# Tests 18..29: decrypt strings encrypted by Tencent's code

my @cs = qw(
0b18072ffabdf31f42826e4757c41f1a
85c63deac3ee4dbb66f42ae2391ac096
494b2308c0fd4894ce20e85f613545d8
c785525460c6fa0cbf1b28d828945ab6
a0984a62b76a21e2b40a323d514da6c7
5f69cbe12cade5facc5602092317b79a
448a18cb83f06d04d57ae4ef7beff150
a2599974353a71103b45d604e20eea35bc321881c5d28f18
0b18072ffabdf31fc30b4999ece8ff3489815a8f724cbab2
85c63deac3ee4dbbe801a13fa33b85a0fa8b98103ad1031e

a2599974353a7110453fb795b53a1ae15089c0dd008f442a1570b31fe53b24949a1982cd1777c2708d63b50ea31987e272ea0aceb557764e8860d9cde5567d5bbd798a7aad80f2444dc37cdb8164551d0072ab405a9880b4a401aa80cb8cf8bc70b38bdd5cfddbc49225245ff4c4dda86165521d355b9defd79978c31cce53ce7490038d8ff5edaed1788e2ccde2deaeddc818f45882919877bc88bed3a20012b4cf34f751a51c3748ca6310bfd8bebb6e4b4170a4ed65ee008d2b4aed42b4ee29d233912e4c1cda3c5ea101e7487a46714c2d5099e4205c834960e729d9a709007d70761b3edd3f

82d64e87e5a48198572f7bc9b75e57b2d022ffbd1a767f021ea10b5a3433818199ac39e0f6193ddb1d02997983c308b476988cb7f0413d5ddd515f31f6d3dacad5da35218a92e48e1080ee11c80e15014dc6b42767d408f6bda401671229d6e51f81bfc4e93e3568f1664d4e2749ae4a61b7b382612768514d0ca048d247edd8eb7d9107033f53b399798d375996264578100ba73c0ce2262325452febb3e0ecc95ef3a74caf941694ef575e155f443e5a57db65075dfc35268212b272017f65c02dff80387272ee52f8c495b4d1e4cda72816443acf3b0c3eead12e593b33e3fd41acebb1d10eb463d76d15b3a913f20985768b9050afa98b3993d28d376c07044a4fe78b5a271455be9a206c9c80b9
);

foreach my $c (@cs) {
    ok(test_decrypt_encrypt_decrypt(pack("H*", $c), $key));
}

# Test 30: random string test

ok(random_test());

__END__
