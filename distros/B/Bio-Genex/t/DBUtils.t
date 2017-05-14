# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Chromosome.t'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..21\n"; }
END {print "not ok 1\n" unless $loaded;}
use Carp;
# use blib;



use Bio::Genex;
use lib 't';
use TestDB qw($ECOLI_SPECIES 
	      $TEST_ES_NAME 
	      $TEST_ES
	      $TEST_SOFTWARE_NAME 
	      $TEST_SOFTWARE
	      $TEST_CONTACT_PERSON
	      $TEST_CONTACT
	      $TEST_USF
	      $TEST_USF_NAME
	      result
	     );
use Bio::Genex::DBUtils qw(assert_table_defined  
		      create_select_sql 
		      lookup_id 
		      lookup_species_id 
		      lookup_usf_id 
		      lookup_contact_id 
		      lookup_software_id 
		      lookup_experiment_id 
		      fetch_es_ids 
		      fetch_es_species
		      fetch_db_ids_for_species
		      output_spot_data
		      fetch_am_ids 
		      fetch_last_id 
		      create_insert_sql);
$loaded = 1;
my $i = 1;
print "ok ", $i++, "\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

$dbh = Bio::Genex::current_connection();

#
# check that assert_table_defined finds a real table
eval {assert_table_defined($dbh,'Species')};
print "not " if $@;
print "ok ", $i++, "\n";

#
# check that assert_table_defined dies on a bogus table
eval {assert_table_defined($dbh,'NOT_A_REAL_TABLE')};
print "not " unless $@;
print "ok ", $i++, "\n";

#
# check that create_insert_sql adds the correct number of 
# placeholders
$sql = create_insert_sql($dbh,'Species',['c1','c2','c3']);
print "not " unless $sql =~ /(\?,?){3}/;
print "ok ", $i++, "\n";

# check that create_insert_sql returns a string without 
# placeholders when given a hash of column/value pairs
$sql = create_insert_sql($dbh,'Species',{c1=>1,c2=>2,c3=>3});
print "not " if $sql =~ /\?/;
print "ok ", $i++, "\n";

#
# check that create_select_sql gives valid SQL
$sql = create_select_sql($dbh,COLUMNS=>['spc_pk'],
			 FROM=>['Species'],
			 WHERE=>"spc_pk = $ECOLI_SPECIES",
			 DISTINCT=>1,);
eval {
  @list = @{$dbh->selectall_arrayref($sql)};
  die $DBI::errstr if $dbh->err;
};
if ($@) {
  print "not ";
} else {
  print "not " unless scalar @list == 1 && 
    $list[0]->[0] == $ECOLI_SPECIES;
}
print "ok ", $i++, "\n";

#
# check create_select_sql with a limit
$sql = create_select_sql($dbh,COLUMNS=>['am_pk'],
			 FROM=>['ArrayMeasurement'],
			 LIMIT=>3,);
eval {
  @list = @{$dbh->selectall_arrayref($sql)};
  die $DBI::errstr if $dbh->err;
};
if ($@) {
  print "not ";
} else {
  print "not " unless scalar @list == 3;
}
print "ok ", $i++, "\n";

#
# check that fetch_es_ids() gives the correct number of pkeys
$sql = create_select_sql($dbh,COLUMNS=>['es_pk'],
			 FROM=>['ExperimentSet']);

eval {
  @ids = fetch_es_ids();
  @list = @{$dbh->selectall_arrayref($sql)};
  die $DBI::errstr if $dbh->err;
};
if ($@) {
  print "not ";
} else {
  print "not " unless scalar @ids == scalar @list;
}
print "ok ", $i++, "\n";

#
# check that fetch_db_ids_for_species() 
eval {
  @ids = fetch_db_ids_for_species($ECOLI_SPECIES);
  die $DBI::errstr if $dbh->err;
};
result(!$@ && scalar @ids, $i); $i++;

