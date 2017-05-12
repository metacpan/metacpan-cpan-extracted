use Test::Most;

use Chef::Knife::Cmd;

my $node  = 'arfarf';
my $knife = Chef::Knife::Cmd->new(noop => 1);

my $client = 'client';
is $knife->client->delete($client),
    "knife client delete $client",
    "knife client delete $client";

done_testing;
