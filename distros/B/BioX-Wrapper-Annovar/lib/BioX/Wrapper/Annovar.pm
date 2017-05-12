package BioX::Wrapper::Annovar;

#use 5.006;

use Moose;
use File::Find::Rule;
use File::Basename;
use File::Path qw(make_path remove_tree);
use File::Find::Rule;
use Cwd;
use IO::Uncompress::Gunzip;
use Data::Dumper;

require Vcf;

extends 'BioX::Wrapper';
with 'MooseX::Getopt';
with 'MooseX::Getopt::Usage';

=head1 NAME

BioX::Wrapper::Annovar - A wrapper around the annovar annotation pipeline

=head1 VERSION

Version 0.06

=cut

our $VERSION = '0.40';


=head1 SYNOPSIS

    annovar-wrapper.pl --vcfs file1.vcf,file2.vcf --annovardb_path /path/to/annovar/dbs

This module is a wrapper around the popular annotation tool, annovar. http://www.openbioinformatics.org/annovar/ . The commands generated are taken straight from the documentation. In addition, there is an option to reannotate using vcf-annotate from vcftools.

It takes as its input a list or directory of vcf files, bgzipped and tabixed or not, and uses annovar to create annotation files. These multianno table files can be optionally reannotated into the vcf file. This script does not actually execute any commands, only writes them to STDOUT for the user to run as they wish.

It comes with an executable script annovar-wrapper.pl. This should be sufficient for most of your needs, but if you wish to overwrite methods you can always do so in the usual Moose fashion.

    #!/usr/bin/env perl

    package Main;

    use Moose;
    extends 'BioX::Wrapper::Annovar';

    BioX::Wrapper::Annovar->new_with_options->run;

    sub method_to_override {
        my $self = shift;

        #dostuff
    };

    before 'method' => sub  {
        my $self = shift;

        #dostuff
    };

    has '+variable' => (
        #things to add to variable declaration
    );

    #or

    has 'variable' => (
        #override variable declaration
    );

    1;

Please see the Moose::Manual::MethodModifiers for more information.

=head1 Prerequisites

This module requires the annovar download. The easiest thing to do is to put the annovar scripts in your ENV{PATH}, but if you choose not to do this you can also pass in the location with

annovar-wrapper.pl --tableannovar_path /path/to/table_annovar.pl --convert2annovar_path /path/to/convert2annovar.pl

It requires Vcf.pm, which comes with vcftools.

Vcftools is publicly available for download.  http://vcftools.sourceforge.net/.

    export PERL5LIB=$PERL5LIB:path_to_vcftools/perl

If you wish to you reannotate the vcf file you need to have bgzip and tabix installed, and have the executables in vcftools in your path.

    export PATH=$PATH:path_to_vcftools

=head1 Generate an Example

To generate an example you can run the following commands

    tabix -h ftp://ftp.1000genomes.ebi.ac.uk/vol1/ftp/release/20100804/ALL.2of4intersection.20100804.genotypes.vcf.gz 2:39967768-40000000 > test.vcf
    bgzip test.vcf
    tabix test.vcf.gz
    vcf-subset -c HG00098,HG00100,HG00106,HG00112,HG00114 test.vcf.gz | bgzip -c > out.vcf.gz
    tabix out.vcf.gz
    rm test.vcf.gz
    rm test.vcf.gz.tbi

    annovar-wrapper.pl --vcfs out.vcf.gz --annovar_dbs refGene --annovar_fun g --outdir annovar_out --annovardb_path /path/to/annovar/dbs > my_cmds.sh

There is more detail on the example in the pod files.

=cut

=head1 Variables

=cut

=head2 Annovar Options

=cut

=head3 tableannovar_path

You can put the location of the annovar scripts in your ENV{PATH}, and the default is fine. If annovar is not in your PATH, please supply the location.

=cut

has 'tableannovar_path' => (
    is => 'rw',
    isa => 'Str',
    required => 1,
    default => "table_annovar.pl"
);

