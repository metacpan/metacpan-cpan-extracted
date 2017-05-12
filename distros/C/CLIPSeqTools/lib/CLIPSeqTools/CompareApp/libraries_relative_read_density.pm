=head1 NAME

CLIPSeqTools::CompareApp::libraries_relative_read_density - Measure read
density around the reads of a reference library

=head1 SYNOPSIS

clipseqtools-compare libraries_relative_read_density [options/parameters]

=head1 DESCRIPTION

For a library A and a reference library B, measure the density of A reads
around the middle position of B reads.

=head1 OPTIONS

  Input options for library.
    --driver <Str>          driver for database connection (eg. mysql,
                            SQLite).
    --database <Str>        database name or path to database file for
                            file based databases (eg. SQLite).
    --table <Str>           database table.
    --host <Str>            hostname for database connection.
    --user <Str>            username for database connection.
    --password <Str>        password for database connection.
    --records_class <Str>   type of records stored in database.
    --filter <Filter>       filter library. May be used multiple times.
                            Syntax: column_name="pattern"
                            e.g. keep reads with deletions AND not repeat
                                 masked AND longer than 31
                                 --filter deletion="def"
                                 --filter rmsk="undef"
                                 --filter query_length=">31"
                            Operators: >, >=, <, <=, =, !=, def, undef

  Input options for reference library.
    --r_driver <Str>        driver for database connection (eg. mysql,
                            SQLite).
    --r_database <Str>      database name or path to database file for
                            file based databases (eg. SQLite).
    --r_table <Str>         database table.
    --r_host <Str>          hostname for database connection.
    --r_user <Str>          username for database connection.
    --r_password <Str>      password for database connection.
    --r_records_class <Str> type of records stored in database.
    --r_filter <Filter>     same as filter but for reference library.

  Other input.
    --rname_sizes <Str>    file with sizes for reference alignment
                           sequences (rnames). Must be tab delimited
                           (chromosome\tsize) with one line per rname.

  Output
    --o_prefix <Str>       output path prefix. Script will create and add
                           extension to path. [Default: ./]

  Other options.
    --span <Int>           the region around reference reads where density
                           is measured. [Default: 25]
    --plot                 call plotting script to create plots.
    -v --verbose           print progress lines and extra information.
    -h -? --usage --help   print help message

=cut

package CLIPSeqTools::CompareApp::libraries_relative_read_density;
$CLIPSeqTools::CompareApp::libraries_relative_read_density::VERSION = '0.1.7';

# Make it an app command
use MooseX::App::Command;
extends 'CLIPSeqTools::CompareApp';


#######################################################################
#######################   Load External modules   #####################
#######################################################################
use Modern::Perl;
use autodie;
use namespace::autoclean;
use PDL::Lite; $PDL::BIGPDL = 0; $PDL::BIGPDL++; # enable huge pdls


#######################################################################
#######################   Command line options   ######################
#######################################################################
option 'rname_sizes' => (
	is            => 'rw',
	isa           => 'Str',
	required      => 1,
	documentation => 'file with sizes for reference alignment sequences '.
						'(rnames). Must be tab delimited (chromosome\tsize) '.
						'with one line per rname.',
);

option 'span' => (
	is            => 'rw',
	isa           => 'Int',
	default       => 25,
	documentation => 'the region around reference reads where density is '.
						'measured.',
);


#######################################################################
##########################   Consume Roles   ##########################
#######################################################################
with
	"CLIPSeqTools::Role::Option::Library" => {
		-alias    => { validate_args => '_validate_args_for_library' },
		-excludes => 'validate_args',
	},
	"CLIPSeqTools::Role::Option::ReferenceLibrary" => {
		-alias    => { validate_args => '_validate_args_for_reference_library' },
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
	$self->_validate_args_for_reference_library;
	$self->_validate_args_for_plot;
	$self->_validate_args_for_output_prefix;
}

