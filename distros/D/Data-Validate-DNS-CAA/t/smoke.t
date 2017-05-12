#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;

use_ok 'Data::Validate::DNS::CAA' or exit 1;

Data::Validate::DNS::CAA->import(qw(
    is_caa_tag
    is_caa_value
    is_caa_issue
    is_caa_issuewild
    is_caa_iodef));

for my $tag (qw(issue issuewild iodef)) {
    ok is_caa_tag($tag);
}

ok !is_caa_tag('foo');

ok is_caa_tag('foo', strict => 0);

ok is_caa_value(issue => 'ca.example.com');
ok is_caa_value(issue => 'ca.example.com; account=1234; policy=ev');
ok is_caa_value(issue => ';');
ok !is_caa_value(issue => '-ca.example.com');
ok !is_caa_value(badtag => 'foo');

ok is_caa_issue('ca.example.com');
ok is_caa_issue('ca.example.com; account=12345');
ok is_caa_issue('ca.example.net; policy=ev');
ok is_caa_issue('ca.example.net; account=12345; policy=ev');
ok is_caa_issue(';');
ok !is_caa_issue('-ca.example.net; account=12345; policy=ev');

ok is_caa_issuewild('ca.example.com');
ok is_caa_issuewild('ca.example.com; account=12345');
ok is_caa_issuewild('ca.example.net; policy=ev');
ok is_caa_issuewild('ca.example.net; account=12345; policy=ev');
ok is_caa_issuewild(';');
ok !is_caa_issuewild('-ca.example.net; account=12345; policy=ev');

ok is_caa_iodef('mailto:security@example.com');
ok is_caa_iodef('http://iodef.example.com');
ok !is_caa_iodef('ca.example.com');
ok !is_caa_iodef('security@example.com');

done_testing;
