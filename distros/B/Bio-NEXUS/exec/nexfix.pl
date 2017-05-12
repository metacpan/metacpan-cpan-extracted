#!/usr/bin/perl -w

################################################################################
# Title: #######################################################################
#                                  nexfix.pl                                   #
################################################################################
# Author: ######################################################################
#                                 Tom Hladish                                  #
################################################################################
# Description: #################################################################
#                                                                              #
# This program takes a list of NEXUS files and checks for specific violations  #
# of the NEXUS standard without using the NEXPL API.  Any files that fail this #
# compliancy check are modified accordingly.  All files are then validated by  #
# reading them in as NEXPL objects and writing them back out again.            #
#                                                                              #
# Currently, nexfix.pl checks for the following compliancy failures:           #
#                                                                              #
# > Character labels (charlabels) for introns that are written in              #
#   "codon-phase" notation must be single-quoted, as they contain a NEXUS      #
#   punctuation mark (the hyphen).  Files produced by our lab before 08/30/05  #
#   that contain intron information most likely have this problem in a         #
#   Characters Block and in the History Block, if one exists.                  #
#                                                                              #
# > OTU names that contain NEXUS punctuation (i.e., (){}/\,;:=*'"`+-<>) need   #
#   to be single-quoted.  Some taxa in our files are hyphenated.  nexfix       #
#   currently checks the following commands for OTU names: TAXLABELS, MATRIX,  #
#   TAXSET.  It does not check the ADD command in the Span Block.              #
#                                                                              #
################################################################################
# Usage: #######################################################################
#                                                                              #
# nexfix.pl [-ckP] filename [filenames]                                        #
#                                                                              #
#   -c   : clobber the old files with the new ones (don't rename the old ones) #
#   -k   : keep the old files intact, renaming the new ones (default is to     #
#          rename the old ones, and write the new files using the old name)    #
#   -P   : do not move non-compliant files to a /problematic/ directory--leave #
#          them where they are                                                 #
#   -v   : send error messages to screen instead of error.log file             #
#                                                                              #
################################################################################

my $RCSId = '$Id: nexfix.pl,v 1.11 2007/02/01 04:52:09 vivek Exp $';
my $shortname = join (" v", $RCSId =~ m/(\w+.?\w+,)v (\d+\.\d+)/);

use strict;
use Data::Dumper;
use Bio::NEXUS;
use File::Copy;
use File::Path;
use Getopt::Std;

# read in the command-line options, if any; see Usage above for details
my %flags;
getopts('ckPv', \%flags) or die "ERROR: Unknown options\n";

# get list of NEXUS files to process
my @paths = @ARGV;

my $punctuation_pattern = '[\(\)\{\}\/\\,;:=\*\'"`\+\-<>]';


