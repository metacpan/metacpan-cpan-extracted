package AI::FANN::Evolving::TrainData;
use strict;
use List::Util 'shuffle';
use AI::FANN ':all';
use Algorithm::Genetic::Diploid::Base;
use base 'Algorithm::Genetic::Diploid::Base';

our $AUTOLOAD;
my $log = __PACKAGE__->logger;

=head1 NAME

AI::FANN::Evolving::TrainData - wrapper class for FANN data

=head1 METHODS

=over

=item new

Constructor takes named arguments. By default, ignores column
named ID and considers column named CLASS as classifier.

=cut

sub new {
	my $self = shift->SUPER::new(
		'ignore'    => [ 'ID'    ],
		'dependent' => [ 'CLASS' ],
		'header'    => {},
		'table'     => [],
		@_
	);
	my %args  = @_;
	$self->read_data($args{'file'}) if $args{'file'};
	$self->trim_data if $args{'trim'};
	return $self;
}

=item ignore_columns

Getter/setter for column names to ignore in the train data structure. 
For example: an identifier columns named 'ID'

=cut

sub ignore_columns {
	my $self = shift;
	$self->{'ignore'} = \@_ if @_;
	return @{ $self->{'ignore'} };
}

=item dependent_columns

Getter/setter for column name(s) of the output value(s).

=cut

sub dependent_columns {
	my $self = shift;
	$self->{'dependent'} = \@_ if @_;
	return @{ $self->{'dependent'} };
}

=item predictor_columns

Getter for column name(s) of input value(s)

=cut

sub predictor_columns {
	my $self = shift;
	my @others = ( $self->ignore_columns, $self->dependent_columns );
	my %skip = map { $_ => 1 } @others;
	return grep { ! $skip{$_} } keys %{ $self->{'header'} };
}

=item predictor_data

Getter for rows of input values

=cut

sub predictor_data {
	my ( $self, %args ) = @_;
	my $i = $args{'row'};
	my @cols = $args{'cols'} ? @{ $args{'cols'} } : $self->predictor_columns;
	
	# build hash of indices to keep
	my %keep = map { $self->{'header'}->{$_} => 1 } @cols;
	
	# only return a single row
	if ( defined $i ) {
		my @pred;
		for my $j ( 0 .. $#{ $self->{'table'}->[$i] } ) {
			push @pred, $self->{'table'}->[$i]->[$j] if $keep{$j};
		}
		return \@pred;
	}
	else {
		my @preds;
		my $max = $self->size - 1;
		for my $j ( 0 .. $max ) {
			push @preds, $self->predictor_data( 'row' => $j, 'cols' => \@cols);
		}
		return @preds;
	}
}

=item dependent_data

Getter for dependent (classifier) data

=cut

sub dependent_data {
	my ( $self, $i ) = @_;
	my @dc = map { $self->{'header'}->{$_} } $self->dependent_columns;
	if ( defined $i ) {
		return [ map { $self->{'table'}->[$i]->[$_] } @dc ];
	}
	else {
		my @dep;
		for my $j ( 0 .. $self->size - 1 ) {
			push @dep, $self->dependent_data($j);
		}
		return @dep;
	}
}

=item read_data

Reads provided input file

=cut

sub read_data {
	my ( $self, $file ) = @_; # file is tab-delimited
	$log->debug("reading data from file $file");
	open my $fh, '<', $file or die "Can't open $file: $!";
	my ( %header, @table );
	while(<$fh>) {
		chomp;
		next if /^\s*$/;
		my @fields = split /\t/, $_;
		if ( not %header ) {
			my $i = 0;
			%header = map { $_ => $i++ } @fields;
		}
		else {
			push @table, \@fields;
		}
	}
	$self->{'header'} = \%header;
	$self->{'table'}  = \@table;
	return $self;
}

=item write_data

Writes to provided output file

=cut

