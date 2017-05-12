#!/usr/local/bin/perl
#
# Copyright (c) 2010 Giuseppe Gallone
#
# See COPYRIGHT section in walk.pm for usage and distribution rights.
#
# Example file to document typical usage of Bio::Homology::InterologWalk::Scores.
# This file uses Getopt::Long for simple management of command line arguments,
# and Term::AnsiColor for clearer console output.

#USAGE perl doScores.pl -tsvfile="yourfile.06out" -intactfile="yourfile.direct.02"

use strict;
use warnings;
use Getopt::Long;
use Term::ANSIColor;
use Bio::Homology::InterologWalk;
use Carp qw(croak);

my $start_run = time;

my $RC;
my $in_path;
my $out_path;
my $score_path;
my $m_mtaxa;

my $work_dir = '../Data/';
my $infilename; #actual dataset to evaluate
my $intactfile; #direct interactions obtained with getDirectInteractions.pl
my $psimi_ont; #psi mi obo ontology from HUPO. See http://www.psidev.info/index.php?q=node/277
GetOptions( 
            'tsvfile=s'     => \$infilename,
            'intactfile=s'  => \$intactfile,
            'ontology=s'    => \$psimi_ont
          );

#filenames and files===============================================
if( !$infilename ){
    print "\nUSAGE perl doScores.pl -tsvfile=\"<yourfile>.06out\" -intactfile=\"<yourfile>.direct.02\"\n";
    exit;
}
if(!$intactfile){
    print "\nUSAGE perl doScores.pl -tsvfile=\"<yourfile>.06out\" -intactfile=\"<yourfile>.direct.02\"\n";
    exit;
}

$in_path = $work_dir . $infilename;
$infilename =~ s/(.*)\..*/$1/;
my $intact_path = $work_dir . $intactfile;

if ( !$psimi_ont ) {
     $psimi_ont = 'psi-mi.obo';
     print "doScores.pl: no psi-mi obo ontology specified..Trying default: $psimi_ont\n";
}
my $ont_path   = $work_dir . $psimi_ont;

#output file (full datafile plus scores column)
my $out_filename = $infilename . $Bio::Homology::InterologWalk::OUTEX7;
$out_path = $work_dir . $out_filename;
#raw scores file (just for convenience)
my $score_filename = $infilename . $Bio::Homology::InterologWalk::OUTEX_SCORES;
$score_path = $work_dir . $score_filename;
#=================================================================



#==================================================================
#Computing Mean Multiple taxa score
#==================================================================
#WARNING: this might take a long time
$m_mtaxa = Bio::Homology::InterologWalk::Scores::compute_multiple_taxa_mean(
                                                            ds_size   => 15,          
                                                            #size: ideally it should be comparable to the dataset size
                                                            ds_number => 2,           
                                                            #max is currently 7, equal to the number of taxa with significant amount of data
                                                            datadir   => $work_dir
                                                            );
if ( !$m_mtaxa ) {
    print "There were errors. Stopping..\n";
    exit;
}

#create a Go:Parser graph to explore the ontology.
my $onto_graph = Bio::Homology::InterologWalk::Scores::parse_ontology($ont_path);
if ( !$onto_graph ) {
    print "There were errors. Stopping..\n";
    exit;
}

#3)#Process the direct interactions data file to retrieve the mean scores for
# interaction type, interaction detection method, experimental method and multiple detection method
#all of these can be obtained from a dataset of direct interactions (ie no orthology projections)
my ( $m_em, $m_it, $m_dm, $m_mdm ) =
  Bio::Homology::InterologWalk::Scores::get_mean_scores( $intact_path, $onto_graph );

#4) compute IPX
print colored ( "Computing putative interaction scores...", 'green' ), "\n";

my $RC_0 = Bio::Homology::InterologWalk::Scores::compute_prioritisation_index(
                                             input_path        => $in_path,
                                             score_path        => $score_path,
                                             output_path       => $out_path,
                                             term_graph        => $onto_graph,
                                             meanscore_em      => $m_em,
                                             meanscore_it      => $m_it,
                                             meanscore_dm      => $m_dm,
                                             meanscore_me_dm   => $m_mdm,
                                             meanscore_me_taxa => $m_mtaxa
);
if ( !$RC_0 ) {
    print "There were errors. Stopping..\n" ;
    exit;
}


$in_path = $out_path;
$out_filename = $infilename . $Bio::Homology::InterologWalk::OUTEX8;
$out_path = $work_dir . $out_filename;
$score_filename = $infilename . '.cons_hist';
$score_path = $work_dir . $score_filename;


#-------------------------------------------------
#EXPERIMENTAL - 
#for testing purposes only
#PLEASE REMOVE if performances severely affected,
#or set "max_nodes" to a smaller value
#-------------------------------------------------

#set up url
my $intact_url = "http://www.ebi.ac.uk/Tools/webservices/psicquic/intact/webservices/current/";
#5) compute Conservation Score, stored in separate column
print "\n\n";
print colored ( "Computing PPI conservation score...", 'green' ), "\n";
my $RC_1 = Bio::Homology::InterologWalk::Scores::compute_conservation_score(
                                             input_path        => $in_path,
                                             score_path        => $score_path,
                                             output_path       => $out_path,
                                             url               => $intact_url,
                                             max_nodes         => 25 
                                             #keep max_nodes to a reasonable number, 
                                             #depending on the power of your machine 
                                             #(eg. < 30 on a reasonably fast dual core workstation)
                                             );
if ( !$RC_1 ) {
    print "There were errors. Stopping..\n" ;
    exit;
}
#------------
#/EXPERIMENTAL
#------------

my $end_run  = time;
my $run_time = $end_run - $start_run;
print "\n\n*FINISHED* Job took $run_time seconds\n";
