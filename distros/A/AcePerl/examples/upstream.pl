#!/usr/local/bin/perl

# This example will pull out N base pairs upstream of each predicted
# gene in C. elegans

use lib '../blib/lib','../blib/arch';
use Ace::Sequence::Multi;
use strict vars;

use constant HOST => 'stein.cshl.org';
use constant MAPS  => 300000;
use constant GENES => 300001;

$|=1;

my $upstream = shift || die "Usage: upstream.pl <size (bp)>\n";

my $db1 = Ace->connect(-host=>HOST,-port=>MAPS)  || die "Connection failure: ",Ace->error;
my $db2 = Ace->connect(-host=>HOST,-port=>GENES) || die "Connection failure: ",Ace->error;

warn "Fetching all predicted genes, please wait....\n";
my @genes = $db2->fetch('Predicted_Gene' => '*');
for my $gene(@genes) {
  my $seq = Ace::Sequence->new(-seq=>$gene,-offset=>(- $upstream),-length=>$upstream);
  next unless my $s = Ace::Sequence->new(-db=>$db1,
					 -name   => $seq->parent,
					 -offset => $seq->offset,
					 -length => $seq->length);
  print $gene,"\t",$s->dna,"\n";
}
