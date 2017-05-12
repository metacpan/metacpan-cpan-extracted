
BEGIN {
  unless ($ENV{RELEASE_TESTING}) {
    print "1..0 # SKIP these tests are for release candidate testing\n";
    exit
  }
}

use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::EOLTests 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/Bio/ASN1/EntrezGene.pm',
    'lib/Bio/ASN1/EntrezGene/Indexer.pm',
    'lib/Bio/ASN1/Sequence.pm',
    'lib/Bio/ASN1/Sequence/Indexer.pm',
    't/00-compile.t',
    't/author-mojibake.t',
    't/author-pod-coverage.t',
    't/author-pod-syntax.t',
    't/input.asn',
    't/input1.asn',
    't/release-eol.t',
    't/release-no-tabs.t',
    't/seq.asn',
    't/testindexer.t',
    't/testparser.t'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
