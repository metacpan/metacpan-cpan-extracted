#!/usr/bin/perl
#
# Copyright (c) 2010 Giuseppe Gallone
#
# See COPYRIGHT section in walk.pm for usage and distribution rights.
#
# Example file that shows how to use the api to pull out real DB interactions from Intact (no interolog walk involved)
# or other PSICQUIC powered websites (under development). You will need this to generate a file of real intact interactions from your
# dataset IN CASE you need to obtain means, for scoring purposes. In such case, this script shall be called before doScores.pl

#USAGE perl getDirectInteractions.pl -filename='mmus_test.txt' -sourceorg='Mus musculus'

use strict;
use warnings;
use Getopt::Long;
use Term::ANSIColor;
use Bio::Homology::InterologWalk;
use Carp qw(croak);

my $in_path;
my $out_path;
my $start_path;
my $work_dir = '../Data/';

my $infilename;
my $sourceorg;
GetOptions('filename=s'=>\$infilename,
           'sourceorg=s'=>\$sourceorg);
#filenames and files===============================================
if(!$infilename){
     $infilename = 'mmus_test.txt';
     print "getDirectInteractions.pl: No filename specified..Trying default..$infilename\n";
}else{
     print "getDirectInteractions.pl: using input file: $infilename\n";
}
if(!$sourceorg){
     #$sourceorg = 'Drosophila melanogaster';
     #$sourceorg = 'Caenorhabditis elegans';
     $sourceorg = 'Mus musculus';
     print "getDirectInteractions.pl: no source organism specified..Using default: $sourceorg..\n";
}else{
     print "getDirectInteractions.pl: Using source organism: $sourceorg.\n";
}
print "\n=========================\n";

$in_path = $work_dir . $infilename;
$start_path = $in_path;
$infilename =~ s/(.*)\..*/$1/;

my $out_filename = $Bio::Homology::InterologWalk::VERSIONEX . $infilename . $Bio::Homology::InterologWalk::INTACTEX0;
$out_path = $work_dir . $out_filename;

my $ensembl_db = 'ensembl';
#get an ensembl connection.
my $registry = Bio::Homology::InterologWalk::setup_ensembl_adaptor(
                                                   connect_to_db   => $ensembl_db,
                                                   source_org      => $sourceorg,
                                                   verbose         => 1
                                                   );
if(!$registry){
    print "\nThere were problems setting up the connection to Ensembl. Aborting..\n";
    exit;
}

#set up url
my $url = "http://www.ebi.ac.uk/Tools/webservices/psicquic/intact/webservices/current/"; 
#get interactions                                                          
my $start_run = time();
print "\n\n", colored ("Getting Interactions from Intact...", 'green'), "\n\n";
my $RC1 = Bio::Homology::InterologWalk::get_direct_interactions(
                                              registry            => $registry,
                                              source_org          => $sourceorg,
                                              input_path          => $in_path,
                                              output_path         => $out_path,
                                              url                 => $url,
                                              check_ids           => 1,     
                                              #no_spoke            => 1,
                                              exp_only            => 1,
                                              physical_only       => 1,
                                              #chimeric            => 1
                                              );                                                          
if(!$RC1){
     print "There were errors. Stopping..\n";
     exit;
}
my $end_run = time();
my $run_time = $end_run - $start_run;                                 
print "*FINISHED* Job took $run_time seconds";


$in_path = $out_path;
$out_filename = $Bio::Homology::InterologWalk::VERSIONEX . $infilename. $Bio::Homology::InterologWalk::INTACTEX1;
$out_path = $work_dir . $out_filename;


print "\n\n", colored ("Getting rid of duplicate rows if any...", 'green'), "\n\n";
my $RC2 = Bio::Homology::InterologWalk::remove_duplicate_rows(
                                          input_path    => $in_path,
                                          output_path   => $out_path,
                                          header        => 'direct',        
                                          );
if(!$RC2){
     print "There were errors. Stopping..\n";
     exit;
}                                                                                                                            

$in_path = $out_path;

$out_filename = $Bio::Homology::InterologWalk::VERSIONEX . $infilename. $Bio::Homology::InterologWalk::INTACTEX2;
$out_path = $work_dir . $out_filename;

# do counts and add a further  column with a "multiple taxa" indicator
print "\n\n", colored ("Gathering counts for score purposes...", 'green'), "\n\n";
my $RC3 = Bio::Homology::InterologWalk::do_counts(
                              input_path    => $in_path,
                              output_path   => $out_path,
                              header        => 'direct',
                              );
if(!$RC3){
     print "There were errors. Stopping..\n";
     exit;
}


$in_path = $out_path;
$out_filename = $Bio::Homology::InterologWalk::VERSIONEX . $infilename. $Bio::Homology::InterologWalk::OUTEX_NEW_DIR;
$out_path = $work_dir . $out_filename;

#let's create a file containing all the new ids discovered (ids not present in the starting set)
print "\n\n", colored ("Counting the number of new ids we got...", 'green'), "\n\n";
my $RC4 = Bio::Homology::InterologWalk::extract_unseen_ids(
                                       start_path  => $start_path,
                                       input_path  => $in_path,
                                       output_path => $out_path,
                                       );                                                                         
if(!$RC4){
     print "There were errors. Stopping..\n";
     exit;
}

$registry->clear();                                                                                                             
print "\n\n", colored ("**FINISHED**", 'green'), "\n\n";        
