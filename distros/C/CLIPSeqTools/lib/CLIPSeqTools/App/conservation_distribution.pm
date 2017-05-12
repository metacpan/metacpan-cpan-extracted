=head1 NAME

CLIPSeqTools::App::conservation_distribution - Measure reads at each conservation level

=head1 SYNOPSIS

clipseqtools conservation_distribution [options/parameters]

=head1 DESCRIPTION

Measure reads at each conservation level

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

  Output
    --o_prefix <Str>       output path prefix. Script will create and add
                           extension to path. [Default: ./]

  Other options.
    --plot                 call plotting script to create plots.
    -v --verbose           print progress lines and extra information.
    -h -? --usage --help   print help message

=cut

package CLIPSeqTools::App::conservation_distribution;
$CLIPSeqTools::App::conservation_distribution::VERSION = '0.1.7';

# Make it an app command
use MooseX::App::Command;
extends 'CLIPSeqTools::App';


#######################################################################
#######################   Load External modules   #####################
#######################################################################
use Modern::Perl;
use autodie;
use namespace::autoclean;
use File::Spec;
use Data::Dumper;


#######################################################################
########################   Load GenOO modules   #######################
#######################################################################
use GenOO::GenomicRegion;


#######################################################################
##########################   Consume Roles   ##########################
#######################################################################
with
	"CLIPSeqTools::Role::Option::Library" => {
		-alias    => { validate_args => '_validate_args_for_library' },
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
	$self->_validate_args_for_plot;
	$self->_validate_args_for_output_prefix;
}

sub run {
	my ($self) = @_;

	warn "Starting analysis: conservation_distribution\n";

	warn "Validating arguments\n" if $self->verbose;
	$self->validate_args();

	warn "Creating reads collection\n" if $self->verbose;
	my $reads_collection = $self->reads_collection;
	$reads_collection->schema->storage->debug(1) if $self->verbose > 1;
	# Make GenOO aware of conservation column
	my $conservation_params = {
		data_type => 'integer',
		is_numeric => 1
	};
	$reads_collection->resultset->result_source->add_columns('conservation' => $conservation_params);
	$reads_collection->resultset->result_class->add_columns('conservation' => $conservation_params);
	$reads_collection->resultset->result_class->register_column('conservation');

	warn "Measuring reads at each conservation level\n" if $self->verbose;
	my %conservation_count;
	my %conservation_count_nocopynumber;
	$reads_collection->foreach_record_do( sub {
		my ($rec) = @_;

		$conservation_count{$rec->conservation} += $rec->copy_number;
		$conservation_count_nocopynumber{$rec->conservation} += 1;

		return 0;
	});

	warn "Creating output path\n" if $self->verbose;
	$self->make_path_for_output_prefix();

	warn "Printing results\n" if $self->verbose;
	open (my $OUT1, '>', $self->o_prefix.'conservation_distribution.tab');
	say $OUT1 join("\t", 'conservation_score', 'count', 'count_no_copy_number');
	say $OUT1 join("\t", $_, $conservation_count{$_}, $conservation_count_nocopynumber{$_}) for sort {$a <=> $b} keys %conservation_count;
	close $OUT1;

	if ($self->plot) {
		warn "Creating plot\n" if $self->verbose;
		CLIPSeqTools::PlotApp->initialize_command_class('CLIPSeqTools::PlotApp::conservation_distribution',
			file     => $self->o_prefix.'conservation_distribution.tab',
			o_prefix => $self->o_prefix
		)->run();
	}
}

1;
