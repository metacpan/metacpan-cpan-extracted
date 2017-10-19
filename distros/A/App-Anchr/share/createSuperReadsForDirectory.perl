#!/usr/bin/env perl
use strict;
use warnings;

use File::Basename;
use Cwd;

# This exec takes a (set of) input read files (in fasta format) and a
# file of input k-unitigs (specified with the switch -kunitigsfile) and outputs
# the set of super-reads for these reads (in fasta format).
#
# The args are the input fasta files as well as (optionally) the directory
# where you want the work to occur. If the directory is not specified, the
# work is done in the current directory.
# If the work directory doesn't exist then it is created.
#
# The flags are as follows:
# -l merLen : the length of the k-mer to use for the calculations (31)
# -t numProcessors : the number of processors to run jellyfish and create_k_unitigs (16)
# -kunitigsfile filename : a user-given k-unitigs file; otherwise we calculate
# -mean-and-stdev-by-prefix-file filename : a file giving mate info about each
#                      library. Each line is the 2-letter prefix for the reads
#                      in the library followed by its mean and stdev. This
#                      file is mandatory unless -jumplibraryreads is specified
# -num-stdevs-allowed maxStdevsAllowedForJoining : max stdevs allowed for joinKUnitigs (5)
# -mkudisr numBaseDiffs : max base diffs between overlapping k-unitigs in super-reads (0)
# -minreadsinsuperread minReads : super-reads containing fewer than numReads
#                                reads will be eliminated (2)
# --stopAfter target : Stop the run after one of the following "target" names:
#               createLengthStatisticsFiles
#               createKUnitigHashTable
#               addMissingMates
#               findReadKUnitigMatches
#               createLengthStatisticsForMergedKUnitigsFiles
#               createKUnitigMaxOverlaps
#               joinKUnitigs
#               getSuperReadInsertCounts
#               createFastaSuperReadSequences
#               reduceSuperReads
#               createFinalReadPlacementFile
#               createFinalSuperReadFastaSequences
# -keep-kunitigs-in-superread-names : Use the super-read names which have the
#                 k-unitig numbers in them; otherwise use numeric names
#                 (lower numbers correspond to shorter super-reads)
# -h : help

# SuperRead pipeline
# Copyright (C) 2012  Genome group at University of Maryland.
#
# This program is free software: you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation, either version 3 of the
# License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

my $cwd    = cwd;

my $maxNodes = 2000;

my $merLen              = 81;
my $numProcessors       = 16;
my $minReadsInSuperRead = 2;
my $seqDiffMax          = 0;
my $numStdevsAllowed    = 5;

my $keepKUnitigsInSuperreadNames = 1;

my $merLenMinus1      = $merLen - 1;
my $maxHashFillFactor = .8;

my $workingDirectory = $ARGV[0];
my $successFile      = "$workingDirectory/superReads.success";
unlink($successFile) if ( -e $successFile );

# The following is set to 1 when the first success file for a step is missing
my $mustRun = 0;

if ( !-d $workingDirectory ) {
    my $cmd = "mkdir $workingDirectory";
    print "$cmd\n";
    system($cmd);
}

# We now require that a k-unitigs file was passed on the command line
my $kUnitigsFile = $ARGV[1];
$kUnitigsFile = returnAbsolutePath($kUnitigsFile);
my $kUnitigLengthsFile = "$workingDirectory/kUnitigLengths.txt";

# The following stores the actual number of k-unitigs
my $numKUnitigsFile = "$workingDirectory/numKUnitigs.txt";

# The following stores the largest k-unitig number (+1)
my $maxKUnitigNumberFile = "$workingDirectory/maxKUnitigNumber.txt";

my $cor_fa_fn                = $ARGV[2];
my $meanAndStdevByPrefixFile = $ARGV[3];

