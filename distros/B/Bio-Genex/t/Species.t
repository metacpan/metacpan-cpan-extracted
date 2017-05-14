# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Chromosome.t'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..9\n"; }
END {print "not ok 1\n" unless $loaded;}
use Carp;



# use blib;
use Bio::Genex::Species;
use Bio::Genex;
use lib 't';
use TestDB qw($ECOLI_SPECIES $YEAST_SPECIES $ECOLI_CHROM $ECOLI_CHROM_LENGTH);
$loaded = 1;
my $i = 1;
print "ok ", $i++, "\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

# testing a random attribute
my $s = new Bio::Genex::Species;
$s->genome_size(555);
if ($s->genome_size() == 555){
  print "ok ", $i++, "\n";
} else {
  print "not ok ", $i++, "\n";
}

# test fetch
$s = new Bio::Genex::Species(id=>$ECOLI_SPECIES);
$s->fetch();
if ($s->genome_size() == $ECOLI_CHROM_LENGTH){
  print "ok ", $i++, "\n";
} else {
  print "not ok ", $i++, "\n";
}

# test delayed_fetch
$s = new Bio::Genex::Species(id=>$ECOLI_SPECIES);
if (not defined $s->get_attribute('genome_size')){
  print "ok ", $i++, "\n";
} else {
  print "not ok ", $i++, "\n";
}

if ($s->genome_size() == $ECOLI_CHROM_LENGTH){
  print "ok ", $i++, "\n";
} else {
  print "not ok ", $i++, "\n";
}

my $dbh = Bio::Genex::current_connection(TRANSACTION=>1,
				    USER=>$Bio::Genex::SU_USERNAME,
				    PASSWORD=>$Bio::Genex::SU_PASSWORD);
# test update_db
$s->primary_scientific_name('foo');

if ($s->update_db($dbh)) {
  print "ok ", $i++, "\n";
} else {
  print "not ok ", $i++, "\n";
}

my ($s2) = Bio::Genex::Species->get_all_objects(
		{column=>'primary_scientific_name',
		 value=>'foo'});
if ($s->spc_pk == $s2->spc_pk) {
  print "ok ", $i++, "\n";
} else {
  print "not ok ", $i++, "\n";
}

$dbh->rollback();
$dbh->disconnect();

# test insert_db
$dbh = Bio::Genex::current_connection(TRANSACTION=>1,
				 USER=>$Bio::Genex::SU_USERNAME,
				 PASSWORD=>$Bio::Genex::SU_PASSWORD);

$s = new Bio::Genex::Species(primary_scientific_name=>'bar',
		       is_circular_genome=>0,
		       is_sequenced_genome=>0,
		       );

if ($s->insert_db($dbh)) {
  print "ok ", $i++, "\n";
} else {
  print "not ok ", $i++, "\n";
}

$s = Bio::Genex::Species->get_all_objects({column=>'primary_scientific_name',
					   value=>'bar'});
if (defined $s) {
  print "ok ", $i++, "\n";
} else {
  print "not ok ", $i++, "\n";
}

$dbh->rollback();
$dbh->disconnect();

1;
