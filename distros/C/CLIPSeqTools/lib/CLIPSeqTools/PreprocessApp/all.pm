=head1 NAME

CLIPSeqTools::PreprocessApp::all - Run all clipseqtools-preprocess analyses.

=head1 SYNOPSIS

clipseqtools-preprocess all [options/parameters]

=head1 DESCRIPTION

Runs all tools to process a CLIP-Seq FastQ file to a database compatible with clipseqtools.
Specifically it will:
1) Trim the adaptor sequence from the end of the reads.
2) Align the reads on a reference genome using STAR aligner.
3) Convert SAM file with alignments into an SQLite database table.
4) Annotate alignments with genic information.
5) Annotate alignments with Repeat Masker.
6) Annotate alignments with deletions.
7) Annotate alignments with conservation.

=head1 OPTIONS

  Input.
    --fastq <Str>          FastQ file with the reads.
    --adaptor <Str>        adaptor sequence.
    --star_genome <Str>    directory with STAR genome index.
    --rmsk <Str>           BED file with repeat masker regions.
    --gtf <Str>            GTF file with genes/transcripts.

  Output
    --o_prefix <Str>       output path prefix. Script will create and add
                           extension to path. Default: ./

  Other input
    --rname_sizes <Str>    file with sizes for reference alignment
                           sequences (rnames). Must be tab delimited
                           (chromosome\tsize) with one line per rname.
    --cons_dir <Str>       directory with phastCons or phyloP files.

  Other options.
    --cutadapt_path <Str>  path to cutadapt executable. [Default: cutadapt].
    --star_path <Str>      path to STAR executable. [Default: STAR].
    --threads <Int>        number of threads to use. [Default: 4].
    -v --verbose           print progress lines and extra information.
    -h -? --usage --help   print help message

=cut

package CLIPSeqTools::PreprocessApp::all;
$CLIPSeqTools::PreprocessApp::all::VERSION = '0.1.8';

# Make it an app command
use MooseX::App::Command;
extends 'CLIPSeqTools::PreprocessApp';


#######################################################################
#######################   Load External modules   #####################
#######################################################################
use Modern::Perl;
use autodie;
use namespace::autoclean;


#######################################################################
#######################   Command line options   ######################
#######################################################################
option 'fastq' => (
	is            => 'rw',
	isa           => 'Str',
	required      => 1,
	documentation => 'FastQ file with the reads.',
);

option 'adaptor' => (
	is            => 'rw',
	isa           => 'Str',
	required      => 1,
	documentation => 'adaptor sequence.',
);

option 'cutadapt_path' => (
	is            => 'rw',
	isa           => 'Str',
	default       => 'cutadapt',
	documentation => 'path to cutadapt executable.',
);

option 'star_genome' => (
	is            => 'rw',
	isa           => 'Str',
	required      => 1,
	documentation => 'directory with STAR genome index.',
);

option 'star_path' => (
	is            => 'rw',
	isa           => 'Str',
	default       => 'STAR',
	documentation => 'path to STAR executable.',
);

option 'threads' => (
	is            => 'rw',
	isa           => 'Int',
	default       => 4,
	documentation => 'number of threads to use.',
);

option 'rmsk' => (
	is            => 'rw',
	isa           => 'Str',
	required      => 1,
	documentation => 'BED file with repeat masker regions.',
);

option 'rname_sizes' => (
	is            => 'rw',
	isa           => 'Str',
	required      => 1,
	documentation => 'file with sizes for reference alignment sequences (rnames). Must be tab delimited (chromosome\tsize) with one line per rname.',
);

option 'cons_dir' => (
	is            => 'rw',
	isa           => 'Str',
	required      => 1,
	documentation => 'directory with phastCons or phyloP files.',
);


#######################################################################
##########################   Consume Roles   ##########################
#######################################################################
with
	"CLIPSeqTools::Role::Option::Genes" => {
		-alias    => { validate_args => '_validate_args_for_genes' },
		-excludes => 'validate_args',
	},
	"CLIPSeqTools::Role::Option::OutputPrefix" => {
		-alias    => { validate_args => '_validate_args_for_output_prefix' },
		-excludes => 'validate_args',
	};


#######################################################################
########################   Interface Methods   ########################
#######################################################################
sub validate_args {
	my ($self) = @_;

	$self->_validate_args_for_plot;
	$self->_validate_args_for_output_prefix;
}

sub run {
	my ($self) = @_;

	CLIPSeqTools::PreprocessApp->initialize_command_class('CLIPSeqTools::PreprocessApp::cut_adaptor',
		fastq         => $self->fastq,
		adaptor       => $self->adaptor,
		o_prefix      => $self->o_prefix,
		cutadapt_path => $self->cutadapt_path,
		verbose       => $self->verbose,
	)->run();

	CLIPSeqTools::PreprocessApp->initialize_command_class('CLIPSeqTools::PreprocessApp::star_alignment',
		fastq         => $self->o_prefix . 'reads.adtrim.fastq',
		star_genome   => $self->star_genome,
		o_prefix      => $self->o_prefix . 'reads.adtrim.',,
		star_path     => $self->star_path,
		threads       => $self->threads,
		verbose       => $self->verbose,
	)->run();

	CLIPSeqTools::PreprocessApp->initialize_command_class('CLIPSeqTools::PreprocessApp::cleanup_alignment',
		sam           => $self->o_prefix . 'reads.adtrim.star_Aligned.out.sam',
		o_prefix      => $self->o_prefix . 'reads.adtrim.star_Aligned.out.',
		verbose       => $self->verbose,
	)->run();

	CLIPSeqTools::PreprocessApp->initialize_command_class('CLIPSeqTools::PreprocessApp::sam_to_sqlite',
		sam_file      => $self->o_prefix . 'reads.adtrim.star_Aligned.out.single.sorted.collapsed.sam',
		database      => $self->o_prefix . 'reads.adtrim.star_Aligned.out.single.sorted.collapsed.db',
		table         => 'sample',
		drop          => 1,
		verbose       => $self->verbose,
	)->run();

	CLIPSeqTools::PreprocessApp->initialize_command_class('CLIPSeqTools::PreprocessApp::annotate_with_genic_elements',
		database      => $self->o_prefix.'reads.adtrim.star_Aligned.out.single.sorted.collapsed.db',
		table         => 'sample',
		gtf           => $self->gtf,
		drop          => 1,
		verbose       => $self->verbose,
	)->run();

	CLIPSeqTools::PreprocessApp->initialize_command_class('CLIPSeqTools::PreprocessApp::annotate_with_file',
		database      => $self->o_prefix.'reads.adtrim.star_Aligned.out.single.sorted.collapsed.db',
		table         => 'sample',
		a_file        => $self->rmsk,
		column        => 'rmsk',
		both_strands  => 1,
		verbose       => $self->verbose,
	)->run();

	CLIPSeqTools::PreprocessApp->initialize_command_class('CLIPSeqTools::PreprocessApp::annotate_with_deletions',
		database      => $self->o_prefix.'reads.adtrim.star_Aligned.out.single.sorted.collapsed.db',
		table         => 'sample',
		drop          => 1,
		verbose       => $self->verbose,
	)->run();

	CLIPSeqTools::PreprocessApp->initialize_command_class('CLIPSeqTools::PreprocessApp::annotate_with_conservation',
		database      => $self->o_prefix.'reads.adtrim.star_Aligned.out.single.sorted.collapsed.db',
		table         => 'sample',
		cons_dir      => $self->cons_dir,
		rname_sizes   => $self->rname_sizes,
		drop          => 1,
		verbose       => $self->verbose,
	)->run();
}

1;
