#!/usr/bin/perl
#
# Copyright (c) 2010 Giuseppe Gallone
#
# See COPYRIGHT section in walk.pm for usage and distribution rights.
#
# Example file to document typical usage of the Bio::Homology::InterologWalk
# package. This file uses Getopt::Long for simple management of command line arguments,
# and Term::AnsiColor for clearer console output.

#USAGE perl doInterologWalk.pl -filename="mmus_test.txt" -sourceorg="Mus musculus" -destorg="all"

use strict;
use warnings;
use Getopt::Long;
use Term::ANSIColor;
use Bio::Homology::InterologWalk;
use Carp qw(croak);

my $in_path;
my $out_path;
my $err_path;
my $work_dir = '../Data/';

my $start_run;
my $end_run;
my $run_time;

my $infilename;
my $sourceorg;
my $destorg;
my $onetoone;
GetOptions(
           'filename=s'  =>\$infilename,
           'sourceorg=s' =>\$sourceorg,
           'destorg=s'   =>\$destorg,
           'onetoone!'   =>\$onetoone
          );

#filenames and files===============================================
if(!$infilename){
     $infilename = 'mmus_test.txt';
     print "doInterologyWalk.pl: no filename specified..Trying default..$infilename\n";
}else{
     print "Using input file: $infilename\n";
}
if(!$sourceorg){
     $sourceorg = 'Mus musculus';
     #$sourceorg = 'Caenorhabditis elegans';
     print "doInterologyWalk.pl: no source organism specified..Using default: $sourceorg..\n";
}else{
     print "doInterologyWalk.pl: Using source organism: $sourceorg.\n";
}
if(!$destorg){
     $destorg = 'all';
     #$destorg = 'Drosophila melanogaster';
     print "doInterologyWalk.pl: no destination organism specified..Using default: $destorg..\n";
}else{
     print "doInterologyWalk.pl: Using destination organism(s): $destorg.\n";
}

if($onetoone){
   print "doInterologyWalk.pl: only considering one-to-one orthology relationships..\n";
}else{
   print "doInterologyWalk.pl: No orthology type specified..Using default: all orthologies..\n";
}

print "\n=========================\n";


$in_path = $work_dir . $infilename;
my $start_data_path = $in_path; #I need this later, when computing counts
$infilename =~ s/(.*)\..*/$1/;
my $out_filename = $Bio::Homology::InterologWalk::VERSIONEX . $infilename . $Bio::Homology::InterologWalk::OUTEX2;
$out_path = $work_dir . $out_filename;

#Ensembl dbs to connect to. Options: 
#a) ensembl: vertebrate compara
#b) pan_homology: pan homology db
#c) metazoa: ensemblgenomes metazoan db.
#d) all: ensembl vertebrates + ensemblgenomes metazoa
my $ensembl_db = 'ensembl';

#1) set up the Ensembl compara connection
my $registry = Bio::Homology::InterologWalk::setup_ensembl_adaptor(
                                                   connect_to_db    => $ensembl_db,
                                                   source_org       => $sourceorg,
                                                   dest_org         => $destorg,
                                                   #verbose         => 1
                                                   );
if(!$registry){
    print "\nThere were problems setting up the connection to Ensembl. Aborting..\n";
    exit;
}

# 2) get forward orthologies.
if($ensembl_db eq "all"){
     print  colored ("\nRetrieving source organism orthologs from Ensembl Compara (All databases)...\n", 'green');
}else{
     print  colored ("\nRetrieving source organism orthologs from Ensembl Compara ($ensembl_db database)...\n", 'green');
}
$start_run = time;
my $RC1 = Bio::Homology::InterologWalk::get_forward_orthologies(
                                                registry      => $registry,
                                                ensembl_db    => $ensembl_db,
                                                input_path    => $in_path,
                                                output_path   => $out_path,
                                                source_org    => $sourceorg,
                                                dest_org      => $destorg,
                                                hq_only       => $onetoone
                                                );
if(!$RC1){
     print "There were errors. Stopping..\n";
     exit;
}
$end_run = time;
$run_time = $end_run - $start_run;                                 
print "*FINISHED* Job took $run_time seconds";

#reset the registry (get another identical one later)
$registry->clear();

#reset file paths. Former output is new input
$in_path = $out_path;
$out_filename = $Bio::Homology::InterologWalk::VERSIONEX . $infilename. $Bio::Homology::InterologWalk::OUTEX3; 
$out_path = $work_dir . $out_filename;

#set up url
my $url = "http://www.ebi.ac.uk/Tools/webservices/psicquic/intact/webservices/current/";