# loop through them
for my $path (@paths) {

    # verify that $path is a file
    unless (-e $path) {warn "'$path' is not a valid filename: skipping\n"; next };
    
    print "Processing: <$path>\n";
    
    # split the path into directory and filename components
    my ($directory, $filename) = $path =~ /(.*?)([^\/]+)$/;

    unless ($flags{v}) { 
        open(STDERR, ">> ./$directory/error.log") || die "Couldn't open error log in $directory\n";
    }
    
    # get the time stamp, so it can be reported later
    my $time = localtime time;
    
#    print STDERR "$shortname run on $time\n";
    
    # slurp in the entire NEXUS file
    my $nexus_text = do {local(@ARGV, $/) = $path; <>};
    
    # move the old file to filename.old unless the user has specified 
    # overwriting (-c) or keeping the original file intact (-k)
    move($path, "$path.old") unless ($flags{c} || $flags{k});
    
    # use an alternate filename for the new file if the user specifies keeping the original file
    if ($flags{k}) {$path = "$path.new";}
    
    # split the file into its commands (and their arguments)
    my @commands = split(/;/, $nexus_text);
    # loop through them
    my $within_history_block = 0;
    for my $command (@commands) {
        # remove previous comments that this program inserted
        $command =~ s/\[This file was checked by nexfix\.pl, v\d+\.\d+ on \w+ \w+\s+\d{1,2}\s+\d{1,2}:\d{2}:\d{2} \d{4}\]\n//;
        # if it's the beginning of the file, insert a comment documenting this processing
        $command =~ s/(#NEXUS)/$1\n\[This file was checked by $shortname on $time\]/;

    $within_history_block = 0 if ($within_history_block and $command =~/(end|endblock)/i);

        # match command, capture the arguments
        if ($command =~ /^\s*charlabels\s+(.+?)\s*$/si) {
            $command = &charlabels($1);
        } elsif ($command =~ /^\s*taxlabels\s+(.+?)\s*$/si) {
            $command = &taxlabels($1);
        } elsif ($command =~ /^\s*matrix\s+(.+?)\s*$/si) {
        $command = &matrix($1); 
        $command =  &history_matrix($command) if ($within_history_block); 
        $command = "\n\tMATRIX\n" . $command; 
        } elsif ($command =~ /^\s*taxset\s+(.+?)\s+=(.+?)\s*$/si) {
            $command = "TAXSET $1 = " . &taxset($2) . "\n";
    } elsif ($command =~ /^\s*tree\s+(.+?)\s+=(.+?)\s*$/si) {
        $command = "\nTREE $1 = " . &tree($2) . "\n";
    } elsif ($command =~ /\s*Begin\s+History/si) {
        $within_history_block = 1;
    } elsif ($command =~ /\s*format /si and $within_history_block) {
        $command .= " statesformat=frequency" if $command !~ /statesformat/;
        } #!!!!!! TO ADD MORE ERROR-CHECKING FUNCTUNALITY, PUT AN ELSIF HERE !!!!!!

    }
    # join the commands back together
    $nexus_text = join(";", @commands);
    # open a FH, write out the altered text
    open( my $fh, ">$path" ) || die "Can't create $path $!" ;
    print $fh $nexus_text;
    close $fh;
    
    # to make sure that the new file is a well-formed NEXUS file, read it in and
    # write it back out with NEXPL.  This is done using a system call so that
    # die commands within NEXPL do not kill this process.

    if ((my $retval = system("perl -MBio::NEXUS -e 'new Bio::NEXUS(\"$path\")->write(\"$path\")'")) == 0) {
        # system command finished properly
        warn "File: <$path> has been validated and written.\n";
    } elsif ( $retval == 2 ) {
        # if the system call returned a value of 2, it's because the process was 
        # interrupted by a SIGINT (such as Ctrl-C)
        warn "Processing of File: <$path> interrupted; file written but not validated\n";
        print "\n$shortname interrupted by SIGINT\n" unless $flags{v};
        die "$shortname interrupted by SIGINT\n";
    } else {
        # print "retval = $retval\n";
        # system command failed, presumably because NEXPL could not read the 
        # file, and the offending files will be moved to ./problematic/
        if ($flags{P}) {
            print "File: <$path> is not NEXPL-compatible\n" unless $flags{v};
            warn "File: <$path> is not NEXPL-compatible\n";
        } else {
            my $problem_dir = "$directory./problematic/";
            mkpath ($problem_dir);
            move ($path, "$problem_dir/$filename.new") if $path =~ /\.new$/;
            move ("$path.old", "$problem_dir/$filename.old") if -e "$path.old";
            move ("./$directory/$filename", "$problem_dir/$filename");
            print "File: <$path> is not NEXPL-compatible and has been moved with original file to ./problematic/\n" unless $flags{v};
            warn "File: <$path> is not NEXPL-compatible and has been moved with original file to ./problematic/\n";
        }
    }
    
    close STDERR unless $flags{v};
}

sub charlabels {
    my ($charlabels) = @_;
    # split the arguments on spaces
    my @charlabels = @{ &parse_tokens($charlabels) };
    # loop through them
CHARLABEL:  for my $charlabel (@charlabels) {
        if ($charlabel =~ /^'.*?'$/) {next CHARLABEL;}
        # put single quotes around them, if they contain hyphens.  In particular,
        # we are expecting charlabels in the condonHYPHENphase form
        $charlabel = "'$charlabel'" if ($charlabel =~ /-/);
    }
    # join them all back together, delimited by spaces
    return "\n\tCHARLABELS\n\t@charlabels";
}

sub taxlabels {
    my ($taxa) = @_;
    my @taxa = @{ &parse_tokens($taxa) };
TAXON:  for my $taxon (@taxa) {
        if ($taxon =~ /^'.*?'$/) {next TAXON;}
        # put single quotes around them, if they contain NEXUS punctuation.
        $taxon = "'$taxon'" if ($taxon =~ /$punctuation_pattern/);
    }
    return "\n\tTAXLABELS @taxa";
}

sub matrix {
    my ($matrix) = @_;
    my @rows = split /\n\t?/, $matrix;
ROW:    for my $row (@rows) {
        my ($taxon, $seq) = $row =~ /\s*('.+'|\S+)\s*(.*?)\s*$/;
        if ($taxon =~ /^'.*?'$/) { $row .="\n"; next ROW;}
        $taxon = "'$taxon'" if ($taxon =~ /$punctuation_pattern/);
        $row = "$taxon  $seq\n";
    }
    return "@rows";
}

sub history_matrix{
    my ($matrix) = @_;
    my @rows = split /\n\t?/, $matrix;
    my ($state0, $state1);
ROW:    for my $row (@rows) {
    my ($taxon, $seq) = $row =~ /\s*('.+'|\S+)\s*(.*?)\s*$/;
    my @seq;

    if ($seq !~ /\(/) {
        @seq = split //,$seq;
        foreach my $char(@seq) {
            $state0 = ($char eq '1') ? 0 : 1;
            $state1 = ($char eq '1') ? 1 : 0;
            $char = "(1:$state1 0:$state0)"; 
        }
    } else {
        @seq = split /[()]/,$seq;
        foreach my $char(@seq) {
            next if $char =~ /^\s*$/; 
            next if $char =~ /:/; 
            my @states = split/\s+/, $char;
            $state0 = $states[0]; 
            $state1 = $states[1];
            $char = "(1:$state1 0:$state0)"; 
        }
    }
    $seq = join('',@seq);
    $row = "$taxon  $seq\n";
}
return "@rows";
}

sub tree {
    my ($tree) = @_;
    # print "$tree\n"; # for debugging
    my @rows = split /[(,:)]/, $tree;
    ROW:    for my $row (@rows) {
        next if $row eq '';
        #       my ($taxon, $seq) = $row =~ /\s*('.+'|\S+)\s*(.*?)\s*$/;
        if ($row=~ /^'.*?'$/) {next ROW;}

        ## Floating point/scientific notation - Reference : http://www.regular-expressions.info/floatingpoint.html
        if ($row =~ /^[-+]?[0-9]*\.?[0-9]+([eE][-+]?[0-9]+)?/) { 
            #print "xx $row\n"; # Debugging
            next ROW;
        }; 

        $tree =~s/$row/'$row'/g if ($row =~ /$punctuation_pattern/);
        #print "$row\n"; # for debugging 
    }
    return "$tree";
}

sub taxset {
    my ($elements) = @_;
    my @elements = @{ &parse_tokens($elements) };
ELEMENT:    for my $element (@elements) {
        if ($element =~ /^'.*?'$/) {next ELEMENT;}
        # put single quotes around them, if they contain NEXUS punctuation.
        $element = "'$element'" if ($element =~ /$punctuation_pattern/);
    }
    return "@elements";
}

sub parse_tokens {
    my ($string) = @_;
    my @tokens;
    my $token = '';
    # split the string on whitespace
    foreach my $chunk ( split (/\s+/, $string) ) {
        # true if chunk is single-quoted
        if ($chunk =~ /^'.*?'$/) {
            # push it onto the array and move on to the next chunk
            push @tokens, $chunk;
        # true if a single quote is found at the beginning of the chunk
        } elsif ($chunk =~ /^'/) {
            # set the token equal to this first chunk of the token
            $token = $chunk;
        # true if the last chunk of a quoted token has been found
        } elsif ($token && $chunk =~ /'$/) {
            # concatenate it with a space
            $token .= " $chunk";
            push @tokens, $token;
            $token = '';
        # if there aren't any quotes at the beginning or end
        }else {
            # either it is an unquoted string without whitespace
            if ($token eq '') {
                push @tokens, $chunk;
            # or it is a chunk in the middle of a quoted token
            }else {
                $token .= " $chunk";
            }
        }
    }
    # send them back whence they came
    return \@tokens;
}

