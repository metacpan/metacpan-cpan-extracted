
BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    print "1..0 # SKIP these tests are for testing by the author\n";
    exit
  }
}

use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'bin/ape',
    'bin/testd',
    'lib/App/Prove/Elasticsearch/Blamer/Default.pm',
    'lib/App/Prove/Elasticsearch/Blamer/Env.pm',
    'lib/App/Prove/Elasticsearch/Blamer/Git.pm',
    'lib/App/Prove/Elasticsearch/Blamer/System.pm',
    'lib/App/Prove/Elasticsearch/Harness.pm',
    'lib/App/Prove/Elasticsearch/Indexer.pm',
    'lib/App/Prove/Elasticsearch/Indexer/DzilDist.pm',
    'lib/App/Prove/Elasticsearch/Indexer/MMDist.pm',
    'lib/App/Prove/Elasticsearch/Parser.pm',
    'lib/App/Prove/Elasticsearch/Planner/Default.pm',
    'lib/App/Prove/Elasticsearch/Platformer/Default.pm',
    'lib/App/Prove/Elasticsearch/Platformer/Env.pm',
    'lib/App/Prove/Elasticsearch/Provisioner/Git.pm',
    'lib/App/Prove/Elasticsearch/Provisioner/Perl.pm',
    'lib/App/Prove/Elasticsearch/Queue/Default.pm',
    'lib/App/Prove/Elasticsearch/Queue/Rabbit.pm',
    'lib/App/Prove/Elasticsearch/Runner/Default.pm',
    'lib/App/Prove/Elasticsearch/Searcher/ByName.pm',
    'lib/App/Prove/Elasticsearch/Utils.pm',
    'lib/App/Prove/Elasticsearch/Versioner/Default.pm',
    'lib/App/Prove/Elasticsearch/Versioner/Env.pm',
    'lib/App/Prove/Elasticsearch/Versioner/Git.pm',
    'lib/App/Prove/Plugin/Elasticsearch.pm',
    'lib/App/ape.pm',
    'lib/App/ape/plan.pm',
    'lib/App/ape/test.pm',
    'lib/App/ape/update.pm',
    't/00-compile.t',
    't/App-Prove-Elasticsearch-Blamer-Default.t',
    't/App-Prove-Elasticsearch-Blamer-Env.t',
    't/App-Prove-Elasticsearch-Blamer-Git.t',
    't/App-Prove-Elasticsearch-Blamer-System.t',
    't/App-Prove-Elasticsearch-Harness.t',
    't/App-Prove-Elasticsearch-Indexer-DzilDist.t',
    't/App-Prove-Elasticsearch-Indexer-MMDist.t',
    't/App-Prove-Elasticsearch-Indexer.t',
    't/App-Prove-Elasticsearch-Parser.t',
    't/App-Prove-Elasticsearch-Planner-Default.t',
    't/App-Prove-Elasticsearch-Platformer-Default.t',
    't/App-Prove-Elasticsearch-Platformer-Env.t',
    't/App-Prove-Elasticsearch-Provisioner-Git.t',
    't/App-Prove-Elasticsearch-Provisioner-Perl.t',
    't/App-Prove-Elasticsearch-Queue-Default.t',
    't/App-Prove-Elasticsearch-Queue-Rabbit.t',
    't/App-Prove-Elasticsearch-Runner-Default.t',
    't/App-Prove-Elasticsearch-Searcher-ByName.t',
    't/App-Prove-Elasticsearch-Utils.t',
    't/App-Prove-Elasticsearch-Versioner-Default.t',
    't/App-Prove-Elasticsearch-Versioner-Env.t',
    't/App-Prove-Elasticsearch-Versioner-Git.t',
    't/App-Prove-Plugin-Elasticsearch.t',
    't/App-ape-plan.t',
    't/App-ape-test.t',
    't/App-ape-update.t',
    't/App-ape.t',
    't/ape.t',
    't/author-critic.t',
    't/author-eol.t',
    't/author-mojibake.t',
    't/author-no-tabs.t',
    't/author-pod-coverage.t',
    't/author-pod-spell.t',
    't/author-pod-syntax.t',
    't/author-synopsis.t',
    't/author-test-version.t',
    't/data/Changes',
    't/data/Makefile.PL',
    't/data/bogus/Changes',
    't/data/bogus/lessbogus/Changes',
    't/data/bogus/lessbogus/subdir/zippy',
    't/data/bogus/morebogus/Changes',
    't/data/bogus/morebogus/subdir/zippy',
    't/data/bogus/zippy',
    't/data/discard.test',
    't/data/pass.test',
    't/release-cpan-changes.t',
    't/release-kwalitee.t',
    't/release-meta-json.t',
    't/release-minimum-version.t',
    't/release-pod-linkcheck.t',
    't/release-unused-vars.t'
);

notabs_ok($_) foreach @files;
done_testing;
