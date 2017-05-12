# vim: filetype=perl :
use strict;
use warnings;

use Test::More tests => 32; # last test to print
use Data::Dumper;

use lib qw< t >;
use ASTest;

use App::Sets;

$ENV{SETS_INTERNAL_SORT} = 1;

close STDOUT;
for my $test (test_specifications()) { # defined below
   my ($t1, $ops, $t2, $result) = @{$test}{qw< t1 op t2 result >};
   $t1 = locate_file($t1);
   $t2 = locate_file($t2);
   for my $op (ref $ops ? @$ops : $ops) {
      {
         open STDOUT, '>', \my $output;
         App::Sets->run('--loglevel' => 'OFF', $t1, $op, $t2);
         is($output, $result, "$t1 $op $t2 - as single string");
         close STDOUT;
      }
      {
         open STDOUT, '>', \my $output;
         App::Sets->run('--loglevel' => 'OFF', $t1, $op, $t2);
         is($output, $result, "$t1 $op $t2 - as single string");
         close STDOUT;
      }
   }
}
done_testing();

sub test_specifications {
   return (
      {
         t1 => 'lista1',
         op => [qw< minus less \ - >],
         t2 => 'lista2',
         result => 'nono
quarto
secondo
sesto
',
      },

      {
         t1 => 'lista1',
         op => [qw< union u U v V | + >],
         t2 => 'lista2',
         result => 'ancora
decimo
nono
nullo
ottavo
primo
quarto
quinto
secondo
sesto
settimo
terzo
undicesimo
',
      },

      {
         t1 => 'lista1',
         op => [qw< intersect i I & ^  >],
         t2 => 'lista2',
         result => 'decimo
ottavo
primo
quinto
settimo
terzo
',
      },
   );
}
