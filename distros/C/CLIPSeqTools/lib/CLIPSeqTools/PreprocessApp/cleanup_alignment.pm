=head1 NAME

CLIPSeqTools::PreprocessApp::cleanup_alignment -  Keep a single record for multimappers, sort and collapse similar STAR alignments.

=head1 SYNOPSIS

clipseqtools-preprocess cleanup_alignment [options/parameters]

=head1 DESCRIPTION

Clean up STAR aligner SAM output file. Will keep only a single record for
multimappers. Will sort STAR alignments and collapse alignments with same
sequence and position. Will add an XC:i tag for each alignment with the
copy number - the number of collapsed alignments.

=head1 OPTIONS

  Input.
    --sam <Str>            SAM file with STAR alignments.

  Output
    --o_prefix <Str>       output path prefix. Script will create and add
                           extension to path. [Default: ./]

  Other options.
    -v --verbose           print progress lines and extra information.
    -h -? --usage --help   print help message

=cut

package CLIPSeqTools::PreprocessApp::cleanup_alignment;
$CLIPSeqTools::PreprocessApp::cleanup_alignment::VERSION = '0.1.10';

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
option 'sam' => (
	is            => 'rw',
	isa           => 'Str',
	required      => 1,
	documentation => 'SAM file with STAR alignments.',
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

	warn "Starting job: cleanup_alignment\n";

	warn "Validating arguments\n" if $self->verbose;
	$self->validate_args();

	warn "Creating output path\n" if $self->verbose;
	$self->make_path_for_output_prefix();

	warn "Keeping a single copy for multimappers\n" if $self->verbose;
	$self->keep_single_copy_for_multimappers($self->sam, $self->o_prefix.'single.sam');

	warn "Sorting SAM file\n" if $self->verbose;
	$self->sort_sam($self->o_prefix.'single.sam', $self->o_prefix.'single.sorted.sam');

	warn "Collapsing alignments with same sequence and position. Adding XC:i tag with copy number\n" if $self->verbose;
	$self->collapse_sorted_sam($self->o_prefix.'single.sorted.sam', $self->o_prefix.'single.sorted.collapsed.sam');
}

sub keep_single_copy_for_multimappers {
	my ($self, $in_sam, $out_sam) = @_;

	open (my $IN, '<', $in_sam);
	open (my $OUT, '>', $out_sam);
	while (my $line = <$IN>) {
		if ($line !~ /^@/) {
			my $flag = (split(/\t/, $line))[1];
			next if $flag & 256;
		}
		print $OUT $line;
	}
	close $IN;
	close $OUT;
}

sub sort_sam {
	my ($self, $in_sam, $out_sam) = @_;

	my $cmd = "(grep \"^@\" $in_sam && grep -v \"^@\" $in_sam | sort -k 3,3 -k 4,4n) > $out_sam";
	system "$cmd";
}

sub collapse_sorted_sam {
	my ($self, $in_sam, $out_sam) = @_;

	my %coords_counts;
	my ($current_pos, $current_rname);

	open (my $IN_SAM, '<', $in_sam);
	open (my $OUT_SAM, '>', $out_sam);
	while (my $line = <$IN_SAM>) {
		chomp $line;

		# Skip the header
		if ($line =~ /^@/) {
			say $OUT_SAM $line;
			next;
		};

		# Split the SAM line and get required fields
		my @fields = split(/\t/, $line);
		my ($flag, $rname, $pos, $seq) = @fields[1, 2, 3, 9];
		$fields[10] = '*'; # delete quality

		# Skip unmapped reads
		next if $flag & 4; #unmapped

		# Get the strand
		my $strand = $flag & 16 ? -1 : 1;

		# Check if a similar record has been read
		if (defined $current_pos and defined $current_rname and ($rname eq $current_rname) and ($pos == $current_pos)) {
			if (!exists $coords_counts{$strand}{$seq}) {
				$coords_counts{$strand}{$seq} = [@fields, 0]; # Q: Why use hash?
				                                              # A: SAM is sorted by rname and pos.
				                                              #    Different sequences that map at exactly the same position could come in a non consecutive manner.
				                                              #    Obviously we don't want to collapse these into one.
			}

			$coords_counts{$strand}{$seq}->[-1]++;
		}
		else {
			if (defined $current_pos and defined $current_rname) {
				_print_records_found_on_previous_pos(\%coords_counts, $OUT_SAM);
			}
			%coords_counts = ();
			$current_rname = $rname;
			$current_pos = $pos;

			$coords_counts{$strand}{$seq} = [@fields, 1];
		}
	}
	_print_records_found_on_previous_pos(\%coords_counts, $OUT_SAM);
	close $IN_SAM;
	close $OUT_SAM;
}


#######################################################################
########################   Private Functions   ########################
#######################################################################
sub _print_records_found_on_previous_pos {
	my ($stored_records_hashref, $OUT) = @_;

	foreach my $strand (keys %{$stored_records_hashref}) {
		foreach my $seq (keys %{$stored_records_hashref->{$strand}}) {
			my $fields = $stored_records_hashref->{$strand}->{$seq};
			$fields->[-1] = join(':', 'XC', 'i', $fields->[-1]);
			say $OUT join("\t", @$fields);
		}
	}
}


1;
