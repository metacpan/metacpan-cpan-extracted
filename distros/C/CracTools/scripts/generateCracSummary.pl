#!/usr/bin/perl

eval 'exec /usr/bin/perl  -S $0 ${1+"$@"}'
    if 0; # not running under some shell
#
use strict;
use warnings;

use Carp;
use CracTools::SAMReader;

=head1 NAME

generateCracSummary.pl - Generate Crac's summary from SAM file

=head1 SYNOPSIS

generateCracSummary.pl file.sam > file.summary

=head1 DESCRIPTION

Create the crac summary report from a sam, sam.gz or bam file.
You will get something like :

----------------------------------
Some STATISTICS            

----------------------------------
Total number of reads analyzed: 68736346

Single: 57784025 (84.0662%)
Multiple: 4617008 (6.71698%)
None: 534816 (0.778069%)
Duplication: 23813841 (34.6452%)

Warning: the sum of the four previous categories may not be equal to 100%.
This is normal: reads are considered by chunks.
In a given read, a chunk may appear multiple times, while another just appears once.

----------------------------------
Explainable: 66335353 (96.507%)

Repetition: 1927356 (2.80398%)
Normal: 18503376 (26.9193%)
Almost-Normal: 11796568 (17.1621%)
Sequence-Errors: 10316781 (15.0092%)
SNV: 2222562 (3.23346%)
Short-Indel: 71294 (0.103721%)
Splice: 3047373 (4.43342%)
Weak-Splice: 1994 (0.00290094%)
Chimera: 648997 (0.944183%)
Paired-end Chimera: 7369210 (10.721%)
Bio-Undetermined: 15408195 (22.4164%)
Undetermined: 1965574 (2.85958%)

=cut

my $sam_file = shift;

die "Missing SAM(.gz)|BAM file in argument" unless defined $sam_file;

my $reader = CracTools::SAMReader->new($sam_file);

my $it = $reader->iterator();

my %infos = (Single             => 0,
	     Multiple           => 0, 
	     None               => 0,
	     Duplication        => 0,
	     Explainable        => 0,
	     Repetition         => 0,
	     Normal             => 0,
	     AlmostNormal       => 0,
	     SequenceErrors     => 0,
	     SNV                => 0,
	     ShortIndel         => 0,
	     Splice             => 0,
	     WeakSplice         => 0,
	     Chimera            => 0,
	     PairedendChimera   => 0,
	     BioUndetermined    => 0,
	     Undetermined       => 0,
    );

my $total = 0;
while (my $line = $it->()) {
  next if $line->isFlagged(256);
  next if $line->isFlagged(2048);
    $total++;
# stats for mapping
    if($line->isClassified('unique')) {
	$infos{Single}++;
    } elsif($line->isClassified('multiple')) {
	$infos{Multiple}++;
    } elsif($line->isClassified('duplicated')) {
	$infos{Duplication}++;
    } else {
	$infos{None}++;
    }
    
# stats for continuity
    if($line->isClassified('normal')) {
	$infos{Normal}++;
    }elsif ($line->isClassified('almostNormal')) {
	$infos{AlmostNormal}++;
    }

#stats for cause  ##todo repetiton and paired-chimera
    $infos{SequenceErrors} += scalar @{$line->events('Error')};    
    $infos{SNV} += scalar @{$line->events('SNP')};  
    $infos{ShortIndel} += (scalar @{$line->events('Del')} + scalar @{$line->events('Ins')});    
    my @junctions = @{$line->events('Junction')};
    foreach my $junction (@junctions){
	if ($junction->{type} eq "coverless"){
	    $infos{WeakSplice}++;
	}else{
	    $infos{Splice}++;
	} 
    }
    $infos{Chimera} += scalar @{$line->events('Chimera')};
    $infos{Undetermined} += scalar @{$line->events('Undetermined')};
    $infos{BioUndetermined} += scalar @{$line->events('BioUndetermined')};
}

$infos{Explainable} = $total - $infos{Undetermined};


###################################################################################

#print the new summary once the sam file has been updated
print "
----------------------------------
Some STATISTICS            

----------------------------------
Total number of reads analyzed: $total

Single: ".$infos{Single}." (".$infos{Single}*100/$total."%)
Multiple: ".$infos{Multiple}." (".$infos{Multiple}*100/$total."%)
None: ".$infos{None}." (".$infos{None}*100/$total."%)
Duplication: ".$infos{Duplication}." (".$infos{Duplication}*100/$total."%)

Warning: the sum of the four previous categories may not be equal to 100%.
This is normal: reads are considered by chunks.
In a given read, a chunk may appear multiple times, while another just appears once.

----------------------------------
Explainable: ".$infos{Explainable}." (".$infos{Explainable}*100/$total."%)

Repetition: "."NA"." ("."NA"."%)
Normal: ".$infos{Normal}." (".$infos{Normal}*100/$total."%)
Almost-Normal: ".$infos{AlmostNormal}." (".$infos{AlmostNormal}*100/$total."%)
Sequence-Errors: ".$infos{SequenceErrors}." (".$infos{SequenceErrors}*100/$total."%)
SNV: ".$infos{SNV}." (".$infos{SNV}*100/$total."%)
Short-Indel: ".$infos{ShortIndel}." (".$infos{ShortIndel}*100/$total."%)
Splice: ".$infos{Splice}." (".$infos{Splice}*100/$total."%)
Weak-Splice: ".$infos{WeakSplice}." (".$infos{WeakSplice}*100/$total."%)
Chimera: ".$infos{Chimera}." (".$infos{Chimera}*100/$total."%)
Paired-end Chimera: "."NA"." ("."NA"."%)
Bio-Undetermined: ".$infos{BioUndetermined}." (".$infos{BioUndetermined}*100/$total."%)
Undetermined: ".$infos{Undetermined}." (".$infos{Undetermined}*100/$total."%)
";
