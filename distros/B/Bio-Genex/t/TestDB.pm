package TestDB;

use strict;
use vars qw($VERSION
	    @ISA
	    @EXPORT
	    @EXPORT_OK
	    $ECOLI_SPECIES
	    $TOTAL_SPECIES
	    $YEAST_SPECIES
	    $ECOLI_CHROM
	    $ECOLI_CHROM_LENGTH
	    $YEAST_CITATION
	    $YEAST_CITATION_AUTHORS
	    $TEST_CONTACT
	    $TEST_CONTACT_PERSON
	    $TEST_GROUPSEC
	    $TEST_GROUPSEC_GROUP_NAME
	    $ECOLI_SAMPLE
	    $ECOLI_SAMPLE_STRAIN
	    $TEST_SOFTWARE
	    $TEST_SOFTWARE_NAME
	    $TEST_ES
	    $TEST_DB
	    $TEST_ES_NAME
	    $TEST_USERSEC
	    $TEST_USERSEC_LOGIN
	    $TEST_USF
	    $TEST_USF_NAME
	    $TEST_BLAST
	   );
use Carp;
use DBI;
use Bio::Genex;

require Exporter;

@ISA = qw(Exporter);

@EXPORT_OK = qw($ECOLI_SPECIES 
		$TOTAL_SPECIES
		$YEAST_SPECIES
		$ECOLI_CHROM 
		$ECOLI_CHROM_LENGTH
		$YEAST_CITATION
		$YEAST_CITATION_AUTHORS
		$TEST_DB
		$TEST_ES
		$TEST_ES_NAME
		$TEST_CONTACT
		$TEST_CONTACT_PERSON
		$TEST_GROUPSEC
		$TEST_GROUPSEC_GROUP_NAME
		$TEST_USERSEC
		$TEST_USERSEC_LOGIN
		$ECOLI_SAMPLE
		$ECOLI_SAMPLE_STRAIN
		$TEST_SOFTWARE
		$TEST_SOFTWARE_NAME
		$TEST_BLAST
		$TEST_USF
		$TEST_USF_NAME
		result
	       );