=head3 convert2annovar_path

You can put the location of the annovar scripts in your ENV{PATH}, and the default is fine. If annovar is not in your PATH, please supply the location

=cut

has 'convert2annovar_path' => (
    is => 'rw',
    isa => 'Str',
    required => 1,
    default => "convert2annovar.pl"
);

=head3 annovardb_path

Path to your annovar databases

=cut

has 'annovardb_path' => (
    is => 'rw',
    isa => 'Str',
    default => '/data/apps/software/annovar/hg19',
    required => 1,
);

=head3 buildver

Its probably hg19 or hg18

=cut

has 'buildver' => (
    is => 'rw',
    isa => 'Str',
    default => 'hg19',
    required => 1,
);

=head3 convert2annovar_opts

Assumes vcf version 4 and that you want to convert all samples

Not using --allsample on a multisample vcf is untested and will probably break the whole pipeline

=cut

has 'convert2annovar_opts' => (
    is => 'rw',
    isa => 'Str',
    default => '-format vcf4 --allsample',
);

=head3 annovar_dbs

These are pretty much all the databases listed on

http://www.openbioinformatics.org/annovar/annovar_download.html for hg19 that I tested as working

    #Download databases with

    cd path_to_annovar_dir
    ./annotate_variation.pl --buildver hg19 -downdb -webfrom annovar esp6500si_aa hg19/

    #Option is an ArrayRef, and can be given as either

    --annovar_dbs cg46,cg69,nci60

    #or

    --annovar_dbs cg46 --annovar_dbs cg69 --annovar_dbs nci60

=cut

#TODO
#Add in a hashref so I don't have to remember the list
#The following are redundant within other databases
#esp are in popfreq_all
#esp6500si_aa
#esp6500si_ea
#ljb23 are in ljb23_all
#ljb23_fathmm
#ljb23_gerp++
#ljb23_lrt
#ljb23_ma
#ljb23_metalr
#ljb23_metasvm
#ljb23_mt
#ljb23_phylop
#ljb23_pp2hdiv
#ljb23_pp2hvar
#ljb23_sift
#ljb23_siphy
#ljb2_pp2hvar
#Leaving out cg46
#
## The following have been tested
# snp138NonFlagged,snp138,popfreq_all,cg69,cosmic68wgs,clinvar_20140211,gwasCatalog,caddgt20,phastConsElements46way,gerp++elem,wgEncodeBroadHmmGm12878HMM,wgEncodeUwDnaseGm12878HotspotsRep2,ljb23_all,refGene

has 'annovar_dbs' => (
    is => 'rw',
    isa => 'ArrayRef',
    required => 0,
    default => sub {
        return [qw(snp138NonFlagged
snp138
popfreq_all
cg69
cosmic68wgs
clinvar_20140211
gwasCatalog
caddgt20
phastConsElements46way
gerp++elem
wgEncodeBroadHmmGm12878HMM
wgEncodeUwDnaseGm12878HotspotsRep2
ljb23_all
refGene
)]
    }
);

=head3 annovar_fun

Functions of the individual databases can be found at

What function your DB may already be listed otherwise it is probably listed in the URLS under Annotation: Gene-Based, Region-Based, or Filter-Based

Functions must be given in the corresponding order of your annovar_dbs

    #Option is an ArrayRef, and can be given as either

    --annovar_fun f,f,g

    #or

    --annovar_fun f --annovar_fun f --annovar_fun g

=cut

has 'annovar_fun' => (
    is => 'rw',
    isa => 'ArrayRef',
    required => 0,
    default => sub {
        return [qw(f
f
f
f
f
f
r
f
r
f
r
r
f
g)]
    }
);

=head3 annovar_cols

Some database annotations generate multiple columns. For reannotating the vcf we need to know what these columns are. Below are the columns generated for the databases given in annovar_dbs

