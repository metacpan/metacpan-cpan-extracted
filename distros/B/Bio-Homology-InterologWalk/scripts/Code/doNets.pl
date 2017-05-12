#!/usr/local/bin/perl
#
# Copyright (c) 2010 Giuseppe Gallone
#
# See COPYRIGHT section in walk.pm for usage and distribution rights.
#
# Example file to document typical usage of  Bio::Homology::InterologWalk::Networks. 
# This file uses Getopt::Long for simple management of command line arguments,
# and Term::AnsiColor for clearer console output.

#USAGE perl doNets.pl -data="yourfile.07out" -origdata="yourfile.txt" -sourceorg="Mus musculus"
#or
#USAGE perl doNets.pl -data="yourfile.06out" -origdata="yourfile.txt" -sourceorg="Mus musculus"

use strict;
use warnings;
use Getopt::Long;
use Term::ANSIColor;
use Bio::Homology::InterologWalk;
use Carp qw(croak);

my $work_dir = "../Data/";

my $infilename;
my $startfilename;
my $outfilename;
my $sourceorg;
my $orthtype;

GetOptions(
    "data=s"          => \$infilename,
    "origdata=s"      => \$startfilename, 
    "sourceorg=s"     => \$sourceorg,
    "orthtype=s"      => \$orthtype
);

#filenames and CLAs===============================================
unless ( $infilename && $startfilename ){
     print "\n";
     print "USAGE=========\n";
     print "perl doNets.pl -data=\"<yourfile>.07out\" -origdata=\"<yourfile>.txt\" -sourceorg=\"Mus musculus\"";
     print "\nif you have scored your results, or\n";
     print "perl doNets.pl -data=\"<yourfile>.06out\" -origdata=\"<yourfile>.txt\" -sourceorg=\"Mus musculus\"";
     print "\nif you have NOT scored your results, or\n";
     print "perl doNets.pl -data=\"<yourfile>.direct.02\" -origdata=\"<yourfile>.txt\" -sourceorg=\"Mus musculus\"";
     print "\nif your input contains direct interactions obtained from Intact.\n";
     print "USAGE=========\n";
     exit;
}else {
    print "doNets.pl: Using input file: $infilename\n";
}

if ( !$sourceorg ) {    #then use some default
    #$sourceorg = "Drosophila melanogaster";
    $sourceorg = "Mus musculus";
    #$sourceorg = 'Caenorhabditis elegans';
    print "doNets.pl: no source organism specified..Using default: $sourceorg\n";
}
else {
    print "doNets.pl: Using source organism: $sourceorg.\n";
}

#==================================================================


my $ensembl_db = 'ensembl';
my $registry = Bio::Homology::InterologWalk::setup_ensembl_adaptor(
                                                  connect_to_db => $ensembl_db,
                                                  source_org    => $sourceorg
                                                  );
if ( !$registry ) {
    print "\nThere were problems setting up the connection to Ensembl. Aborting..\n";
    exit;
}

#get actual network
print colored ( "Building network file from PPI/Putative PPI data...", 'green' ), "\n";
my $start_run = time();
my $RC1        = Bio::Homology::InterologWalk::Networks::do_network(
                                                       registry    => $registry,
                                                       data_file   => $infilename, 
                                                       data_dir    => $work_dir,
                                                       source_org  => $sourceorg,
                                                       #orthology_type => $orthtype,
                                                       #expand_taxa    => 1,
                                                       #ensembl_db     => $ensembl_db,
                                                       );
if ( !$RC1 ) {
    print("There were errors. Stopping..\n");
    exit;
}
my $end_run  = time();
my $run_time = $end_run - $start_run;
print "*FINISHED* Job took $run_time seconds\n";


#create cytoscape attribute files for the .sif file you just obtained
print colored ( "Creating attribute file for sif network...", 'green' ), "\n";
$start_run = time();

my $RC2  = Bio::Homology::InterologWalk::Networks::do_attributes(
                                                       registry        => $registry,
                                                       data_file       => $infilename,
                                                       start_file      => $startfilename,
                                                       data_dir        => $work_dir,
                                                       source_org      => $sourceorg,
                                                       #set the following to 1 ONLY if you are processing
                                                       #direct interactions including chimeric IDs
                                                       #as it will SLOW down the routine considerably
                                                       #label_chimeric  => 1 
                                                       );
if ( !$RC2 ) {
    print("There were errors. Stopping..\n");
    exit;
}

$registry->clear();                                                                                                                 
$end_run  = time();
$run_time = $end_run - $start_run;
print "*FINISHED* Job took $run_time seconds\n\n";
