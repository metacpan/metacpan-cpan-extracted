#!/usr/bin/env perl
# PODNAME: generate_bgc_report.pl
# ABSTRACT: Generates PDF/Word reports from antiSMASH results
# CONTRIBUTOR: Denis BAURAIN <denis.baurain@uliege.be>

use Modern::Perl '2011';
use autodie;

use Smart::Comments;

use Carp;
use Const::Fast;
use File::Basename qw(fileparse);
use File::ShareDir qw(dist_dir);
use File::Temp;
use Getopt::Euclid qw(:vars);
use Path::Class qw(dir file);
use Template;

use aliased 'Bio::Palantir::Parser';


const my $DATA_PATH => dist_dir('Bio-Palantir') . '/';

# check BGC type
if (@ARGV_types) {
    Parser->is_cluster_type_ok(@ARGV_types);
}

my $infile = $ARGV_report_file;

#TODO use abbr seqids in genomes to get taxonomic informations
my ($base, $path) = fileparse($infile);

croak 'Does not work with regions.js reports (antiSMASH 5),'
    . 'an implementation might come soon!'
    if $base eq 'regions.js'
;

$path = dir($path)->absolute;

my $defline = ( split '/', $path )[-1];
$defline =~ s/_/ /g;

my $report = Parser->new( file => $infile );
my $root = $report->root;

my %vars_for = (
    name          => $defline,
    path          => $path,
    clusters_count => $root->count_clusters,
    domains_count => $root->count_domains,
    );

# get genecluster informations
my $i = 0;

for my $cluster ($root->all_clusters) {

    if (@ARGV_types) {
        next unless
            grep { $cluster->type =~ m/$_/xmsi } @ARGV_types;
    }
    my $cluster_rank = $cluster->rank;
   
    my $type = lc $cluster->type;

    my $monomers = join '-', ( map { $_->monomers } $cluster->all_genes );
    
    my @domains;
    for my $gene ($cluster->all_genes) {

        push @domains, map { $_->function } $gene->all_domains;
    }

    my $domains = join ', ', @domains;

    my $structure 
        = -e ($path . '/structures/genecluster' . $cluster_rank . '.png') 
        ? ($path . '/structures/genecluster' . $cluster_rank . '.png') 
        : '0'
    ;
    
    my $cluster_svg 
        = -e ($path . '/svg/genecluster' . $cluster_rank . '.svg') 
        ? ($path . '/svg/genecluster' . $cluster_rank . '.png') 
        : '0'
    ;

    push @{ $vars_for{clusters} }, {
        type        => $type,
        coords      => $cluster->genomic_dna_coordinates,
        size        => $cluster->genomic_dna_size,
        domains     => $domains // 'no domain',
        structure   => $structure,
        cluster_svg => $cluster_svg,
        monomers    => $monomers,
    };
}

# generate a pdf format report
my $template = $DATA_PATH . 'antismash_report.tt';

$path->mkpath();      # create the path if it isn't the case
my $incldir = file($template)->dir->absolute;

my $output = $ARGV_outfile . '.' .$ARGV_filetype;
my $md  = File::Temp->new(suffix => '.markdown'); 

# compute output and include paths for TT
my $tt = Template->new(
    ABSOLUTE    => 1,
);

$tt->process($template, \%vars_for, $md)
    or croak ' Cannot build: ' . file($md) . ": $!";

# convert svg geneclusters, not supported by LaTeX in png format
### Converting biosynthetic gene clusters svg pictures in png 
my $svg_cmd = 'for f in ' . $path->stringify . '/svg/*svg; do inkscape -D '
    . '--export-png= ' . $path->stringify . '/svg/$(basename $f .svg).png $f;'
    . 'done'
;

system($svg_cmd);

# generate pdf/docx report with pandoc
### Generating your report: $output
my $output_cmd = "pandoc $md -s --toc -o $output";
system($output_cmd);

__END__

=pod

=head1 NAME

generate_bgc_report.pl - Generates PDF/Word reports from antiSMASH results

=head1 VERSION

version 0.191800

=head1 NAME

generate_bgc_report.pl - Parses and filters biosynthetic gene cluster 
information from antiSMASH analyses and report these in PDF or docx reports

=head1 USAGE

	$0 [options] --path <biosynml_path> --taxdir <dir>

=head1 REQUIRED ARGUMENTS

=over

=item --report[-file] [=] <infile>

Path to the output file of antismash, which can be either a 
biosynML.xml (antiSMASH 3-4) or a regions.js file (antiSMASH 5).

=for Euclid: infile.type: readable

=back

=head1 OPTIONAL ARGUMENTS

=over

=item --filetype [=] <str>

Your report can be either in PDF or Word docx format. 
Choose pdf or docx [default: pdf].

=for Euclid: str.type: /docx|pdf/
    str.default: 'pdf'

=item --outfile [=] <filename>

Output filename [default: bgc_report].

=for Euclid: filename.type: writable
    filename.default: 'bgc_report'

=item --types [=] <str>...

Filter clusters on a/several specific type(s). 

Types allowed: acyl_amino_acids, amglyccycl, arylpolyene, bacteriocin, 
butyrolactone, cyanobactin, ectoine, hserlactone, indole, ladderane, 
lantipeptide, lassopeptide, microviridin, nrps, nucleoside, oligosaccharide, 
otherks, phenazine, phosphonate, proteusin, PUFA, resorcinol, siderophore, 
t1pks, t2pks, t3pks, terpene.

Any combination of these types, such as nrps-t1pks or t1pks-nrps, is also
allowed. The argument is repeatable.

=item --version

=item --usage

=item --help

=item --man

print the usual program information

=back

=head1 AUTHOR

Loic MEUNIER <lmeunier@uliege.be>

=head1 CONTRIBUTOR

=for stopwords Denis BAURAIN

Denis BAURAIN <denis.baurain@uliege.be>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by University of Liege / Unit of Eukaryotic Phylogenomics / Loic MEUNIER and Denis BAURAIN.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
