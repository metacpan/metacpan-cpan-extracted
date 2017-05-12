#!/usr/local/bin/perl

# This example will pull some information on a sequence
# from the C. Elegans ACEDB.

use lib '../blib/lib','../blib/arch';
use Ace;
use strict vars;

use constant HOST => $ENV{ACEDB_HOST} || 'stein.cshl.org';
use constant PORT => $ENV{ACEDB_PORT} || 200005;

$|=1;

print "Opening the database....";
my $db = Ace->connect(-host=>HOST,-port=>PORT) || die "Connection failure: ",Ace->error;
print "done.\n";

my @sequences = $db->list('Sequence','S*');
print "There are ",scalar(@sequences)," Sequence objects starting with the letter \"S\".\n";
print "The first one's name is ",$sequences[0],"\n";
print "It contains the following top level tags:\n";
foreach ($sequences[0]->tags) {
  print "\t$_\n";
}
print "The following homology types have been identified:\n";
my @homol = $sequences[0]->Homol;
foreach (@homol) {
  my @hits=$_->col;
  print "\t$_ (",scalar(@hits)," hits)\n";
}

print "The DNA homology hits are: ",join(', ',$sequences[0]->DNA_homol),"\n";
my $homol = $sequences[0]->DNA_homol;
print "The sequence of the homologous sequence $homol is: ",$homol->DNA->right,"\n";
