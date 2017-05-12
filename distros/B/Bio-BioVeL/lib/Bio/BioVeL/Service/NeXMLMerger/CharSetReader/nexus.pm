package Bio::BioVeL::Service::NeXMLMerger::CharSetReader::nexus;
use strict;
use warnings;
use Bio::BioVeL::Service::NeXMLMerger::CharSetReader::text;
use base 'Bio::BioVeL::Service::NeXMLMerger::CharSetReader::text';

=over

=item read_charsets

Reads character set definitions from a NEXUS file. The syntax is expected to be like what
is used inside C<mrbayes> blocks and inside C<sets> blocks, i.e.:

	charset <name> = <start coordinate>(-<end coordinate>)?(\<phase>)? ...;

That is, the definition starts with the C<charset> token, a name and an equals sign. Then,
one or more coordinate sets. Each coordinate set has a start coordinate, an optional end
coordinate (otherwise it's interpreted as a single site), and an optional phase statement,
e.g. for codon positions. Alternatively, instead of coordinates, names of other character 
sets may be used. The statement ends with a semicolon. 

Internally, everything after the C<charset> token is dispatched to 
L<Bio::BioVeL::Service::NeXMLMerger::CharSetReader::text::read_charset> which implements
the actual parsing. Subsequently, the collection of character sets is then dispatched to
L<Bio::BioVeL::Service::NeXMLMerger::CharSetReader::text::resolve_references> to 
resolve any named character sets that were referenced in lieu of coordinate sets. The
coordinate sets of the referenced character sets are deepcloned to replace the reference. 

=back

=cut

sub read_charsets {
	my ( $self, $handle ) = @_;
	my $line = 1;
	my %result;
	while(<$handle>) {
		chomp;
		if ( /^\s*charset\s+(.+)$/ ) {
			my $charset = $1;
			my ( $name, $ranges ) = $self->read_charset( $charset, $line );
			$result{$name} = $ranges if $name and $ranges;
		}
		$line++;	
	}
	return $self->resolve_references(%result);
}

1;

