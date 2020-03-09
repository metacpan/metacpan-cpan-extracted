=head1 NAME

CLIPSeqTools::PreprocessApp::annotate_with_deletions - Annotate alignments in a database table with deletions.

=head1 SYNOPSIS

clipseqtools-preprocess annotate_with_deletions [options/parameters]

=head1 DESCRIPTION

Annotate alignments in a database table with deletions.
This may by particularly useful for HITS-CLIP analysis.
Add a column named deletion that will be NOT NULL if the alignment has a deletion and NULL otherwise.

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

  Database options.
    --drop                 drop column if it already exists (not
                           supported in SQlite).

  Other options.
    -v --verbose           print progress lines and extra information.
    -h -? --usage --help   print help message

=cut

package CLIPSeqTools::PreprocessApp::annotate_with_deletions;
$CLIPSeqTools::PreprocessApp::annotate_with_deletions::VERSION = '0.1.9';

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
############################   Attributes   ###########################
#######################################################################
has 'column' => (
	is            => 'rw',
	isa           => 'Str',
	default       => 'deletion',
	documentation => 'name for the new annotation column.',
);


#######################################################################
#######################   Command line options   ######################
#######################################################################
option 'drop' => (
	is            => 'rw',
	isa           => 'Bool',
	documentation => 'drop columns if they already exist (not supported in SQlite).',
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
	
	warn "Starting: annotate_with_deletions\n";
	
	warn "Validating arguments\n" if $self->verbose;
	$self->validate_args();

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
		my $rs = $reads_collection->resultset->search({
			cigar => { like => '%D%' },
		});
			
		$rs->update({deletion => 1});
		
		return 0;
	});
}

1;
