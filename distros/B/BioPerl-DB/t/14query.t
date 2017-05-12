# -*-Perl-*-
# $Id$

BEGIN {
    use lib '.';
    use Bio::Root::Test;
    test_begin(-tests => 23);

	use_ok('Bio::DB::Query::SqlQuery');
	use_ok('Bio::DB::Query::SqlGenerator');
	use_ok('Bio::DB::Query::BioQuery');
	use_ok('Bio::DB::Query::QueryConstraint');
	use_ok('Bio::DB::BioSQL::mysql::BasePersistenceAdaptorDriver');
}

my $query = Bio::DB::Query::SqlQuery->new(-tables => ["table1"]);
my $sqlgen = Bio::DB::Query::SqlGenerator->new(-query => $query);

my $sql = $sqlgen->generate_sql();
is ($sql, "SELECT * FROM table1");

$query->add_datacollection("table1", "table2");
$sql = $sqlgen->generate_sql();
is ($sql, "SELECT * FROM table1, table2");

$query->selectelts("col1", "col2", "col3");
$sql = $sqlgen->generate_sql();
is ($sql, "SELECT col1, col2, col3 FROM table1, table2");

$query->groupelts("col1", "col3");
$sql = $sqlgen->generate_sql();
is ($sql, "SELECT col1, col2, col3 FROM table1, table2 GROUP BY col1, col3");

$query->groupelts([]);
$query->orderelts("col2","col3");
$sql = $sqlgen->generate_sql();
is ($sql, "SELECT col1, col2, col3 FROM table1, table2 ORDER BY col2, col3");

$query->where(["col4 = ?", "col5 = 'somevalue'"]);
$sql = $sqlgen->generate_sql();
is ($sql, "SELECT col1, col2, col3 FROM table1, table2 WHERE col4 = ? AND col5 = 'somevalue' ORDER BY col2, col3");

$query->where(["and",
	       ["or", "col4 = ?", "col5 = 'somevalue'"],
	       ["col2 = col4", "col6 not like 'abcd*'"]]);
$sql = $sqlgen->generate_sql();
is ($sql, "SELECT col1, col2, col3 FROM table1, table2 WHERE (col4 = ? OR col5 = 'somevalue') AND (col2 = col4 AND col6 NOT LIKE 'abcd\%') ORDER BY col2, col3");

$query = Bio::DB::Query::BioQuery->new();
$mapper = Bio::DB::BioSQL::mysql::BasePersistenceAdaptorDriver->new();

$query->selectelts(["accession_number","version"]);
$query->datacollections(["Bio::PrimarySeqI"]);
$tquery = $query->translate_query($mapper);
$sql = $sqlgen->generate_sql($tquery);
is ($sql, "SELECT bioentry.accession, bioentry.version FROM bioentry");

$query->selectelts([]);
$query->datacollections(["Bio::Species=>Bio::PrimarySeqI"]);
$tquery = $query->translate_query($mapper);
$sql = $sqlgen->generate_sql($tquery);
is ($sql, "SELECT * FROM bioentry, taxon_name WHERE bioentry.taxon_id = taxon_name.taxon_id");

$query->datacollections(["Bio::PrimarySeqI e",
			 "Bio::Species=>Bio::PrimarySeqI sp"]);
$tquery = $query->translate_query($mapper);
$sql = $sqlgen->generate_sql($tquery);
is ($sql, "SELECT * FROM bioentry e, taxon_name sp WHERE e.taxon_id = sp.taxon_id");

$query->datacollections(["Bio::PrimarySeqI e",
			 "Bio::Species=>Bio::PrimarySeqI sp",
			 "BioNamespace=>Bio::PrimarySeqI db"]);
$query->where(["sp.binomial like 'Mus *'",
	       "e.desc like '*receptor*'",
	       "db.namespace = 'ensembl'"]);
$tquery = $query->translate_query($mapper);
$sql = $sqlgen->generate_sql($tquery);
is ($sql,
    "SELECT * ".
    "FROM bioentry e, taxon_name sp, biodatabase db ".
    "WHERE e.taxon_id = sp.taxon_id AND e.biodatabase_id = db.biodatabase_id ".
    "AND (sp.name LIKE 'Mus \%' AND e.description LIKE '\%receptor\%' ".
    "AND db.name = 'ensembl')");

$query->selectelts(["e.accession_number","e.version"]);
$query->datacollections(["Bio::PrimarySeqI e",
			 "Bio::Species=>Bio::PrimarySeqI sp",
			 "BioNamespace=>Bio::PrimarySeqI db",
			 "Bio::Annotation::DBLink xref",
			 "Bio::PrimarySeqI<=>Bio::Annotation::DBLink"]);
$query->where(["sp.binomial like 'Mus *'",
	       "e.desc like '*receptor*'",
	       "db.namespace = 'ensembl'",
	       "xref.database = 'SWISS'"]);
#$query->flag();
$tquery = $query->translate_query($mapper);
$sql = $sqlgen->generate_sql($tquery);
is ($sql,
    "SELECT e.accession, e.version ".
    "FROM bioentry e, taxon_name sp, biodatabase db, dbxref xref, bioentry_dbxref ".
    "WHERE e.taxon_id = sp.taxon_id AND e.biodatabase_id = db.biodatabase_id ".
    "AND e.bioentry_id = bioentry_dbxref.bioentry_id ".
    "AND xref.dbxref_id = bioentry_dbxref.dbxref_id ".
    "AND (sp.name LIKE 'Mus \%' AND e.description LIKE '\%receptor\%' ".
    "AND db.name = 'ensembl' AND xref.dbname = 'SWISS')");

