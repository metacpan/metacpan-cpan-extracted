print "1..1\n";
require CookBookB::Struct1;

$a = CookBookB::Struct1->new;
$a->desc( "twiddle" );
$x = $a->hello;
print "ok ", ($x == 100), "\n";