#3) get interactions from intact or other services.
print "\n\n", colored ("Retrieving Interactions from Intact...", 'green'), "\n\n";
$start_run = time;
my $RC2 = Bio::Homology::InterologWalk::get_interactions(
                                         input_path       => $in_path,
                                         output_path      => $out_path,
                                         url              => $url,
                                         no_spoke         => 1, 
                                         exp_only         => 1, 
                                         physical_only    => 1, 
                                         );
if(!$RC2){
     print "There were errors. Stopping..\n";
     exit;
}
$end_run = time;
$run_time = $end_run - $start_run;                               
print "*FINISHED* Job took $run_time seconds";

$in_path = $out_path;
$out_filename = $Bio::Homology::InterologWalk::VERSIONEX . $infilename. $Bio::Homology::InterologWalk::OUTEX4; 
#we can also get an error dump:
my $err_filename = $Bio::Homology::InterologWalk::VERSIONEX . $infilename. $Bio::Homology::InterologWalk::ERREX;
$out_path = $work_dir . $out_filename;
$err_path = $work_dir . $err_filename;

#4) get the same registry 
$registry = Bio::Homology::InterologWalk::setup_ensembl_adaptor(
                                                   connect_to_db   => $ensembl_db,
                                                   source_org      => $sourceorg,
                                                   dest_org        => $destorg,
                                                   );
if(!$registry){
    print "\nThere were problems setting up the connection to Ensembl. Aborting..\n";
    exit;
}
# 5) get backward orthologies.
print "\n\n", colored ("Retrieving orthologs back in source organism from Ensembl Compara ($ensembl_db database)...", 'green'), "\n\n";
$start_run = time;
my $RC3 = Bio::Homology::InterologWalk::get_backward_orthologies(
                                                 registry       => $registry,
                                                 ensembl_db     => $ensembl_db,
                                                 input_path     => $in_path,
                                                 output_path    => $out_path,
                                                 error_path     => $err_path,
                                                 source_org     => $sourceorg, 
                                                 hq_only        => $onetoone,
                                                 #check_ids      => 1,
                                                 );
if(!$RC3){
     print "There were errors. Stopping..\n";
     exit;
}
$end_run = time;
$run_time = $end_run - $start_run;                               
print "*FINISHED* Job took $run_time seconds";
$registry->clear(); 

$in_path = $out_path;
$out_filename = $Bio::Homology::InterologWalk::VERSIONEX . $infilename. $Bio::Homology::InterologWalk::OUTEX5;
$out_path = $work_dir . $out_filename;


# 6) Intact sometimes returns duplicate rows. This method will remove them
print "\n\n", colored ("Getting rid of duplicate rows if any...", 'green'), "\n\n";
my $RC4 = Bio::Homology::InterologWalk::remove_duplicate_rows(
                                              input_path   => $in_path,
                                              output_path  => $out_path,
                                              header       => 'standard', #header for the orthology walk algorithm. standard intact ppi process has different header
                                              );                                                                                                                         
if(!$RC4){
     print "There were errors. Stopping..\n";
     exit;
}
$in_path = $out_path;
$out_filename = $Bio::Homology::InterologWalk::VERSIONEX . $infilename. $Bio::Homology::InterologWalk::OUTEX6;
$out_path = $work_dir . $out_filename;

# 7) do counts and add further columns with indicators useful for scoring the data
print "\n\n", colored ("Gathering counts for score purposes...", 'green'), "\n\n";
my $RC5 = Bio::Homology::InterologWalk::do_counts(
                                  input_path  => $in_path,
                                  output_path => $out_path,
                                  header      => 'standard',
                                  );                                           

if(!$RC5){
     print "There were errors. Stopping..\n";
     exit;
}
$in_path = $out_path;
$out_filename = $Bio::Homology::InterologWalk::VERSIONEX . $infilename. $Bio::Homology::InterologWalk::OUTEX_NEW;
$out_path = $work_dir . $out_filename;


# 8) create a file containing all the new ids discovered (ids not present in the starting set)
print "\n\n", colored ("Counting the number of new ids we got...", 'green'), "\n\n";
my $RC6 = Bio::Homology::InterologWalk::extract_unseen_ids(
                                           start_path     => $start_data_path,
                                           input_path     => $in_path,
                                           output_path    => $out_path,
                                           hq_only        => $onetoone,
                                           );
if(!$RC6){
     print "There were errors. Stopping..\n";
     exit;
}    
                                                                                                           
print "\n\n", colored ("**FINISHED**", 'green'), "\n\n";                                                                          
