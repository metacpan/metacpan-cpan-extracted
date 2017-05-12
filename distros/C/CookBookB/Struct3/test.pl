use CookBookB::Struct3;

$a = bless {}, CookBookB::Struct3;

$a->{lTrackId} = 42;
$a->{szDescription} = "hello, world";

$a->hello;

$b = CookBookB::Struct3::makeone();

print "b->lTrackId = $b->{lTrackId}\n";
print "b->szDescription = $b->{szDescription}\n";

bless $b, CookBookB::Struct3;
$b->hello;

