#!/usr/bin/perl -w
use strict;
use List::Util 'sum';
use Getopt::Long;

use vars qw/$start $end $current_chr @scores %seen %highest $win $normal $bam/;

use constant WIN => 25;

# A script to make bam coverage windows in WIG/BED 4 format
# requires that samtools be installed
# This script operates on one bam file at a time.  If you are comparing
# across bam files of diffenrent sizes (read numbers), take note
# of the normalization option.
# Sheldon McKay (sheldon.mckay@gmail.com)


BEGIN {
    die "samtools must be installed!" unless `which samtools`;
}


GetOptions ("normalize=i" => \$normal,
            "bam=s"       => \$bam,
            "window=i"    => \$win);

$bam or usage();

open BAM, "samtools depth $bam |";

$win ||= WIN;
$start = 1;
$end   = $win;

my $factor = normalization_factor($normal); 

chomp(my $name = `basename $bam .bam`);
print qq(track type=wiggle_0 name="$name" description="read coverage for $bam (window size $win)"\n);

while (<BAM>) {
    chomp;
    my ($chr,$coord,$score) = split;
    $current_chr ||= $chr;

    check_sorted($chr,$coord);

    if ( $chr ne $current_chr ||
	 $coord > $end ) {
	open_window($chr,$coord);
    }

    push @scores, $score;
    $current_chr = $chr;
}


sub open_window {
    my ($chr,$coord) = @_;

    if ($chr ne $current_chr) {
	$seen{$current_chr}++;
    }

    # close the last window, if needed
    if (@scores > 0) {
	close_window();
    }

    $start = nearest_start($coord);
    $end   = $start + $win;
}

sub close_window {
    my $sum = sum(@scores) or return 0;
    my $score = $sum/$win;
    $score *= $factor;
    print join("\t",$current_chr,$start,$end,$score), "\n";
    @scores = ();
    exit 0 unless $score;
}

sub nearest_start {
    my $start = shift;

    return 1 if $start < $win;

    while  ($start % $win) {
	$start--;
    }

    return $start;
}

sub normalization_factor {
    return 1 unless my $nahm = shift;
    print STDERR "Calculating total number of reads in $bam\n";
    chomp(my $total = `samtools view -c $bam`);
    print STDERR "$bam has $total reads\n";
    return $total/$nahm;
}

# sanity check for unsorted bam
sub check_sorted {
    my ($chr,$coord) = @_;

    return 1 if $coord > ($highest{$chr} || 0);
    $highest{$chr} = $coord;

    return 1 unless $seen{$chr};

    die_unsorted($chr,$coord);
}

sub die_unsorted {
    my ($chr,$coord) = @_;
    die "$chr $coord: $bam does not appear to be sorted\n",
    "Please try 'samtools sort' first";
}

sub usage {
    die '
Usage: perl bam_coverage_windows.pl -b bamfile -n 10_000_000 -w 25
    -b name of bam file to read REQUIRED
    -w window size (default 25)
    -n normalized read number -- if you will be comparing multiple bam files 
                                 select the read number to normalize against.
                                 all counts will be adjusted by a factor of:
                                 actual readnum/normalized read num

'
}
