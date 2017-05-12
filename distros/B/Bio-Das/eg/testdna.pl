#!/usr/local/bin/perl

use lib './blib/lib','../blib/lib';
use Bio::Das;

# serialize it
my $das = Bio::Das->new(10);  # timeout of 10 sec
my $response = $das->dna(-dsn => 'http://www.wormbase.org/db/das/elegans',
			 -segment => ['CHROMOSOME_I:1,10000',
				      'CHROMOSOME_II:1,10000']);
die $response->error unless $response->is_success;

my $results = $response->results;

for my $seg (keys %$results) {
  print $seg,"\t",length $results->{$seg},"\n";
}
