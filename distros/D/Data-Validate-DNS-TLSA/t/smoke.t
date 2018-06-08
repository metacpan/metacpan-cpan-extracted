#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Warnings;
use Data::Validate::DNS::TLSA ':all';

ok is_tlsa_port('_443');
ok is_tlsa_port('_443', underscore => 1);
ok !is_tlsa_port('443', underscore => 1);
ok !is_tlsa_port('0443');
ok !is_tlsa_port(65536);

ok is_tlsa_protocol('_tcp');
ok is_tlsa_protocol('_tcp', underscore => 1);
ok !is_tlsa_protocol('tcp', underscore => 1);
ok is_tlsa_protocol('tcp');

for my $proto (qw(tcp udp sctp)) {
    ok is_tlsa_protocol($proto, strict => 1), "$proto is a valid TLSA protocol";
}

ok !is_tlsa_protocol('foo', strict => 1);

ok is_tlsa_domain_name('_443._tcp.example');
ok !is_tlsa_domain_name('443.tcp.example');
ok !is_tlsa_domain_name('_443');
ok !is_tlsa_domain_name('_443.tcp.example');

# is_tlsa_selector
for my $val (0,1,255) {
    ok defined(is_tlsa_selector($val, strict => 1)), "$val is a valid TLSA selector";
}

for my $val (2..254) {
    ok is_tlsa_selector($val);
    ok !is_tlsa_selector($val, strict => 1);
}

for my $val (0..2, 255) {
    ok defined(is_tlsa_matching_type($val, strict => 1)), "$val is a TLSA matching type (strict)";
    ok defined(is_tlsa_matching_type($val)), "$val is a TLSA matching type";
}

for my $val (3..254) {
    ok !is_tlsa_matching_type($val, strict => 1);
    ok is_tlsa_matching_type($val);
}

ok !is_tlsa_matching_type(256);
ok !is_tlsa_matching_type(256, strict => 1);


for my $val (0..3, 255) {
    ok defined(is_tlsa_cert_usage($val, strict => 1)), "$val is a valid TLSA cert usage value (strict)";
    ok defined(is_tlsa_cert_usage($val)), "$val is a valid TLSA cert usage value";
}

for my $val (4..254) {
    ok !is_tlsa_cert_usage($val, strict => 1), "$val is a not valid TLSA cert usage value (strict)";
    ok is_tlsa_cert_usage($val), "$val is a valid TLSA cert usage value (relaxed)";
}

ok is_tlsa_cert_association(
    join ' ',
        'd2abde240d7cd3ee6b4b28c54df034b9',
        '7983a1d16e8a410e4561cb106618e971'
);

ok is_tlsa_cert_association(
    join "\n    ",
        'd2abde240d7cd3ee6b4b28c54df034b9',
        '7983a1d16e8a410e4561cb106618e971'
);

ok !is_tlsa_cert_association('xxx');
ok !is_tlsa_cert_association(' ');

done_testing;
