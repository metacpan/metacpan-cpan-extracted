use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/App/ElasticSearch/Utilities.pm',
    'lib/App/ElasticSearch/Utilities/Aggregations.pm',
    'lib/App/ElasticSearch/Utilities/Connection.pm',
    'lib/App/ElasticSearch/Utilities/HTTPRequest.pm',
    'lib/App/ElasticSearch/Utilities/Query.pm',
    'lib/App/ElasticSearch/Utilities/QueryString.pm',
    'lib/App/ElasticSearch/Utilities/QueryString/AutoEscape.pm',
    'lib/App/ElasticSearch/Utilities/QueryString/BareWords.pm',
    'lib/App/ElasticSearch/Utilities/QueryString/FileExpansion.pm',
    'lib/App/ElasticSearch/Utilities/QueryString/IP.pm',
    'lib/App/ElasticSearch/Utilities/QueryString/Nested.pm',
    'lib/App/ElasticSearch/Utilities/QueryString/Plugin.pm',
    'lib/App/ElasticSearch/Utilities/QueryString/Ranges.pm',
    'lib/App/ElasticSearch/Utilities/QueryString/Underscored.pm',
    'lib/App/ElasticSearch/Utilities/VersionHacks.pm',
    'lib/Types/ElasticSearch.pm',
    'scripts/es-alias-manager.pl',
    'scripts/es-apply-settings.pl',
    'scripts/es-copy-index.pl',
    'scripts/es-daily-index-maintenance.pl',
    'scripts/es-graphite-dynamic.pl',
    'scripts/es-index-blocks.pl',
    'scripts/es-nagios-check.pl',
    'scripts/es-nodes.pl',
    'scripts/es-open.pl',
    'scripts/es-search.pl',
    'scripts/es-status.pl',
    'scripts/es-storage-overview.pl',
    't/00-compile.t',
    't/01-querystring.t',
    't/02-index-data.t',
    't/03-hash-flattening.t'
);

notabs_ok($_) foreach @files;
done_testing;
