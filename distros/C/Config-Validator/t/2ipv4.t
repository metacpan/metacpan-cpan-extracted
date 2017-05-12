#!perl

use strict;
use warnings;
use Config::Validator;
use Test::More tests => 21;

sub test_data () {
    my($validator, $label, $data);

    $validator = Config::Validator->new({ type => "ipv4" });
    while ($data = <DATA>) {
        chomp($data);
        $data =~ s/\s+#.*$//;
        next unless length($data);
        if ($data =~ /^(VALID|INVALID)$/) {
            $label = $data;
            next;
        }
        $@ = "";
        eval { $validator->validate($data) };
        $@ =~ s/\s+$//;
        if ($label eq "VALID") {
            is($@, "", "valid $data");
        } elsif ($label eq "INVALID") {
            ok($@, "invalid $data");
        } else {
            die;
        }
    }
}

test_data();

__DATA__

VALID

0.0.0.0
0.1.2.3
127.0.0.1
192.168.0.17
16.32.64.128
255.255.255.255

INVALID

0.1.2
0.1.2.3.4
32.64.128.256
192.168.0.1e
192:168:0:17
192 168 0 17
192,168,0,17
192 168 0 17
192.168.000.017
192.168.0.1717
192.168.o.17
192.168.0.17.
 192.168.0.17
192.168.0.17 
192168017

