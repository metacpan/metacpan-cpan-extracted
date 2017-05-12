#!perl -wT
# $Id: /local/CPAN/AxKit-XSP-Currency/t/xsp.t 1456 2005-03-11T01:04:01.341817Z claco  $
use strict;
use warnings;
require Test::More;
use lib 't/lib';
use TestHelper qw(comp_to_file);

eval 'use Apache::Test 1.16';
Test::More::plan(skip_all =>
    'Apache::Test 1.16 not installed') if $@;

## these tests have expected output
my @outputtests = (
    'format.xsp',
    'format_code.xsp',
    'format_options.xsp',
    'format_code_options.xsp',
    'format_children.xsp',
    'format_children_precedence.xsp',
    'symbol.xsp',
    'symbol_code.xsp',
    'symbol_options.xsp',
    'symbol_code_options.xsp',
    'symbol_children.xsp',
    'symbol_children_precedence.xsp',
);

## these test have somewhat unpredictable tests
my @othertests = (
    'convert.xsp',
    'convert_children_precedence.xsp',
    'convert_mixed.xsp',
    'format_convert.xsp',
);

require Apache::TestUtil;
Apache::TestUtil->import(qw(t_debug));
Apache::TestRequest->import(qw(GET));
Apache::Test::plan(tests => ((scalar @outputtests * 2) + scalar @othertests),
    need('AxKit', 'mod_perl', need_apache(1), need_lwp())
);

my $docroot = Apache::Test::vars('documentroot');

foreach (@outputtests) {
    my $r = GET("/axkit/$_");

    ok($r->code == 200);

    my ($ok, $response, $file) = comp_to_file($r->content, "$docroot/axkit/out/$_.out");

    t_debug($_);
    t_debug("HTTP Status: " . $r->code);
    t_debug("Expected:\n", $file);
    t_debug("Received:\n", $response);

    ok($ok);
};

foreach (@othertests) {
    my $r = GET("/axkit/$_");

    t_debug($_);
    t_debug("HTTP Status: " . $r->code);
    t_debug("Received:\n", $r->content);

    ok($r->code == 200);
};