sub write_data {
	my ( $self, $file ) = @_;
	
	# use file or STDOUT
	my $fh;
	if ( $file ) {
		open $fh, '>', $file or die "Can't write to $file: $!";
		$log->info("writing data to $file");
	}
	else {
		$fh = \*STDOUT;
		$log->info("writing data to STDOUT");
	}
	
	# print header
	my $h = $self->{'header'};
	print $fh join "\t", sort { $h->{$a} <=> $h->{$b} } keys %{ $h };
	print $fh "\n";
	
	# print rows
	for my $row ( @{ $self->{'table'} } ) {
		print $fh join "\t", @{ $row };
		print $fh "\n";
	}
}

=item trim_data

Trims sparse rows with missing values

=cut

sub trim_data {
	my $self = shift;
	my @trimmed;
	ROW: for my $row ( @{ $self->{'table'} } ) {
		next ROW if grep { not defined $_ } @{ $row };
		push @trimmed, $row;
	}
	my $num = $self->{'size'} - scalar @trimmed;
	$log->info("removed $num incomplete rows");
	$self->{'table'} = \@trimmed;
}

=item sample_data

Sample a fraction of the data

=cut

sub sample_data {
	my $self   = shift;
	my $sample = shift || 0.5;
	my $clone1 = $self->clone;
	my $clone2 = $self->clone;
	my $size   = $self->size;
	my @sample;
	$clone2->{'table'} = \@sample;
	while( scalar(@sample) < int( $size * $sample ) ) {
		my @shuffled = shuffle( @{ $clone1->{'table'} } );
		push @sample, shift @shuffled;
		$clone1->{'table'} = \@shuffled;
	}
	return $clone2, $clone1;
}

=item partition_data

Creates two clones that partition the data according to the provided ratio.

=cut

sub partition_data {
	my $self   = shift;
	my $sample = shift || 0.5;
	my $clone1 = $self->clone;
	my $clone2 = $self->clone;
	my $remain = 1 - $sample;
	$log->info("going to partition into $sample : $remain");
		
	# compute number of different dependent patterns and ratios of each
	my @dependents = $self->dependent_data;
	my %seen;
	for my $dep ( @dependents ) {
		my $key = join '/', @{ $dep };
		$seen{$key}++;
	}
	
	# adjust counts to sample size
	for my $key ( keys %seen ) {
		$log->debug("counts: $key => $seen{$key}");
		$seen{$key} = int( $seen{$key} * $sample );
		$log->debug("rescaled: $key => $seen{$key}");
	}

	# start the sampling	
	my @dc = map { $self->{'header'}->{$_} } $self->dependent_columns;
	my @new_table; # we will populate this
	my @table = @{ $clone1->{'table'} }; # work on cloned instance
	
	# as long as there is still sampling to do 
	SAMPLE: while( grep { !!$_ } values %seen ) {
		for my $i ( 0 .. $#table ) {
			my @r = @{ $table[$i] };
			my $key = join '/', @r[@dc];
			if ( $seen{$key} ) {
				my $rand = rand(1);
				if ( $rand < $sample ) {
					push @new_table, \@r;
					splice @table, $i, 1;
					$seen{$key}--;
					$log->debug("still to go for $key: $seen{$key}");
					next SAMPLE;
				}
			}
		}
	}
	$clone2->{'table'} = \@new_table;
	$clone1->{'table'} = \@table;
	return $clone2, $clone1;
}

=item size

Returns the number of data records

=cut

sub size { scalar @{ shift->{'table'} } }

=item to_fann

Packs data into an L<AI::FANN> TrainData structure

=cut

sub to_fann {
	$log->debug("encoding data as FANN struct");
	my $self = shift;
	my @cols = @_ ? @_ : $self->predictor_columns;
	my @deps = $self->dependent_data;
	my @pred = $self->predictor_data( 'cols' => \@cols );
	my @interdigitated;
	for my $i ( 0 .. $#deps ) {
		push @interdigitated, $pred[$i], $deps[$i];
	}
	return AI::FANN::TrainData->new(@interdigitated);
}

=back

=cut

1;
