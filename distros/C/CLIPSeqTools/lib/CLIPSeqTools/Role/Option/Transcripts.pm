=head1 NAME

CLIPSeqTools::Role::Option::Transcripts - Role to enable reading a GTF file with transcripts from the command line

=head1 SYNOPSIS

Role to enable reading a GTF file with transcripts from the command line

  Defines options.
      -gtf <Str>               GTF file for transcripts.

  Provides attributes.
      transcript_collection    the collection of transcripts that is read from the GTF

=cut


package CLIPSeqTools::Role::Option::Transcripts;
$CLIPSeqTools::Role::Option::Transcripts::VERSION = '0.1.7';

#######################################################################
#######################   Load External modules   #####################
#######################################################################
use Modern::Perl;
use MooseX::App::Role;


#######################################################################
########################   Load GenOO modules   #######################
#######################################################################
use GenOO::TranscriptCollection::Factory;


#######################################################################
#######################   Command line options   ######################
#######################################################################
option 'gtf' => (
	is            => 'rw',
	isa           => 'Str',
	required      => 1,
	documentation => 'GTF file with transcripts',
);


#######################################################################
######################   Interface Attributes   #######################
#######################################################################
has 'transcript_collection' => (
	is        => 'rw',
	builder   => '_read_transcript_collection',
	lazy      => 1,
);


#######################################################################
########################   Interface Methods   ########################
#######################################################################
sub validate_args {}


#######################################################################
#########################   Private Methods   #########################
#######################################################################
sub _read_transcript_collection {
	my ($self) = @_;
	
	return GenOO::TranscriptCollection::Factory->create('GTF', {
		file => $self->gtf
	})->read_collection;
}

1;
