#!/usr/bin/env perl
use FindBin;
use lib "$FindBin::Bin/../lib";
use Activiti::Rest::Client;
use Data::Dumper;

binmode STDOUT,":utf8";

my $client = Activiti::Rest::Client->new(
  url => 'http://kermit:kermit@localhost:8080/activiti-rest/service'
);

my $form = $client->form(processDefinitionId => "vacationRequest:1:33")->parsed_content;
print Dumper($form);
