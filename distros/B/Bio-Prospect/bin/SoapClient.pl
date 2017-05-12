#!/usr/bin/env perl

#-------------------------------------------------------------------------------
# NAME: SoapClient.pl
# PURPOSE: test script for the SoapClient object
# USAGE: SoapClient.pl sequence-file
#
# $Id: SoapClient.pl,v 1.6 2003/11/18 19:45:46 rkh Exp $
#-------------------------------------------------------------------------------

use Bio::Prospect::Options;
use Bio::Prospect::SoapClient;
use Bio::Prospect::Thread;
use Bio::SeqIO;
use warnings;
use strict;
use vars qw( $VERSION );
$VERSION = sprintf( "%d.%02d", q$Revision: 1.6 $ =~ /(\d+)\.(\d+)/ );


die( "USAGE: SoapClient.pl <input sequence> \n" ) if $#ARGV != 0;

my $in = new Bio::SeqIO( -format=> 'Fasta', '-file' => $ARGV[0] );
my $po = new Bio::Prospect::Options( seq=>1, svm=>1, global_local=>1,
  templates=>['1alu', '1bgc','1eera']);

# host parameter should equal the host running SoapServer process
my $pf = new Bio::Prospect::SoapClient( {options=>$po});

while ( my $s = $in->next_seq() ) {
  my @threads = $pf->thread( $s ); 
  print "threads ... " . ($#threads+1) . "\n";
  foreach my $t ( @threads ) {
    print '-'x80,"\n";
    print "tname           " . $t->tname . "\n";
    print "svm score:      " . $t->svm_score() . "\n";
    print "raw score:      " . $t->raw_score() . "\n";
    print "align:\n" . $t->alignment() . "\n";
  }
}
