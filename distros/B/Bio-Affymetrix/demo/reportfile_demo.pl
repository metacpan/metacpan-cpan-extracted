#!/usr/bin/perl

# Demonstration program that produces a file intended to match the format
# of a report file, as produced by  MAS5, using the Bio::Affymetrix::*
# modules 

# Some fields are marked as UNPARSEABLE- these are fields that we have currently 
# written code to parse yet. 

# By Nick James, David J Craigon. This script is free software, you
# are free to use it under the same terms as Perl itself.

# This (may) only work with Arabidopsis chips

# Usage: reportfile_demo.pl CDF_file_name CHP_file_name

use Bio::Affymetrix::CDF;
use Bio::Affymetrix::CHP;

use strict;
use warnings;

if (scalar(@ARGV)!=2) {
    die "Usage: ".$0." cdffilename chipfilename";
}

# Parse CDF file into Bio::Affymetrix::CDF object
my $cdf=new Bio::Affymetrix::CDF();

$cdf->parse_from_file($ARGV[0]);

# Parse CHP file into Bio::Affymetrix::CHP object
my $chp=new Bio::Affymetrix::CHP($cdf);

$chp->parse_from_file($ARGV[1]);



# Begin the report file. All of these bits can be got out straight
# away from the object

printf "

Report Type:	Fake Expression Report
Date:          	11:28AM 10/07/2004
______________________________________________________________________

Filename:	%s
Probe Array Type:	%s
Algorithm:	%s
Probe Pair Thr:	UNPARSEABLE
Controls:	%s
______________________________________________________________________

Alpha1:	%.2f
Alpha2:	%.2f
Tau:	%.3f
Noise (RawQ):	%.3f
Scale Factor (SF):	%.3f
TGT Value:	%i
Norm Factor (NF):	%.3f
______________________________________________________________________

Background:
%s
Noise:
%s
Corner+
UNPARSEABLE
Corner-
UNPARSEABLE
Central-
UNPARSEABLE
______________________________________________________________________

",
$ARGV[1],
$chp->probe_array_type(),
$chp->algorithm_name(),
"UNPARSEABLE",
$chp->algorithm_params()->{"Alpha1"},
$chp->algorithm_params()->{"Alpha2"},
$chp->algorithm_params()->{"Tau"},
$chp->summary_statistics()->{"RawQ"},
$chp->algorithm_params()->{"SF"},
$chp->algorithm_params()->{"TGT"},
$chp->algorithm_params()->{"NF"},
$chp->summary_statistics()->{"Background"},
$chp->summary_statistics()->{"Noise"}
;


# Now we will calculate the % present, % absent etc. and calculate
# average signals

# Put results into $h to save typing
my $h=$chp->probe_set_results();

# Good way of working out total number of probesets
my $total_probe_sets=scalar(keys %$h);

my $present;
my $presentsignal;
my $absent;
my $absentsignal;
my $marginal;
my $marginalsignal;
my $nocall;
my $nocallsignal;

# For each probe on the array...
foreach my $i (keys %$h) {
    #... Work out detection call, sum signal for each call
    if ($h->{$i}->{"DetectionCall"} eq "P") {
	$present++;
	$presentsignal+=$h->{$i}->{"Signal"};
    } elsif ($h->{$i}->{"DetectionCall"} eq "M") {
	$marginal++;
	$marginalsignal+=$h->{$i}->{"Signal"};
    } elsif ($h->{$i}->{"DetectionCall"} eq "A") {
	$absent++;
	$absentsignal+=$h->{$i}->{"Signal"};
    } elsif ($h->{$i}->{"DetectionCall"} eq "N") {
	$nocall++;
	$nocallsignal+=$h->{$i}->{"Signal"};
    } else {
	die "Don't recognise ".$i."'s detection call value ".$h->{$i}->{"DetectionCallx"};
    }
}

# Mean values calculated below

printf "
The following data represents probe sets that exceed the probe pair threshold 
and are not called \"No Call\".

Total Probe Sets:	%d
Number Present:	%d	%.1f%%
Number Absent:	%d	%.1f%%
Number Marginal:	%d	%.1f%%

Average Signal (P):	%.1f
Average Signal (A):	%.1f
Average Signal (M):	%.1f
Average Signal (All):	%.1f
",
$total_probe_sets,
$present,
($present/($present+$marginal+$absent))*100,
$absent,
($absent/($present+$marginal+$absent))*100,
$marginal,
($marginal/($present+$marginal+$absent))*100,
$presentsignal/$present,
$absentsignal/$absent,
$marginalsignal/$marginal,
($marginalsignal+$absentsignal+$presentsignal)/($marginal+$absent+$present)
;


