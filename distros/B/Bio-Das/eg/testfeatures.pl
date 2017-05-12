#!/usr/local/bin/perl

use lib '.','./blib/lib','../blib/lib';
use Bio::Das;
use Carp 'cluck';

my $das = Bio::Das->new(15);  # timeout of 15 sec
# $das->debug(1);
# $das->proxy('http://kato.lsjs.org/');

# this callback will print the features as they are reconstructed
my $callback = sub {
  my $feature = shift;
  my $segment = $feature->segment;
  my ($start,$stop) = ($feature->start,$feature->stop);
  print "$segment => $feature ($start,$stop)\n";
};

$das->debug(0);

my $response = $das->features(-dsn => 'http://genome.cse.ucsc.edu/cgi-bin/das/hg16',
			      -segment => [
					   'chr1:1000000,1020000',
					   'chr22:17000000,17010000',
					  ],
			      -category => 'transcription',
			      -callback => $callback
			     );
die $response->error unless $response->is_success;

my $results = $response->results;

for my $seg (keys %$results) {
  my @features = @{$results->{$seg}};
  print join " ",$seg,@features,"\n";
}