my $prefixForOverlapsBetweenKUnitigs = "$workingDirectory/overlap";
my $kUnitigOverlapsFile              = "${prefixForOverlapsBetweenKUnitigs}.overlaps";
my $superReadCountsFile              = "$workingDirectory/superReadCounts.all";

my $joinerOutput = "$workingDirectory/readPositionsInSuperReads";

my $sequenceCreationErrorFile = "$workingDirectory/createFastaSuperReadSequences.errors.txt";

my $finalSuperReadSequenceFile = "$workingDirectory/superReadSequences.fasta";
my $finalReadPlacementFile
    = "$workingDirectory/readPlacementsInSuperReads.final.read.superRead.offset.ori.txt";

# In addition to obvious output file, this also generates the files
# numKUnitigs.txt, maxKUnitigNumber.txt, and totBasesInKUnitigs.txt in
# $workingDirectory
my $cmd
    = "faops size $kUnitigsFile > $kUnitigLengthsFile; "
    . "wc -l $kUnitigLengthsFile | awk '{print \$1}' > $numKUnitigsFile; "
    . "tail -n 1 $kUnitigLengthsFile | awk '{print \$1+1}' > $maxKUnitigNumberFile";
&runCommandAndExitIfBad( $cmd, $kUnitigLengthsFile, 1, "createLengthStatisticsFiles",
    $numKUnitigsFile, $maxKUnitigNumberFile, $kUnitigLengthsFile );

my $minSizeNeededForTable = 0;
open( FILE, $kUnitigLengthsFile );
while ( my $line = <FILE> ) {
    chomp($line);
    my ( undef, $ks ) = split( /\s+/, $line );
    $minSizeNeededForTable += ( $ks - $merLenMinus1 );
}
$minSizeNeededForTable = int( $minSizeNeededForTable / $maxHashFillFactor );

open( FILE, $maxKUnitigNumberFile );
my $maxKUnitigNumber = <FILE>;
chomp($maxKUnitigNumber);
close(FILE);

my $normalFileSizeMinimum = 1;

#
# joinKUnitigs
#
$cmd
    = "createKUnitigMaxOverlaps $kUnitigsFile "
    . "-kmervalue $merLen -largest-kunitig-number "
    . ( int($maxKUnitigNumber) + 1 )
    . " $prefixForOverlapsBetweenKUnitigs";
&runCommandAndExitIfBad( $cmd, $kUnitigOverlapsFile, 0, "createKUnitigMaxOverlaps",
    $kUnitigOverlapsFile, "$workingDirectory/overlap.coords" );

# Find the matches of k-unitigs to reads and pipe to the shooting method
$cmd
    = "findMatchesBetweenKUnitigsAndReads "
    . " -m $merLen -t $numProcessors -o /dev/fd/1 "
    . "$kUnitigsFile $maxKUnitigNumberFile $minSizeNeededForTable $cor_fa_fn "
    . " | joinKUnitigs_v3"
    . " --max-nodes-allowed $maxNodes --mean-and-stdev-by-prefix-file $meanAndStdevByPrefixFile"
    . " --num-stdevs-allowed $numStdevsAllowed --unitig-lengths-file $kUnitigLengthsFile "
    . " --num-kunitigs-file $maxKUnitigNumberFile --overlaps-file $kUnitigOverlapsFile"
    . " --min-overlap-length $merLenMinus1 -o $joinerOutput"
    . " -t $numProcessors /dev/fd/0";
&runCommandAndExitIfBad( $cmd, $joinerOutput, $normalFileSizeMinimum, "joinKUnitigs",
    $joinerOutput );

