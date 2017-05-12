package Bio::BioVeL::Service::NeXMLMerger::CharSetReader::text;
use strict;
use warnings;
use Storable 'dclone';
use Bio::BioVeL::Service::NeXMLMerger::CharSetReader;
use base 'Bio::BioVeL::Service::NeXMLMerger::CharSetReader';

=over

=item read_charsets

Reads character set definitions from a text file. The syntax is expected to be like what
is used inside C<mrbayes> blocks and inside C<sets> blocks after the charset token, 
i.e.:

	<name> = <start coordinate>(-<end coordinate>)?(\<phase>)? ...;

That is, the definition starts with a name and an equals sign. Then, one or more 
coordinate sets. Each coordinate set has a start coordinate, an optional end
coordinate (otherwise it's interpreted as a single site), and an optional phase statement,
e.g. for codon positions. Alternatively, instead of coordinates, names of other character 
sets may be used. The statement ends with a semicolon. 

Each line with data in it is dispatched to C<read_charset> for reading. After reading, the 
collection of character sets is then dispatched to
L<Bio::BioVeL::Service::NeXMLMerger::CharSetReader::text::resolve_references> to 
resolve any named character sets that were referenced in lieu of coordinate sets. The
coordinate sets of the referenced character sets are deepcloned to replace the reference. 

=cut

sub read_charsets {
	my ( $self, $handle ) = @_;
	my $line = 1;
	my %result;
	while(<$handle>) {
		chomp;
		if ( /\S/ ) {
			my ( $name, $ranges ) = $self->read_charset( $_, $line );
			if ( $name and $ranges ) {
				$result{$name};
			}
		}
		$line++;
	}
	return $self->resolve_references(%result);
}

=item resolve_references

Given a collection of character sets, finds the coordinate sets that are named references
to other characters sets, looks them up and copies over their coordinates.

=cut

sub resolve_references {
	my ( $self, %charsets ) = @_;
	for my $set ( keys %charsets ) {
		my @resolved;
		my @ranges = @{ $charsets{$set} };
		for my $range ( @ranges ) {
			if ( my $ref = delete $range->{'ref'} ) {
				push @resolved, map { dclone($_) } @{ $charsets{$ref} };
			}
			else {
				push @resolved, $range;
			}
		}
		$charsets{$set} = \@resolved;
	}
	return %charsets;
}

=item read_charset

Reads a character set, returns:

1. a character set name

2. an array reference of coordinate sets. Each set is represented as a hash reference as
follows:

	{
		'start' => <start coordinate>, # required
		'end'   => <end coordinate>,   # optional
		'phase' => <steps to the next site in set>, # optional
		'ref'   => <name of character set>, # optional
	}

=cut

sub read_charset {
	my ( $self, $string, $line ) = @_;
	my $log = $self->logger;
	
	# charset statement is name = ranges ;
	if ( $string =~ /^\s*(\S+?)\s*=\s*(.+?)\s*;\s*$/ ) {
		my ( $name, $ranges ) = ( $1, $2 );
		my @ranges;
		$log->debug("found charset name $name on line $line");
		
		# ranges are space separated
		for my $range ( split /\s+/, $ranges ) {
			$log->debug("parsing range $range");
		
			# initialize range data structure
			my %range = ( 
				'start' => undef, 
				'end'   => undef, 
				'phase' => undef,
				'ref'   => undef,
			);
			
			# range is a named reference
			if ( $range =~ /[a-z]/i ) {
				$range{'ref'} = $range;
			}
			
			# range has coordinates
			else {
				# number after / is phase
				if ( $range =~ /\\(\d+)$/ ) {
					$range{'phase'} = $1;
					$log->debug("phase of range $range is $range{phase}");
				}
			
				# number after - is end coordinate
				if ( $range =~ /-(\d+)/ ) {
					$range{'end'} = $1;
					$log->debug("end of range $range is $range{end}");
				}
			
				# first number is start coordinate
				if ( $range =~ /^(\d+)/ ) {
					$range{'start'} = $1;
					$log->debug("start of range $range is $range{start}");
				}
			}
			push @ranges, \%range;
		}
		return $name => \@ranges;
	}
	else {
		$log->warn("unreadable string on line $line: $string");
	}
}

=back

=cut

1;