To add give a hashref of array

=cut

has 'annovar_cols' => (
    is => 'rw',
    isa => 'HashRef',
    required => 0,
    default => sub {
        my $href = {};
        #Old table_annovar.pl script
#        $href->{popfreq_max} = ["PopFreqMax"];
#        $href->{popfreq_all} = ["PopFreqMax","1000G2012APR_ALL","1000G2012APR_AFR","1000G2012APR_AMR","1000G2012APR_ASN","1000G2012APR_EUR","ESP6500si_AA","ESP6500si_EA","CG46","NCI60","SNP137","COSMIC65","DISEASE"];
#        $href->{refGene} = ["Func.refGene","Gene.refGene","ExonicFunc.refGene","AAChange.refGene"];
#	    $href->{ljb_all} = [ qw/LJB_PhyloP LJB_PhyloP_Pred LJB_SIFT LJB_SIFT_Pred LJB_PolyPhen2 LJB_PolyPhen2_Pred LJB_LRT LJB_LRT_Pred LJB_MutationTaster LJB_MutationTaster_Pred LJB_GERP++/ ];
#	    $href->{ljb2_all} = [ qw/LJB2_SIFT LJB2_PolyPhen2_HDIV LJB2_PP2_HDIV_Pred LJB2_PolyPhen2_HVAR LJB2_PolyPhen2_HVAR_Pred LJB2_LRT LJB2_LRT_Pred LJB2_MutationTaster LJB2_MutationTaster_Pred LJB_MutationAssessor LJB_MutationAssessor_Pred LJB2_FATHMM LJB2_GERP++ LJB2_PhyloP LJB2_SiPhy/ ];
#	$href->{ljb23_all} = [ qw/LJB23_SIFT_score LJB23_SIFT_score_converted LJB23_SIFT_pred LJB23_Polyphen2_HDIV_score LJB23_Polyphen2_HDIV_pred LJB23_Polyphen2_HVAR_score LJB23_Polyphen2_HVAR_pred LJB23_LRT_score LJB23_LRT_score_converted LJB23_LRT_pred LJB23_MutationTaster_score LJB23_MutationTaster_score_converted LJB23_MutationTaster_pred LJB23_MutationAssessor_score LJB23_MutationAssessor_score_converted LJB23_MutationAssessor_pred LJB23_FATHMM_score LJB23_FATHMM_score_converted LJB23_FATHMM_pred LJB23_RadialSVM_score LJB23_RadialSVM_score_converted LJB23_RadialSVM_pred LJB23_LR_score LJB23_LR_pred LJB23_GERP++ LJB23_PhyloP LJB23_SiPhy/ ];

#        #Which one?
#        #$href->{refGene} = ["Func.refGene","Gene.refGene", "ExonicFunc.refGene","AAChange.refGene"];
        $href->{refGene} = ["Func.refGene","Gene.refGene","GeneDetail.refGene", "ExonicFunc.refGene","AAChange.refGene"];
        $href->{ljb_all} = [ qw/LJB_PhyloP LJB_PhyloP_Pred LJB_SIFT LJB_SIFT_Pred LJB_PolyPhen2 LJB_PolyPhen2_Pred LJB_LRT LJB_LRT_Pred LJB_MutationTaster LJB_MutationTaster_Pred LJB_GERPPP/ ];
        $href->{ljb2_all} = [ qw/LJB2_SIFT LJB2_PolyPhen2_HDIV LJB2_PP2_HDIV_Pred LJB2_PolyPhen2_HVAR LJB2_PolyPhen2_HVAR_Pred LJB2_LRT LJB2_LRT_Pred LJB2_MutationTaster LJB2_MutationTaster_Pred LJB_MutationAssessor LJB_MutationAssessor_Pred LJB2_FATHMM LJB2_GERPPP LJB2_PhyloP LJB2_SiPhy/ ];
        $href->{ljb23_all} = [ qw/LJB23_SIFT_score LJB23_SIFT_score_converted LJB23_SIFT_pred LJB23_Polyphen2_HDIV_score LJB23_Polyphen2_HDIV_pred LJB23_Polyphen2_HVAR_score LJB23_Polyphen2_HVAR_pred LJB23_LRT_score LJB23_LRT_score_converted LJB23_LRT_pred LJB23_MutationTaster_score LJB23_MutationTaster_score_converted LJB23_MutationTaster_pred LJB23_MutationAssessor_score LJB23_MutationAssessor_score_converted LJB23_MutationAssessor_pred LJB23_FATHMM_score LJB23_FATHMM_score_converted LJB23_FATHMM_pred LJB23_RadialSVM_score LJB23_RadialSVM_score_converted LJB23_RadialSVM_pred LJB23_LR_score LJB23_LR_pred LJB23_GERPPP LJB23_PhyloP LJB23_SiPhy/ ];
        $href->{popfreq_all} = [ qw/PopFreqMax 1000G2012APR_ALL 1000G2012APR_AFR 1000G2012APR_AMR 1000G2012APR_ASN 1000G2012APR_EUR ESP6500si_ALL ESP6500si_AA ESP6500si_EA CG46/ ];
        return $href;
    }
);

