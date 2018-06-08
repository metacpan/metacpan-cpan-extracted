#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Warnings;
use Data::Validate::DNS::TLSA;

my $v = new_ok 'Data::Validate::DNS::TLSA';

ok $v->is_tlsa_port('_443', underscore => 1);
ok !$v->is_tlsa_port('abc');

ok $v->is_tlsa_protocol('_tcp', underscore => 1);
ok !$v->is_tlsa_protocol('123');

ok $v->is_tlsa_domain_name('_443._tcp.example.com');

ok $v->is_tlsa_selector(1);
ok $v->is_tlsa_matching_type(2);
ok $v->is_tlsa_cert_usage(3);

ok $v->is_tlsa_cert_association('dead beef cafe');

done_testing;
