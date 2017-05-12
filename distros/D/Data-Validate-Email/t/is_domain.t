#!/usr/bin/perl

# -------------------------------------------------------------------------------
# test harness for Data::Validate::is_domain
#
# Author: Richard Sonnen (http://www.richardsonnen.com/)
# -------------------------------------------------------------------------------

use lib './t';
use ExtUtils::TBone;

use lib './blib';
use Data::Validate::Email qw(is_domain);

my $t = ExtUtils::TBone->typical();

$t->begin(12);
$t->msg("testing is_domain...");

# valid
$t->ok(defined(is_domain('test.com')), 'test.com');
$t->ok(defined(is_domain('sub.test.com')), 'sub.test.com');
$t->ok(defined(is_domain('sub-test.com')), 'sub-test.com');
$t->ok(defined(is_domain('sub-test.com.au')), 'sub-test.com.au');


# invalid
$t->ok(!defined(is_domain('')), "bad: ''");
$t->ok(!defined(is_domain('host')), "bad: host");
$t->ok(!defined(is_domain('sonnen@frii.com')), 'bad: sonnen@frii.com');
$t->ok(!defined(is_domain('test dot.com')), "bad: test dot.com");

# test passthrough to Data::Validate::Domain
$t->ok(defined(is_domain('com', {domain_allow_single_label => 1})), 'single-label test');
$t->ok(defined(is_domain('bob.foo', {domain_private_tld => {foo => 1}})), 'private TLD test');

# as an object
my $v = Data::Validate::Email->new();
$t->ok(defined($v->is_domain('test.com')), 'test.com (object)');
$t->ok(!defined($v->is_domain('foobar@bar.com')), 'bad: foobar@bar.com (object)');

# we're done
$t->end();

