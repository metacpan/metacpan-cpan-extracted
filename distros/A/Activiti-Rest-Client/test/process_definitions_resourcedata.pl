#!/usr/bin/env perl
use FindBin;
use lib "$FindBin::Bin/../lib";
use Activiti::Rest::Client;
use Data::Dumper;

binmode STDOUT,":utf8";

my $client = Activiti::Rest::Client->new(
  url => 'http://kermit:kermit@localhost:8080/activiti-rest/service'
);

my $pdefs = $client->process_definitions->parsed_content;
my @ids = map { $_->{id} } @{ $pdefs->{data} };
for my $id(@ids){
  print $client->process_definition_resource_data(processDefinitionId => $id)->parsed_content;
}
