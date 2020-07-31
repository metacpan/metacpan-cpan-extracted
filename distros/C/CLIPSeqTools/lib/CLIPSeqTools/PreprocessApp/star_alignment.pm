=head1 NAME

CLIPSeqTools::PreprocessApp::star_alignment - Do reads alignment with STAR.

=head1 SYNOPSIS

clipseqtools-preprocess star_alignment [options/parameters]

=head1 DESCRIPTION

Do reads alignment with STAR.

=head1 OPTIONS

  Input.
    --fastq <Str>          FastQ file with the reads.
    --star_genome <Str>    directory with STAR genome index

  Output
    --o_prefix <Str>       output path prefix. Script will create and add
                           extension to path. [Default: ./]

  Other options.
    --star_path <Str>      path to STAR executable. [Default: STAR].
    --threads <Int>        number of threads to use. [Default: 4].
    -v --verbose           print progress lines and extra information.
    -h -? --usage --help   print help message

=cut

package CLIPSeqTools::PreprocessApp::star_alignment;
$CLIPSeqTools::PreprocessApp::star_alignment::VERSION = '0.1.10';

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

#######################################################################
##########################   Consume Roles   ##########################
#######################################################################
with
	"CLIPSeqTools::Role::Option::OutputPrefix" => {
		-alias    => { validate_args => '_validate_args_for_output_prefix' },
		-excludes => 'validate_args',
	};


#######################################################################
########################   Interface Methods   ########################
#######################################################################
sub validate_args {
	my ($self) = @_;

	$self->_validate_args_for_output_prefix;
}

sub run {
	my ($self) = @_;

	warn "Starting job: star_alignment\n";

	warn "Validating arguments\n" if $self->verbose;
	$self->validate_args();

	warn "Preparing command\n" if $self->verbose;
	my $cmd = join(' ',
		$self->star_path,
		'--genomeDir ' . $self->star_genome,
		'--readFilesIn ' . $self->fastq,
		'--runThreadN ' . $self->threads,
		'--outSAMattributes All',
		'--outFilterMultimapScoreRange 0',
		'--alignIntronMax 50000',
		'--outFilterMatchNmin 15',
		'--outFilterMatchNminOverLread 0.9',
		'--outFileNamePrefix ' . $self->o_prefix. 'star_',
	);

	if ($self->fastq =~ /\.gz$/) {
		$cmd .= ' ' . '--readFilesCommand zcat';
	}

	warn "Creating output path\n" if $self->verbose;
	$self->make_path_for_output_prefix();

	warn "Running cutadapt\n" if $self->verbose;
	warn "Command: $cmd\n" if $self->verbose;
	system "$cmd";
}


1;