my $tempSize = -s $joinerOutput;
if ( $tempSize == 0 ) {
    $cmd = "touch $superReadCountsFile";
    print "$cmd\n";
    system($cmd);
}
else {
    my $minFileSizeToPass;
    if ( $minReadsInSuperRead > 1 ) {
        $minFileSizeToPass = 0;
        $cmd
            = "getSuperReadInsertCountsFromReadPlacementFileTwoPasses -n `cat $numKUnitigsFile "
            . " | perl -ane '{print \$F[0]*20}'` -o $superReadCountsFile $joinerOutput";
    }
    else {
        $minFileSizeToPass = $normalFileSizeMinimum;
        $cmd
            = "getSuperReadInsertCountsFromReadPlacementFile -n `cat $numKUnitigsFile "
            . "| perl -ane '{print \$F[0]*20}'` -o $superReadCountsFile -i $joinerOutput";
    }
    &runCommandAndExitIfBad( $cmd, $superReadCountsFile, $minFileSizeToPass,
        "getSuperReadInsertCounts", $superReadCountsFile );
}

my $goodSuperReadsNamesFile  = "$workingDirectory/superReadNames.txt";
my $fastaSuperReadErrorsFile = "$workingDirectory/createFastaSuperReadSequences.errors.txt";

#
# reduce SR
#
my $localGoodSequenceOutputFile = "${finalSuperReadSequenceFile}.all";
my $superReadNameAndLengthsFile = "$workingDirectory/sr_sizes.tmp";
my $reduceFile                  = "$workingDirectory/reduce.tmp";
my $reduceFileTranslated        = "$workingDirectory/reduce.tmp.renamed";
my $tflag                       = "-rename-super-reads";
if ($keepKUnitigsInSuperreadNames) {
    $tflag = "";
}
$cmd
    = "cat $superReadCountsFile "
    . "| createFastaSuperReadSequences $workingDirectory /dev/fd/0 "
    . "-seqdiffmax $seqDiffMax -min-ovl-len $merLenMinus1 -minreadsinsuperread $minReadsInSuperRead "
    . " -good-sr-filename $goodSuperReadsNamesFile "
    . "-kunitigsfile $kUnitigsFile -good-sequence-output-file $localGoodSequenceOutputFile "
    . "-super-read-name-and-lengths-file $superReadNameAndLengthsFile $tflag 2> $sequenceCreationErrorFile";
&runCommandAndExitIfBad( $cmd, $superReadNameAndLengthsFile, $normalFileSizeMinimum,
    "createFastaSuperReadSequences",
    $localGoodSequenceOutputFile, $goodSuperReadsNamesFile, $superReadNameAndLengthsFile );

$cmd
    = "reduce_sr $maxKUnitigNumber $kUnitigLengthsFile $merLen $superReadNameAndLengthsFile -o $reduceFile";
&runCommandAndExitIfBad( $cmd, $reduceFile, $normalFileSizeMinimum, "reduceSuperReads",
    $reduceFile, $fastaSuperReadErrorsFile );

if ( !$keepKUnitigsInSuperreadNames ) {
    $cmd
        = "translateReduceFile.perl $goodSuperReadsNamesFile $workingDirectory/reduce.tmp > $reduceFileTranslated";
    &runCommandAndExitIfBad( $cmd, $reduceFileTranslated, $normalFileSizeMinimum,
        "translateReduceFile", $reduceFileTranslated );
}

$tflag = "--translate-super-read-names";
if ($keepKUnitigsInSuperreadNames) {
    $reduceFileTranslated = $reduceFile;
    $tflag                = "";
}
$cmd
    = "eliminateBadSuperReadsUsingList --read-placement-file $joinerOutput --good-super-reads-file $goodSuperReadsNamesFile $tflag --reduce-file $reduceFileTranslated > $finalReadPlacementFile";
&runCommandAndExitIfBad( $cmd, $finalReadPlacementFile, $normalFileSizeMinimum,
    "createFinalReadPlacementFile",
    $finalReadPlacementFile );

$cmd
    = "outputRecordsNotOnList $reduceFileTranslated $localGoodSequenceOutputFile 0 --fld-num 0 > $finalSuperReadSequenceFile";