# House keeping controls
# Look for all things that looke like house keeping controls, then print them out


my %housekeeping;

foreach my $i (keys %$h) {
    if ((uc $i)=~/(AFFX.*(ACTIN|UBQ|GAPDH))[_-]([35M])/) {
	if (!defined $housekeeping{$1}) {
	    $housekeeping{$1}={};
	}
	$housekeeping{$1}->{$3}=[$h->{$i}->{"Signal"},$h->{$i}->{"DetectionCall"}];
    }
}



print "
______________________________________________________________________

Housekeeping Controls:
Probe Set\tSig(5')\tDet(5')\tSig(M')\tDet(M')\tSig(3')\tDet(3')\tSig(all)\tSig(3'/5')
";


{
    no warnings "uninitialized";

    foreach my $i (sort keys %housekeeping) {
	print $i."\t";
	if (defined $housekeeping{$i}->{"5"}->[0]) {
	    printf "%.2f\t%s\t",$housekeeping{$i}->{"5"}->[0],$housekeeping{$i}->{"5"}->[1];
	} else {
	    print "\t\t";
	}


	if (defined $housekeeping{$i}->{"M"}->[0]) {
	    printf "%.2f\t%s\t",$housekeeping{$i}->{"M"}->[0],$housekeeping{$i}->{"M"}->[1];
	} else {
	    print "\t\t";
	}


	if (defined $housekeeping{$i}->{"3"}->[0]) {
	    printf "%.2f\t%s\t",$housekeeping{$i}->{"3"}->[0],$housekeeping{$i}->{"3"}->[1];
	} else {
	    print "\t\t";
	}

	printf "%.2f\t",(($housekeeping{$i}->{"3"}->[0]+$housekeeping{$i}->{"5"}->[0]+$housekeeping{$i}->{"M"}->[0])/((defined $housekeeping{$i}->{"M"}->[0]?1:0)+(defined $housekeeping{$i}->{"5"}->[0]?1:0)+(defined $housekeeping{$i}->{"3"}->[0]?1:0)));

	if (defined $housekeeping{$i}->{"5"}->[0] && defined $housekeeping{$i}->{"3"}->[0]) {
	    printf "%.2f",$housekeeping{$i}->{"3"}->[0]/$housekeeping{$i}->{"5"}->[0];
	}
	print "\n";
    }



# Spike controls

    print "
______________________________________________________________________
Spike Controls:
Probe Set	Sig(5')	Det(5')	Sig(M')	Det(M')	Sig(3')	Det(3')	Sig(all)	Sig(3'/5')
";

    foreach my $i ("BioB","BioC","BioDn","CreX","DapX","LysX","PheX","ThrX","TrpnX") {
	print uc $i."\t";
	
	if (defined $h->{"AFFX-$i-5_at"}) {
	    printf "%.2f\t%s\t",$h->{"AFFX-$i-5_at"}->{"Signal"},$h->{"AFFX-$i-5_at"}->{"DetectionCall"};
	} else {
	    print "\t\t";
	}

	if (defined $h->{"AFFX-$i-M_at"}) {
	    printf "%.2f\t%s\t",$h->{"AFFX-$i-M_at"}->{"Signal"},$h->{"AFFX-$i-M_at"}->{"DetectionCall"};
	} else {
	    print "\t\t";
	}

	if (defined $h->{"AFFX-$i-3_at"}) {
	    printf "%.2f\t%s\t",$h->{"AFFX-$i-3_at"}->{"Signal"},$h->{"AFFX-$i-3_at"}->{"DetectionCall"};
	} else {
	    print "\t\t";
	}

	printf "%.2f\t",(($h->{"AFFX-$i-3_at"}->{"Signal"}+$h->{"AFFX-$i-5_at"}->{"Signal"}+$h->{"AFFX-$i-M_at"}->{"Signal"})/((defined $h->{"AFFX-$i-3_at"}->{"Signal"}?1:0)+(defined $h->{"AFFX-$i-5_at"}->{"Signal"}?1:0)+(defined $h->{"AFFX-$i-M_at"}->{"Signal"}?1:0)));

	if (defined $h->{"AFFX-$i-3_at"} && defined $h->{"AFFX-$i-5_at"}) {
	    printf "%.2f",($h->{"AFFX-$i-3_at"}->{"Signal"}/$h->{"AFFX-$i-5_at"}->{"Signal"});
	}
	print "\n";
    }
    print "______________________________________________________________________\n";
}
