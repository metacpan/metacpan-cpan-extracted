=head1 NAME

CLIPSeqTools::PreprocessApp::annotate_with_genic_elements - Annotate alignments in a database table with genic information.

=head1 SYNOPSIS

clipseqtools-preprocess annotate_with_genic_elements [options/parameters]

=head1 DESCRIPTION

Annotate alignments in a database table with genic information
Adds columns named "transcript", "exon", "coding_transcript", "utr5", "cds", "utr3".
Column values will be NOT NULL if an alignment is contained in the corresponding region and NULL otherwise.

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

  Database options.
    --drop                 drop columns if they already exist (not
                           supported in SQlite).

  Other options.
    -v --verbose           print progress lines and extra information.
    -h -? --usage --help   print help message

=cut

package CLIPSeqTools::PreprocessApp::annotate_with_genic_elements;
$CLIPSeqTools::PreprocessApp::annotate_with_genic_elements::VERSION = '0.1.7';

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
	},
	"CLIPSeqTools::Role::Option::Transcripts" => {
		-alias    => { validate_args => '_validate_args_for_transcripts' },
		-excludes => 'validate_args',
	};


#######################################################################
########################   Interface Methods   ########################
#######################################################################
sub validate_args {
	my ($self) = @_;
	
	$self->_validate_args_for_library;
	$self->_validate_args_for_transcripts;
}

sub run {
	my ($self) = @_;
	
	warn "Starting: annotate_with_genic_elements\n";
	
	warn "Validating arguments\n" if $self->verbose;
	$self->validate_args();

	warn "Creating transcript collection\n" if $self->verbose;
	my $transcript_collection = $self->transcript_collection;

	warn "Creating reads collection\n" if $self->verbose;
	my $reads_collection = $self->reads_collection;
	my $reads_rs = $reads_collection->resultset;


	my $table = $self->table;
	if ($self->drop) {
		warn "Droping columns transcript, exon, coding_transcript, utr5, cds, utr3\n" if $self->verbose;
		try {
			$reads_collection->schema->storage->dbh_do( sub {
				my ($storage, $dbh, @cols) = @_;
				$dbh->do( "ALTER TABLE $table DROP COLUMN transcript" );
				$dbh->do( "ALTER TABLE $table DROP COLUMN exon" );
				$dbh->do( "ALTER TABLE $table DROP COLUMN coding_transcript" );
				$dbh->do( "ALTER TABLE $table DROP COLUMN utr5" );
				$dbh->do( "ALTER TABLE $table DROP COLUMN cds" );
				$dbh->do( "ALTER TABLE $table DROP COLUMN utr3" );
			});
		};
	}

	try {
		warn "Creating columns transcript, exon, coding_transcript, utr5, cds, utr3\n" if $self->verbose;
		$reads_collection->schema->storage->dbh_do( sub {
			my ($storage, $dbh, @cols) = @_;
			$dbh->do( "ALTER TABLE $table ADD COLUMN transcript INT(1)" );
			$dbh->do( "ALTER TABLE $table ADD COLUMN coding_transcript INT(1)" );
			$dbh->do( "ALTER TABLE $table ADD COLUMN exon INT(1)" );
			$dbh->do( "ALTER TABLE $table ADD COLUMN utr5 INT(1)" );
			$dbh->do( "ALTER TABLE $table ADD COLUMN cds INT(1)" );
			$dbh->do( "ALTER TABLE $table ADD COLUMN utr3 INT(1)" );
		});
	} catch {
		warn "Warning: Column creation failed. Maybe some columns already exist.\n" if $self->verbose;
		warn "Caught error: $_\n"  if $self->verbose > 1;
	};

	warn "Looping on transcripts to annotate records.\nThis might take a long time. Relax...\n" if $self->verbose;
	$reads_collection->schema->txn_do(sub {
		$transcript_collection->foreach_record_do( sub {
			my ($transcript) = @_;
			
			my $transcript_reads_rs = $reads_rs->search({
				strand => $transcript->strand,
				rname  => $transcript->rname,
				start  => { '-between' => [$transcript->start, $transcript->stop] },
				stop   => { '-between' => [$transcript->start, $transcript->stop] },
			});
			
			$transcript_reads_rs->update({transcript => 1});
			
			foreach my $exon (@{$transcript->exons}) {
				my $exon_reads_rs = $transcript_reads_rs->search([
					start => { '-between' => [$exon->start, $exon->stop] },
					stop  => { '-between' => [$exon->start, $exon->stop] },
				]);
				
				$exon_reads_rs->update({exon => 1});
			}
			
			if ($transcript->is_coding) {
				foreach my $part_type ('utr5', 'cds', 'utr3') {
					my $part = $transcript->$part_type() or next;
					my $part_reads_rs = $transcript_reads_rs->search([
						start => { '-between' => [$part->start, $part->stop] },
						stop  => { '-between' => [$part->start, $part->stop] },
					]);
					
					$part_reads_rs->update({$part_type => 1});
				}
				
				$transcript_reads_rs->update({coding_transcript => 1});
			}
		});
	});

}


1;
