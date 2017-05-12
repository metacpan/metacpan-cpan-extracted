#!perl

# This script will run a FDR FET analysis.
# It requires two files, a list of genes with P values, see t/HIV-loci-pval.inp
# for an example, and a list of pathways, see t/example_pathways.txt for
# an example. The results go into the outdir directory. The other options
# are described in the FdrFet.pm documentation.

use strict;
use Bio::FdrFet;
use Getopt::Long;

my $fdrcutoff = 35;
my ($genefile, $pathwayfile, $outdir);
my $help = 0;
my $verbose = 0;
my $universe = "genes";
my $genecount = undef;
my $arrays = 0;
&GetOptions("fdr=i" => \$fdrcutoff,
	    "genelist=s" => \$genefile,
	    "pathway=s" => \$pathwayfile,
	    "outdir=s" => \$outdir,
	    "help!" => \$help,
	    "verbose!" => \$verbose,
	    "universe=s" => \$universe,
	    "genecount=i" => \$genecount,
	    "arrays!" => \$arrays
	);

my $usage = <<EOF;
fdr-fet.pl -fdr=integer
           -genelist=file
           -pathway=file
           -outdir=output_directory
           -universe=universe_setting
           -genecount=integer
           -[no]help
           -[no]verbose
           -[no]arrays
EOF

if (not $outdir or
    not $genefile or
    not $pathwayfile or
    $help) {
    print STDERR $usage;
    exit(1);
}

my $obj = new Bio::FdrFet($fdrcutoff);
$obj->verbose($verbose);
$obj->universe($universe);
#read in gene set/pathway data

open (IN, $pathwayfile) || die "can not open pathway annotation file $pathwayfile: $!\n";
while (<IN>) {
    chomp;
    my ($gene, $dbacc, $desc, $rest) = split (/\t/, $_, 4);
    $obj->add_to_pathway("gene" => $gene,
			 "dbacc" => $dbacc,
			 "desc" => $desc);
}
close IN;

#read in genes and associated p values
my (%genes, @fdrs);
open (IN, $genefile) || die "can not open gene file $genefile: $!\n";
my $ref_size = 0;
while (<IN>) {
    my ($gene, $pval) = split (/\t/, $_);
    $obj->add_to_genes("gene" => $gene,
		       "pval" => $pval);
    $ref_size++;
}
close IN;
if ($universe eq 'user') {
    $obj->gene_count($genecount);
}
$obj->calculate;

if (not -d $outdir) {
    system("mkdir -p $outdir");
}
open (PATH, ">$outdir/$pathwayfile.fdr$fdrcutoff.detail.out") ||
    die "can not open pathway analysis detail file: $!\n";

foreach my $p ($obj->pathways) {
    foreach my $locus (@{$obj->pathway_result($p, 'loci')}) {
	my @components = map {$obj->pathway_result($p, $_)} ('odds',
							     'q',
							     'm',
							     'n',
							     'k');
	$components[0] = sprintf("%.2f", $components[0]);
	my $rest = join(':', @components);
	if ($components[0] == 0) {
	    $rest = '0.00:';
	}
	printf PATH "%s\t%s\t%.2f\t$rest\t$locus\n",
	$p,
	$obj->pathway_desc($p),
	$obj->pathway_result($p, 'logpval');
    }
    if ($arrays) {
	print "Log Pval for pathway $p:\n";
	my @logpval = $obj->pathway_result($p, 'logpval', 'all');
	for (my $i = 0; $i < $fdrcutoff; $i++) {
	    printf "%d\t%.2f\n", $i+1, $logpval[$i];
	}
    }
}
close PATH;

#output pathways and their P values from GSEA
open (OUT, ">$outdir/$pathwayfile.out") || die "can not open pathway analysis output file: $!\n";
foreach my $p ($obj->pathways) {
    printf OUT "$p\t%s\t%.2f\n", $obj->pathway_desc($p), $obj->pathway_result($p, 'logpval');
}
close OUT;
