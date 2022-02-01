=head1 NAME

CLIPSeqTools::PreprocessApp::collapse_fastq -  Keep a single record for
identical sequences

=head1 SYNOPSIS

clipseqtools-preprocess collapse_fastq [options/parameters]

=head1 DESCRIPTION

Collapse a fastq file. Will keep only a single record for each group of
identical sequences.

=head1 OPTIONS

  Input.
    --fastq <Str>          FASTQ file with sequences
    --memsave <Int>        Memory saving factor. 0 is the fastest but uses the
                           most memory. 1 uses ~1/4 of memory and ~4x time.
                           Each step (2, 3, 4 etc) changes memory and time
                           by a factor of 4. If this option is used the output
                           will be grouped by first N nucleotides.
                           [Default: 0]

  Output
    --o_prefix <Str>       output path prefix. Script will create and add
                           extension to path. [Default: ./]

  Other options.
    -v --verbose           print progress lines and extra information.
    -h -? --usage --help   print help message

=cut

package CLIPSeqTools::PreprocessApp::collapse_fastq;
$CLIPSeqTools::PreprocessApp::collapse_fastq::VERSION = '1.0.0';

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

option 'memsave' => (
	is            => 'rw',
	isa           => 'Int',
	required      => 0,
	default       => 0,
	documentation => 'Memory saving factor. 0 is the fastest but uses the most memory. 1 uses ~1/4 of memory and ~4x time. Each step (2, 3, 4 etc) changes memory and time by a factor of 4. If this option is used the output will be grouped by first N nucleotides.',
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

	warn "Starting job: collapse_fastq\n";

	warn "Validating arguments\n" if $self->verbose;
	$self->validate_args();

	warn "Creating output path\n" if $self->verbose;
	$self->make_path_for_output_prefix();

	warn "Collapsing FASTQ\n" if $self->verbose;
	$self->collapse_fastq($self->fastq, $self->memsave, $self->o_prefix.'collapsed.fastq');
}

sub collapse_fastq {
	my ($self, $fastq, $k, $out) = @_;
	my @kmers;
	open (OUT, ">", $out);

	if ($k == 0){
		push @kmers, '.';
	}
	else {
		@kmers = _permuteK($k);
	}

	my $count = 0;
	foreach my $kmer (@kmers){
		my $fp = GenOO::Data::File::FASTQ->new(file => $fastq);
		my %already_found = ();
		while (my $rec = $fp->next_record) {
			my $seq = $rec->sequence;
			if ($seq =~ /![ATGC]/){
				next;
			}
			if ($seq !~ /^$kmer/){
				next;
			}
			if (exists $already_found{$seq}){
				next;
			}
			else {
				$already_found{$seq} = 1;
				print OUT $rec->to_string."\n";
			}
		}
	}

	#for non ATGC nucleotide reads
	my $fp = GenOO::Data::File::FASTQ->new(file => $fastq);
	my %already_found = ();
	while (my $rec = $fp->next_record) {
		my $seq = $rec->sequence;
		unless ($seq =~ /![ATGC]/){
			next;
		}
		if (exists $already_found{$seq}){
			next;
		}
		else {
			$already_found{$seq} = 1;
			print OUT $rec->to_string."\n";
		}
	}

	close OUT;
}


#######################################################################
########################   Private Functions   ########################
#######################################################################
sub _permuteK {
     my $k = shift;
     my $alphabet = shift || [ qw( A T G C ) ];
     my @bases = @$alphabet;
     my @words = @bases;
     for ( 1 .. --$k ) {
         my @newwords;
         foreach my $w (@words) {
             foreach my $b (@bases) {
                 push (@newwords, $w.$b);
             }
         }
         @words = @newwords;
     }
     return @words;
 }


1;
