#!/usr/bin/env perl
use FindBin;
use lib "$FindBin::Bin/../lib";
use Activiti::Rest::Client;
use Data::Dumper;

binmode STDOUT,":utf8";

my $client = Activiti::Rest::Client->new(
  url => 'http://rest:rest@andric.ugent.be:8888/activiti-rest/service'
);

my $res = $client->delete_historic_process_instance(processInstanceId => 418);

print Dumper($res->parsed_content);
