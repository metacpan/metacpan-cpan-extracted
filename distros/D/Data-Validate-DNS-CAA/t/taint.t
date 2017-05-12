#!/usr/bin/env perl -T
#
# Test that validation functions untaint correctly
#

use strict;
use warnings;
use Test::More;
use Taint::Util qw(taint);
use Scalar::Util qw(tainted);

use_ok 'Data::Validate::DNS::CAA' or exit 1;

my $v = new_ok 'Data::Validate::DNS::CAA';

for my $check (qw(is_caa_issue is_caa_issuewild)) {
    note "taint testing: $check";

    taint(my $val = 'ca.example.com');

    ok tainted($val), 'value is tainted';

    my $rv = $v->$check($val);

    ok !tainted($rv), 'return value is not tainted';

    is $rv, $val;
}

taint(my $val = 'mailto:security@example.net');
ok tainted($val);
my $rv = $v->is_caa_iodef($val);
ok !tainted($rv), 'is_caa_iodef untaints';

taint($val = 'ca.example.net');
ok tainted($val);
$rv = $v->is_caa_value(issue => $val);
ok !tainted($rv), 'is_caa_value untaints';
is $rv, $val;

taint($val = 'issue');
ok tainted($val);
$rv = $v->is_caa_tag($val);
ok !tainted($rv), 'is_caa_tag untaints';
is $rv, $val;

done_testing;
