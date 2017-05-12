use Test::More;

use lib qw( t );

use PluginLibB;

# To get access to the algorithm provided by module PluginLibB, we have to use
# the keys stored in these publicly accessible variables.

my $cd1 = PluginLibB->new($PluginLibB::meth1);
my $cd2 = PluginLibB->new($PluginLibB::meth2);
my $cd3 = PluginLibB->new($PluginLibB::meth3);

is($cd1->checkdigit(234), 1, 'checked method1 of PluginLibB');
is($cd2->basenumber(234), 2, 'checked method2 of PluginLibB');
is($cd3->complete(234),   3, 'checked method3 of PluginLibB');

done_testing();
