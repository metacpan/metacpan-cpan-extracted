use strict;
use warnings FATAL => 'all';
use Test::More;
use Test::Exception;
use Catmandu::Importer::EuropePMC;

my $network_test = $ENV{NETWORK_TEST} || "";

SKIP: {
    skip "No NETWORK_TEST env variable set.", 1 unless $network_test;

    my $pkg = "Catmandu::Importer::EuropePMC";

    # search
    my $rec = $pkg->new(query => '10779411')->first;

    like($rec->{title}, qr/^Structural basis/, "title ok");
    is($rec->{pmid}, '10779411', "pmid ok");

    my $raw_rec = $pkg->new(query => '10779411', raw => 1)->first;
    is ($raw_rec->{responseWrapper}->{hitCount}, 1, "hitCount ok");

    # databaseLinks
    my $db_imp = $pkg->new(
        pmid => '10779411',
        module => 'databaseLinks',
        db => 'uniprot',
        page => '1',
        );

    is($db_imp->first->{dbName}, "UNIPROT", "Database links ok");

    my $dp_imp_page = $pkg->new(
        pmid => '10779411',
        module => 'databaseLinks',
        db => 'uniprot',
        page => '3',
        );

    ok (!defined $dp_imp_page->first, "page does not exist");

    # citations
    my $citation = $pkg->new(
        pmid => '10779411',
        module => 'citations',
        );

    ok ($citation->count > 10, "Some citations fetched");

    # references
    my $reference = $pkg->new(
        pmid => '10592235',
        module => 'references',
        );

    ok ($reference->count > 10, "Some references fetched");

}

done_testing;