BEGIN {
  my $dbh = Bio::Genex::current_connection();
  unless (defined $TEST_DB) {
    my $sql = 'SELECT name FROM ExternalDatabase WHERE name ';
    $sql .= 'LIKE \'%SGD%\'';
    ($TEST_DB) =
      @{$dbh->selectall_arrayref($sql)->[0]};
    die $DBI::errstr if $dbh->err;
  }
  unless (defined $TEST_BLAST) {
    my $sql = 'SELECT bh_pk FROM BlastHits WHERE match_accession =';
    $sql .= ' \'test\'';
    ($TEST_BLAST) =
      @{$dbh->selectall_arrayref($sql)->[0]};
    die $DBI::errstr if $dbh->err;
  }
  unless (defined $TEST_USF && $TEST_USF_NAME) {
    my $sql = 'SELECT usf_pk,usf_name FROM UserSequenceFeature WHERE usf_name =';
    $sql .= ' \'b0001\'';
    ($TEST_USF, $TEST_USF_NAME) =
      @{$dbh->selectall_arrayref($sql)->[0]};
    die $DBI::errstr if $dbh->err;
  }
  unless (defined $TEST_ES && $TEST_ES_NAME) {
    my $sql = 'SELECT es_pk,name FROM ExperimentSet WHERE biology_description LIKE';
    $sql .= ' \'%Wes Hatfield%\'';
    ($TEST_ES, $TEST_ES_NAME) =
      @{$dbh->selectall_arrayref($sql)->[0]};
    die $DBI::errstr if $dbh->err;
  }
  unless (defined $TEST_SOFTWARE && $TEST_SOFTWARE_NAME) {
    my $sql = 'SELECT sw_pk,name FROM Software WHERE name LIKE';
    $sql .= ' \'%ArrayVision%\'';
    ($TEST_SOFTWARE, $TEST_SOFTWARE_NAME) =
      @{$dbh->selectall_arrayref($sql)->[0]};
    die $DBI::errstr if $dbh->err;
  }
  unless (defined $ECOLI_SAMPLE && $ECOLI_SAMPLE_STRAIN) {
    my $sql = 'SELECT smp_pk,strain FROM Sample WHERE strain LIKE';
    $sql .= ' \'%IH100%\'';
    ($ECOLI_SAMPLE, $ECOLI_SAMPLE_STRAIN) =
      @{$dbh->selectall_arrayref($sql)->[0]};
    die $DBI::errstr if $dbh->err;
  }
  unless (defined $TEST_GROUPSEC && $TEST_GROUPSEC_GROUP_NAME) {
    my $sql = 'SELECT gs_pk,group_name FROM GroupSec WHERE group_name=\'';
    $sql .= 'test group\'';
    ($TEST_GROUPSEC, $TEST_GROUPSEC_GROUP_NAME) =
      @{$dbh->selectall_arrayref($sql)->[0]};
    die $DBI::errstr if $dbh->err;
  }
  unless (defined $TEST_CONTACT && $TEST_CONTACT_PERSON) {
    my $sql = 'SELECT con_pk,contact_person FROM Contact WHERE type=\'';
    $sql .= 'test_user\' AND organization=\'test_organization\'';
    ($TEST_CONTACT, $TEST_CONTACT_PERSON) =
      @{$dbh->selectall_arrayref($sql)->[0]};
    die $DBI::errstr if $dbh->err;
  }
  unless (defined $TEST_USERSEC && $TEST_USERSEC_LOGIN) {
    my $sql = 'SELECT us_pk,login FROM UserSec WHERE con_fk=';
    $sql .= $TEST_CONTACT;
    ($TEST_USERSEC, $TEST_USERSEC_LOGIN) =
      @{$dbh->selectall_arrayref($sql)->[0]};
    die $DBI::errstr if $dbh->err;
  }
  unless (defined $YEAST_CITATION && $YEAST_CITATION_AUTHORS) {
    my $sql = 'SELECT cit_pk,authors FROM Citation WHERE title LIKE';
    $sql .= ' \'%Control of Gene Expression%\'';
    ($YEAST_CITATION,$YEAST_CITATION_AUTHORS) = 
      @{$dbh->selectall_arrayref($sql)->[0]};
    die $DBI::errstr if $dbh->err;
  }
  unless (defined $TOTAL_SPECIES) {
    my $sql = 'SELECT spc_pk FROM Species';
    $TOTAL_SPECIES = scalar @{$dbh->selectall_arrayref($sql)};
    die $DBI::errstr if $dbh->err;
  }
  unless (defined $ECOLI_SPECIES) {
    my $sql = 'SELECT spc_pk FROM Species WHERE primary_scientific_name LIKE \'';
    $sql .= 'Escherichia%' . '\'';
    $ECOLI_SPECIES = $dbh->selectall_arrayref($sql)->[0][0];
    die $DBI::errstr if $dbh->err;
  }
  unless (defined $YEAST_SPECIES) {
    my $sql = 'SELECT spc_pk FROM Species WHERE primary_scientific_name LIKE \'';
    $sql .= 'Saccharomyces%' . '\'';
    $YEAST_SPECIES = $dbh->selectall_arrayref($sql)->[0][0];
    die $DBI::errstr if $dbh->err;
  }
  unless (defined $ECOLI_CHROM && $ECOLI_CHROM_LENGTH) {
    my $sql = 'SELECT chr_pk,length FROM Chromosome WHERE spc_fk=';
    $sql .= $ECOLI_SPECIES;
    ($ECOLI_CHROM, $ECOLI_CHROM_LENGTH) = 
      @{$dbh->selectall_arrayref($sql)->[0]}; 
    die $DBI::errstr if $dbh->err;
  }
}

sub result {
  my ($cond,$i) = @_;
  print STDOUT "not " unless $cond;
  print STDOUT "ok ", $i, "\n";
}
