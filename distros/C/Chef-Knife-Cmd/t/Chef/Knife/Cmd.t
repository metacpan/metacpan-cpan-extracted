use Test::Most;

use Chef::Knife::Cmd;

my $knife = Chef::Knife::Cmd->new(noop => 1);

my $cmd = $knife->bootstrap(
    '127.0.0.1',
    distro             => 'chef-full',
    environment        => 'production',
    no_host_key_verify => 1,
    node_name          => 'arfarf',
    run_list           => 'role[base]',
    sudo               => 1,
);

is $cmd,
    "knife bootstrap 127.0.0.1 --distro chef-full --environment production --no-host-key-verify --node-name arfarf --run-list 'role[base]' --sudo",
    "knife bootstrap 127.0.0.1 --distro chef-full --environment production --no-host-key-verify --node-name arfarf --run-list 'role[base]' --sudo";

done_testing;
