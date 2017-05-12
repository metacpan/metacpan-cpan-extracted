
use lib '../../lib';

use Data::Dumper;

eval('use Local::Plugin1;');
eval('use Local::Plugin2;');

use Class::Injection;
use Local::Abstract;

Class::Injection::install();


my $foo = Local::Abstract->new();








my @res = $foo->test();

print "\n---- context is array ---\n\n";
print Dumper(@res);

