use Test::Most skip_all => 'requires a chef server';

use Chef::Knife::Cmd;

my $knife;
my $out;
my $node     = "eric";
my $expected = {
    name             => $node,
    chef_environment => "production",
    run_list         => ignore,
    normal           => ignore,
};

my $cb = sub {
    my ($type, $msg) = @_;
    diag "$type $msg\n";
};

$knife = Chef::Knife::Cmd->new(callback => $cb);
$out   = $knife->node->show($node);
like $out , qr/Node Name:\s+$node/, "knife node show $node";

$out   = $knife->node->show($node, format => 'json');
cmp_deeply $out, $expected, "knife node show $node --format json";

$knife = Chef::Knife::Cmd->new(format => 'json', callback => $cb);
$out   = $knife->node->show($node);
cmp_deeply $out, $expected, "knife node show $node --format json (constructor)";

unlink 't/knife.log';

done_testing;