#
# check that fetch_am_ids() gives the correct number of pkeys
$sql = create_select_sql($dbh,COLUMNS=>['am_pk'],
			 FROM=>['ArrayMeasurement'],
			 WHERE=>"primary_es_fk = $TEST_ES",
			);

eval {
  @ids = fetch_am_ids($TEST_ES);
  @list = @{$dbh->selectall_arrayref($sql)};
  die $DBI::errstr if $dbh->err;
};
if ($@) {
  print "not ";
} else {
  print "not " unless scalar @ids == scalar @list;
}
print "ok ", $i++, "\n";

#
# check that we can filter with fetch_am_ids() 
$type = 'derived ratio';
$sql = create_select_sql($dbh,COLUMNS=>['am_pk'],
			 FROM=>['ArrayMeasurement'],
			 WHERE=>"primary_es_fk = $TEST_ES AND type = \'$type\'",
			);

eval {
  @ids = fetch_am_ids($TEST_ES,$type);
  @list = @{$dbh->selectall_arrayref($sql)};
  die $DBI::errstr if $dbh->err;
};
if ($@) {
  print "not ";
} else {
  print "not " unless scalar @ids == scalar @list;
}
print "ok ", $i++, "\n";

#
# check lookup_id()
$sql = create_select_sql($dbh,COLUMNS=>['es_pk'],
			 FROM=>['ExperimentSet'],
			 WHERE=>"es_pk = $TEST_ES",
			);

eval {
  $id = lookup_id($dbh,'ExperimentSet','es_pk','es_pk',$TEST_ES);
  $sql_id = $dbh->selectall_arrayref($sql)->[0][0];
  die $DBI::errstr if $dbh->err;
};
if ($@) {
  print "not ";
} else {
  print "not " unless $sql_id == $id;
}
print "ok ", $i++, "\n";

#
# check lookup_id() with approximate matching
$name = 'Escher';
eval {
  $id = lookup_id($dbh,'Species','primary_scientific_name','spc_pk', $name, 1);
};
print "not " if $@ || $ECOLI_SPECIES != $id;
print "ok ", $i++, "\n";

#
# check lookup_species_id()
eval {
  $id = lookup_species_id($dbh,'Escherichia',1);
};
print "not " if $@ || $ECOLI_SPECIES != $id;
print "ok ", $i++, "\n";


#
# check lookup_usf_id()
eval {
  $id = lookup_usf_id($dbh,$TEST_USF_NAME);
};
print "not " if $@ || $TEST_USF != $id;
print "ok ", $i++, "\n";

#
# check lookup_contact_id()
eval {
  $id = lookup_contact_id($dbh,$TEST_CONTACT_PERSON);
};
print "not " if $@ || $TEST_CONTACT != $id;
print "ok ", $i++, "\n";

#
# check lookup_software_id()
eval {
  $id = lookup_software_id($dbh,$TEST_SOFTWARE_NAME);
};
print "not " if $@ || $TEST_SOFTWARE != $id;
print "ok ", $i++, "\n";

#
# check lookup_experiment_id()
eval {
  $id = lookup_experiment_id($dbh,$TEST_ES_NAME);
};
print "not " if $@ || $TEST_ES != $id;
print "ok ", $i++, "\n";

#
# check fetch_es_species()
eval {
  $spc_db = fetch_es_species($dbh,$TEST_ES);
};
print "not " if $@ || $ECOLI_SPECIES != $spc_db->spc_pk;
print "ok ", $i++, "\n";

#
# check fetch_last_id()
eval {
  $id = fetch_last_id($dbh,'Software');
};
print "not " if $@;
print "ok ", $i++, "\n";

$file = 'tmp.out';
open(TMP,">$file") or die "Couldn't open $file for writing";

output_spot_data(\*TMP,
		 $TEST_ES,
		 'derived_ratio');
close(TMP);
open(TMP,$file) or die "Couldn't open $file for reading";
@lines = <TMP>;
print "not " if scalar @lines < 4000;
print "ok ", $i++, "\n";

END {unlink $file};
1;
