package Bio::BioVeL::Service::NeXMLMerger::MetaReader::json;
use strict;
use Bio::BioVeL::Service::NeXMLMerger::MetaReader;
use base 'Bio::BioVeL::Service::NeXMLMerger::MetaReader';
use JSON;

=over

=item read_meta

Function to read meta data from a json file handle. Returns array
of hashes with key/value pairs representing metadata for 
annotatable objects.

=back

=cut
 
sub read_meta {
    my ($self, $fh) = @_;
    my $log = $self->logger;
    my @result;
    my $json =  do { local $/; <$fh> };
    if ( my $data = decode_json($json) ) { 
    	$log->info("successfully parsed JSON");
		@result = @{ $data };
    }
    else {
    	$log->warn("problem parsing JSON: $json");
    }
    return @result;
}

1;
