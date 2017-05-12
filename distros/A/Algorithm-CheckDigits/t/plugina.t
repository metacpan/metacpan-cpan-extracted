use Test::More;

use lib qw( t );

# Since the module PluginLibA reexports the function CheckDigits() from
# Algorithm::CheckDigits, we do not need to explicitly use that module to get
# the function into our name space.

use PluginLibA;

# To get access to the algorithm provided by module PluginLibA, we have to use
# the keys stored in these publicly accessible variables.

my $cd1 = CheckDigits($PluginLibA::meth1);
my $cd2 = CheckDigits($PluginLibA::meth2);
my $cd3 = CheckDigits($PluginLibA::meth3);

is($cd1->checkdigit(234), 1, 'checked method1 of PluginLibA');
is($cd2->basenumber(234), 2, 'checked method2 of PluginLibA');
is($cd3->complete(234),   3, 'checked method3 of PluginLibA');

done_testing();
