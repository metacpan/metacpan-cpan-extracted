#!/usr/local/bin/perl

use lib '.','./blib/lib','../blib/lib';
use Bio::Das;

my $das = Bio::Das->new(15);  # timeout of 15 sec
# $das->proxy('http://kato.lsjs.org/');
# $das->debug(1);

my @responses = $das->features(-dsn => ['http://www.wormbase.org:80/db/das/elegans',
					'http://dev.wormbase.org:80/db/das/elegans'
				       ],
			       -segment => [
					    'I:1,10000',
					    'II:1,10000',
					   ],
			       -category => 'transcription',
			      );
for my $response (@responses) {
  print "results from ",$response->dsn,"\n";
  die $response->error unless $response->is_success;

  my $results = $response->results;
  for my $seg (keys %$results) {
    my @features = @{$results->{$seg}};
    print "\t",join " ",$seg,scalar @features,"features \n";
  }
}

my $iterator =  $das->features(-dsn => ['http://www.wormbase.org/db/das/elegans',
					'http://dev.wormbase.org/db/das/elegans'
				       ],
			       -segment => [
					    'I:1,10000',
					    'II:1,10000',
					   ],
			       -category => 'transcription',
			       -iterator => 1,
			      );

while (my $feature = $iterator->next_seq) {
  my $dsn  = $feature->segment->dsn;
  my $type = $feature->type;
  print "got a $type from $dsn\n";
}

print "\n\n";
$das = Bio::Das->new('http://www.wormbase.org/db/das'=>'elegans');
my $segment =  $das->segment('I',1=>10000);
my $iterator = $segment->features(
				  -category => 'transcription',
				  -iterator => 1,
				 );

while (my $feature = $iterator->next_seq) {
  my $dsn  = $feature->segment->dsn;
  my $type = $feature->type;
  print "got a $type from $dsn\n";
}

print "\n";
$das = Bio::Das->new(15);  # timeout of 15 sec
my @responses = $das->stylesheet(-dsn => ['http://www.wormbase.org/db/das/elegans',
					  'http://dev.wormbase.org/db/das/elegans'
					 ]
				 );
foreach (@responses) { 
  my $dsn = $_->dsn;
  print $dsn->id,' (',$dsn->base,') ',$_->is_success,"\n"; 
}
