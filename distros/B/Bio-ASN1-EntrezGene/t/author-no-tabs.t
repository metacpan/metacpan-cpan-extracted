
BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    print qq{1..0 # SKIP these tests are for testing by the author\n};
    exit
  }
}

use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/Bio/ASN1/EntrezGene.pm',
    'lib/Bio/ASN1/EntrezGene/Indexer.pm',
    'lib/Bio/ASN1/Sequence.pm',
    'lib/Bio/ASN1/Sequence/Indexer.pm',
    'lib/Bio/SeqIO/entrezgene.pm',
    't/00-compile.t',
    't/author-eol.t',
    't/author-mojibake.t',
    't/author-no-tabs.t',
    't/author-pod-coverage.t',
    't/author-pod-syntax.t',
    't/entrezgene.t',
    't/input.asn',
    't/input1.asn',
    't/seq.asn',
    't/testindexer.t',
    't/testparser.t'
);

notabs_ok($_) foreach @files;
done_testing;