=head3 vcfs

VCF files can be given individually as well.

    #Option is an ArrayRef and can be given as either

    --vcfs 1.vcf,2.vcf,3.vcfs

    #or

    --vcfs 1.vcf --vcfs 2.vcf --vcfs 3.vcf

Don't mix the methods

=cut

has 'vcfs' => (
    is => 'rw',
    isa => 'ArrayRef',
    required => 0,
);



=head3 annotate_vcf

Use vcf-annotate from VCF tools to annotate the VCF file

This does not overwrite the original VCF file, but instead creates a new one

To turn this off

    annovar-wrapper.pl --annotate_vcf 0

=cut

has 'annotate_vcf' => (
    is => 'rw',
    isa => 'Bool',
    default => 1,
    required => 1,
);

=head2 Internal Variables

You shouldn't need to change these

=cut

has 'samples' => (
    is => 'rw',
    isa => 'HashRef',
    required => 0,
    default => sub { return {} },
);

has 'orig_samples' => (
    is => 'rw',
    isa => 'HashRef',
    required => 0,
    default => sub { return {} },
);

has 'file' => (
    traits  => ['String'],
    is => 'rw',
    isa => 'Str',
    required => 0,
    default => sub { return "" },
    handles => {
        match_file     => 'match',
    },
);

has 'fname' => (
    is => 'rw',
    isa => 'Str',
    required => 0,
    default => sub { return "" },
);

=head1 SUBROUTINES/METHODS

=cut

=head2 run

Subroutine that starts everything off

=cut

sub run {
    my($self) = @_;

    $self->print_opts;

    $self->check_files;
    $self->parse_commands;
    $self->find_vcfs;
    $self->write_annovar;
}

#Moving this over to BioX::Wrapper base class
#=head2 print_opts

#Print out the command line options

#=cut

#sub print_opts {
    #my($self) = @_;

    #print "## This file was generated with the options\n";
    #for(my $x=0; $x<=$#ARGV; $x++){
        #next unless $ARGV[$x];
        #print "#\t$ARGV[$x]\t".$ARGV[$x+1]."\n";
        #$x++;
    #}
    #print "\n";
#}

=head2 check_files

Check to make sure either an indir or vcfs are supplied

=cut

sub check_files{
    my($self) = @_;
    my($t);

    die print "Must specificy an indirectory or vcfs!\n" if (!$self->indir && !$self->vcfs);

    if($self->indir){
        $t = $self->indir;
        $t =~ s/\/$//g;
        $self->indir($t);
    }

    $t = $self->outdir;
    $t =~ s/\/$//g;
    $t = $t."/annovar-wrapper";
    $self->outdir($t);

    #make the outdir
    make_path($self->outdir) if ! -d $self->outdir;
    make_path($self->outdir."/annovar_interim") if ! -d $self->outdir."/annovar_interim";
    make_path($self->outdir."/annovar_final") if ! -d $self->outdir."/annovar_final";
}

