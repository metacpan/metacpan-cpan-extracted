use Test::Most;

use Chef::Knife::Cmd;

my $node  = 'arfarf';
my $knife = Chef::Knife::Cmd->new(noop => 1);

is $knife->ec2->server->list(),
    "knife ec2 server list",
    "knife ec2 server list";

is $knife->ec2->server->create(node_name => $node),
    "knife ec2 server create --node-name $node",
    "knife ec2 server create --node-name $node";

my $cmd = $knife->ec2->server->delete(
    ['i-12345678'],
    node_name => $node,
    region    => 'us-east-1',
    purge     => 1,
    yes       => 1,
);
is $cmd,
    "knife ec2 server delete i-12345678 --node-name $node --purge --region us-east-1 --yes",
    "knife ec2 server delete i-12345678 --node-name $node --purge --region us-east-1 --yes";

done_testing;
