#!/usr/bin/perl
 
# This script will remove specific records in ontology table, as well as in 
# term, term_relationship, term_path, term_dbxref, term_synonym, which are 
# related to ontology table.
# 
# Tested with mysql.
#
# $Id$
#
# Cared for by Juguang Xiao, juguang@tll.org.sg
#
# Copyright Juguang Xiao 
#
# You may distribute this script under the same terms as perl itself

#
# Note from the "editor" (Hilmar): 99% of this should not be necessary with
# enabled foreign key constraints. If you want to delete an entire ontology,
# delete the record from the ontology table, and everything else should be
# taken care of by the database server. Likewise, to get rid of an ontology
# term, delete the record from the term table. Dependent records in other
# tables should be deleted for you automatically through cascading deletes
# on the foreign key constraints. (This is one reason why properly supported
# foreign key constraints are extremely useful, not fluff as MySql used to
# claim.)
#
# Send email to biosql-l@open-bio.org if you have questions about this.
#  

use strict;
use Getopt::Long;
use Bio::DB::EasyArgv;

my $db = get_biosql_db_from_argv;
my $ontology_name;
GetOptions('ontology_name=s' => \$ontology_name);

my $dbh = $db->dbcontext->dbi->get_connection;

my $sql="SELECT * FROM ontology WHERE name = ?";

my $sth = $dbh->prepare($sql);
$sth->execute($ontology_name);
my $hashref = $sth->fetchrow_hashref;
unless(defined $hashref){
    die "Cannot find '$ontology_name' in the database\n";
}
my $ontology_id = $hashref->{ontology_id};
$sth=$dbh->prepare("SELECT term_id FROM term WHERE ontology_id=?");
$sth->execute($ontology_id);
my @term_ids;
while(my $term = $sth->fetch){
    push @term_ids, $term->[0];
}

# Now start to delete. The order of deleting should be with the 
# consideration of table relationship. Usually the tables which are 
# not refered should be removed before the referring tables.
# The order is (term_synonym, term_relationship, term_path, term_dbxref) -
# term - ontology

my $sth_term_synonym=$dbh->prepare("DELETE FROM term_synonym WHERE term_id =?");
my $sth_term_dbxref=$dbh->prepare('DELETE FROM term_dbxref WHERE term_id=?');
foreach my $term_id (@term_ids){
    $sth_term_synonym->execute($term_id);
    $sth_term_dbxref->execute($term_id);
}

my $sth_term_path=$dbh->prepare('DELETE FROM term_path WHERE ontology_id =?');
my $sth_term_relationship=
    $dbh->prepare('DELETE FROM term_relationship WHERE ontology_id =?');
my $sth_term=$dbh->prepare('DELETE FROM term WHERE ontology_id=?');
$sth_term_path->execute($ontology_id);
$sth_term_relationship->execute($ontology_id);
$sth_term->execute($ontology_id);

$sth = $dbh->prepare("DELETE FROM ontology WHERE ontology_id =?");
$sth->execute($ontology_id);



