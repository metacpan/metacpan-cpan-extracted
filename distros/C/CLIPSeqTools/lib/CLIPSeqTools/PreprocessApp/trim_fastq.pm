=head1 NAME

CLIPSeqTools::PreprocessApp::trim_fastq -  Trim N nucleotides from the start
and/or end of FASTQ sequences.

=head1 SYNOPSIS

clipseqtools-preprocess trim_fastq [options/parameters]

=head1 DESCRIPTION

Trim the sequences in a fastq file.
Removes N nucleotides from the start and/or end of each sequence.

=head1 OPTIONS

  Input.
    --fastq <Str>          FASTQ file with reads.
    --N_from_start <Int>   Number of nucleotides to trim from the start of
                           each sequence. [Default: 0]
    --N_from_end <Int>     Number of nucleotides to trim from the end of
                           each sequence. [Default: 0]

  Output
    --o_prefix <Str>       output path prefix. Script will create and add
                           extension to path. [Default: ./]

  Other options.
    -v --verbose           print progress lines and extra information.
    -h -? --usage --help   print help message

=cut

package CLIPSeqTools::PreprocessApp::trim_fastq;
$CLIPSeqTools::PreprocessApp::trim_fastq::VERSION = '0.1.9';

# Make it an app command
use MooseX::App::Command;
use GenOO::Data::File::FASTQ;
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
	documentation => 'FASTQ file with sequences.',
);

option 'N_from_start' => (
	is            => 'rw',
	isa           => 'Int',
	required      => 0,
	default       => 0,
	documentation => 'Number of nucleotides to trim from the start of each sequence [Default: 0]',
);

option 'N_from_end' => (
	is            => 'rw',
	isa           => 'Int',
	required      => 0,
	default       => 0,
	documentation => 'Number of nucleotides to trim from the end of each sequence [Default: 0]',
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

	warn "Starting job: trim_fastq\n";

	warn "Validating arguments\n" if $self->verbose;
	$self->validate_args();

	warn "Creating output path\n" if $self->verbose;
	$self->make_path_for_output_prefix();

	warn "Trimming FASTQ\n" if $self->verbose;
	$self->trim_fastq(
		$self->fastq, $self->N_from_start, $self->N_from_end,
		$self->o_prefix.'trimmed.fastq');
}

sub trim_fastq {
	my ($self, $fastq, $Nstart, $Nend, $out) = @_;

	open (my $OUT, ">", $out);

	my $class = "GenOO::Data::File::FASTQ";
	my $fp = $class->new(file => $fastq);

	while (my $rec = $fp->next_record) {
		my $seq = $rec->sequence;
		my $qual = $rec->quality;

		if ($Nstart >= length($seq)){next;}
		if ($Nstart > 0){
			$seq = substr($seq, $Nstart);
			$qual = substr($qual, $Nstart);
		}

		if ($Nend >= length($seq)){next;}
		if ($Nend > 0){
			$seq = substr($seq, 0, (0 - $Nend));
			$qual = substr($qual, 0, (0 - $Nend));
		}
		$rec->sequence($seq);
		$rec->quality($qual);
		print $OUT $rec->to_string."\n";
	}

}


#######################################################################
########################   Private Functions   ########################
#######################################################################

1;
