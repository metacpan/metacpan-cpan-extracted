#!perl

use strict;
use warnings;
use Config::Validator;
use Test::More tests => 19;

sub test_data () {
    my($validator, $label, $data);

    $validator = Config::Validator->new({ type => "hostname" });
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

x
localhost
acme.com
acme3.com
en.wikipedia.org
IN-ADDR.ARPA
3Com.COM
3M.COM
aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa.bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb.ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc.ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd

INVALID

.
7
127.0.0.1
26.0.0.73.COM
acme.com.
.acme.com
acme.-com
acme..com
aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa.org
aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa.bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb.ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc.dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd.x
