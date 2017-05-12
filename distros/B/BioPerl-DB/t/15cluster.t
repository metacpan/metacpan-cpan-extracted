# -*-Perl-*-
# $Id$

BEGIN {
    use lib 't';
    use Bio::Root::Test;
    test_begin(-tests => 162);

	use_ok('DBTestHarness');
	use_ok('Bio::ClusterIO');
}

$biosql = DBTestHarness->new("biosql");
$db = $biosql->get_DBAdaptor();
ok $db;

my $objio = Bio::ClusterIO->new('-format' => 'unigene',
				'-file' => test_input_file('unigene.data'));
my $clu = $objio->next_cluster();
ok $clu;

my $pclu = $db->create_persistent($clu);
ok $pclu;
isa_ok $pclu, "Bio::DB::PersistentObjectI";
isa_ok $pclu, "Bio::ClusterI";

$pclu->namespace("mytestnamespace");
$pclu->create();
my $dbid = $pclu->primary_key();
ok $dbid;

my $adp = $db->get_object_adaptor($clu);
ok $adp;
isa_ok $adp, "Bio::DB::PersistenceAdaptorI";

# try/finally
eval {
    $dbclu = $adp->find_by_primary_key($dbid);
    ok $dbclu;

    is ($dbclu->display_id, $clu->display_id);
    is ($dbclu->description, $clu->description);
    is ($dbclu->size, $clu->size);
    is (scalar($dbclu->get_members), scalar($clu->get_members));
    is (scalar($dbclu->get_members), $clu->size);
    is ($dbclu->species->binomial, $clu->species->binomial);

    # check all annotation objects
    my @dbkeys =
	sort { $a cmp $b } $dbclu->annotation->get_all_annotation_keys();
    my @keys =
	sort { $a cmp $b } $clu->annotation->get_all_annotation_keys();
    is (scalar(@dbkeys), scalar(@keys));
    my $i = 0;
    while($i < @dbkeys) {
	is ($dbkeys[$i], $keys[$i]);
	my @dbanns = sort {
	    $a->as_text cmp $b->as_text;
	} $dbclu->annotation->get_Annotations($dbkeys[$i]);
	my @anns = sort {
	    $a->as_text cmp $b->as_text;
	} $clu->annotation->get_Annotations($dbkeys[$i]);
	is (scalar(@dbanns), scalar(@anns),
	    "number of annotations don't match for key ".$dbkeys[$i]);
	my $j = 0;
	while($j < @dbanns) {
	    is ($dbanns[$j]->as_text, $anns[$j]->as_text,
		"values for annotation element $j don't match for key ".
		$dbkeys[$i]);
	    $j++;
	}
	$i++;
    }

    # check all members
    my @dbmems = sort {
	$a->accession_number() cmp $b->accession_number();
    } $dbclu->get_members();
    my @mems = sort {
	$a->accession_number() cmp $b->accession_number();
    } $clu->get_members();
    $i = 0;
    while(($i < @mems) && ($i < @dbmems)) {
	is ($dbmems[$i]->accession_number, $mems[$i]->accession_number);
	is ($dbmems[$i]->display_id, $mems[$i]->display_id);
	is ($dbmems[$i]->namespace, $mems[$i]->namespace);
	$i++;
    }

    # test cluster member association removal
    ok $adp->remove_members($dbclu);
    # re-fetch and test members
    $dbclu = $adp->find_by_primary_key($dbid);
    ok $dbclu;
    is (scalar($dbclu->get_members()), 0);
    # but the members should be still there (just not associated anymore)
    my $seq = $dbmems[0]->adaptor->find_by_primary_key($dbmems[0]->primary_key);
    ok $seq;
    is ($seq->accession_number, $dbmems[0]->accession_number);
    # and the original size is retained, like it or not
    is ($dbclu->size, 29);
    # now try to update the size (we should be able to do that in the
    # absence of any members
    $dbclu->size(10);
    $dbclu->store();
    # refetch and test
    $dbclu = $adp->find_by_primary_key($dbid);
    is ($dbclu->size, 10);
};

print STDERR $@ if $@;

# delete clu
is ($pclu->remove(), 1);
my $ns = Bio::DB::Persistent::BioNamespace->new(-identifiable => $pclu);
ok $ns = $db->get_object_adaptor($ns)->find_by_unique_key($ns);
ok $ns->primary_key();
is ($ns->remove(), 1);
