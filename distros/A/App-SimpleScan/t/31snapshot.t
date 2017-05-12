use Test::More tests=>1;
use Test::Differences;

$ENV{HARNESS_PERL_SWITCHES} = "" unless defined $ENV{HARNESS_PERL_SWITCHES};

$expected = <<EOS;
UNNAMED_TEST: tests=9, ok=8, failed=1, skipped=1, todo=2 (1 UNEXPECTEDLY SUCCEEDED)
F 7 Deliberately broken test (asia) [http://asia.search.yahoo.com/search/news?p=bush&ei=UTF-8&fr=sfp&fl=0&x=wrt&debug=qa] [/fnord/ should match]
#   Failed test 'Deliberately broken test (asia) [http://asia.search.yahoo.com/search/news?p=bush&ei=UTF-8&fr=sfp&fl=0&x=wrt&debug=qa] [/fnord/ should match]'
#   in /home/y/lib/perl5/site_perl/5.6.1/Test/WWW/Simple.pm at line 65.
#          got: "<!doctype html public "-//W3C//DTD HTML 4.01//EN" "...
#       length: 37943
#     doesn't match '(?-xism:fnord)'
# See snapshot at /some/location
T 9 unexpected success (asia) [http://asia.search.yahoo.com/search/news?p=bush&ei=UTF-8&fr=sfp&fl=0&x=wrt&debug=qa] [/yahoo/ should match]
# See snapshot at /some/location
EOS

$got = `bin/simple_report -v -v <t/snap.tap`;
eq_or_diff $got, $expected, "extended output as planned";

