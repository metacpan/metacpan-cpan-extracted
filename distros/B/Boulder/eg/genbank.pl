#!/usr/local/bin/perl

# This requires LWP to be installed.
use lib '.','..';

use Boulder::Genbank;
$gb = new Boulder::Genbank(-accessor=>'Entrez',-param=>[qw/M57939 M28274 L36028/]);

while (my $s = $gb->get) {
  @introns = $s->Features->Intron;
  print "There are ",scalar(@introns)," introns.\n";
  if (@introns) {
    foreach (sort {$a->Number <=> $b->Number} @introns) {
      print "Intron number ",$_->Number,":\n",
            "\tPosition = ",$_->Position,"\n",
            "\tEvidence = ",$_->Evidence,"\n";
    }
  }
  @exons = $s->Features->Exon;
  print "There are ",scalar(@exons)," exons.\n";
  if (@exons) {
    foreach (sort {$a->Number <=> $b->Number} @exons) {
      print "Exon number ",$_->Number,":\n",
            "\tPosition = ",$_->Position,"\n",
            "\tEvidence = ",$_->Evidence,"\n",
            "\tGene = ",$_->Gene,"\n";
    }
  }
  
  if ($s->Features->Polya_signal || $s->Features->Polya_site) {
    print "The first PolyA site is at ",$s->Features->Polya_signal ? 
      $s->Features->Polya_signal->Position :
      $s->Features->Polya_site->Position
	,"\n";
  }
  
  print "This sequence has the following top level tags: ",join(',',$s->tags),"\n";
  print "\n","Here's the whole thing as a table:\n";
  print $s->asTable;
  print "------------------------------------\n";
}