&runCommandAndExitIfBad( $cmd, $finalSuperReadSequenceFile, $normalFileSizeMinimum,
    "createFinalSuperReadFastaSequences",
    $finalSuperReadSequenceFile );

$cmd = "touch $successFile";
system($cmd);

exit(0);

# If localCmd is set, it captures the return code and makes
# sure it ran properly. Otherwise it exits.
# If one sets the fileName then we assume it must exist
# With minSize one can set the minimum output file size
sub runCommandAndExitIfBad {
    my ( $localCmd, $fileName, $minSize, $stepName, @filesCreated ) = @_;
    my ( $retCode, $exitValue,    $sz );
    my ( $totSize, $tempFilename, $local_cmd );
    my ( $success_fn, $failDir );

    #    sleep (5); # For testing only
    $failDir = $workingDirectory . "/" . $stepName . ".Failed";
    if ( -e $failDir ) {
        $local_cmd = "rm -rf $failDir";
        print "$local_cmd\n";
        system($local_cmd);
    }
    $success_fn = $workingDirectory . "/" . $stepName . ".success";
    if ( -e $success_fn ) {
        if ($mustRun) {
            unlink($success_fn);
        }
        else {
            print STDERR "Step $stepName already completed. Continuing.\n";
            goto successfulRun;
        }
    }
    else {
        $mustRun = 1;
    }

    if ( $localCmd =~ /\S/ ) {
        print "$localCmd\n";
        system($localCmd);
        $retCode = $?;
        if ( $retCode == -1 ) {
            print STDERR "failed to execute: $!\n";
            goto failingRun;
        }
        elsif ( $retCode & 127 ) {
            printf STDERR "child died with signal %d, %s coredump\n",
                ( $retCode & 127 ), ( $retCode & 128 ) ? 'with' : 'without';
            goto failingRun;
        }
        else {
            $exitValue = $retCode >> 8;
            if ( $exitValue == 255 ) { $exitValue = -1; }
            if ( $exitValue != 0 ) {
                printf STDERR "child exited with value %d\n", $exitValue;
                print STDERR "Command \"$localCmd\" failed. Bye!\n";
                $retCode = $exitValue;
                goto failingRun;
            }
        }
    }
    goto successfulRun unless ( $fileName =~ /\S/ );
    if ( $fileName =~ /\*/ ) {
        goto multipleFiles;
    }
    if ( !-e $fileName ) {
        print STDERR "Output file \"$fileName\" doesn't exist. Bye!\n";
        $retCode = 1;
        goto failingRun;
    }
    $sz = -s $fileName;
    if ( $sz < $minSize ) {
        print STDERR
            "Output file \"$fileName\" is of size $sz, must be at least of size $minSize. Bye!\n";
        $retCode = 1;
        goto failingRun;
    }
    goto successfulRun;
multipleFiles:
    $local_cmd = "ls $fileName |";
    $totSize   = 0;
    open( CMD, $local_cmd );
    while ( $tempFilename = <CMD> ) {
        chomp($tempFilename);
        $sz = -s $tempFilename;
        $totSize += $sz;
    }
    close(CMD);
    if ( $totSize < $minSize ) {
        print STDERR
            "The combined output files from \"$fileName\" have a total size of $totSize, must be at least of size $minSize. Bye!\n";
        $retCode = 1;
        goto failingRun;
    }
successfulRun:
    if ( !-e $success_fn ) {
        $local_cmd = "touch $success_fn";
        print "$local_cmd\n";
        system($local_cmd);
    }

    return;

failingRun:
    my $outdir = "$workingDirectory/${stepName}.Failed";
    mkdir($outdir);
    for (@filesCreated) {
        $local_cmd = "mv $_ $outdir";
        print "$local_cmd\n";
        system($local_cmd);
    }
    exit($retCode);
}

sub returnAbsolutePath {
    my ($file) = @_;
    if ( $file !~ /^\// ) {
        $file = "$cwd/$file";
    }
    return ($file);
}
