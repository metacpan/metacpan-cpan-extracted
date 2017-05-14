# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Chromosome.t'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..14\n"; }
END {print "not ok 1\n" unless $loaded;}
# use blib;
use Bio::Genex;
use Bio::Genex::Software;
use Carp;


use lib 't';
use TestDB qw($YEAST_SPECIES
	      $TOTAL_SPECIES
	      $ECOLI_SPECIES
	      $ECOLI_CHROM
	      $TEST_SOFTWARE
	      $ECOLI_CHROM_LENGTH);
$loaded = 1;
my $i = 1;
print "ok ", $i++, "\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

my $dbh;

# test that we get a DBI connection to 'genex' using 
# Bio::Genex::_connect()
$Bio::Genex::_CURRENT_CONNECTION->disconnect() 
  if defined $Bio::Genex::_CURRENT_CONNECTION;

# test #2
$dbh = Bio::Genex::_connect();
print "not " unless defined $dbh 
  && $dbh->isa("DBI::db") 
  && $dbh->isa("Bio::Genex::Connect") 
  && $dbh->{Name} eq $Bio::Genex::DBNAME;
print "ok ", $i++, "\n";

# test #3
# test that $Bio::Genex::_CURRENT_CONNECTION is not set with _connect()
print "not " if defined $Bio::Genex::_CURRENT_CONNECTION;
print "ok ", $i++, "\n";

$dbh->disconnect();

# test #4
# test that we get a DBI connection to 'genex' using 
# Bio::Genex::current_connection()
$dbh = Bio::Genex::current_connection();
print "not " unless defined $dbh 
  && $dbh->isa("DBI::db") 
  && $dbh->isa("Bio::Genex::Connect") 
  && $dbh->{Name} eq $Bio::Genex::DBNAME;
print "ok ", $i++, "\n";

# test #5
# test that $Bio::Genex::_CURRENT_CONNECTION is set using current_conntction()
print "not " unless defined $Bio::Genex::_CURRENT_CONNECTION;
print "ok ", $i++, "\n";

# test #6
# check that disconnect undefines $Bio::Genex::_CURRENT_CONNECTION
$dbh->disconnect();
print "not " if defined $Bio::Genex::_CURRENT_CONNECTION;
print "ok ", $i++, "\n";

# test Bio::Genex::undefined
use Bio::Genex::Chromosome;
my $c = new Bio::Genex::Chromosome(id=>$ECOLI_CHROM);

# test #7
# we haven't fetched the data for the chromosome yet, 
# so when we call get_attribute(), the value should be undef
print "not " if defined $c->get_attribute('length');
print "ok ", $i++, "\n";

# test #8
# this call to length should call Bio::Genex::undefined(), and
# fetch the value from the DB
print "not " unless $c->length() == $ECOLI_CHROM_LENGTH;
print "ok ", $i++, "\n";

# test #9
# test that we get a warning when attempting delayed_fetch
# without setting the id attribute
$s = Bio::Genex::Species->new();
{
  $::got_it = 0;
  local $SIG{__WARN__} = sub { $::got_it = 1;};
  my $tmp = $s->genome_size();
  print "not " unless $::got_it;
  print "ok ", $i++, "\n";
}

# 
# Test that fetching an OTM_FKEY 
#    gives back an array_ref of the proper type of objects
#
# test #10
use Bio::Genex::Species;
$s = Bio::Genex::Species->new(id=>$ECOLI_SPECIES);
my $array_ref = $s->chromosome_obj();
print "not " unless ref($array_ref) eq 'ARRAY' &&
  ref($array_ref->[0]) && $array_ref->[0]->isa('Bio::Genex::Chromosome');
print "ok ", $i++, "\n";

# test #11
#
# test that we have the OTM fkey methods. This is to monitor a bug
# were I ignored adding OTM fkey methods to the attribute() call
$s = new Bio::Genex::Species(id=>$ECOLI_SPECIES);
if (grep {/usersequencefeature_fk/} $s->get_attribute_names) {
  print "ok ", $i++, "\n";
} else {
  print "not ok ", $i++, "\n";  
}

# test #12
#
# test get_all_objects()
my @objs = Bio::Genex::Species->get_all_objects();
if (scalar @objs == $TOTAL_SPECIES && 
    scalar @objs == scalar grep {$_->isa('Bio::Genex::Species')} @objs) 
{
  print "ok ", $i++, "\n";
} else {
  print "not ok ", $i++, "\n";  
}

# test #13
#
# test get_objects(@list)
@objs = Bio::Genex::Species->get_objects($ECOLI_SPECIES,$YEAST_SPECIES);
if (scalar @objs == 2 && 
    $objs[0]->isa('Bio::Genex::Species') && 
    $objs[1]->isa('Bio::Genex::Species')) {
  print "ok ", $i++, "\n";
} else {
  print "not ok ", $i++, "\n";  
}

# test #14
# 
# Test that fetching an FKEY_FKEY in Bio::Genex::undefined() 
#    gives back an object of the proper type
#
my $sw = Bio::Genex::Software->new(id=>$TEST_SOFTWARE);
my $con = $sw->con_obj();
print "not " unless ref($con) && $con->isa('Bio::Genex::Contact');
print "ok ", $i++, "\n";


1;
