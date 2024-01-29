use strict;

use Test::Exception;
use Test::More;

use Test::RequiresInternet;

use_ok('Bio::DB::Taxonomy');

my %params;

if (defined $ENV{BIOPERLEMAIL}) {
    $params{'-email'} = $ENV{BIOPERLEMAIL};
    $params{'-delay'} = 1;
}

{
    ok my $db = Bio::DB::Taxonomy->new(-source => 'entrez', %params);
    isa_ok $db, 'Bio::DB::Taxonomy::entrez';
    isa_ok $db, 'Bio::DB::Taxonomy';
}

{
    my $db = Bio::DB::Taxonomy->new(-source => 'entrez', %params);
    my $id;
    my $n;

    cmp_ok $db->get_num_taxa, '>', 880_000; # 886,907 as of 08-May-2012

    $id = $db->get_taxonid('Homo sapiens');
    is $id, 9606;

    # easy test on human, try out the main Taxon methods
    ok $n = $db->get_taxon(9606);
    is $n->id, 9606;
    is $n->object_id, $n->id;
    is $n->ncbi_taxid, $n->id;
    is $n->parent_id, 9605;
    is $n->rank, 'species';

    is $n->node_name, 'Homo sapiens';
    is $n->scientific_name, $n->node_name;
    is ${$n->name('scientific')}[0], $n->node_name;

    my %common_names = map { $_ => 1 } $n->common_names;
    cmp_ok keys %common_names, '>=', 3, ref($db).": common names";
    ok exists $common_names{human};

    is $n->division, 'Primates';
    is $n->genetic_code, 1;
    is $n->mitochondrial_genetic_code, 2;
    ok defined $n->pub_date;
    ok defined $n->create_date;
    ok defined $n->update_date;

    # briefly test some Bio::Tree::NodeI methods
    ok my $ancestor = $n->ancestor;
    is $ancestor->scientific_name, 'Homo';
    # unless set explicitly, Bio::Taxon doesn't return anything for
    # each_Descendent; must ask the database directly
    ok my @children = $ancestor->db_handle->each_Descendent($ancestor);
    cmp_ok @children, '>', 0;

    sleep(3);

    # do some trickier things...
    ok my $n2 = $db->get_Taxonomy_Node('89593');
    is $n2->scientific_name, 'Craniata';

    # briefly check we can use some Tree methods
    my $tree = Bio::Tree::Tree->new();
    is $tree->get_lca($n, $n2)->scientific_name, 'Craniata';

    # get lineage_nodes
    my @nodes = $tree->get_nodes;
    is scalar(@nodes), 0;
    my @lineage_nodes;
    @lineage_nodes = $tree->get_lineage_nodes($n->id); # read ID, only works if nodes have been added to tree
    is scalar @lineage_nodes, 0;
    @lineage_nodes = $tree->get_lineage_nodes($n);     # node object always works
    cmp_ok(scalar @lineage_nodes, '>', 20);

    # get lineage string
    like($tree->get_lineage_string($n), qr/cellular organisms;Eukaryota/);
    like($tree->get_lineage_string($n,'-'), qr/cellular organisms-Eukaryota/);
    like($tree->get_lineage_string($n2), qr/cellular organisms;Eukaryota/);

    # can we actually form a Tree and use other Tree methods?
    ok $tree = Bio::Tree::Tree->new(-node => $n);
    cmp_ok($tree->number_nodes, '>', 20);
    cmp_ok(scalar($tree->get_nodes), '>', 20);
    is $tree->find_node(-rank => 'genus')->scientific_name, 'Homo';

    # check that getting the ancestor still works now we have explitly set the
    # ancestor by making a Tree
    is $n->ancestor->scientific_name, 'Homo';

    sleep(3);

    ok $n = $db->get_Taxonomy_Node('1760');
    is $n->scientific_name, 'Actinomycetes';

    sleep(3);

    # entrez isn't as good at searching as flatfile, so we have to special-case
    my @ids = sort $db->get_taxonids('Chloroflexi');
    is scalar @ids, 2;
    is_deeply \@ids, [200795, 32061];

    $id = $db->get_taxonids('Chloroflexi (class)');
    is($id, 'No hit');

    @ids = $db->get_taxonids('Rhodotorula');
    cmp_ok @ids, '>=' , 1;
    # From NCBI: Taxid 592558 was merged into taxid 5533 on June 16, 2017
    is( (grep { $_ == 592558 } @ids), 0, 'Value no longer found');
    ok grep { $_ == 5533 } @ids;
}


# we can recursively fetch all descendents of a taxon
{
    my $db = Bio::DB::Taxonomy->new(-source=>"entrez", %params);
    $db->get_taxon(10090);

    my $lca = $db->get_taxon(314146);
    my @descs = $db->get_all_Descendents($lca);
    cmp_ok @descs, '>=', 17;
}


# tests for #182
{
    my $db = Bio::DB::Taxonomy->new(-source=>"entrez", %params);

    my @taxa = qw(viruses Deltavirus unclassified plasmid);

    for my $taxon (@taxa) {
        test_taxid($db, $taxon);
    }

    sub test_taxid {
        my ($db, $taxa) = @_;
        my @taxonids = $db->get_taxonids($taxa);
        cmp_ok(scalar(@taxonids), '>', 0, "Got IDs returned for $taxa:".join(',', @taxonids));
        my $taxon;
        lives_ok { $taxon = $db->get_taxon(-taxonid => pop @taxonids) } "IDs generates a Bio::Taxonomy::Node";
        if (defined $taxon) {
            like( $taxon->scientific_name, qr/$taxa/i, "Name returned matches $taxa");
        } else {
            ok(0, "No taxon object returned for $taxa");
        }
    }
}


# tests for #212
{
    my $db = Bio::DB::Taxonomy->new( -source => "entrez", %params);

    # String                 | What I expect | What I get
    # ---------------------- | ------------- | ----------
    # 'Lissotriton vulgaris' | 8324          | 8324
    # 'Chlorella vulgaris'   | 3077          | 3077
    # 'Phygadeuon solidus'   | 1763951       | 1763951
    # 'Ovatus'               | 666060        | 666060
    # 'Phygadeuon ovatus'    | 2890685       | 2890685
    # 'Zaphod Beeblebrox'    | "No hit"      | "No hit"

    my @ids;
    @ids = $db->get_taxonids('Lissotriton vulgaris');
    is $ids[0], 8324, 'Correct: Lissotriton vulgaris';
    @ids = $db->get_taxonids('Chlorella vulgaris');
    is $ids[0], 3077, 'Correct: Chlorella vulgaris';
    @ids = $db->get_taxonids('Phygadeuon solidus');
    is $ids[0], 1763951, 'Correct: Phygadeuon solidus';
    @ids = $db->get_taxonids('Ovatus');
    is $ids[0], 666060, 'Correct: Ovatus';
    @ids = $db->get_taxonids('Phygadeuon ovatus');
    is $ids[0], '2890685', 'Correct: 2890685';
    @ids = $db->get_taxonids('Zaphod Beeblebrox');
    is $ids[0], 'No hit', 'Correct: No hit';
}

done_testing();
