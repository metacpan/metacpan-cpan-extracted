=head1 NAME

CLIPSeqTools::App::distribution_on_introns_exons - Measure read distribution
on exons and introns.

=head1 SYNOPSIS

clipseqtools distribution_on_introns_exons [options/parameters]

=head1 DESCRIPTION

Measure the distribution of reads along exons and introns.
Will split the exons and introns of coding transcripts in bins and measure the
read density in each bin. Will keep only unique introns and exons foreach
location. The read copy number is not used in this analysis.

=head1 OPTIONS

  Input options for library.
    --driver <Str>         driver for database connection (eg. mysql,
                           SQLite).
    --database <Str>       database name or path to database file for file
                           based databases (eg. SQLite).
    --table <Str>          database table.
    --host <Str>           hostname for database connection.
    --user <Str>           username for database connection.
    --password <Str>       password for database connection.
    --records_class <Str>  type of records stored in database.
    --filter <Filter>      filter library. May be used multiple times.
                           Syntax: column_name="pattern"
                           e.g. keep reads with deletions AND not repeat
                                masked AND longer than 31
                                --filter deletion="def"
                                --filter rmsk="undef" .
                                --filter query_length=">31".
                           Operators: >, >=, <, <=, =, !=, def, undef

  Other input
    --gtf <Str>            GTF file with genes/transcripts.

  Output
    --o_prefix <Str>       output path prefix. Script will create and add
                           extension to path. [Default: ./]

  Other options.
    --bins <Int>           number of bins each element is split into.
                           [Default: 10]
    --length_thres <Int>   genic elements shorter than this are skipped.
                           [Default: 300]
    --plot                 call plotting script to create plots.
    -v --verbose           print progress lines and extra information.
    -h -? --usage --help   print help message

=cut

package CLIPSeqTools::App::distribution_on_introns_exons;
$CLIPSeqTools::App::distribution_on_introns_exons::VERSION = '0.1.7';

# Make it an app command
use MooseX::App::Command;
extends 'CLIPSeqTools::App';


#######################################################################
#######################   Load External modules   #####################
#######################################################################
use Modern::Perl;
use autodie;
use namespace::autoclean;


#######################################################################
#######################   Command line options   ######################
#######################################################################
option 'bins' => (
	is            => 'rw',
	isa           => 'Int',
	default       => 5,
	documentation => 'number of bins each element is split into.',
);

option 'length_thres' => (
	is            => 'rw',
	isa           => 'Int',
	default       => 300,
	documentation => 'genic elements shorter than this are skipped.',
);


#######################################################################
##########################   Consume Roles   ##########################
#######################################################################
with
	"CLIPSeqTools::Role::Option::Library" => {
		-alias    => { validate_args => '_validate_args_for_library' },
		-excludes => 'validate_args',
	},
	"CLIPSeqTools::Role::Option::Genes" => {
		-alias    => { validate_args => '_validate_args_for_genes' },
		-excludes => 'validate_args',
	},
	"CLIPSeqTools::Role::Option::Plot" => {
		-alias    => { validate_args => '_validate_args_for_plot' },
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

	$self->_validate_args_for_library;
	$self->_validate_args_for_genes;
	$self->_validate_args_for_plot;
	$self->_validate_args_for_output_prefix;
}

sub run {
	my ($self) = @_;

	warn "Starting analysis: distribution_on_introns_exons\n";

	warn "Validating arguments\n" if $self->verbose;
	$self->validate_args();

	warn "Creating transcript collection\n" if $self->verbose;
	my $transcript_collection = $self->transcript_collection;
	my @coding_transcripts =
		grep{$_->is_coding} $transcript_collection->all_records;

	warn "Creating reads collection\n" if $self->verbose;
	my $reads_col = $self->reads_collection;

	warn "Measuring reads in bins of introns/exons\n" if $self->verbose;
	my (%exons, %introns);
	foreach my $transcript (@coding_transcripts) {
		foreach my $exon (@{$transcript->exons}) {
			next if exists $exons{$exon->location};

			my $exon_counts = copy_number_in_bins_of_element(
				$exon, $reads_col, $self->bins);
			$exon->extra({counts => $exon_counts});
			$exons{$exon->location} = $exon;
		}

		foreach my $intron (@{$transcript->introns}) {
			next if exists $introns{$intron->location};

			my $intron_counts = copy_number_in_bins_of_element(
				$intron, $reads_col, $self->bins);
			$intron->extra({counts => $intron_counts});
			$introns{$intron->location} = $intron;
		}
	};
	warn "Counted exons:   " . scalar(keys %exons)   . "\n" if $self->verbose;
	warn "Counted introns: " . scalar(keys %introns) . "\n" if $self->verbose;

	warn "Creating output path\n" if $self->verbose;
	$self->make_path_for_output_prefix();

	warn "Printing results\n" if $self->verbose;
	open (my $OUT, '>', $self->o_prefix.'distribution_on_introns_exons.tab');
	say $OUT join(
		"\t", 'element', 'location', (map {'bin_' . $_} (0..$self->bins-1)));
	foreach my $exon_loc (keys %exons) {
		my $exon = $exons{$exon_loc};
		say $OUT join(
			"\t", 'exon', $exon->location, @{$exon->extra->{counts}});
	}
	foreach my $intron_loc (keys %introns) {
		my $intron = $introns{$intron_loc};
		say $OUT join(
			"\t", 'intron', $intron->location, @{$intron->extra->{counts}});
	}

	if ($self->plot) {
		warn "Creating plot\n" if $self->verbose;
		CLIPSeqTools::PlotApp->initialize_command_class(
			'CLIPSeqTools::PlotApp::distribution_on_introns_exons',
			file     => $self->o_prefix.'distribution_on_introns_exons.tab',
			o_prefix => $self->o_prefix
		)->run();
	}
}


#######################################################################
############################   Functions   ############################
#######################################################################
sub copy_number_in_bins_of_element {
	my ($elm, $reads_col, $bins) = @_;

	my @counts = map{0} 0..$bins-1;
	my $max_length = $reads_col->longest_record->length;
	my $span = int($max_length / 2);

	$reads_col->foreach_contained_record_do(
		$elm->strand, $elm->chromosome, $elm->start-$span, $elm->stop+$span,
		sub {
			my ($record) = @_;

			my $record_mid = $record->mid_position;
			return 0 if (
				$record_mid < $elm->start or $record_mid > $elm->stop);

			my $bin = int($bins *
				(abs($elm->head_mid_distance_from($record)) / $elm->length));

			$counts[$bin] += 1; # $record->copy_number;
		});

	return \@counts;
}

1;
