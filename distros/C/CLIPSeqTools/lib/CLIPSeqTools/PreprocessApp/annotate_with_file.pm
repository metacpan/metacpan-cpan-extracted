=head1 NAME

CLIPSeqTools::PreprocessApp::annotate_with_file - Annotate alignments in a database table with regions from a BED/SAM file.

=head1 SYNOPSIS

clipseqtools-preprocess annotate_with_file [options/parameters]

=head1 DESCRIPTION

Annotate alignments in a database table with regions from a BED/SAM file.
Adds a user defined column that will be NOT NULL if an alignment is contained within a region from the file and NULL otherwise.

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
    --a_type <Str>         type of file with annotation regions (i.e. BED,
                           SAM).
    --a_file <Str>         file with annotation regions.

  Database options.
    --drop                 drop column if it already exists (not
                           supported in SQlite).

  Other options.
    --column <Str>         name for the new annotation column.
    --both_strands         annotate both strands irrespective of the
                           region strand specified in the file. May be
                           useful for repeats where only one strand is
                           usually provided.
    -v --verbose           print progress lines and extra information.
    -h -? --usage --help   print help message

=cut

package CLIPSeqTools::PreprocessApp::annotate_with_file;
$CLIPSeqTools::PreprocessApp::annotate_with_file::VERSION = '0.1.10';

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


#######################################################################
#######################   Command line options   ######################
#######################################################################
option 'a_type' => (
	is            => 'rw',
	isa           => 'Str',
	default       => 'BED',
	documentation => 'type of file with annotation regions (ie. BED, SAM).',
);

option 'a_file' => (
	is            => 'rw',
	isa           => 'Str',
	required      => 1,
	documentation => 'file with annotation regions.',
);

option 'column' => (
	is            => 'rw',
	isa           => 'Str',
	required      => 1,
	documentation => 'name for the new annotation column.',
);

option 'drop' => (
	is            => 'rw',
	isa           => 'Bool',
	documentation => 'drop columns if they already exist (not supported in SQlite).',
);

option 'both_strands' => (
	is            => 'rw',
	isa           => 'Bool',
	documentation => 'annotate both strands irrespective of the region strand specified in the file. May be useful for repeats where only one strand is usually provided.',
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
	
	warn "Starting: annotate_with_file\n";
	
	warn "Validating arguments\n" if $self->verbose;
	$self->validate_args();

	warn "Opening annotations file\n" if $self->verbose;
	my $a_class = 'GenOO::Data::File::'.$self->a_type;
	eval 'require ' . $a_class;
	my $a_file_parser = $a_class->new(file => $self->a_file);

	warn "Opening reads collection\n" if $self->verbose;
	my $reads_collection = $self->reads_collection;
	my $reads_rs = $reads_collection->resultset;

	if ($self->drop) {
		warn "Droping column ".$self->column."\n" if $self->verbose;
		try {
			$reads_collection->schema->storage->dbh_do( sub {
				my ($storage, $dbh, @cols) = @_;
				$dbh->do('ALTER TABLE '.$self->table.' DROP COLUMN '.$self->column);
			});
		};
	}

	try {
		warn "Creating column ".$self->column."\n" if $self->verbose;
		$reads_collection->schema->storage->dbh_do( sub {
			my ($storage, $dbh, @cols) = @_;
			$dbh->do('ALTER TABLE '.$self->table.' ADD COLUMN '.$self->column.' INT(1)');
		});
	} catch {
		warn "Warning: Column creation failed. Maybe column already exist.\n" if $self->verbose;
		warn "$_\n"  if $self->verbose > 1;
	};

	warn "Looping on annotation file to annotate records.\nThis might take a long time. Relax...\n" if $self->verbose;
	$reads_collection->schema->txn_do( sub {
		while (my $record = $a_file_parser->next_record) {
			my $search_hs = {
				rname         => $record->rname,
				start         => { '-between' => [$record->start, $record->stop] },
				stop          => { '-between' => [$record->start, $record->stop] },
			};
			$search_hs->{strand} = $record->strand if !$self->both_strands;
			
			$reads_rs->search($search_hs)->update({$self->column => 1});
			
			warn " Parsed records: ".$a_file_parser->records_read_count."\n" if $self->verbose > 1 and $a_file_parser->records_read_count % 10000 == 0;
		}
	});
}

1;
