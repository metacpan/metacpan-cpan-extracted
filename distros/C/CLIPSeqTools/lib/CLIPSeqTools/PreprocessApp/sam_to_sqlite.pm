=head1 NAME

CLIPSeqTools::PreprocessApp::sam_to_sqlite - Load a SAM file in an SQLite database.

=head1 SYNOPSIS

clipseqtools-preprocess sam_to_sqlite [options/parameters]

=head1 DESCRIPTION

Store alignments from a SAM file into and SQLite database. If SAM tag XC:i exists it will be used as the copy number of the record.

=head1 OPTIONS

  Input options.
    --sam_file <Str>       sam file to be stored in database. If not
                           specified STDIN is used.
    --records_class <Str>  type of records stored in SAM file. [Default:
                           GenOOx::Data::File::SAMstar::Record]

  Database options.
    --database <Str>       database name or path. Will be created.
    --table <Str>          database table. Will be created.
    --drop <Str>           drop table if it already exists.

  Other options.
    -v --verbose           print progress lines and extra information.
    -h -? --usage --help   print help message

=cut

package CLIPSeqTools::PreprocessApp::sam_to_sqlite;
$CLIPSeqTools::PreprocessApp::sam_to_sqlite::VERSION = '0.1.8';

# Make it an app command
use MooseX::App::Command;
extends 'CLIPSeqTools::PreprocessApp';


#######################################################################
#######################   Load External modules   #####################
#######################################################################
use Modern::Perl;
use autodie;
use namespace::autoclean;
use DBI;


##############################################
# Import GenOO
use GenOO::Data::File::SAM;


#######################################################################
#######################   Command line options   ######################
#######################################################################
option 'sam_file' => (
	is            => 'rw',
	isa           => 'Str',
	documentation => 'sam file to be stored in database. If not specified STDIN is used.',
);

option 'records_class' => (
	is            => 'rw',
	isa           => 'Str',
	default       => 'GenOOx::Data::File::SAMstar::Record',
	documentation => 'type of records stored in SAM file.',
);

option 'database' => (
	is            => 'rw',
	isa           => 'Str',
	required      => 1,
	documentation => 'database name or path. Will be created.',
);

option 'table' => (
	is            => 'rw',
	isa           => 'Str',
	required      => 1,
	documentation => 'database table. Will be created.',
);

option 'drop' => (
	is            => 'rw',
	isa           => 'Bool',
	documentation => 'drop table if it already exists.',
);


#######################################################################
########################   Interface Methods   ########################
#######################################################################
sub validate_args {}

sub run {
	my ($self) = @_;
	
	warn "Validating arguments\n" if $self->verbose;
	$self->validate_args();
	
	# Load required classes
	eval 'require ' . $self->records_class;

	warn "Reading SAM\n" if $self->verbose;
	my $sam = GenOO::Data::File::SAM->new(
		file          => $self->sam_file,
		records_class => $self->records_class,
	);

	warn "Connecting to the database\n" if $self->verbose;
	my $dbh = DBI->connect('dbi:SQLite:database=' . $self->database) or die "Can't connect to database: $DBI::errstr\n";

	if ($self->drop) {
		warn "Dropping table " . $self->table . "\n" if $self->verbose;
		$dbh->do( q{DROP TABLE IF EXISTS } . $self->table );
	}

	warn "Creating table " . $self->table . "\n" if $self->verbose;
	{
		local $dbh->{PrintError} = 0; #temporarily suppress the warning in case table already exists
		
		$dbh->do(
			'CREATE TABLE '.$self->table.' ('.
				'id INTEGER PRIMARY KEY AUTOINCREMENT,'.
				'strand INT(1) NOT NULL,'.
				'rname VARCHAR(250) NOT NULL,'.
				'start UNSIGNED INT(10) NOT NULL,'.
				'stop UNSIGNED INT(10) NOT NULL,'.
				'copy_number UNSIGNED INT(6) NOT NULL DEFAULT 1,'.
				'sequence VARCHAR(250) NOT NULL,'.
				'cigar VARCHAR(250) NOT NULL,'.
				'mdz VARCHAR(250),'.
				'number_of_mappings UNSIGNED INT(5),'.
				'query_length UNSIGNED INT(4) NOT NULL,'.
				'alignment_length UNSIGNED INT(5) NOT NULL'.
			');'
		);
		
		if ($dbh->err) {
			die "Error: " . $dbh->errstr . "\n";
		}
	}


	warn "Loading data to table " . $self->table . "\n" if $self->verbose;
	$dbh->begin_work;
	my $insert_statement = $dbh->prepare(
		q{INSERT INTO } . $self->table . q{ (id, strand, rname, start, stop, copy_number, sequence, cigar, mdz, number_of_mappings, query_length, alignment_length) VALUES(?,?,?,?,?,?,?,?,?,?,?,?)}
	);
	while (my $record = $sam->next_record) {
		my $copy_number = $record->copy_number;
		if (defined $record->tag('XC:i')) {
			$copy_number = $record->tag('XC:i');
		}
		
		$insert_statement->execute(undef,$record->strand, $record->rname, $record->start, $record->stop, $copy_number, $record->query_seq, $record->cigar, $record->mdz, $record->number_of_mappings, $record->query_length, $record->alignment_length);
		
		if ($sam->records_read_count % 100000 == 0) {
			$dbh->commit;
			$dbh->begin_work;
		}
	}
	$dbh->commit;

	warn "Building index on " . $self->table . "\n" if $self->verbose;
	$dbh->do(q{CREATE INDEX } . $self->table . q{_loc ON } . $self->table .q{ (rname, start);});

	warn "Disconnecting from the database\n" if $self->verbose;
	$dbh->disconnect;
}

1;
