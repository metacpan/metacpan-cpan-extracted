# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Bio-SDRS.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

local *STDERR = *STDOUT;

use Test::More qw(no_plan);
BEGIN { use_ok('Bio::SDRS') };

my $multiple = 1.05;
my $ldose = 0.4;
my $hdose = 25000;
my $step = 20;
my $maxproc = 4;
my $trim = 0;
my $significance = 0.05;
my $outdir = ".";
my $debug = 0;

my $ifile = 0;
foreach my $infile (("t/OVCAR4_HCS_avg.txt",
		     "t/divzero.txt")) {
    $ifile += 1;
    my $sdrs = Bio::SDRS->new();
    ok($sdrs, "Object created.");
    ok($sdrs->multiple($multiple) == $multiple, "Multiple set");
    ok($sdrs->ldose($ldose) == $ldose, "ldose set");
    ok($sdrs->hdose($hdose) == $hdose, "hdose set");
    ok($sdrs->step($step) == $step, "step set");
    ok($sdrs->maxproc($maxproc) == $maxproc, "maxproc set");
    ok($sdrs->trim($trim) == $trim, "trim set");
    ok($sdrs->significance($significance) == $significance, "significance set");
    ok($sdrs->debug($debug) == $debug, "debug set");

    open (IN, $infile) || die "can not open infile $infile: $!\n";
    my $doses = <IN>;
    chomp($doses);
    $doses =~ s/\s*$//;
    my @doses = split (/\t/, $doses);
    shift @doses;

    $sdrs->doses(@doses);
    my $count = 0;
    while (<IN>) {
	chomp;
	$count++;
	my ($assay, @data) = split (/\t/, $_);
	$sdrs->set_assay($assay, @data);
    }
    close IN;
    $sdrs->calculate;
    open (OUT, ">t/sdrs.$ifile.$multiple.$step.EC50.out") ||
	die "can not open EC50 output file: $!\n";
    foreach my $assay ($sdrs->assays) {
	print OUT "$assay";
	foreach my $prop (('MAX', 'MIN', 'LOW', 'HIGH', 'EC50',
			   'PVALUE', 'EC50RANGE', 'PEAK', 'A', 'B',
			   'D', 'FOLD')) {
	    print OUT "\t", $sdrs->ec50data($assay, $prop);
	}
	print OUT "\n";
    }
    close OUT;
    my $file = "t/sdrs.$ifile.$multiple.$step.out";
    open (OUT, ">$file") ||
	die "Unable to open $file: $!\n";
    print OUT $sdrs->scandata;
    close OUT;
    # The following test bypasses some of the analysis checking
    # because the divide by zero error causes inconsistent results
    # from one machine to another. What's important is that the ec50
    # comes back as -1, which the above files check.
    if ($ifile != 2) { 
	open (SORT, ">t/sdrs.$ifile.sorted_probes.out") ||
	    die "can not open sorted probeset output file: $!\n";
	open (PVAL, ">t/sdrs.$ifile.pval_FDR.out") ||
	    die "can not open p value output file: $!\n";

	foreach my $dose ($sdrs->score_doses) {
	    my $dose_st = sprintf("%.5f", $dose);
	    print SORT "${dose_st}\t", join("\t", $sdrs->sorted_assays_by_dose($dose)), "\n";
	    print PVAL "${dose_st}\t", join("\t", $sdrs->pvalues_by_dose($dose)), "\n";
	}

	close SORT;
	close PVAL;
    }
    
    $ENV{"LC_ALL"} = "C";
    foreach my $f (("sdrs.$ifile.1.05.20.EC50.out",
		    "sdrs.$ifile.1.05.20.out",
		    "sdrs.$ifile.pval_FDR.out",
		    "sdrs.$ifile.sorted_probes.out")) {
	if (-r "t/${f}" and -r "t/ref.${f}.srt") {
	    ok(system("sort t/${f} >t/${f}.srt") == 0, "Sort ${f}");
	    &compare_files("t/${f}.srt", "t/ref.${f}.srt");
	}
    }
}

sub compare_files {
    my $file1 = shift;
    my $file2 = shift;
    my $limit = 1;

    local (*IN1, *IN2);

    ok(open (IN1, "<$file1"), "Open $file1");
    ok(open (IN2, "<$file2"), "Open $file2");
    my $count = 0;
    while (my $line1 = <IN1>) {
	my $line2 = <IN2>;
	if (not defined $line2) {
	    ok(0, "$file1 bigger than $file2");
	    last;
	}
	$count++;
	if ($line1 eq $line2) {
	    ok(1, "$file1: Lines $count match");
	}
	else {
	    chomp $line1;
	    chomp $line2;
	    if ($limit-- > 0) {
		my @words1 = split(/\t/, $line1);
		my @words2 = split(/\t/, $line2);
		my $ok = (scalar(@words1) == scalar(@words2));
		for (my $i = 0; $i < scalar(@words1); $i++) {
		    if ($words1[$i] ne $words2[$i]) {
			if ($words1[$i] eq 'inf') {
			    if ($words2[$i] < 1.0e300) {
				$ok = 0;
			    }
			}
			elsif ($words2[$i] eq 'inf') {
			    if ($words1[$i] < 1.0e300) {
				$ok = 0;
			    }
			}
			else {
			    $ok = 0;
			}
		    }
		}
		ok($ok,
		   "$file1: line $count match: line1 = $line1\nline2 = $line2");
	    }
	}
    }
    my $line2 = <IN2>;
    if (defined $line2) {
	ok(0, "$file2 bigger than $file1");
    }
    close IN1;
    close IN2;
}


