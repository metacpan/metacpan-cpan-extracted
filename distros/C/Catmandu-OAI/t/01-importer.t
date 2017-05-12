use strict;
use warnings;
use Catmandu::Importer::OAI;
use Test::More;

my $importer = Catmandu::Importer::OAI->new(
    url => 'http://biblio.ugent.be/oai',
    set => "allFtxt",
    dry => 1,
);

my $record = $importer->first;

ok exists $record->{url} , 'dry run';

# skip live testing by default (mock server instead)
if ($ENV{RELEASE_TESTING}) {
    $importer = Catmandu::Importer::OAI->new(
        url => 'http://biblio.ugent.be/oai',
        set => "allFtxt"
    );

    $record = $importer->first;

    ok $record , 'listrecords';


    $importer = Catmandu::Importer::OAI->new(
        url => 'http://biblio.ugent.be/oai',
        set => "allFtxt",
        listIdentifiers => 1,
    );

    $record = $importer->first;

    ok $record, 'listidentifiers';
}

done_testing;
