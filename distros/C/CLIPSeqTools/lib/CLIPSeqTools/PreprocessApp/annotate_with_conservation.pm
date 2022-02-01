=head1 NAME

CLIPSeqTools::PreprocessApp::annotate_with_conservation - Annotate alignments in a database table with conservation scores.

=head1 SYNOPSIS

clipseqtools-preprocess annotate_with_conservation [options/parameters]

=head1 DESCRIPTION

Annotate alignments in a database table with phastCons or phyloP
conservation scores. Adds a column named "conservation" with the average
conservation score for the nucleotides of each read.
To minimize storage needs, the conservation score is converted from
floating point number to integer by multiplying with 1000.

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
    --rname_sizes <Str>    file with sizes for reference alignment
                           sequences (rnames). Must be tab delimited
                           (chromosome\tsize) with one line per rname.
    --cons_dir <Str>       directory with phastCons or phyloP files.


  Database options.
    --drop                 drop column if it already exists (not
                           supported in SQlite).

  Other options.
    -v --verbose           print progress lines and extra information.
    -h -? --usage --help   print help message

=cut

package CLIPSeqTools::PreprocessApp::annotate_with_conservation;
$CLIPSeqTools::PreprocessApp::annotate_with_conservation::VERSION = '1.0.0';

# Make it an app command
use MooseX::App::Command;
extends 'CLIPSeqTools::PreprocessApp';


#######################################################################
#######################   Load External modules   #####################
#######################################################################
use Modern::Perl;
use autodie;
use namespace::autoclean;
use Try::Tiny;
use PDL::Lite; $PDL::BIGPDL = 0; $PDL::BIGPDL++; # enable huge pdls


#######################################################################
#######################   Command line options   ######################
#######################################################################
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

option 'drop' => (
	is            => 'rw',
	isa           => 'Bool',
	documentation => 'drop column if they already exist (not supported in SQlite).',
);


#######################################################################
##########################   Consume Roles   ##########################
#######################################################################
with
	"CLIPSeqTools::Role::Option::Library" => {
		-alias    => { validate_args => '_validate_args_for_library' },
		-excludes => 'validate_args',
	};


#######################################################################
########################   Interface Methods   ########################
#######################################################################
sub validate_args {
	my ($self) = @_;

	$self->_validate_args_for_library;
}

sub run {
	my ($self) = @_;

	warn "Starting: annotate_with_conservation\n";

	warn "Validating arguments\n" if $self->verbose;
	$self->validate_args();

	warn "Reading sizes for reference alignment sequences\n" if $self->verbose;
	my %rname_sizes = $self->read_rname_sizes;

	warn "Opening reads collection\n" if $self->verbose;
	my $reads_collection = $self->reads_collection;
	my @rnames = $reads_collection->rnames_for_all_strands;
	$reads_collection->schema->storage->debug(1) if $self->verbose > 1;

	warn "Creating new column conservation if required\n" if $self->verbose;
	$self->create_new_column_if_required($reads_collection);

	warn "Looping on annotation file to annotate records.\nThis might take a long time. Relax...\n" if $self->verbose;
	foreach my $rname (@rnames) {
		warn "Reading conservation data for $rname\n" if $self->verbose;
		my $pdl = $self->plylop_pdl_for($rname, $rname_sizes{$rname});
		if (!defined $pdl) {
			warn "Could not find conservation file for $rname. Skipping.\n";
			next;
		}

		warn "Annotating records for $rname\n" if $self->verbose;
		$reads_collection->schema->txn_do( sub {
			$reads_collection->foreach_record_on_rname_do($rname, sub {
				my ($record) = @_;

				my $record_plylop_avg = $pdl->slice([$record->start, $record->stop])->average();

				$record->conservation($record_plylop_avg);
				$record->update();

				return 0;
			});
		});
	}
}

sub create_new_column_if_required {
	my ($self, $reads_collection) = @_;

	if ($self->drop) {
		warn "Droping column conservation\n" if $self->verbose;
		try {
			$reads_collection->schema->storage->dbh_do( sub {
				my ($storage, $dbh, @cols) = @_;
				$dbh->do('ALTER TABLE '.$self->table.' DROP COLUMN conservation');
			});
		}
		catch {
			warn "Warning: Column could not be dropped.\n" if $self->verbose;
		};
	}

	try {
		warn "Creating column conservation\n" if $self->verbose;
		$reads_collection->schema->storage->dbh_do( sub {
			my ($storage, $dbh, @cols) = @_;
			$dbh->do('ALTER TABLE '.$self->table.' ADD COLUMN conservation INT(5)');
		});
	}
	catch {
		warn "Warning: Column creation failed. Maybe column already exist.\n" if $self->verbose;
		warn "$_\n"  if $self->verbose > 1;
	};

	# Make GenOO aware of the new column
	my $conservation_params = {
		data_type => 'decimal',
		is_numeric => 1
	};
	$reads_collection->resultset->result_source->add_columns('conservation' => $conservation_params);
	$reads_collection->resultset->result_class->add_columns('conservation' => $conservation_params);
	$reads_collection->resultset->result_class->register_column('conservation');
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

sub plylop_pdl_for {
	my ($self, $rname, $rname_size) = @_;

	my $pdl = PDL->zeros(PDL::short(), $rname_size);

	my @files = glob $self->cons_dir . '/' . $rname . '.*';
	die "More than one matching files for $rname" if @files > 1;
	my $file = $files[0];
	if (!defined $file) {
		return;
	}
	chomp $file;
	open (my $H, "gzip -dc $file |");

	my ($start, $step);
	while (my $line = $H->getline) {
		chomp $line;
		if ($line =~ /^fixedStep\schrom=(.+)\sstart=(.+)\sstep=(.+)/) { #fixedStep chrom=chr1 start=10918 step=1
			($start, $step) = ($2 - 1, $3);
		}
		else {
			my $piddle_tag_region = $pdl->slice([$start, $start + $step - 1]) .= int(1000 * $line);
			$start += $step;
		}
	}
	close $H;

	return $pdl;
}

1;
