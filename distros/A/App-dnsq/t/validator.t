#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use FindBin qw($RealBin);
use lib "$RealBin/../lib";

use_ok('DNSQuery::Validator', qw(:all));
use_ok('DNSQuery::Constants', qw(:all));

# Test domain validation
subtest 'Domain validation' => sub {
    my ($valid, $error);
    
    # Valid domains
    ($valid, $error) = validate_domain('google.com');
    ok($valid, 'Valid domain: google.com');
    
    ($valid, $error) = validate_domain('sub.example.co.uk');
    ok($valid, 'Valid domain: sub.example.co.uk');
    
    # Invalid domains
    ($valid, $error) = validate_domain('');
    ok(!$valid, 'Empty domain rejected');
    
    ($valid, $error) = validate_domain('domain..com');
    ok(!$valid, 'Consecutive dots rejected');
    
    ($valid, $error) = validate_domain('-invalid.com');
    ok(!$valid, 'Leading hyphen rejected');
    
    ($valid, $error) = validate_domain('a' x 254);
    ok(!$valid, 'Too long domain rejected');
};

# Test IP validation
subtest 'IP validation' => sub {
    my ($valid, $error);
    
    # Valid IPv4
    ($valid, $error) = validate_ip('8.8.8.8');
    ok($valid, 'Valid IPv4: 8.8.8.8');
    
    ($valid, $error) = validate_ip('192.168.1.1');
    ok($valid, 'Valid IPv4: 192.168.1.1');
    
    # Valid IPv6
    ($valid, $error) = validate_ip('2001:4860:4860::8888');
    ok($valid, 'Valid IPv6: 2001:4860:4860::8888');
    
    # Invalid IPs
    ($valid, $error) = validate_ip('256.1.1.1');
    ok(!$valid, 'Invalid IPv4 octet rejected');
    
    ($valid, $error) = validate_ip('not.an.ip');
    ok(!$valid, 'Non-IP string rejected');
};

# Test query type validation
subtest 'Query type validation' => sub {
    my ($valid, $error);
    
    # Valid types
    ($valid, $error) = validate_query_type('A');
    ok($valid, 'Valid type: A');
    
    ($valid, $error) = validate_query_type('AAAA');
    ok($valid, 'Valid type: AAAA');
    
    ($valid, $error) = validate_query_type('mx');
    ok($valid, 'Valid type: mx (case insensitive)');
    
    # Invalid types
    ($valid, $error) = validate_query_type('INVALID');
    ok(!$valid, 'Invalid type rejected');
    
    ($valid, $error) = validate_query_type('');
    ok(!$valid, 'Empty type rejected');
};

# Test port validation
subtest 'Port validation' => sub {
    my ($valid, $error);
    
    ($valid, $error) = validate_port(53);
    ok($valid, 'Valid port: 53');
    
    ($valid, $error) = validate_port(8053);
    ok($valid, 'Valid port: 8053');
    
    ($valid, $error) = validate_port(0);
    ok(!$valid, 'Port 0 rejected');
    
    ($valid, $error) = validate_port(65536);
    ok(!$valid, 'Port > 65535 rejected');
    
    ($valid, $error) = validate_port('abc');
    ok(!$valid, 'Non-numeric port rejected');
};

# Test timeout validation
subtest 'Timeout validation' => sub {
    my ($valid, $error);
    
    ($valid, $error) = validate_timeout(5);
    ok($valid, 'Valid timeout: 5');
    
    ($valid, $error) = validate_timeout(1);
    ok($valid, 'Valid timeout: 1');
    
    ($valid, $error) = validate_timeout(0);
    ok(!$valid, 'Timeout 0 rejected');
    
    ($valid, $error) = validate_timeout(-1);
    ok(!$valid, 'Negative timeout rejected');
};

# Test constants
subtest 'Constants' => sub {
    ok($DNSQuery::Constants::VALID_QUERY_TYPES{A}, 'A type exists in constants');
    ok($DNSQuery::Constants::VALID_QUERY_TYPES{AAAA}, 'AAAA type exists in constants');
    ok($DNSQuery::Constants::VALID_QUERY_TYPES{MX}, 'MX type exists in constants');
    
    ok($DNSQuery::Constants::VALID_QUERY_CLASSES{IN}, 'IN class exists in constants');
    
    is($DNSQuery::Constants::MIN_PORT, 1, 'MIN_PORT is 1');
    is($DNSQuery::Constants::MAX_PORT, 65535, 'MAX_PORT is 65535');
    is($DNSQuery::Constants::MAX_DOMAIN_LENGTH, 253, 'MAX_DOMAIN_LENGTH is 253');
};

done_testing();
