=head1 NAME

CLIPSeqTools::CompareApp::all - Run all clipseqtools-compare analyses.

=head1 SYNOPSIS

clipseqtools-compare all [options/parameters]

=head1 DESCRIPTION

Run all clipseqtools-compare analyses.

Takes two libraries (one called input and one called reference) on which all
single clipseqtools analyses have ran.  Assumes that all single clipseqtools
analyses used a common o_prefix for each library.

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
                                --filter rmsk="undef" .
                                --filter query_length=">31".
                            Operators: >, >=, <, <=, =, !=, def, undef
    --res_prefix <Str>      results prefix of clipseqtools analysis.
                            Should match the o_prefix used when running
                            clipseqtools on the library.

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
    --r_res_prefix <Str>    results prefix of clipseqtools analysis.
                            Should match the o_prefix used when running
                            clipseqtools on the reference library.

  Other input.
    --rname_sizes <Str>     file with sizes for reference alignment
                            sequences (rnames). Must be tab delimited
                            (chromosome\tsize) with one line per rname.

  Output
    --o_prefix <Str>        output path prefix. Script will create and add
                            extension to path. Default: ./

  Other options.
    -v --verbose           print progress lines and extra information.
    -h -? --usage --help   print help message

=cut

package CLIPSeqTools::CompareApp::all;
$CLIPSeqTools::CompareApp::all::VERSION = '1.0.0';

# Make it an app command
use MooseX::App::Command;
extends 'CLIPSeqTools::CompareApp';


#######################################################################
#######################   Load External modules   #####################
#######################################################################
use Modern::Perl;
use autodie;
use namespace::autoclean;


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

option 'res_prefix' => (
	is            => 'rw',
	isa           => 'Str',
	required      => 1,
	documentation => 'results prefix of clipseqtools analysis. Should match '.
						'the o_prefix used when running clipseqtools on the '.
						'library.',
);

option 'r_res_prefix' => (
	is            => 'rw',
	isa           => 'Str',
	required      => 1,
	documentation => 'results prefix of clipseqtools analysis. Should match '.
						'the o_prefix used when running clipseqtools on the '.
						'reference library.',
);


#######################################################################
##########################   Consume Roles   ##########################
#######################################################################
with
	"CLIPSeqTools::Role::Option::Library" => {
		-alias    => {validate_args => '_validate_args_for_library'},
		-excludes => 'validate_args',
	},
	"CLIPSeqTools::Role::Option::ReferenceLibrary" => {
		-alias    => {validate_args => '_validate_args_for_reference_library'},
		-excludes => 'validate_args',
	},
	"CLIPSeqTools::Role::Option::Plot" => {
		-alias    => {validate_args => '_validate_args_for_plot'},
		-excludes => 'validate_args',
	},
	"CLIPSeqTools::Role::Option::OutputPrefix" => {
		-alias    => {validate_args => '_validate_args_for_output_prefix'},
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

	my %options;

	map{$options{$_} = $self->$_ if defined $self->$_} (
		'driver', 'database', 'table', 'host', 'user', 'password',
		'records_class', 'filter', 'res_prefix', 'r_driver', 'r_database',
		'r_table', 'r_host', 'r_user', 'r_password', 'r_records_class',
		'r_filter', 'r_res_prefix', 'o_prefix', 'rname_sizes', 'plot',
		'verbose');

	CLIPSeqTools::CompareApp->initialize_command_class(
		'CLIPSeqTools::CompareApp::libraries_overlap_stats',
		%options
	)->run();

	CLIPSeqTools::CompareApp->initialize_command_class(
		'CLIPSeqTools::CompareApp::libraries_relative_read_density',
		%options
	)->run();

	CLIPSeqTools::CompareApp->initialize_command_class(
		'CLIPSeqTools::CompareApp::compare_counts',
		table    => [
			$self->res_prefix.'counts.transcript.tab',
			$self->r_res_prefix.'counts.transcript.tab'],
		key_col  => ['transcript_id'],
		val_col  => 'transcript_exonic_count_per_nt',
		o_prefix => $self->o_prefix.'transcript.',
		t_name   => ['primary_lib', 'reference_lib'],
		plot     => $self->plot,
		verbose  => $self->verbose,
	)->run();

	CLIPSeqTools::CompareApp->initialize_command_class(
		'CLIPSeqTools::CompareApp::compare_counts',
		table    => [
			$self->res_prefix.'counts.gene.tab',
			$self->r_res_prefix.'counts.gene.tab'],
		key_col  => ['gene_name', 'gene_location'],
		val_col  => 'gene_exonic_count_per_nt',
		o_prefix => $self->o_prefix.'gene.',
		t_name   => ['primary_lib', 'reference_lib'],
		plot     => $self->plot,
		verbose  => $self->verbose,
	)->run();

	CLIPSeqTools::CompareApp->initialize_command_class(
		'CLIPSeqTools::CompareApp::compare_counts',
		table    => [
			$self->res_prefix.'counts.exon.tab',
			$self->r_res_prefix.'counts.exon.tab'],
		key_col  => ['transcript_id', 'exon_location'],
		val_col  => 'exon_count_per_nt',
		o_prefix => $self->o_prefix.'exon.',
		t_name   => ['primary_lib', 'reference_lib'],
		plot     => $self->plot,
		verbose  => $self->verbose,
	)->run();

	CLIPSeqTools::CompareApp->initialize_command_class(
		'CLIPSeqTools::CompareApp::compare_counts',
		table    => [
			$self->res_prefix.'counts.intron.tab',
			$self->r_res_prefix.'counts.intron.tab'],
		key_col  => ['transcript_id', 'intron_location'],
		val_col  => 'intron_count_per_nt',
		o_prefix => $self->o_prefix.'intron.',
		t_name   => ['primary_lib', 'reference_lib'],
		plot     => $self->plot,
		verbose  => $self->verbose,
	)->run();
}

1;
