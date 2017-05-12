print "1..$last\n";  # $last is set below

use CookBookA::Ex8;
#use Devel::Peek 'Dump';

$a = CookBookA::Ex8->new;
$a->into;
$a->set_elem(0,"ok 4");
$a->set_elem(1,"ok 5");
$a->set_elem(2,"ok 6");
$a->into;


$b = ["ok 7", "ok 8"];
CookBookA::Ex8A::into10( $b );

$c = CookBookA::Ex8A::outof10();
foreach (@$c){
	print "$_\n";
}
$c->[0] = "ok 12";
$c->[1] = "ok 13";
$c->[2] = "ok 14";
$c->[3] = "ok 15";
CookBookA::Ex8A::into10( $c );

BEGIN { $last = 15; }
