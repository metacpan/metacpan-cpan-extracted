use CookBookB::Struct2;

$a = bless [], CookBookB::Struct2;

$a->[0] = 42;
$a->[1] = "hello, world";

$a->hello;

$b = CookBookB::Struct2::makeone();

print "b->lTrackId = $b->[0]\n";
print "b->szDescription = $b->[1]\n";

bless $b, CookBookB::Struct2;
$b->hello;

