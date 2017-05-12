use Test::More;

use lib qw( t );

# Since PluginLibB does not inherit from Algorithm::CheckDigits we have to use
# Algorithm::CheckDigits here to make use of the function CheckDigits() to get
# our algorithm checker.
#
use Algorithm::CheckDigits;
use PluginLibB;

# To get access to the algorithm provided by module PluginLibB, we have to use
# the keys stored in these publicly accessible variables.

my $cd1 = CheckDigits($PluginLibB::meth1);
my $cd2 = CheckDigits($PluginLibB::meth2);
my $cd3 = CheckDigits($PluginLibB::meth3);

is($cd1->checkdigit(234), 1, 'checked method1 of PluginLibB');
is($cd2->basenumber(234), 2, 'checked method2 of PluginLibB');
is($cd3->complete(234),   3, 'checked method3 of PluginLibB');

done_testing();
