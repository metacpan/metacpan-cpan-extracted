#!/usr/bin/env perl

#author Nicolas Philippe
#goal   create a file in GFF3 format using Ensembl API to query on Ensembl GB.

use constant REGISTRY                      => 'Bio::EnsEMBL::Registry';
use constant NONE                          => 'N/A';

use FileHandle;
use strict;
use warnings;
use POSIX;
use Getopt::Long;
use Pod::Usage;
use Bio::EnsEMBL::Registry;
use Bio::EnsEMBL::ApiVersion;

=pod


=head1 SYNOPSIS

    buildGFF3FromEnsembl.pl [-h|--f] [--output <output_file>] [--est] <genome> 
    The mandatory argument is a genome which is indexed in Ensembl GB. 
    For example:
             'Homo Sapiens' for Human,
             'Pan troglodytes' for Chimpanzee,
             'Mus musculus' for Mouse,
             'Macaca mulatta' for Macaque,
             'Pongo pygmaeus' for Orangutan,
              etc (cf http://www.ensembl.org/info/about/species.html)
    --output: put the filename to write the gff3 output (STDOUT by default)  
    --est: build GFF3 from Ensembl API with OtherFeatures DB (Core DB by default)

=head1 OPTIONS

    -h, --help, --fullhelp
    --output=I<output_file>
    --est
    
    make a GFF3 file on <output_file>
      column 1: <seqname> 
                The name of the sequence. Commonly, this is the chromosome ID or
                contig ID. Note that the coordinates used must be unique within
                each sequence name in all GTFs for an annotation set.

      column 2: <source>
                The source column should be a unique label indicating where the 
                annotations came from Ensembl.
      column 3: <feature>
                exon, cds, five, three, gene or mRNA
      column 4: <start exon>
                Start coordinates of the feature relative to the beginning of the 
                sequence named in <seqname>. 
      column 5: <end exon>
                End coordinates of the feature relative to the beginning of the 
                sequence named in <seqname>. 
      column 6: <score>
                .
      column 7: <strand>
                strand of the exon relative to the genome, ie - or +
      column 8: <frame>
                .
      column 9: a list of binome <key "value"> separated by a semicolon ";". 
                A GFF file has the same three mandatory attributes at the end 
                of the record (Note that other attributes are optional):
                  -ID=value                      A globally unique identifier for the feature.
                  -Parent=value1,...,valueN      A list of identifier(s) for the parent(s) of the feature.
                  -Name=value                    The HGNC name of the gene 
               
                This script define the following attributes:
               
                  -transcripts_nb=value          The number of transcripts contained in the gene
                  -exons_nb=value                The number of exons contained in the transcript/gene
                  -exon_rank=value               The rank of the exon contained in the gene
                  -type "prefix:value"           The nature of the mRNA where the "prefix" 
                                                 represents a first class level (protein_coding, 
                                                 small_ncRNA, lincRNA, other_lncRNA, other_noncodingRNA)
                                                 and "value" is the biotype defined by Ensembl. 
 

=head1 REQUIRES

    Perl5.
    Bio::EnsEMBL
    Getopt::Long
    Pod::Usage
    
=head1 AUTHOR

    Nicolas PHILIPPE <nicolas.philippe@inserm.fr>

=cut


my ($help, $fullhelp, $est, $output_file)
  =(    0,         0,    0,        undef);

# parse options and print usage if there is a syntax error.
GetOptions("full|full-help"     => \$fullhelp,
           "help|?"   => \$help,
	   "output=s"      => \$output_file,
	   "est"      => \$est)
    or pod2usage(-verbose => 0);


if ($help || scalar @ARGV < 1) {
    pod2usage(-verbose => 0);
}elsif ($fullhelp){
    pod2usage(-verbose => 2);
}

my $registry = REGISTRY;
my $output = FileHandle->new;
my $genome = $ARGV[0];

$registry->load_all() or die("ensembl API is required");

if (defined $output_file){
    open($output,">$output_file") or die("enable to open $output_file");
}else{
    open($output,">&STDOUT") or die("enable to open >&STDOUT");
}
print $output "##gff-version 3\n";
print $output "# The organism is $genome\n";
print $output "# The API version used is ".software_version()."\n";


my $gene_adaptor;
if ($est){
    $gene_adaptor = $registry->get_adaptor( $genome, 'OtherFeatures', 'Gene' ) or die("No registry for OtherFeatures Db");
}else{   
    $gene_adaptor = $registry->get_adaptor( $genome, 'Core', 'Gene' ) or die("No registry for Core DB");
}
my @genes = @{ $gene_adaptor->fetch_all() };


my $source;
if ($est){
    $source ="Ensembl_EST";
}else{
    $source ="Ensembl_CORE";
}

foreach my $gene (@genes){
    my $gene_id = $gene->stable_id() or die("gene_id is required");
    if ($gene_id =~ /^\d/){
	my $tmp = "GENEID".$gene_id;
	$gene_id = $tmp;
    } 
    my $gene_start = $gene->start() or die("gene_start is required");
    my $gene_end = $gene->end() or die("gene_start is required");
    
    my $chr = $gene->slice()->seq_region_name() or die("seq_name is required");
    my $strand;
    if ($gene->strand() == -1){
	$strand = "-";
    }else{
	$strand = "+";
    }
 
    my $desc = NONE ; 
    if (defined $gene->biotype()){
	#protein coding part
	if ($gene->biotype() eq "protein_coding" || $gene->biotype() eq "pseudogene" 
	    || $gene->biotype =~ /IG_C/i || $gene->biotype =~ /IG_V/i 
	    || $gene->biotype =~ /TR_V/i || $gene->biotype =~ /TR_C/i
	    || $gene->biotype =~ /TR_J/i || $gene->biotype =~ /IG_D/i
	    || $gene->biotype =~ /IG_J/i || $gene->biotype =~ /TR_D/i
	    || $gene->biotype eq "polymorphic_pseudogene"){
	    $desc = "protein_coding:".$gene->biotype;
	}elsif ($gene->biotype() eq "miRNA" || $gene->biotype() eq "miRNA_pseudogene" 
		|| $gene->biotype() eq "snRNA" || $gene->biotype() eq "snRNA_pseudogene" 
		|| $gene->biotype eq "snoRNA" || $gene->biotype() eq "snoRNA_pseudogene" 
		|| $gene->biotype() eq "rRNA" || $gene->biotype() eq "rRNA_pseudogene"
		|| $gene->biotype() eq "Mt_rRNA" || $gene->biotype() eq "Mt_rRNA_pseudogene"
		|| $gene->biotype() eq "Mt_tRNA" || $gene->biotype() eq "Mt_tRNA_pseudogene"
		|| $gene->biotype() eq "tRNA" || $gene->biotype() eq "tRNA_pseudogene"
		|| $gene->biotype() eq "scRNA" || $gene->biotype() eq "scRNA_pseudogene"
		|| $gene->biotype eq "ncRNA" || $gene->biotype eq "ncRNA_pseudogene"
		|| $gene->biotype eq "3prime_overlapping_ncrna") {
	    $desc = "small_ncRNA:".$gene->biotype();
	}elsif ($gene->biotype() =~ /lincRNA/i){
	    $desc = "lincRNA:".$gene->biotype();
	}elsif ($gene->biotype() eq "antisense" || $gene->biotype() eq "sense_intronic"
		|| $gene->biotype() eq "processed_transcript"){
	    $desc = "other_lncRNA:".$gene->biotype();
	}elsif ($gene->biotype() =~ /non_coding/ 
		|| $gene->biotype() eq "misc_RNA" || $gene->biotype() eq "misc_RNA_pseudogene"
		|| $gene->biotype() eq "ncrna_host" || $gene->biotype() eq "sense_overlapping"
		|| $gene->biotype() eq "retained_intron"
		|| $gene->biotype() eq "processed_pseudogene" || $gene->biotype() eq "unprocessed_pseudogene"
		|| $gene->biotype() eq "transcribed_processed_pseudogene" 
		|| $gene->biotype() eq "transcribed_unprocessed_pseudogene" 
		|| $gene->biotype() eq "retrotransposed" || $gene->biotype() eq "unitary_pseudogene"
	    ){
	    $desc = "other_noncodingRNA:".$gene->biotype();
	}
    }
    my $hugo = defined $gene->external_name()? $gene->external_name():NONE ;

    my @exons_gene = @{ $gene->get_all_Exons() };
    my $nb_exons_gene = scalar @exons_gene;

    my $exon_rank_gene = 1;    
    my %exons;
    my %same_exons;
    foreach my $exon (@exons_gene){
	my $exon_id = $exon->stable_id() or die("exon id is required");
	my $exon_start = $exon->start() or die("exon start is required");
	my $exon_end = $exon->end() or die("exon end is required");
	# Sometimes, exons have the same START and END in ensembl for the same gene, so we correct that
	if (!defined $same_exons{$exon_start."@".$exon_end}){
	    $exons{$exon_id}{'START'} = $exon_start; 
	    $exons{$exon_id}{'END'} = $exon_end; 
	    $exons{$exon_id}{'RANK'} = $exon_rank_gene;
	    $exons{$exon_id}{'REDUNDANT'} = NONE;
	    $exon_rank_gene++;
	    $same_exons{$exon_start."@".$exon_end} = $exon_id;
    	}else{
	    $exons{$exon_id}{'REDUNDANT'} = $same_exons{$exon_start."@".$exon_end};
	}
    }
    
    my @transcripts = @{ $gene->get_all_Transcripts() };
    my $nb_transcripts = scalar @transcripts; 

    # First, write genes features 
    print $output "$chr\t$source\tgene\t$gene_start\t$gene_end\t.\t$strand\t.\tID=$gene_id\;Name=$hugo\;transcripts_nb=$nb_transcripts\;exons_nb=$nb_exons_gene\n" unless ($gene_start eq NONE);

    my ($five_start,$five_end,$three_start,$three_end);
    foreach my $transcript (@transcripts){
	my $transcript_id = $transcript->stable_id() or die("transcript id is required");
	# Sometimes, transcript_id is the same that gene_id but it is a problem so we check that
	if ($transcript_id eq $gene_id){
	    $transcript_id .= ".mRNA";
	}
	my $transcript_start = $transcript->start() or die("transcript start is required");
	my $transcript_end = $transcript->end() or die("transcript end is required");
	my $cds_start = defined $transcript->coding_region_start() ? $transcript->coding_region_start():NONE;
	my $cds_end = defined $transcript->coding_region_end() ? $transcript->coding_region_end():NONE;
	if ($strand eq "+"){	
	    $five_end = ($cds_start =~ m/^\d+$/ && $cds_start > $transcript_start) ? ($cds_start -1):NONE; 
	    $five_start = ($five_end eq NONE) ? NONE:$transcript_start; 
	    $three_start = ($cds_end =~ m/^\d+$/ && $cds_end < $transcript_end) ? ($cds_end +1):NONE;
	    $three_end = ($three_start eq NONE) ? NONE:$transcript_end;
	}else{
	    $three_end = ($cds_start =~ m/^\d+$/ && $cds_start > $transcript_start) ? ($cds_start -1):NONE; 
	    $three_start = ($three_end eq NONE) ? NONE:$transcript_start; 
	    $five_start = ($cds_end =~ m/^\d+$/ && $cds_end < $transcript_end) ? ($cds_end +1):NONE;
	    $five_end = ($five_start eq NONE) ? NONE:$transcript_end;
	}
	my @exons_transcript = @{ $transcript->get_all_Exons() };
	my $nb_exons_transcript = scalar @exons_transcript;

	foreach my $exon (@exons_transcript){
	    my $exon_id = $exon->stable_id() or die("exon id is required");
	    if (defined $exons{$exon_id}){
		# correct exon_id if the current exon is redundant
		if ($exons{$exon_id}{'REDUNDANT'} ne NONE){
		    $exon_id = $exons{$exon_id}{'REDUNDANT'};
		}
                # we add the transcript_id as a parent of the exon_id
		if (defined $exons{$exon_id}{'PARENT'}){
		    $exons{$exon_id}{'PARENT'} .= ",$transcript_id";
		}else{
		    $exons{$exon_id}{'PARENT'} .= "$transcript_id";
		} 
	    }else{
		die("the exon \"$exon_id\" is necessarily associated to a gene");
	    }
	}
	
	# Second, write transcripts features 
	print $output "$chr\t$source\tfive\t$five_start\t$five_end\t.\t$strand\t.\tID=$transcript_id.five\;Parent=$transcript_id\n" unless ($five_start eq NONE);
	print $output "$chr\t$source\tcds\t$cds_start\t$cds_end\t.\t$strand\t.\tID=$transcript_id.cds\;Parent=$transcript_id\n" unless ($cds_start eq NONE);
	print $output "$chr\t$source\tthree\t$three_start\t$three_end\t.\t$strand\t.\tID=$transcript_id.three\;Parent=$transcript_id\n" unless ($three_start eq NONE);
	print $output "$chr\t$source\tmRNA\t$transcript_start\t$transcript_end\t.\t$strand\t.\tID=$transcript_id\;Parent=$gene_id\;exons_nb=$nb_exons_transcript\;type=$desc\n";
    }
    
    # we must delete redundant exons before writing exons features
    foreach my $exon_id (keys %exons){
	if ($exons{$exon_id}{'REDUNDANT'} ne NONE){
	    delete $exons{$exon_id};
	}
    } 

    # Finally, write exons features 
    foreach my $exon_id (sort {$exons{$a}{'RANK'} <=> $exons{$b}{'RANK'}}
			 keys %exons){
	my $exon_start = $exons{$exon_id}{'START'};
	my $exon_end = $exons{$exon_id}{'END'};
	my $exon_parents = $exons{$exon_id}{'PARENT'};
	my $exon_rank = $exons{$exon_id}{'RANK'};
	print $output "$chr\t$source\texon\t$exon_start\t$exon_end\t.\t$strand\t.\tID=$exon_id\;Parent=$exon_parents\;exon_rank=$exon_rank\n";
    }

}

$output->close();
