=head1 NAME

CLIPSeqTools::App::cluster_size_and_score_distribution - Assemble reads in clusters and measure their size and number of contained reads distribution

=head1 SYNOPSIS

clipseqtools cluster_size_and_score_distribution [options/parameters]

=head1 DESCRIPTION

Assemble reads in clusters and measure their size and number of contained reads distribution.
Reads that are closer than a user defined threshold are assembled in clusters.
Cluster size and number of reads (score) contained in each cluster is measured.
Output: Distribution of cluster size (cluster_size_distribution.tab). Distribution of cluster scores (cluster_score_distribution.tab).

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
    --allowed_dis <Int>    reads closer than this value are assembled in
                           clusters. Default: 0
    --plot                 call plotting script to create plots.
    -v --verbose           print progress lines and extra information.
    -h -? --usage --help   print help message

=cut

package CLIPSeqTools::App::cluster_size_and_score_distribution;
$CLIPSeqTools::App::cluster_size_and_score_distribution::VERSION = '0.1.10';

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


#######################################################################
########################   Load GenOO modules   #######################
#######################################################################
use GenOO::GenomicRegion;


#######################################################################
#######################   Command line options   ######################
#######################################################################
option 'allowed_dis' => (
	is            => 'rw',
	isa           => 'Int',
	default       => 0,
	documentation => 'reads closer than this value are assembled in clusters.',
);


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
	
	warn "Starting analysis: cluster_size_and_score_distribution\n";
	
	warn "Validating arguments\n" if $self->verbose;
	$self->validate_args();
	
	warn "Creating reads collection\n" if $self->verbose;
	my $reads_collection = $self->reads_collection;
	$reads_collection->schema->storage->debug(1) if $self->verbose > 1;
	
	warn "Creating clusters and measuring size and score\n" if $self->verbose;
	my $assembled_cluster;
	my %cluster_size_count;
	my %cluster_score_count;
	$reads_collection->foreach_record_sorted_by_location_do( sub {
		my ($rec) = @_;
		
		return 0 if $rec->cigar =~ /N/; # throw away reads with huge gaps (introns)
		
		if (!defined $assembled_cluster) {
			$assembled_cluster = $self->_create_new_cluster_from_record($rec);
			return 0;
		}
		
		if ($rec->overlaps_with_offset($assembled_cluster, 1, $self->allowed_dis)) {
			if ($rec->start < $assembled_cluster->start) {
				$assembled_cluster->start($rec->start);
			}
			if ($rec->stop > $assembled_cluster->stop) {
				$assembled_cluster->stop($rec->stop);
			}
			$assembled_cluster->copy_number($assembled_cluster->copy_number + $rec->copy_number);
		}
		else {
			$cluster_size_count{$assembled_cluster->length}++;
			$cluster_score_count{$assembled_cluster->copy_number}++;
			$assembled_cluster = $self->_create_new_cluster_from_record($rec);
		}
		
		return 0;
	});

	warn "Creating output path\n" if $self->verbose;
	$self->make_path_for_output_prefix();
	
	warn "Printing results for cluster sizes\n" if $self->verbose;
	open (my $OUT1, '>', $self->o_prefix.'cluster_size_distribution.tab');
	say $OUT1 join("\t", 'cluster_size', 'count');
	say $OUT1 join("\t", $_, $cluster_size_count{$_}) for sort {$a <=> $b} keys %cluster_size_count;
	close $OUT1;
	
	warn "Printing results for cluster scores\n" if $self->verbose;
	open (my $OUT2, '>', $self->o_prefix.'cluster_score_distribution.tab');
	say $OUT2 join("\t", 'cluster_score', 'count');
	say $OUT2 join("\t", $_, $cluster_score_count{$_}) for sort {$a <=> $b} keys %cluster_score_count;
	close $OUT2;
	
	if ($self->plot) {
		warn "Creating plot\n" if $self->verbose;
		CLIPSeqTools::PlotApp->initialize_command_class('CLIPSeqTools::PlotApp::cluster_size_and_score_distribution', 
			cluster_sizes_file  => $self->o_prefix.'cluster_size_distribution.tab',
			cluster_scores_file => $self->o_prefix.'cluster_score_distribution.tab',
			o_prefix            => $self->o_prefix
		)->run();
	}
}


#######################################################################
#########################   Private Methods   #########################
#######################################################################
sub _create_new_cluster_from_record {
	my ($self, $rec) = @_;
	
	return GenOO::GenomicRegion->new(
		strand      => $rec->strand,
		chromosome  => $rec->rname,
		start       => $rec->start,
		stop        => $rec->stop,
		copy_number => $rec->copy_number,
	);
}
1;
