use strict;
use warnings;
use Test::More;

BEGIN { use_ok 'Catmandu::Importer::Zotero' }
require_ok 'Catmandu::Importer::Zotero';

# skip live testing by default (mock server instead)
if ($ENV{RELEASE_TESTING}) {
    my $importer = Catmandu::Importer::Zotero->new(
        userID => '475425',
    );

    my $record = $importer->first;
    ok $record , 'search';

    my $array = $importer->take(15)->to_array;
    ok @$array > 10 , '>10 results'
}

done_testing;
