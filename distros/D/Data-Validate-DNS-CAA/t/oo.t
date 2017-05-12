#!/usr/bin/env perl
#
# Test Object Interface of Data::Validate::DNS::CAA
#

use strict;
use warnings;
use Test::More;

use_ok 'Data::Validate::DNS::CAA' or exit 1;

my $v = new_ok 'Data::Validate::DNS::CAA';

for my $tag (qw(issue issuewild iodef)) {
    ok $v->is_caa_tag($tag);
}

ok !$v->is_caa_tag('badtag');

ok $v->is_caa_value(issue => 'ca.example.com');
ok !$v->is_caa_value(badtag => 'foo');

ok $v->is_caa_issue('ca.example.com');
ok !$v->is_caa_issue('-ca.example.net; account=12345; policy=ev');

ok $v->is_caa_issuewild('ca.example.com');
ok !$v->is_caa_issuewild('-ca.example.net; account=12345; policy=ev');

ok $v->is_caa_iodef('mailto:security@example.com');
ok !$v->is_caa_iodef('ca.example.com');

done_testing;
