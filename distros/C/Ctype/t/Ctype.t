print "1..5\n";
use Ctype qw(isalpha useperlfns);
print "ok 1\n";
$obj = Ctype->new("A");
if ($obj->isuppercase) {
	print "ok 2\n";
} else {
	print "not ok 2\n";
}
if (isalpha("A")) {
	print "ok 3\n";
} else {
	print "not ok 3\n";
}
$obj->useperlfns;
if ($obj->isuppercase) {
	print "ok 4\n";
} else {
	print "not ok 4\n";
}
$Ctype::useperlfns = 1;
if (isalpha("A")) {
	print "ok 5\n";
} else {
	print "not ok 5\n";
}
