
BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    print qq{1..0 # SKIP these tests are for testing by the author\n};
    exit
  }
}

use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
    'bin/bp_einfo',
    'bin/bp_genbank_ref_extractor',
    'lib/Bio/DB/EUtilities.pm',
    'lib/Bio/EUtilities.pm',
    'lib/Bio/Tools/EUtilities.pm',
    'lib/Bio/Tools/EUtilities/EUtilDataI.pm',
    'lib/Bio/Tools/EUtilities/EUtilParameters.pm',
    'lib/Bio/Tools/EUtilities/History.pm',
    'lib/Bio/Tools/EUtilities/HistoryI.pm',
    'lib/Bio/Tools/EUtilities/Info.pm',
    'lib/Bio/Tools/EUtilities/Info/FieldInfo.pm',
    'lib/Bio/Tools/EUtilities/Info/LinkInfo.pm',
    'lib/Bio/Tools/EUtilities/Link.pm',
    'lib/Bio/Tools/EUtilities/Link/LinkSet.pm',
    'lib/Bio/Tools/EUtilities/Link/UrlLink.pm',
    'lib/Bio/Tools/EUtilities/Query.pm',
    'lib/Bio/Tools/EUtilities/Query/GlobalQuery.pm',
    'lib/Bio/Tools/EUtilities/Summary.pm',
    'lib/Bio/Tools/EUtilities/Summary/DocSum.pm',
    'lib/Bio/Tools/EUtilities/Summary/Item.pm',
    'lib/Bio/Tools/EUtilities/Summary/ItemContainerI.pm',
    't/00-compile.t',
    't/EUtilParameters.t',
    't/author-eol.t',
    't/author-mojibake.t',
    't/author-no-tabs.t',
    't/author-pod-syntax.t',
    't/egquery.t',
    't/einfo.t',
    't/elink_acheck.t',
    't/elink_lcheck.t',
    't/elink_llinks.t',
    't/elink_ncheck.t',
    't/elink_neighbor.t',
    't/elink_neighbor_history.t',
    't/elink_scores.t',
    't/epost.t',
    't/esearch.t',
    't/espell.t',
    't/esummary.t',
    't/release-EUtilities.t'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