=head2 find_vcfs

Use File::Find::Rule to find the vcfs

=cut

sub find_vcfs{
    my($self) = @_;

    return if $self->vcfs;
    $self->vcfs([]);

    my $rule = File::Find::Rule->file->name(qr/(vcf|vcf\.gz)$/)->start( $self->indir);
    while ( defined ( my $file = $rule->match ) ) {
        push(@{$self->vcfs}, $file);
    }

    die print "No vcfs were found!\n" unless $self->vcfs;
}

=head2 parse_commands

Allow for giving ArrayRef either in the usual fashion or with commas

=cut

sub parse_commands{
    my($self) = @_;

    if($#{$self->annovar_dbs} == 0){
        my @tmp = split(",", $self->annovar_dbs->[0]);
        $self->annovar_dbs(\@tmp);
    }
    if($#{$self->annovar_fun} == 0){
        my @tmp = split(",", $self->annovar_fun->[0]);
        $self->annovar_fun(\@tmp);
    }

    return unless $self->vcfs;
    if($#{$self->vcfs} == 0){
        my @tmp = split(",", $self->vcfs->[0]);
        $self->vcfs(\@tmp);
    }
}

=head2 write_annovar

Write the commands that

Convert the vcf file to annovar input
Do the annotations
Reannotate the vcf - if you want

=cut

sub write_annovar{
    my($self) = @_;

    die print "Dbs are ".scalar @{$self->annovar_dbs}."\nand Funcs are ".scalar @{$self->annovar_fun}." \n" unless scalar @{$self->annovar_dbs} == scalar @{$self->annovar_fun};

#    #Convert vcf to annovar
    print "## Converting to annovar input\n\n";
    foreach my $file (@{$self->vcfs}){
        print "## Processing file $file\n\n";

        $self->file($file);
        my $tname = basename($self->file);
        $tname =~ s/\.vcf$|\.vcf\.gz$//;
        $self->fname($tname);
#        $self->fname(basename($self->file));
        $self->get_samples;
        $self->convert_annovar;

    }
    print "## Wait for all convert commands to complete\n";
    print "wait\n\n";

#    #Annotate annovar input

    $self->iter_vcfs('table_annovar');

    print "## Wait for all table commands to complete\n";
    print "wait\n\n";

#    #Annotate the VCF
#    #This is only relevant for putting it back into vcfs

    return unless $self->annotate_vcf;

    $self->iter_vcfs('gen_descr');

    print "## Wait for file copying bgzip and tabix to finish...\n";
    print "wait\n\n";

    $self->iter_vcfs('gen_annot');

    print "## Wait for all vcf-annotate commands to complete\n";
    print "wait\n\n";

    $self->iter_vcfs('merge_vcfs');

}

=head2 iter_vcfs

Iterate over the vcfs with some changes for lookups

=cut

sub iter_vcfs{
#    my $self = shift;
    my($self, $fun) = @_;

    foreach my $file (@{$self->vcfs}){
        $self->file($file);
        my $tname = basename($self->file);
        $tname =~ s/\.vcf$|\.vcf\.gz$//;
        $self->fname($tname);
#        $self->fname(basename($self->file));
        #Make this a parameter of the script
        $self->$fun;
    }

}

=head2 get_samples

Using VCF tools get the samples listed per vcf file

Supports files that are bgzipped or not

Sample names are stripped of all non alphanumeric characters.

=cut

