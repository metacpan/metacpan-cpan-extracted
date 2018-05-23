=head1 NAME

CLIPSeqTools::App::export_bed - Export reads to a BED file.

=head1 SYNOPSIS

clipseqtools export_bed [options/parameters]

=head1 DESCRIPTION

Export reads to a BED file. Note that if the reads were collapsed in the
preprocessing step then the exported reads are also collapsed. In this case
the score field in the BED file corresponds to the copy number of the
collapsed reads e.g. if 5 reads were collapsed into 1 then the score field of
the BED file will be 5.

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
                                --filter rmsk="undef"
                                --filter query_length=">31".
                           Operators: >, >=, <, <=, =, !=, def, undef

  Output
    --o_prefix <Str>       output path prefix. Script will create and add
                           extension to path. [Default: ./]

  Other options.
    -v --verbose           print progress lines and extra information.
    -h -? --usage --help   print help message

=cut


package CLIPSeqTools::App::export_bed;
$CLIPSeqTools::App::export_bed::VERSION = '0.1.8';

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
##########################   Consume Roles   ##########################
#######################################################################
with
	"CLIPSeqTools::Role::Option::Library" => {
		-alias    => { validate_args => '_validate_args_for_library' },
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
	$self->_validate_args_for_output_prefix;
}

sub run {
	my ($self) = @_;

	warn "Starting analysis: export_bed\n";

	warn "Validating arguments\n" if $self->verbose;
	$self->validate_args();

	warn "Creating reads collection\n" if $self->verbose;
	my $reads_collection = $self->reads_collection;
	$reads_collection->schema->storage->debug(1) if $self->verbose > 1;

	warn "Creating output path\n" if $self->verbose;
	$self->make_path_for_output_prefix();

	warn "Exporting reads to BED file\n" if $self->verbose;
	open (my $OUT, '>', $self->o_prefix.'exported_reads.bed');
	$reads_collection->foreach_record_do( sub {
		my ($rec) = @_;

		say $OUT join("\t",
			$rec->rname, $rec->start, $rec->stop + 1, "-",
			$rec->copy_number, $rec->strand_symbol);

		return 0;
	});
	close $OUT;
}

1;
