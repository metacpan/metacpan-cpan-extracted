#!/sur/bin/env perl -T

use strict;
use warnings;
use Test::More;
use Taint::Util qw(taint);
use Scalar::Util qw(tainted);
use Data::Validate::DNS::TLSA;

my $v = new_ok 'Data::Validate::DNS::TLSA';

my %tests = (
    is_tlsa_port             => '_443',
    is_tlsa_protocol         => '_tcp',
    is_tlsa_domain_name      => '_443._tcp.example.com',
    is_tlsa_selector         => 1,
    is_tlsa_matching_type    => 2,
    is_tlsa_cert_usage       => 3,
    is_tlsa_cert_association => 'dead beef cafe');

while (my ($test, $value) = each %tests) {
    note "taint test for $test";

    taint(my $tainted = $value);

    ok tainted($tainted);

    my $rv = $v->$test($value);

    ok !tainted($rv), 'return value is not tainted';

    is $rv, $value;
}

done_testing;
