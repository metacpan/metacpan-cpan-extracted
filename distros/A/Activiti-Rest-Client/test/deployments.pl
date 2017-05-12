#!/usr/bin/env perl
use FindBin;
use lib "$FindBin::Bin/../lib";
use Activiti::Rest::Client;
use Data::Dumper;

binmode STDOUT,":utf8";

my $client = Activiti::Rest::Client->new(
  url => 'http://kermit:kermit@localhost:8080/activiti-rest/service'
);

my $deployments = $client->deployments->parsed_content;
my @ids = map { $_->{id} } @{ $deployments->{data} };
for my $id(@ids){
  print Dumper($client->deployment(deploymentId => $id)->parsed_content);
}