sub get_samples{
    my($self) = @_;

    my(@samples, $vcf, $out, $fh);

#This doesn't work in large vcf files, end up with funny blocks
#    if($self->match_file(qr/gz$/)){
#        $fh = new IO::Uncompress::Gunzip $self->file or warn "## File handle didn't work for gzipped file ".$self->file."\n\n";
#    }
#    else{
#        $fh = new IO::File $self->file, "r" or warn "## File handle didn't work for ".$self->file."\n\n";
#    }

#    next unless $fh;

    $vcf = Vcf->new(file => $self->file);
    $vcf->parse_header();
    (@samples) = $vcf->get_samples();

#    #TODO Have this in a proper debug msg
#    print "##Before transform samples are :\n##".join("\n##", @samples)."\n";

    #Keep the original samples names for subsetting the vcf
    my(@tmp) = @samples;
    $self->orig_samples->{$self->file} = \@tmp;

    #Must keep this the same as annovar!
#    #I think annovar got rid of these in the most recent implementation
#    2014-12-20 Downloaded new annovar
#    @samples = map { s/[^A-Za-z0-9\-\.]//g; $_ } @samples;
#    @samples = map { s/^\.//g; $_ } @samples;

#    #TODO Have this in a proper debug msg
#    print "##After transform samples are :\n##".join("\n##", @samples)."\n";
    $vcf->close();

#    #TODO Put a warning msg here
    die print "There are no samples!\n" unless @samples;

    $self->samples->{$self->file} = \@samples;

    print "##Original samples names are :\n##".join("\n##", @{$self->orig_samples->{$self->file}})."\n";
    print "##Annovar samples names are :\n##".join("\n##", @{$self->samples->{$self->file}})."\n";
}

=head2 convert_annovar

Print out the command to print the convert2annovar commands

=cut

sub convert_annovar{
    my($self) = @_;

    print $self->convert2annovar_path." ".$self->convert2annovar_opts." ".$self->file." \\\n--outfile ".$self->outdir."/".$self->fname.".annovar\n\n";
}

=head2 table_annovar

Print out the commands to generate the annotation using table_annovar.pl command.

=cut

sub table_annovar{
    my($self) = @_;

    print "## Generating annotations\n\n";
    foreach my $sample (@{$self->samples->{$self->file}}){
        print "## Processing sample $sample\n";
        print $self->tableannovar_path." ".$self->outdir."/".$self->fname.".annovar.$sample.avinput \\\n ".$self->annovardb_path." --buildver ".$self->buildver." \\\n -protocol ".join(",", @{$self->annovar_dbs})." \\\n -operation ".join(",", @{$self->annovar_fun})." \\\n -nastring NA --outfile ".$self->outdir."/".$self->fname.".annovar.$sample \\\n";
        print "&& find ".$self->outdir."/ |grep ".$self->outdir."/".$self->fname.".annovar.$sample | grep -v \"multianno\" | xargs -i -t mv {} ".$self->outdir."/annovar_interim \\\n";
        print "&& find ".$self->outdir."/ |grep ".$self->outdir."/".$self->fname.".annovar.$sample | grep \"avinput\$\" | xargs -i -t mv {} ".$self->outdir."/annovar_interim \\\n";
        print "&& find ".$self->outdir."/ |grep ".$self->outdir."/".$self->fname.".annovar.$sample | grep \"multianno\" | xargs -i -t mv {} ".$self->outdir."/annovar_final\n\n";
    }

}

=head2 vcf_annotate

Generate the commands to annotate the vcf file using vcf-annotate

=cut

sub vcf_annotate{
    my($self) = @_;

    $self->gen_descr;
    $self->gen_annot;


    $self->merge_vcfs;
}

=head2 gen_descr

Bgzip, tabix, all of vcftools,  and sort must be in your PATH for these to work.


There are two parts to this command.

The first prepares the annotation file.

1. The annotation file is backed up just in case
2. The annotation file is sorted, because I had some problems with sorting
3. The annotation file is bgzipped, as required by vcf-annotate
4. The annotation file is tabix indexed using the special commands -s 1 -b 2 -e 3

