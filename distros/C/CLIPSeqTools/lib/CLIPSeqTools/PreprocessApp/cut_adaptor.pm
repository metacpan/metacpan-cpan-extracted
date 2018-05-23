=head1 NAME

CLIPSeqTools::PreprocessApp::cut_adaptor - Cut the adaptor sequence from the 3'end of reads.

=head1 SYNOPSIS

clipseqtools-preprocess cut_adaptor [options/parameters]

=head1 DESCRIPTION

Cut the adaptor sequence from the 3'end of reads.
Uses cutadapt to remove the adaptor which is usually ligated at the 3'end of reads.

=head1 OPTIONS

  Input.
    --fastq <Str>          FastQ file with the reads.
    --adaptor <Str>        adaptor sequence.

  Output
    --o_prefix <Str>       output path prefix. Script will create and add
                           extension to path. [Default: ./]

  Other options.
    --cutadapt_path <Str>  path to cutadapt executable. [Default: cutadapt].
    -v --verbose           print progress lines and extra information.
    -h -? --usage --help   print help message

=cut

package CLIPSeqTools::PreprocessApp::cut_adaptor;
$CLIPSeqTools::PreprocessApp::cut_adaptor::VERSION = '0.1.8';

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
	
	warn "Starting job: cut_adaptor\n";
	
	warn "Validating arguments\n" if $self->verbose;
	$self->validate_args();
	
	warn "Preparing command\n" if $self->verbose;
	my $cmd = join(' ',
		$self->cutadapt_path,
		$self->fastq,
		'-n 3',
		'-m 15',
		'-e 0.25',
		'-a ' . $self->adaptor,
		'-o ' . $self->o_prefix . 'reads.adtrim.fastq'
	);
	
	warn "Creating output path\n" if $self->verbose;
	$self->make_path_for_output_prefix();
	
	warn "Running cutadapt\n" if $self->verbose;
	warn "Command: $cmd\n" if $self->verbose;
	system "$cmd";
}


1;
