#!/usr/bin/env perl
use FindBin;
use lib "$FindBin::Bin/../lib";
use Activiti::Rest::Client;
use Data::Dumper;

binmode STDOUT,":utf8";

my $client = Activiti::Rest::Client->new(
  url => 'http://kermit:kermit@localhost:8080/activiti-rest/service'
);

my $users = $client->users->parsed_content;
my @ids = map { $_->{id} } @{ $users->{data} };
for my $id(@ids){
  print Dumper($client->user(userId => $id)->parsed_content);
  print Dumper($client->user_info(userId => $id)->parsed_content);
}