The second writes out the vcf-annotate commands

Example with RefGene
zcat ../../variants.vcf.gz | vcf-annotate -a sorted.annotation.gz \
    -d key=INFO,ID=SAMPLEID_Func_refGene,Number=0,Type=String,Description='SAMPLEID Annovar Func_refGene' \
    -d key=INFO,ID=SAMPLEID_Gene_refGene,Number=0,Type=String,Description='SAMPLEID Annovar Gene_refGene' \
    -d key=INFO,ID=SAMPLEID_ExonicFun_refGene,Number=0,Type=String,Description='SAMPLEID Annovar ExonicFun_refGene' \
    -d key=INFO,ID=SAMPLEID_AAChange_refGene,Number=0,Type=String,Description='SAMPLEID Annovar AAChange_refGene' \
    -c CHROM,FROM,TO,-,-,INFO/SAMPLEID_Func_refGene,INFO/SAMPLEID_Gene_refGene,INFO/SAMPLEID_ExonicFun_refGene,INFO/SAMPLEID_AAChange_refGene > SAMPLEID.annotated.vcf

=cut

sub gen_descr{
    my($self) = @_;

    print "##Prepare to reannotate VCF files\n\n";

    make_path($self->outdir."/vcf-annotate_interim") if ! -d $self->outdir."/vcf-annotate_interim";
    make_path($self->outdir."/vcf-annotate_final") if ! -d $self->outdir."/vcf-annotate_final";

    foreach my $sample (@{$self->samples->{$self->file}}){
        print "cp ".$self->outdir."/annovar_final/".$self->fname.".annovar.$sample.hg19_multianno.txt \\\n";
        print $self->outdir."/vcf-annotate_interim/".$self->fname.".annovar.$sample.hg19_multianno.txt \\\n";
        print "&& sed -i 's/;/,/;s/=/->/;s/GERP++/GERPPP/;s/+/P/'g ".$self->outdir."/vcf-annotate_interim/".$self->fname.".annovar.$sample.hg19_multianno.txt \\\n";
        print "&& sort -k1,1 -k2,2n ".$self->outdir."/vcf-annotate_interim/".$self->fname.".annovar.$sample.hg19_multianno.txt > ";
        print $self->outdir."/vcf-annotate_interim/".$self->fname.".sorted.annovar.$sample.hg19_multianno.txt \\\n";
        print "&& bgzip -f ".$self->outdir."/vcf-annotate_interim/".$self->fname.".sorted.annovar.$sample.hg19_multianno.txt \\\n";
        print "&& tabix -s 1 -b 2 -e 3 ".$self->outdir."/vcf-annotate_interim/".$self->fname.".sorted.annovar.$sample.hg19_multianno.txt.gz \n\n";
    }

}

=head2 gen_annot

=cut

sub gen_annot {
    my $self = shift;

    print "##Reannotate VCF files\n\n";
    foreach my $sample (@{$self->samples->{$self->file}}){
        if($self->match_file(qr/gz$/)){
            print "zcat ".$self->file." | ";
        }
        else{
            print "cat ".$self->file." | ";
        }
        print "vcf-annotate -a ".$self->outdir."/vcf-annotate_interim/".$self->fname.".sorted.annovar.$sample.hg19_multianno.txt.gz \\\n";

        foreach my $db (@{$self->annovar_dbs}){
            if(exists $self->annovar_cols->{$db}){
                my $tmp = $self->annovar_cols->{$db};

                #Test this!!!
                $db =~ s/\+/P/g;
                $db =~ s/\W/_/g;

                foreach my $t (@$tmp){
                    $t =~ s/\+/P/g;
                    $t =~ s/\W/_/g;
                    print <<EOF;
                -d key=INFO,ID=$sample.annovar.$db.$t,Number=0,Type=String,Description='Annovar $sample $db $t' \\
EOF
                }
            }
            else{
                print <<EOF;
                -d key=INFO,ID=$sample.annovar.$db,Number=0,Type=String,Description='Annovar gen $sample $db' \\
EOF
            }

        }

        $self->gen_cols($sample);
    }

}

