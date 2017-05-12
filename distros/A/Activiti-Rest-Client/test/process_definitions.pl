#!/usr/bin/env perl
use FindBin;
use lib "$FindBin::Bin/../lib";
use Activiti::Rest::Client;
use Data::Dumper;

binmode STDOUT,":utf8";

my $client = Activiti::Rest::Client->new(
  url => 'http://kermit:kermit@localhost:8080/activiti-rest/service'
);

my $res = $client->process_definitions;

die("no parsed content") unless $res->has_parsed_content;

my $pdefs = $res->parsed_content;

my @ids = map { $_->{id} } @{ $pdefs->{data} };
for my $id(@ids){
  print Dumper($client->process_definition(processDefinitionId => $id)->parsed_content);
}
