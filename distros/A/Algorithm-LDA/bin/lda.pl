#!/usr/bin/perl
=head1 NAME

lda.pl - This program returns the topics of a document set.

=head1 SYNOPSIS

This is a utility that performs Latent Direchlet Allocation over a 
document set. 

=head1 USAGE

Usage: lda.pl DIR

=head1 INPUT

=head2 DIR 

The directory of text documents 

=head1 OPTIONS

Optional command line arguements

=head3 --help

Displays the quick summary of program options.

=head3 --version

Displays the version information.

=head1 SYSTEM REQUIREMENTS

=over

=item * Perl (version 5.8.5 or better) - http://www.perl.org

=back

=head1 CONTACT US
   
  If you have any trouble installing and using Algorithm-LDA, 
  please contact us via :
    
      Bridget T. McInnes: bthomson at vcu.edu

=head1 AUTHORS

 Nick Jordan, Virginia Commonwealth University 

 Bridget T. McInnes, Virginia Commonwealth University 

=head1 COPYRIGHT

Copyright (c) 2016

 Bridget T. McInnes, Virginia Commonwealth University 
 bthomson at vcu.edu

 Nick Jordan, Virginia Commonwealth University 

This program is free software; you can redistribute it and/or modify it under
the terms of the GNU General Public License as published by the Free Software
Foundation; either version 2 of the License, or (at your option) any later
version.

This program is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with
this program; if not, write to:

 The Free Software Foundation, Inc.,
 59 Temple Place - Suite 330,
 Boston, MA  02111-1307, USA.

=cut

###############################################################################

#                               THE CODE STARTS HERE
###############################################################################

#                           ================================
#                            COMMAND LINE OPTIONS AND USAGE
#                           ================================

use Getopt::Long;
use Algorithm::LDA;

eval(GetOptions( "version", "help", "topics=s", "stop=s", "iterations=s")) or die ("Please check the above mentioned option(s).\n");

#  if help is defined, print out help
if( defined $opt_help ) {    
    $opt_help = 1;
    &showHelp();
    exit;
}

#  if version is requested, show version
if( defined $opt_version ) {
    $opt_version = 1;
    &showVersion();
    exit;
}

# At least 2 terms should be given on the command line.
if( scalar(@ARGV) < 1 ) { 
    print STDERR "Please specify directory on command line\n"; 
    &minimalUsageNotes();
    exit;
}

# $dir - Directory Containing Text Files
my $dir = shift; 
opendir(DIR, $dir) || die "Could not open dir ($dir)\n";
my @files = grep { $_ ne '.' and $_ ne '..' } readdir DIR; close DIR;

# $totalDocs - Total Documents 
my $totalDocs = $#files; 

# $numTopics - Number of topics
my $numTopics = 10; 
if(defined $opt_topics) { 
    $numTopics = $opt_topics; 
}

# $stop - Stopword list (regex)
my $stop = shift; 
if(defined $opt_stop) { 
    $stop = $opt_stop; 
}

# TODO -- add as options
# $maxIterations - Maximum Iterations
# $updateCorpus - 1 = Force update documents, 0 = allow loading from JSON
# $wordThreshold - Minimum number of documents a word must appear in
# $alpha - Default Alpha value
# $numWords - Number of words per topic
my $maxIterations = 1000;
if(defined $opt_iterations) { 
    $maxIterations = $opt_iterations; 
}
my $updateCorpus = 0;
my $wordThreshold = 10;
my $alpha = 0.1;
my $numWords = 5;


my $test = new Algorithm::LDA($dir, $numTopics, $maxIterations, $totalDocs, $updateCorpus, $wordThreshold, $alpha, $numWords, $stop);

##############################################################################
#  function to output minimal usage notes
##############################################################################
sub minimalUsageNotes {
    
    print "Usage: lda.pl [OPTIONS] DIR\n";
    &askHelp();
    exit;
}

##############################################################################
#  function to output help messages for this program
##############################################################################
sub showHelp() {
        
    print "This is a utility that takes as directory of documents, performs LDA\n";
    print "and stores the results in the Results directory.\n\n";

    print "Usage: lda.pl [OPTIONS] DIR\n\n";

    print "General Options:\n\n";

    print "--version                Prints the version number\n\n";
    
    print "--help                   Prints this help message.\n\n";

    print "--stoplist FILE          A file containing a list of words to be excluded\n\n";
    
    print "--iterations NUM         Max number of iterations [Default: 1000]\n\n";

    print "--topics NUM             Number of topics [Default: 10]\n\n";

}

##############################################################################
#  function to output the version number
##############################################################################
sub showVersion {
    print '$Id: lda.pl,v 1.114 2016/07/12 20:18:30 btmcinnes Exp $';
    print "\nCopyright (c) 2017, Nick Jordan & Bridget McInnes\n";
}

##############################################################################
#  function to output "ask for help" message when user's goofed
##############################################################################
sub askHelp {
    print STDERR "Type lda.pl --help for help.\n";
}
    
