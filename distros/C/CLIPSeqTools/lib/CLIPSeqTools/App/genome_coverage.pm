=head1 NAME

CLIPSeqTools::App::genome_coverage - Measure percent of genome covered by reads.

=head1 SYNOPSIS

clipseqtools genome_coverage [options/parameters]

=head1 DESCRIPTION

Measure the percent of genome that is covered by the reads of a library.

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

  Other input.
    --rname_sizes <Str>    file with sizes for reference alignment
                           sequences (rnames). Must be tab delimited
                           (chromosome\tsize) with one line per rname.

  Output
    --o_prefix <Str>       output path prefix. Script will create and add
                           extension to path. [Default: ./]

  Other options.
    -v --verbose           print progress lines and extra information.
    -h -? --usage --help   print help message

=cut


package CLIPSeqTools::App::genome_coverage;
$CLIPSeqTools::App::genome_coverage::VERSION = '0.1.9';

# Make it an app command
use MooseX::App::Command;
extends 'CLIPSeqTools::App';


#######################################################################
#######################   Load External modules   #####################
#######################################################################
use Modern::Perl;
use autodie;
use namespace::autoclean;
use PDL::Lite;


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
	$self->usage_error('File with sizes for reference alignment sequences is required') if !$self->rname_sizes;
}

sub run {
	my ($self) = @_;
	
	warn "Starting analysis: genome_coverage\n";
	
	warn "Validating arguments\n" if $self->verbose;
	$self->validate_args();
	
	warn "Reading sizes for reference alignment sequences\n" if $self->verbose;
	my %rname_sizes = $self->read_rname_sizes;
		
	warn "Creating reads collection\n" if $self->verbose;
	my $reads_collection = $self->reads_collection;
	my @rnames = $reads_collection->rnames_for_all_strands;
		
	warn "Creating output path\n" if $self->verbose;
	$self->make_path_for_output_prefix();
		
	warn "Calculating genome coverage\n" if $self->verbose;
	my $total_genome_coverage = 0;
	my $total_genome_length = 0;
	open(my $OUT, '>', $self->o_prefix.'genome_coverage.tab');
	say $OUT join("\t", 'rname', 'covered_area', 'size', 'percent_covered');
	foreach my $rname (@rnames) {
		warn "Working for $rname\n" if $self->verbose;
		my $pdl = PDL->zeros(PDL::byte(), $rname_sizes{$rname});
		
		$reads_collection->foreach_record_on_rname_do($rname, sub {
			$pdl->slice([$_[0]->start, $_[0]->stop]) .= 1;
			return 0;
		});
		
		my $covered_area = $pdl->sum();
		say $OUT join("\t", $rname, $covered_area, $rname_sizes{$rname}, $covered_area/$rname_sizes{$rname}*100);
		
		$total_genome_coverage += $covered_area;
		$total_genome_length += $rname_sizes{$rname};
	}
	say $OUT join("\t", 'Total', $total_genome_coverage, $total_genome_length, $total_genome_coverage/$total_genome_length*100);
	close $OUT;
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


1;
