#!/usr/local/bin/perl

# This example will pull out N base pairs upstream of each predicted
# gene in C. elegans

use lib '..','../blib/arch';
use Ace::Sequence;
use strict vars;

use constant HOST => $ENV{ACEDB_HOST} || 'formaggio.cshl.org';
use constant PORT => $ENV{ACEDB_PORT} || 200005;

$|=1;

my $upstream = shift || die "Usage: upstream.pl <size (bp)>\n";

my $db = Ace->connect(-host=>HOST,-port=>PORT) || die "Connection failure: ",Ace->error;

warn "Fetching all predicted genes, please wait....\n";
#my @genes = $db->fetch('Predicted_Gene' => '*');

my @genes = $db->fetch(Predicted_Gene => '4R79.2');
for my $gene(@genes) {
  next unless my $seq = Ace::Sequence->new(-seq=>$gene,
					   -offset => (-$upstream-1),
					   -length => ($upstream)
					  );
  print $gene,"\t",$seq->dna,"\n";
}
