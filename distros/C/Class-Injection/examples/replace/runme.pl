
use lib '../../lib';

use Local::Target;
use Local::Over;


Class::Injection::install();


my $foo = Local::Target->new();


$foo->test();


