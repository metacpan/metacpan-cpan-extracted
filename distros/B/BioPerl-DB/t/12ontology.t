# -*-Perl-*-
# $Id$

BEGIN {
    use lib 't';
    use Bio::Root::Test;
    test_begin(-tests => 740);
	use_ok('DBTestHarness');
	use_ok('Bio::OntologyIO');
}

$biosql = DBTestHarness->new("biosql");
ok $biosql;

$db = $biosql->get_DBAdaptor();
ok $db;

my $ontio = Bio::OntologyIO->new(-file => test_input_file('sofa.ontology'),
				 -format => 'soflat');
ok ($ontio);
my $ont = $ontio->next_ontology();
ok ($ont);
$ont->name("My Test Ontology"); # avoid clashes

# insert by inserting all relationships (there are no isolated terms in SOFA)
foreach my $rel ($ont->get_relationships()) {
    # change ID prefix to avoid clashes
    foreach my $term_meth ("subject_term","object_term") {
	my $id = $rel->$term_meth->identifier();
	next if $id =~ /^MYTO/;
	$rel->$term_meth->identifier("MYTO:".substr($id,3)) if $id;
    }
    # make persistent and insert
    my $prel = $db->create_persistent($rel);
    ok ($prel->create());
    ok ($prel->primary_key());
}

# now get the ontology back from the database
my $dbont = Bio::Ontology::Ontology->new(-name => "My Test Ontology");
$dbont = $db->get_object_adaptor($dbont)->find_by_unique_key($dbont);
ok ($dbont);
ok ($dbont->primary_key());

# set up the query to get all relationships
my $queryrels = 
    Bio::DB::Query::BioQuery->new(
       -datacollections => ["Bio::Ontology::OntologyI=>Bio::Ontology::RelationshipI"],
       -where => ["Bio::Ontology::OntologyI::primary_key = ".
		  $dbont->primary_key()
		  ]
                                  );
my $reladp = $db->get_object_adaptor("Bio::Ontology::RelationshipI");
my $qres = $reladp->find_by_query($queryrels);
while(my $rel = $qres->next_object()) {
    is ($rel->ontology->name, "My Test Ontology");
    $dbont->add_term($rel->subject_term);
    $dbont->add_term($rel->object_term);
    #$dbont->add_term($rel->predicate_term);
    $dbont->add_relationship($rel);
}

# now query the ontology
my ($term) = $dbont->find_terms(-identifier => "MYTO:0000233");
ok ($term);
is ($term->identifier, "MYTO:0000233");
is ($term->name, "processed_transcript");
@rels = $dbont->get_relationships($term);
is (scalar(@rels), 5);
@relset = grep { $_->predicate_term->name eq "IS_A"; } @rels;
is (scalar(@relset), 3);
@relset = grep { $_->object_term->identifier eq "MYTO:0000233"; } @rels;
is (scalar(@relset), 4);

# check for correct storage and retrieval of synonyms and dbxrefs
($term) = $dbont->find_terms(-identifier => "MYTO:0000203");
ok ($term);
is ($term->name, "untranslated_region");
my @syns = $term->get_synonyms();
is (scalar(@syns), 1);
is ($syns[0], "UTR");
# modify, update, and re-retrieve to check with multiple synonyms, and with
# dbxrefs (this version of SOFA doesn't come with any dbxrefs)
$term->add_synonym("junk DNA");
$term->add_dbxref(-dbxrefs => [Bio::Annotation::DBLink->new(-database   => "MYDB",
					       -primary_id => "yaddayadda")]);
ok ($term->store());
$term = $term->adaptor->find_by_primary_key($term->primary_key);
ok ($term);
# now test
@syns = $term->get_synonyms();
is (scalar(@syns), 2);
is (scalar(grep { $_ eq "junk DNA"; } @syns), 1);
is (scalar($term->get_dbxrefs()), 1);

#
# test the transitive closure computations
#
my $ontadp = $db->get_object_adaptor("Bio::Ontology::OntologyI");
my $ontname = "My BioSQL Predicate Ontology";
my $id_pred = Bio::Ontology::Term->new(-name => "identity",
				       -ontology => $ontname);
my $superpred = Bio::Ontology::Term->new(-name => "PART_OF",
					 -ontology => $ontname);
my $subcl_pred = Bio::Ontology::Term->new(-name => "implies",
					  -ontology => $ontname);

ok ($ontadp->compute_transitive_closure($ont,
					-truncate => 1,
					-predicate_superclass => $superpred,
					-subclass_predicate   => $subcl_pred,
					-identity_predicate   => $id_pred));
#
# now query and test the results
# set up the query to get all relationships
$query = Bio::DB::Query::BioQuery->new(
               -datacollections => ["Bio::Ontology::OntologyI=>Bio::Ontology::PathI o",
				    "Bio::Ontology::TermI=>Bio::Ontology::PathI tsubj::subject",
				    "Bio::Ontology::TermI=>Bio::Ontology::PathI tobj::object",
			 ],
	       -where => ["o.name = 'My Test Ontology'",
			  "tobj.name = 'gene'",
			  "tsubj.name = 'exon'"]
				       );
my $pathadp = $db->get_object_adaptor("Bio::Ontology::PathI");
$qres = $pathadp->find_by_query($query);
my $n = 0;
while(my $path = $qres->next_object()) {
    is ($path->ontology->name, "My Test Ontology");
    is ($path->subject_term->name, "exon");
    is ($path->object_term->name, "gene");
    is ($path->predicate_term->name, "PART_OF");
    $n++;
}
is ($n, 1);

# test for distance zero paths
$query = Bio::DB::Query::BioQuery->new(
               -datacollections => [
                    "Bio::Ontology::OntologyI=>Bio::Ontology::PathI o",
                    "Bio::Ontology::TermI=>Bio::Ontology::PathI tpred::predicate",
			 ],
	       -where => ["o.name = 'My Test Ontology'",
			  "tpred.name = 'identity'"]
				       );
$qres = $pathadp->find_by_query($query);
$n = 0;
while(my $path = $qres->next_object()) {
    is ($path->ontology->name, "My Test Ontology");
    is ($path->subject_term->name, $path->object_term->name);
    is ($path->predicate_term->name, "identity");
    is ($path->predicate_term->ontology->name, "My BioSQL Predicate Ontology");
    is ($path->distance, 0);
    $n++ if $path->subject_term->identifier; # don't count hard-coded but
					     # unused relationship types
}
is ($n, 86);

#
# test removal of relationships
#
$ont = Bio::Ontology::Ontology->new(-name => "My Test Ontology");
ok ($reladp->remove_all_relationships($ont));

# try to find any relationships
$reladp = $db->get_object_adaptor("Bio::Ontology::RelationshipI");
$qres = $reladp->find_by_query($queryrels);
ok ($qres);
$n = 0;
while ($qres->next_object()) {
    $n++;
}
is ($n, 0);

# there should still be terms though
my $dbterm = Bio::Ontology::Term->new(-identifier => "MYTO:0000233");
$dbterm = $db->get_object_adaptor($dbterm)->find_by_unique_key($dbterm);
ok ($dbterm);
ok ($dbterm->primary_key);
ok ($dbterm->ontology);
is ($dbterm->ontology->name, "My Test Ontology");
is ($dbterm->identifier, "MYTO:0000233");
($term) = $dbont->find_terms(-identifier => "MYTO:0000233");
ok ($term);
is ($dbterm->name, $term->name);
is (scalar($dbterm->get_synonyms()), scalar($term->get_synonyms()));