=head2 gen_cols

Generate the -c portion of the vcf-annotate command

=cut

sub gen_cols{
    my($self, $sample) = @_;

    my $cols = "-c CHROM,FROM,TO,-,-";

    foreach my $db (@{$self->annovar_dbs}){
        if(exists $self->annovar_cols->{$db}){
            my $tmp = $self->annovar_cols->{$db};

            foreach my $t (@$tmp){
                $cols .= ",INFO/$sample.annovar.$db.$t";
            }
        }
        else{
            $cols .= ",INFO/$sample.annovar.$db";
        }

    }

    print $cols." | bgzip -f -c > ".$self->outdir."/vcf-annotate_final/".$self->fname.".$sample.annovar.vcf.gz && \\\n";
    print "tabix -p vcf ".$self->outdir."/vcf-annotate_final/".$self->fname.".$sample.annovar.vcf.gz\n\n";

}

=head2 merge_vcfs

There is one vcf-annotated file per sample, so merge those at the the end to get a multisample file using vcf-merge

=cut

sub merge_vcfs {
    my($self) = @_;

    return if scalar @{$self->samples->{$self->file}} == 1;

    print "##Merge single sample VCF files\n\n";

    print "vcf-merge \\\n";
    foreach my $sample (@{$self->samples->{$self->file}}){
        print $self->outdir."/vcf-annotate_final/".$self->fname.".$sample.annovar.vcf.gz \\\n";
    }
    print " | bgzip -f -c > ".$self->outdir."/vcf-annotate_interim/".$self->fname.".allsamples.annovar.vcf.gz \\\n";
    print "&& tabix -p vcf ".$self->outdir."/vcf-annotate_interim/".$self->fname.".allsamples.annovar.vcf.gz\n";

    print "\nwait\n\n";

    $self->subset_vcfs();

}

=head2 subset_vcfs

vcf-merge used in this fashion will create a lot of redundant columns, because it wants to assume all sample names are unique

Straight from the vcftools documentation

vcf-subset -c NA0001,NA0002 file.vcf.gz | bgzip -c > out.vcf.gz

=cut

sub subset_vcfs {
    my($self) = @_;

    print "##Subsetting the files to get rid of redundant info\n\n";

    my $str = join(",", @{$self->orig_samples->{$self->file}});

    print "vcf-subset -c $str ".$self->outdir."/vcf-annotate_interim/".$self->fname.".allsamples.annovar.vcf.gz | bgzip -f -c > ".$self->outdir."/vcf-annotate_final/".$self->fname.".allsamples.nonredundant.annovar.vcf.gz \\\n";
    print "&& tabix -p vcf ".$self->outdir."/vcf-annotate_final/".$self->fname.".allsamples.nonredundant.annovar.vcf.gz\n";

    print "## Finished processing file ".$self->file."\n\n";
}



=head1 AUTHOR

Jillian Rowe, C<< <jillian.e.rowe at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-annovar-wrapper at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Annovar-Wrapper>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Annovar::Wrapper


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Annovar-Wrapper>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Annovar-Wrapper>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Annovar-Wrapper>

=item * Search CPAN

L<http://search.cpan.org/dist/Annovar-Wrapper/>

=back


=head1 ACKNOWLEDGEMENTS

This module is a wrapper around the well developed annovar pipeline. The
commands come straight from the documentation.

This module was originally developed at and for Weill Cornell Medical College
in Qatar within ITS Advanced Computing Team and scientific input from Khalid
Fahkro. With approval from WCMC-Q, this information was generalized and put on
github, for which the authors would like to express their gratitude.

=head1 LICENSE AND COPYRIGHT

Copyright 2014 Weill Cornell Medical College Qatar.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

1; # End of Annovar::Wrapper