sub run {
	my ($self) = @_;

	warn "Starting analysis: libraries_relative_read_density\n";

	warn "Validating arguments\n" if $self->verbose;
	$self->validate_args();

	warn "Reading sizes for reference alignment sequences\n" if $self->verbose;
	my %rname_sizes = $self->read_rname_sizes;

	warn "Creating reads collection\n" if $self->verbose;
	my $reads_collection = $self->reads_collection;
	my @rnames = $reads_collection->rnames_for_all_strands;

	warn "Creating reference reads collection\n" if $self->verbose;
	my $r_reads_collection = $self->r_reads_collection;

	warn "Measuring read density around reference\n" if $self->verbose;
	my $size = 2*$self->span+1;
	my $counts_with_cn_sense     = PDL->zeros(PDL::longlong(), $size);
	my $counts_with_cn_antisense = PDL->zeros(PDL::longlong(), $size);
	my $counts_no_cn_sense       = PDL->zeros(PDL::longlong(), $size);
	my $counts_no_cn_antisense   = PDL->zeros(PDL::longlong(), $size);
	foreach my $rname (@rnames) {
		warn "Annotate $rname with primary records\n" if $self->verbose;
		my $rname_size = $rname_sizes{$rname};
		my $pdl_plus_with_cn  = PDL->zeros(PDL::long(), $rname_size);
		my $pdl_plus_no_cn    = PDL->zeros(PDL::long(), $rname_size);
		my $pdl_minus_with_cn = PDL->zeros(PDL::long(), $rname_size);
		my $pdl_minus_no_cn   = PDL->zeros(PDL::long(), $rname_size);
		$reads_collection->foreach_record_on_rname_do($rname, sub {
			my ($p_record) = @_;

			my $coords = [$p_record->start, $p_record->stop];
			my $cn = $p_record->copy_number;
			my $strand = $p_record->strand;

			if ($strand == 1) {
				$pdl_plus_with_cn->slice($coords) += $cn;
				$pdl_plus_no_cn->slice($coords)   += 1;
			}
			elsif ($strand == -1) {
				$pdl_minus_with_cn->slice($coords) += $cn;
				$pdl_minus_no_cn->slice($coords)   += 1;
			}

			return 0;
		});

		warn "Measuring density around reference ($rname)\n" if $self->verbose;
		$r_reads_collection->foreach_record_on_rname_do($rname, sub {
			my ($r_record) = @_;

			my $ref_pos     = $r_record->mid_position;
			my $begin       = $ref_pos - $self->span;
			my $end         = $ref_pos + $self->span;
			my $cn = $r_record->copy_number;
			my $strand      = $r_record->strand;

			return 0 if $begin < 0 or $end >= $rname_size;

			if ($strand == 1) {
				my $coords = [$begin, $end];
				$counts_with_cn_sense     +=
					PDL::longlong($pdl_plus_with_cn->slice($coords))  * $cn;
				$counts_no_cn_sense       +=
					PDL::longlong($pdl_plus_no_cn->slice($coords));
				$counts_with_cn_antisense +=
					PDL::longlong($pdl_minus_with_cn->slice($coords)) * $cn;
				$counts_no_cn_antisense   +=
					PDL::longlong($pdl_minus_no_cn->slice($coords));
			}
			elsif ($strand == -1) {
				my $coords = [$end, $begin]; #reverse
				$counts_with_cn_sense     +=
					PDL::longlong($pdl_minus_with_cn->slice($coords)) * $cn;
				$counts_no_cn_sense       +=
					PDL::longlong($pdl_minus_no_cn->slice($coords));
				$counts_with_cn_antisense +=
					PDL::longlong($pdl_plus_with_cn->slice($coords))  * $cn;
				$counts_no_cn_antisense   +=
					PDL::longlong($pdl_plus_no_cn->slice($coords));
			}

			return 0;
		});
	}

	warn "Creating output path\n" if $self->verbose;
	$self->make_path_for_output_prefix();

	warn "Printing results\n" if $self->verbose;
	open (my $OUT, '>', $self->o_prefix.'libraries_relative_read_density.tab');
	say $OUT join("\t", 'relative_position', 'counts_with_copy_number_sense',
		'counts_no_copy_number_sense', 'counts_with_copy_number_antisense',
		'counts_no_copy_number_antisense');
	for (my $distance = 0-$self->span; $distance<=$self->span; $distance++) {
		my $idx = $distance + $self->span;
		say $OUT join("\t", $distance, $counts_with_cn_sense->at($idx),
			$counts_no_cn_sense->at($idx),
			$counts_with_cn_antisense->at($idx),
			$counts_no_cn_antisense->at($idx));
	}
	close $OUT;

	if ($self->plot) {
		warn "Creating plot\n" if $self->verbose;
		CLIPSeqTools::PlotApp->initialize_command_class(
			'CLIPSeqTools::PlotApp::libraries_relative_read_density',
			file     => $self->o_prefix.'libraries_relative_read_density.tab',
			o_prefix => $self->o_prefix
		)->run();
	}
}

sub read_rname_sizes {
	my ($self) = @_;

	my %rname_size;
	open (my $CHRSIZE, '<', $self->rname_sizes);
	while (my $line = <$CHRSIZE>) {
		chomp $line;
		my ($chr, $size) = split(/\t/, $line);
		$rname_size{$chr} = $size;
	}
	close $CHRSIZE;
	return %rname_size;
}

1;
