#!/usr/bin/env perl
use FindBin;
use lib "$FindBin::Bin/../lib";
use Activiti::Rest::Client;
use Data::Dumper;

binmode STDOUT,":utf8";

my $client = Activiti::Rest::Client->new(
  url => 'http://kermit:kermit@localhost:8080/activiti-rest/service'
);

my $models = $client->models->parsed_content;
my @ids = map { $_->{id} } @{ $models->{data} };
for my $id(@ids){
  print Dumper($client->model(modelId => $id)->parsed_content);
}
