
use lib '../../lib';

use Data::Dumper;

eval('use Local::Plugin1;');
eval('use Local::Plugin2;');

use Class::Injection;
use Local::Abstract;

Class::Injection::install();





my $foo = Local::Abstract->new();



print "\n---- context is scalar ---\n\n";

my $res = $foo->test();

print Dumper($res);


#  print Dumper(Class::Injection::info);


Class::Injection::show_replacement_matrix;
