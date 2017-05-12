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
print $_."\n" for map { $_->{id} } @{ $pdefs->{data} };
