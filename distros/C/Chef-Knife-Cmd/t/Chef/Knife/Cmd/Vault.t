use Test::Most;

use Chef::Knife::Cmd;

my $node   = 'arfarf';
my $vault  = 'priv_keys';
my $item   = 'tarsnap';
my $values = '{ "yarf" : "gnarble", "yiff" : 1 }';
my $admin  = 'batman';
my $path   = '/tmp/deleteme';

my $knife = Chef::Knife::Cmd->new(noop => 1);

is $knife->vault->create($vault, $item, $values),
    "knife vault create $vault $item '$values'",
    "knife vault create $vault $item '$values'";

my $cmd = $knife->vault->update($vault, $item, undef, 
    search => "name:$node", 
    mode   => "client",
);
is $cmd,
    "knife vault update $vault $item --mode client --search name:$node",
    "knife vault update $vault $item --mode client --search name:$node";

my $rv = $knife->vault->delete($vault, $item,
    admins => $admin,
    mode   => 'client',
);
is $rv,
    "knife vault delete $vault $item --admins $admin --mode client",
    "knife vault delete $vault $item --admins $admin --mode client";

is $knife->vault->show($vault, $item),
    "knife vault show $vault $item",
    "knife vault show $vault $item";

is $knife->vault->list,
    "knife vault list",
    "knife vault list";

my $cmd2 = $knife->vault->remove($vault, $item, undef, 
    search => "name:$node", 
    mode   => "client",
);
is $cmd2,
    "knife vault remove $vault $item --mode client --search name:$node",
    "knife vault remove $vault $item --mode client --search name:$node";

is $knife->vault->download($vault, $item, $path),
    "knife vault download $vault $item $path",
    "knife vault download $vault $item $path";

done_testing;
