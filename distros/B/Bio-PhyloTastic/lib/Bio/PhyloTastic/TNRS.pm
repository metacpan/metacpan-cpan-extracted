package Bio::PhyloTastic::TNRS;
use strict;
use warnings;
use JSON;
use URI::Escape;
use Data::Dumper;
use LWP::UserAgent;
use Bio::Phylo::IO 'parse';
use Bio::Phylo::Util::CONSTANT ':objecttypes';
use base 'Bio::PhyloTastic';

=head1 NAME

Bio::PhyloTastic::TNRS - Taxonomic Name Reconciliation Service

=head1 SYNOPSIS

 phylotastic TNRS -i <infile> -o <outfile>

=head1 DESCRIPTION

This module calls the TNRS service L<http://api.phylotastic.org/tnrs/>

=head1 OPTIONS AND ARGUMENTS

=over

=item -i infile

An input file. Default is a text file with one name per line. Required.

=item -o outfile

An output file name. If '-', prints output to STDOUT. Required.

=item -d informat

An input format, including NEXUS, Newick, NeXML, PhyloXML, TaxList. Optional.
Default is TaxList (i.e. a simple text file).

=item -s outformat

An output format, including NeXML, TaxList. Optional. Default is TaxList (i.e.
a simple text file).

=item -t timeout

Number of seconds until user agent times out. Optional. Default is 60.

=item -t wait

Number of seconds between polling the TNRS service. Optional. Default is 5.

=back

=cut

# URL for the taxonomic name resolution service
my $TNRS_URL = 'http://128.196.142.27:3000/submit';

# defaults
my $timeout = 60;
my $wait    = 5;
my $serializer = 'taxlist';

sub _get_args {
	return (
		'timeout=i' => \$timeout,
		'wait=i'    => \$wait,
		'deserializer=s' => [ 'taxlist' ],
		'serializer=s'   => \$serializer,
	);
}

sub _run {
	my ( $class, $project ) = @_;
	
	# fetch logger
	my $log = $class->_log;
	
	# get taxa
	my ($taxa) = @{ $project->get_items(_TAXA_) };
	$log->info("extracted taxa");
	
	# fetch names from taxon objects
	my %taxon_for_name = map { $_->get_name => $_ } @{ $taxa->get_entities };
	
	# do the request
	my $result = _fetch_url( $TNRS_URL, 'post', 'query' => join "\n", keys %taxon_for_name ); # this is a redirect
	my $obj = decode_json($result);
	
	# start polling
	while(1) {
		sleep $wait;
		my $result = _fetch_url($obj->{'uri'},'get');
		my $obj = decode_json($result);
		if ( $obj->{'names'} ) {
			$log->debug(Dumper($obj));
			return _process_result($result);
			exit(0);
		}
	}

}

# fetch data from a URL
sub _fetch_url {
	my ( $url, $method, %form ) = @_;
	my $log = __PACKAGE__->_log;
	$log->info("going to fetch $url");
	
	# instantiate user agent
	my $ua = LWP::UserAgent->new;
	$ua->timeout($timeout);
	$log->info("instantiated user agent with timeout $timeout");
	
	# do the request on LWP::UserAgent $ua
	my $response = $ua->$method($url,\%form);
	
	# had a 200 OK
	if ( $response->is_success ) {
		$log->info($response->status_line);
		my $content = $response->decoded_content;
		return $content;
	}
	else {
		$log->error($response->status_line);
		die $response->status_line;
	}	
}

# parses the final TNRS result, maps back to input taxa, creates output
sub _process_result {
	my $content = shift;
	my $log = __PACKAGE__->_log;
	
	# parse result
	my ($tnrs_taxa) = @{ parse(
		'-format' => 'tnrs',
		'-string' => $content,
		'-as_project' => 1,
	)->get_items(_TAXA_) };
	$log->info("retrieved ".$tnrs_taxa->get_ntax. " results");
	
	# identify predicates to write out to adjacency table
	my @predicates;
	for my $meta ( @{ $tnrs_taxa->get_meta } ) {
		if ( my $source = $meta->get_object('tnrs:source') ) {
			push @predicates, "tnrs:${source}";
		}
	}
	
	# return result
	return $tnrs_taxa;
}

1;