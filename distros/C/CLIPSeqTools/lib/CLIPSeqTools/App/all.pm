=head1 NAME

CLIPSeqTools::App::all - Run all clipseqtools analyses

=head1 SYNOPSIS

clipseqtools all [options/parameters]

=head1 DESCRIPTION

Run all clipseqtools analyses.

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
                                -filter deletion="def"
                                -filter rmsk="undef" .
                                -filter query_length=">31".
                           Operators: >, >=, <, <=, =, !=, def, undef

  Other input
    -gtf <Str>             GTF file with genes/transcripts. [Required]
    -rname_sizes <Str>     file with sizes for reference alignment sequences
                           (rnames). Must be tab delimited (chromosome\tsize)
                           with one line per rname. [Required]

  Output
    --o_prefix <Str>       output path prefix. Script will create and add
                           extension to path. [Default: ./]

  Other options.
    --allowed_dis <Int>    reads closer than this value are assembled in
                           clusters. Default: 0
    --plot                 call plotting script to create plots.
    -v --verbose           print progress lines and extra information.
    -h -? --usage --help   print help message

=cut

package CLIPSeqTools::App::all;
$CLIPSeqTools::App::all::VERSION = '0.1.9';

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
option 'rname_sizes' => (
	is            => 'rw',
	isa           => 'Str',
	required      => 1,
	documentation => 'file with sizes for reference alignment sequences (rnames). Must be tab delimited (chromosome\tsize) with one line per rname.',
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

	my %options;

	$options{'driver'}        = $self->driver        if defined $self->driver;
	$options{'database'}      = $self->database      if defined $self->database;
	$options{'table'}         = $self->table         if defined $self->table;
	$options{'host'}          = $self->host          if defined $self->host;
	$options{'user'}          = $self->user          if defined $self->user;
	$options{'password'}      = $self->password      if defined $self->password;
	$options{'records_class'} = $self->records_class if defined $self->records_class;
	$options{'filter'}        = $self->filter        if defined $self->filter;
	$options{'o_prefix'}      = $self->o_prefix      if defined $self->o_prefix;
	$options{'gtf'}           = $self->gtf           if defined $self->gtf;
	$options{'rname_sizes'}   = $self->rname_sizes   if defined $self->rname_sizes;
	$options{'plot'}          = $self->plot          if defined $self->plot;
	$options{'verbose'}       = $self->verbose       if defined $self->verbose;

	CLIPSeqTools::App->initialize_command_class('CLIPSeqTools::App::cluster_size_and_score_distribution', %options)->run();
	CLIPSeqTools::App->initialize_command_class('CLIPSeqTools::App::count_reads_on_genic_elements', %options)->run();
	CLIPSeqTools::App->initialize_command_class('CLIPSeqTools::App::distribution_on_genic_elements', %options)->run();
	CLIPSeqTools::App->initialize_command_class('CLIPSeqTools::App::distribution_on_introns_exons', %options)->run();
	CLIPSeqTools::App->initialize_command_class('CLIPSeqTools::App::genome_coverage', %options)->run();
	CLIPSeqTools::App->initialize_command_class('CLIPSeqTools::App::genomic_distribution', %options)->run();
	CLIPSeqTools::App->initialize_command_class('CLIPSeqTools::App::nmer_enrichment_over_shuffled', %options)->run();
	CLIPSeqTools::App->initialize_command_class('CLIPSeqTools::App::nucleotide_composition', %options)->run();
	CLIPSeqTools::App->initialize_command_class('CLIPSeqTools::App::reads_long_gaps_size_distribution', %options)->run();
	CLIPSeqTools::App->initialize_command_class('CLIPSeqTools::App::size_distribution', %options)->run();
	CLIPSeqTools::App->initialize_command_class('CLIPSeqTools::App::conservation_distribution', %options)->run();
}


1;
