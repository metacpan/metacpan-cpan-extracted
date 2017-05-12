# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Bio-FdrFet.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

# use Test::More tests => 10
use strict;
use Test::More qw(no_plan);
BEGIN { use_ok('Bio::FdrFet') };

use Data::Dumper;
my %fdr7 = ('intersection' => 123,
	    'union' => 312,
	    'genes' => 317,
	    'user' => 176);
	    
foreach my $universe (('intersection', 'union', 'genes', 'user')) {
    my $obj = new Bio::FdrFet(34);
    ok($obj, "Object created");
    ok($obj->universe($universe) eq $universe, "Universe setting");
    ok($obj->verbose(0) == 0, "Verbose setting");
    ok($obj->fdr_cutoff == 34, "FDR cutoff readout 1");
    ok($obj->fdr_cutoff(35) == 35, "FDR cutoff readout 2");
    
    if (not open (IN, "<t/HIV-loci-pval.inp")) {
	BAIL_OUT("Unable to open pval test file: $!");
    }
    
    my $ref_size = 0;
    while (<IN>) {
	chomp;
	my ($gene, $pval) = split (/\t/, $_);
	$obj->add_to_genes("gene" => $gene,
			   "pval" => $pval);
	$ref_size++;
    }
    close IN;
    if ($universe eq 'user') {
	$obj->gene_count(20000);
    }
    # Get the number for the next test using the following line.
    # diag(sprintf("%d genes were found.", scalar($obj->genes)));
    ok(scalar($obj->genes) == 11349, "gene count");
    if (not open (IN, "<t/example_pathways.txt")) {
	BAIL_OUT("Unable to open pathway test file: $!");
    }

    while (<IN>) {
	chomp;
	my ($gene, $dbacc, $desc) = split(/\t/, $_);
	$obj->add_to_pathway("gene" => $gene,
			     "dbacc" => $dbacc,
			     "desc" => $desc);
    }
    close IN;
    # Get the number for the next test using the following line.
    # diag(sprintf("%d pathways were found.", scalar($obj->pathways)));
    ok(scalar($obj->pathways) == 7, "pathway count");
    $obj->calculate;
    # Get the number for the next test using the following line.
    # diag(sprintf("$universe fdr_position(7) = %d", $obj->fdr_position(7)));
    ok($obj->fdr_position(7) == $fdr7{$universe}, "$universe FDR position check");

    if (not open(IN, "<t/results.detail.$universe")) {
	BAIL_OUT("Unable to open results detail file for $universe: $!");
    }
    my $i = 0;

    while (<IN>) {
	$i++;
	chomp;
	my ($pathway, $desc, $pval, $fetparms, $gene) = split(/\t/);
	my %seen = map {$_ => 1} @{$obj->pathway_result($pathway, 'loci')};
	ok($desc eq $obj->pathway_desc($pathway), "$universe detail $i: pathway");
	my $logpval = sprintf("%.2f", $obj->pathway_result($pathway, 'logpval'));
	ok($pval == $logpval, "$universe detail $i: pval");
	my @components = map {$obj->pathway_result($pathway, $_)} ('odds',
								   'q',
								   'm',
								   'n',
								   'k');
	$components[0] = sprintf("%.2f", $components[0]);
	if ($fetparms ne '0.00:') {
	    ok($fetparms eq join(':', @components), "$universe detail $i: fetparms");
	}
	ok($seen{$gene}, "$universe detail $i: gene");
	if ($i % 10 == 0) {	# Reduce the number of test points -- all of them is overkill.
	    my $fdr = $obj->pathway_result($pathway, 'fdr');
	    my ($bestfdr, $bestlogpval, $bestodds, $bestq, $bestm, $bestn, $bestk, $bestloci);
	    my @logpval = $obj->pathway_result($pathway, 'logpval', 'all');
	    #	diag("$universe $i logpval: " . join(' ', @logpval) . "\n");
	    my @odds = $obj->pathway_result($pathway, 'odds', 'all');
	    my @q = $obj->pathway_result($pathway, 'q', 'all');
	    my @m = $obj->pathway_result($pathway, 'm', 'all');
	    my @n = $obj->pathway_result($pathway, 'n', 'all');
	    my @k = $obj->pathway_result($pathway, 'k', 'all');
	    my @loci = $obj->pathway_result($pathway, 'loci', 'all');
	    for (my $ifdr = 0; $ifdr < 35; $ifdr++) {
		if ($ifdr == 0 or $logpval[$ifdr] > $bestlogpval) {
		    $bestfdr = $ifdr + 1;
		    $bestlogpval = $logpval[$ifdr];
		    $bestodds = $odds[$ifdr];
		    $bestq = $q[$ifdr];
		    $bestm = $m[$ifdr];
		    $bestn = $n[$ifdr];
		    $bestk = $k[$ifdr];
		    $bestloci = $loci[$ifdr];
		}
	    }
	    ok($bestfdr == $fdr, "$universe detail $i: FDR $fdr check");
	    ok(sprintf("%.2f", $bestlogpval) eq $logpval, "$universe detail $i: LOGPVAL array check");
	    ok(sprintf("%.2f", $bestodds) eq $components[0], "$universe detail $i: ODDS array check");
	    ok($bestq == $components[1], "$universe detail $i: Q array check");
	    ok($bestm == $components[2], "$universe detail $i: M array check");
	    ok($bestn == $components[3], "$universe detail $i: N array check");
	    ok($bestk == $components[4], "$universe detail $i: K array check");
	    ok(join(":", @{$obj->pathway_result($pathway, 'loci')}) eq
	       join(":", @{$bestloci}),
	       "$universe detail $i: LOCI array check");
	}
    }
    close IN;
    
    if (not open(IN, "<t/results.pathway.$universe")) {
	BAIL_OUT("Unable to open results detail file for $universe: $!");
    }
    
    $i = 0;
    while (<IN>) {
	chomp;
	$i++;
	my ($p, $desc, $logpval) = split(/\t/);
	ok($desc eq $obj->pathway_desc($p), "Pathway descriptor $i");
	ok($logpval eq sprintf("%.2f", $obj->pathway_result($p, 'logpval')), "Pathway logpval $i");
    }
    close IN;
    
    $i = 0;
    my $prev_logpval = 0.0;
    foreach my $pathway ($obj->pathways('sorted')) {
	my $logpval = $obj->pathway_result($pathway, 'LOGPVAL');
	#     diag(sprintf("Pathway $pathway %s has logpval = %6.4f",
	# 		 $obj->pathway_desc($pathway),
	#		 $logpval));
	if (++$i > 1) {
	    ok($logpval <= $prev_logpval, "Sorting test $i");
	}
	$prev_logpval = $logpval;
	ok(scalar($obj->pathway_genes($pathway)) == $obj->pathway_result($pathway, 'K'),
	   "Pathway $pathway gene count");
    }
}
