#!/usr/bin/env perl

#-------------------------------------------------------------------------------
# NAME: LocalClient.pl
# PURPOSE: test script for the LocalClient object
# USAGE: LocalClient.pl input-sequence
#
# $Id: LocalClient.pl,v 1.12 2003/11/18 19:45:46 rkh Exp $
#-------------------------------------------------------------------------------

use Bio::Prospect::Options;
use Bio::Prospect::LocalClient;
use Bio::Prospect::Thread;
use Bio::SeqIO;
use Bio::Structure::IO;
use Bio::Prospect::Init;
use warnings;
use strict;
use vars qw( $VERSION );
$VERSION = sprintf( "%d.%02d", q$Revision: 1.12 $ =~ /(\d+)\.(\d+)/ );


die( "USAGE: LocalClient.pl input-sequence\n" ) if 
  $#ARGV != 0;

my $in = new Bio::SeqIO( -format=> 'Fasta', '-file' => $ARGV[0] );
my $po = new Bio::Prospect::Options( seq=>1, svm=>1, global_local=>1,
	templates=>['1bgc', '1alu','1lki','1huw','1f6fa','1cnt3','1ax8','1evsa','1f45b']);
my $pf = new Bio::Prospect::LocalClient( {options=>$po} );

while ( my $s = $in->next_seq() ) {
  my $xml = $pf->xml( $s ); 
	print STDERR $xml;
  my @threads = $pf->thread( $s ); 
  print "threads ... " . ($#threads+1) . "\n";
  foreach my $t ( @threads ) {
    print '-'x80,"\n";
    print "tname           " . $t->tname . "\n";
    print "svm score:      " . $t->svm_score() . "\n";
    print "raw score:      " . $t->raw_score() . "\n";
    print "align:\n" . $t->alignment() . "\n";

		my $pdb  = Bio::Structure::IO->new(-file => "$Bio::Prospect::Init::PROCESSED_PDB_PATH/".$t->tname.".pdb" , '-format' => 'pdb');
		my $struc = $pdb->next_structure();
		print "pdb:    " . $t->output_rasmol_script($struc) . "\n";
  }
}