$query = Bio::DB::Query::BioQuery->new();
$query->datacollections(["Bio::PrimarySeqI<=>Bio::Annotation::SimpleValue"]);
$query->where(["Bio::PrimarySeqI::primary_key = 10",
	       "Bio::Annotation::SimpleValue::ontology = 3"]);
$tquery = $query->translate_query($mapper);
$sql = $sqlgen->generate_sql($tquery);
is ($sql,
    "SELECT * ".
    "FROM bioentry, term, bioentry_qualifier_value ".
    "WHERE bioentry.bioentry_id = bioentry_qualifier_value.bioentry_id ".
    "AND term.term_id = bioentry_qualifier_value.term_id ".
    "AND (bioentry.bioentry_id = 10 AND term.ontology_id = 3)");

$query->datacollections(
		  ["Bio::PrimarySeqI e",
		   "Bio::Annotation::SimpleValue sv",
		   "Bio::PrimarySeqI<=>Bio::Annotation::SimpleValue esva"]);
$query->where(["Bio::PrimarySeqI::primary_key = 10",
	       "Bio::Annotation::SimpleValue::ontology = 3"]);
$tquery = $query->translate_query($mapper);
$sql = $sqlgen->generate_sql($tquery);
is ($sql,
    "SELECT * ".
    "FROM bioentry e, term sv, bioentry_qualifier_value esva ".
    "WHERE e.bioentry_id = esva.bioentry_id ".
    "AND sv.term_id = esva.term_id ".
    "AND (e.bioentry_id = 10 AND sv.ontology_id = 3)");

$query->datacollections(
		  ["Bio::DB::BioSQL::PrimarySeqAdaptor",
		   "Bio::DB::BioSQL::SimpleValueAdaptor sv",
		   "Bio::DB::BioSQL::PrimarySeqAdaptor<=>Bio::DB::BioSQL::SimpleValueAdaptor"]);
$query->where(["Bio::PrimarySeqI::primary_key = 10",
	       "Bio::Annotation::SimpleValue::ontology = 3"]);
$tquery = $query->translate_query($mapper);
$sql = $sqlgen->generate_sql($tquery);
is ($sql,
    "SELECT * ".
    "FROM bioentry, term sv, bioentry_qualifier_value ".
    "WHERE bioentry.bioentry_id = bioentry_qualifier_value.bioentry_id ".
    "AND sv.term_id = bioentry_qualifier_value.term_id ".
    "AND (bioentry.bioentry_id = 10 AND sv.ontology_id = 3)");

$query->datacollections(
		  ["Bio::PrimarySeqI c::subject",
		   "Bio::PrimarySeqI p::object",
		   "Bio::PrimarySeqI<=>Bio::PrimarySeqI<=>Bio::Ontology::TermI"]);
$query->where(["p.accession_number = 'Hs.2'",
	       "Bio::Ontology::TermI::name = 'cluster member'"]);
$tquery = $query->translate_query($mapper);
$sql = $sqlgen->generate_sql($tquery);
is ($sql,
    "SELECT * ".
    "FROM bioentry c, bioentry p, term, bioentry_relationship ".
    "WHERE c.bioentry_id = bioentry_relationship.subject_bioentry_id ".
    "AND p.bioentry_id = bioentry_relationship.object_bioentry_id ".
    "AND term.term_id = bioentry_relationship.term_id ".
    "AND (p.accession = 'Hs.2' AND term.name = 'cluster member')");

# this must also work with different objects in the association that map
# to the same tables though
$query->datacollections(
		  ["Bio::PrimarySeqI c::subject",
		   "Bio::PrimarySeqI p::object",
		   "Bio::PrimarySeqI<=>Bio::ClusterI<=>Bio::Ontology::TermI"]);
$query->where(["p.accession_number = 'Hs.2'",
	       "Bio::Ontology::TermI::name = 'cluster member'"]);
$tquery = $query->translate_query($mapper);
$sql = $sqlgen->generate_sql($tquery);
is ($sql,
    "SELECT * ".
    "FROM bioentry c, bioentry p, term, bioentry_relationship ".
    "WHERE c.bioentry_id = bioentry_relationship.subject_bioentry_id ".
    "AND p.bioentry_id = bioentry_relationship.object_bioentry_id ".
    "AND term.term_id = bioentry_relationship.term_id ".
    "AND (p.accession = 'Hs.2' AND term.name = 'cluster member')");

$query = Bio::DB::Query::BioQuery->new(
               -datacollections => ["Bio::Ontology::OntologyI=>Bio::Ontology::PathI o",
				    "Bio::Ontology::TermI=>Bio::Ontology::PathI ts::subject",
				    "Bio::Ontology::TermI=>Bio::Ontology::PathI to::object",
			 ],
	       -where => ["o.name = 'My Test Ontology'",
			  "ts.name = 'exon'",
			  "to.name = 'gene'"]
				       );
$tquery = $query->translate_query($mapper);
$sql = $sqlgen->generate_sql($tquery);
is ($sql,
    "SELECT * ".
    "FROM term_path, ontology o, term ts, term to ".
    "WHERE term_path.ontology_id = o.ontology_id ".
    "AND term_path.subject_term_id = ts.term_id ".
    "AND term_path.object_term_id = to.term_id ".
    "AND (o.name = 'My Test Ontology' ".
    "AND ts.name = 'exon' AND to.name = 'gene')");
