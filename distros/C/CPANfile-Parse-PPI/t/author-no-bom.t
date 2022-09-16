
BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    print qq{1..0 # SKIP these tests are for testing by the author\n};
    exit
  }
}

use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoBOM 0.002

use Test::More 0.88;
use Test::BOM;

my @files = (
    'lib/CPANfile/Parse/PPI.pm',
    't/data.t',
    't/data/App-tcpproxy-cpanfile',
    't/data/Archive-Any-Create-cpanfile',
    't/data/Badge-Depot-Plugin-Gratipay-cpanfile',
    't/data/Data-Visitor-Tiny-cpanfile',
    't/data/Dist-Zilla-Plugin-InsertCopyright-cpanfile',
    't/data/Finance-Google-Portfolio-cpanfile',
    't/data/Haineko-cpanfile',
    't/data/Inferno-RegMgr-cpanfile',
    't/data/JSON-Schema-Shorthand-cpanfile',
    't/data/Module-New-cpanfile',
    't/data/Perl-Critic-Policy-Perlsecret-cpanfile',
    't/data/Smart-Args-cpanfile',
    't/data/Spellunker-Perl-cpanfile',
    't/data/Test-Name-FromLine-cpanfile',
    't/data/Text-Haml-cpanfile',
    't/data/Text-Ux-cpanfile',
    't/data/Time-Duration-ja-cpanfile',
    't/data/Web-Library-jQuery-cpanfile',
    't/data/WebService-Simple-cpanfile',
    't/data/Webservice-Diffbot-cpanfile',
    't/die/001.t',
    't/die/002.t',
    't/die/003.t',
    't/simple.t',
    't/simple_feature.t',
    't/syntax/conflicts.t',
    't/syntax/recommends.t',
    't/syntax/requires.t',
    't/tests.json',
    't/warnings/001.t',
    't/warnings/002.t',
    't/warnings/003.t'
);

ok(file_hasnt_bom($_)) for @files;

done_testing;
