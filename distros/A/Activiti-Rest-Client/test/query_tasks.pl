#!/usr/bin/env perl
use FindBin;
use lib "$FindBin::Bin/../lib";
use Activiti::Rest::Client;
use Data::Dumper;

binmode STDOUT,":utf8";

my $client = Activiti::Rest::Client->new(
  url => 'http://rest:rest@andric.ugent.be:8888/activiti-rest/service'
);

my $res = $client->query_tasks(
  content => {
#    "processDefinitionKey" => "CustomerRequest",
#    includeProcessVariables => "true",  
    candidateGroup => "LWBIB"
    #processInstanceId => 418    
#    processInstanceVariables => [
#      {
#          "name" => "library",
#          "value" => "BIB",
#          "operation" => "equals",
#          "type" => "string"
#      }
#    ]
  }
);

die("no parsed content") unless $res->has_parsed_content;

print Dumper($res->parsed_content);
