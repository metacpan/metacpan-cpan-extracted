=head1 NAME

CLIPSeqTools::App::nmer_enrichment_over_shuffled - Measure Nmer enrichment over shuffled reads.

=head1 SYNOPSIS

clipseqtools nmer_enrichment_over_shuffled [options/parameters]

=head1 DESCRIPTION

Measure words of length N (Nmer) enrichment and compare to shuffled reads. Shuffling is done at the nucleotide level and p-values are calculated using permutations.

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
    --nmer_length <Int>    length N of the Nmer. Default: 6
    --permutations <Int>   number of permutation to be performed. 
                           Use more than 100 to get p-values < 0.01.
    --subset <Num>         run analysis on random subset. Option specifies
                           number (if integer) or percent (if % is used)
                           of data to be used.
    -v --verbose           print progress lines and extra information.
    -h -? --usage --help   print help message

=cut

package CLIPSeqTools::App::nmer_enrichment_over_shuffled;
$CLIPSeqTools::App::nmer_enrichment_over_shuffled::VERSION = '1.0.0';

# Make it an app command
use MooseX::App::Command;
extends 'CLIPSeqTools::App';


#######################################################################
#######################   Load External modules   #####################
#######################################################################
use Modern::Perl;
use autodie;
use namespace::autoclean;
use List::Util qw(sum max);
use List::Util qw(shuffle);


#######################################################################
#######################   Command line options   ######################
#######################################################################
option 'nmer_length' => (
	is            => 'rw',
	isa           => 'Int',
	default       => 6,
	documentation => 'the length N of the Nmer.',
);

option 'permutations' => (
	is            => 'rw',
	isa           => 'Int',
	default       => 100,
	documentation => 'the number of permutation to be performed. Use more than 100 to get p-values < 0.01.',
);

option 'subset' => (
	is            => 'rw',
	isa           => 'Str',
	default       => '100%',
	documentation => 'run analysis on random subset. Option specifies the number (if integer) or percent (if % is used) of data to be used.',
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
}

sub run {
	my ($self) = @_;
	
	warn "Starting analysis: nmer_enrichment_over_shuffled\n";
	
	warn "Validating arguments\n" if $self->verbose;
	$self->validate_args();

	warn "Creating reads collection\n" if $self->verbose;
	my $reads_collection = $self->reads_collection;

	my $subset_factor = 1;
	if ($self->subset ne '100%') {
		warn "Calculating subset parameters\n" if $self->verbose;
		my $records_count = $reads_collection->records_count;
		if ($self->subset =~ /(.+)%/) {
			$subset_factor = $1 / 100;
		}
		else {
			$subset_factor = $self->subset / $records_count;
		}
		warn "Program will run on approximatelly ".sprintf('%.0f', $subset_factor*100)."% of library\n" if $self->verbose;
	}

	warn "Counting Nmer occurrences in original and shuffled reads\n" if $self->verbose;
	my %nmer_stats;
	$reads_collection->foreach_record_do(sub{
		my ($record) = @_;
		
		return 0 if rand > $subset_factor;
		
		my $seq = $record->sequence;
		for my $i (0..length($seq)-$self->nmer_length) {
			my $nmer = substr($seq, $i, $self->nmer_length);
			$nmer_stats{$nmer}->{'count'}        += $record->copy_number;
			$nmer_stats{$nmer}->{'collapsed_count'} += 1;
		}
		
		my @seq_array = split(//, $seq);
		for (my $perm = 0; $perm < $self->permutations; $perm++) {
			my @random_seq_array = shuffle(@seq_array);
			for (my $i=0; $i < @seq_array - $self->nmer_length + 1; $i++) {
				my $nmer = join('', @random_seq_array[$i..$i+$self->nmer_length-1]);
				$nmer_stats{$nmer}->{'sh_count'}->[$perm]           += $record->copy_number;
				$nmer_stats{$nmer}->{'sh_collapsed_count'}->[$perm] += 1;
			}
		}
		
		return 0;
	});

	warn "Creating output path\n" if $self->verbose;
	$self->make_path_for_output_prefix();

	warn "Calculating p-values and printing results.\n" if $self->verbose;
	open (my $OUT, '>', $self->o_prefix.'nmer_enrichment_over_shuffled.tab');
	say $OUT join("\t", 'nmer', 'count', 'collapsed_count', 'average_sh_count', 'average_sh_collapsed_count', 'enrichment', 'collapsed_enrichment', 'pvalue', 'collapsed_pvalue');
	foreach my $nmer (keys %nmer_stats) {
		next if $nmer =~ /N/;
		
		my $count                = $nmer_stats{$nmer}->{'count'}                 || 0;
		my $collapsed_count      = $nmer_stats{$nmer}->{'collapsed_count'}       || 0;
		my @sh_counts            = @{$nmer_stats{$nmer}->{'sh_count'}};
		my @sh_collapsed_counts  = @{$nmer_stats{$nmer}->{'sh_collapsed_count'}};
		
		map{$_ = 0 if !$_} @sh_counts;           # make any undefined values 0
		map{$_ = 0 if !$_} @sh_collapsed_counts; # make any undefined values 0
		
		my $avg_sh_count         = sum(@sh_counts) / $self->permutations           || 1;
		my $avg_collapsed_count  = sum(@sh_collapsed_counts) / $self->permutations || 1;
		
		my $enrichment           = $count / $avg_sh_count;
		my $collapsed_enrichment = $collapsed_count / $avg_collapsed_count;
		
		my $pvalue               = _equal_or_more($count, @sh_counts) / $self->permutations;
		my $collapsed_pvalue     = _equal_or_more($collapsed_count, @sh_collapsed_counts) / $self->permutations;
		
		say $OUT join("\t", $nmer, $count, $collapsed_count, $avg_sh_count, $avg_collapsed_count, $enrichment, $collapsed_enrichment, $pvalue, $collapsed_pvalue);
	}
}


#######################################################################
########################   Private Functions   ########################
#######################################################################
sub _equal_or_more {
	my $value = shift;
	
	return scalar(grep {$_ >= $value} @_);
}






1;
