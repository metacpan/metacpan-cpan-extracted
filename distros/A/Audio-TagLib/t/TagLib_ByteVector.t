use Test::More tests => 59;

BEGIN { use_ok('Audio::TagLib::ByteVector') };

my @methods = qw(new DESTROY setData data mid at find rfind containsAt
                 startsWith endsWith endsWithPartialMatch append clear size resize
                 begin end isNull isEmpty checksum toUInt toShort toLongLong _to_array
                 setItem _equal _notEqual _lessThan _greatThan _add copy fromUInt
                 fromShort fromLongLong fromCString null);
can_ok('Audio::TagLib::ByteVector', @methods)                                       or
    diag("can_ok failed");

my $i = Audio::TagLib::ByteVector->new();
is($i->data(), undef)						                                        or 
	diag("new an empty object failed");
is(Audio::TagLib::ByteVector->new(3, "a")->data(), "aaa")		                    or 
	diag("new an object with size and padding char failed");
cmp_ok(Audio::TagLib::ByteVector->new(3)->size(), '==', 3)		                    or 
	diag("new an object with size and char=0 failed");
$i->setData("blah blah blah");
is(Audio::TagLib::ByteVector->new($i)->data(), "blah blah blah") 	                or 
	diag("copy constructor failed");
is(Audio::TagLib::ByteVector->new("t")->data(), "t")                                or
	diag("literal constructor failed");
cmp_ok(Audio::TagLib::ByteVector->new("t")->size(), "==", 1)		                or 
	diag("new an object with char failed");
is(Audio::TagLib::ByteVector->new("blah", length("blah"))->data(), "blah")	        or 
	diag("new an object with string and length failed");
cmp_ok(Audio::TagLib::ByteVector->new("blah", 10)->size(), "==", 10)	            or 
	diag("new an object with string and length failed");
is(Audio::TagLib::ByteVector->new("blah")->data(), "blah") 		                    or 
	diag("new an object with string, check data failed");
cmp_ok(Audio::TagLib::ByteVector->new("blah")->size(), "==", 4) 	                or 
	diag("new an object with string, check size failed");
$i = Audio::TagLib::ByteVector::->new('blah blah blah');
$i->setData('BLAH');
is($i->data(), 'BLAH')	                                                            or
	 diag('method setData failed');
cmp_ok($i->size(), '==', 4)		                                                    or 
	diag('method setData update failed'); 
$i->setData('blah BLAH', 4);
is($i->data(), 'blah') 	                                                            or 
	diag('method setData with length failed');
$i = Audio::TagLib::ByteVector::->new("blah blah");
is($i->mid(0,1)->data(), "b")		                                                or
	diag("method mid with length = 1 failed");
is($i->mid(0,2)->data(), "bl")		                                                or 
	diag("method mid with length = 2 failed");
is($i->at(0), "b")			                                                        or 
	diag("method at failed");
is($i->at(4), " ")			                                                        or 
	diag("method at failed");
my $j = Audio::TagLib::ByteVector->new("blah");
cmp_ok($i->find($j), "==", 0)		                                                or 
	diag("method find(pattern) failed");
cmp_ok($i->find($j, 1), "==", 5)	                                                or 
	diag("method find(pattern, offset) failed");
cmp_ok($i->find($j, 1, 1), "==", 5)	                                                or 
	diag("method find failed");
cmp_ok($i->rfind($j), "==", 5)		                                                or 
	diag("method rfind(pattern) failed");
cmp_ok($i->rfind($j, 5), "==", 5) 	                                                or 
	diag("method rfind(pattern, offset) failed");
cmp_ok($i->rfind($j, 5, 1), "==", 5) 	                                            or 
	diag("method rfind failed");
ok($i->containsAt($j, 0))		                                                    or 
	diag("method containsAt(pattern)");
# Look for "ah" ("blah" offset 2) in "blah blah" (starting at 7)
ok($i->containsAt($j, 7, 2))		                                                or 
	diag("method containsAt(pattern, offset, patternOffset)
failed");
# Look for "bl" ("blah" offset 0 length 2) in "blah blah" (starting at 5)
ok($i->containsAt($j, 5, 0, 2))	                                                    or 
	diag("method containsAt failed");
ok($i->startsWith($j))			                                                    or 
	diag("method startsWith failed");
ok($i->endsWith($j))			                                                    or 
	diag("method endsWith failed");
ok($i->endsWithPartialMatch(Audio::TagLib::ByteVector->new("a blah")))              or 
	diag("method endsWithPartialMatch failed");
$i->append(Audio::TagLib::ByteVector->new(" blah"));
is($i->data(), "blah blah blah")	                                                or 
	diag("method append failed");

$i = Audio::TagLib::ByteVector->new("blah");
$i->clear();
is($i->data(), undef) 			                                                    or 
	diag("method clear failed");
# GCL length of undef is undef
# cmp_ok($i->size(), "==", length($i->data())) 		or 
cmp_ok($i->size(), "==", 0) 		                                                or 
	diag("method size failed");

$i = Audio::TagLib::ByteVector->new("blah blah");
$i = $i->resize(4);
is($i->data(), "blah")			                                                    or 
	diag("method resize failed");
cmp_ok($i->size(), "==", 4) 		                                                or 
	diag("method resize failed");

my $ibegin = $i->begin();
isa_ok($ibegin, "Audio::TagLib::ByteVector::Iterator") 	                            or 
	diag("method begin() failed");
my $iend = $i->end();
isa_ok($iend, "Audio::TagLib::ByteVector::Iterator") 		                        or 
	diag("method end() failed");

ok(not $i->isNull()) 			                                                    or 
	diag("method isNull failed");
ok(Audio::TagLib::ByteVector->null()->isNull())                                                     or 
	diag("method isNull failed");
ok(not $i->isEmpty())			                                                    or 
	diag("method isEmpty failed");
ok(Audio::TagLib::ByteVector->null()->isEmpty())                                    or
	diag("method isEmpty failed");

$i = Audio::TagLib::ByteVector->new("blah blah");
# GCL Is this implementation dependent?
# cmp_ok($i->checksum(), "==", 1911406642) or
cmp_ok($i->checksum(), "==", 1698033220)                                            or
	diag("method checksum failed");
cmp_ok($i->toUInt(), "==", 1651269992)	                                            or 
	diag("method toUInt failed");
cmp_ok($i->toShort(), "==", 25196)	                                                or 
	diag("method toShort failed");
is($i->toLongLong(), "7.0921506130495e+18")                                         or 
	diag("method toLongLong failed");
is($i->[0], "b")			                                                        or 
	diag("operator[] failed");
is($i->[4], " ")			                                                        or 
	diag("operator[] failed");
$i->setItem(0, "B");
is($i->[0], "B")			                                                        or 
	diag("method setItem failed");
$i->setItem(0, "b");
ok($i == Audio::TagLib::ByteVector->new($i))	                                    or 
	diag("operator== failed");
ok($i != Audio::TagLib::ByteVector->new())	                                        or 
	diag("operator!= failed");
ok($i > Audio::TagLib::ByteVector->new("a"))	                                    or 
	diag("operator> failed");
ok($i < Audio::TagLib::ByteVector->new("f"x20))                                     or 
	diag("operator< failed");
$j = Audio::TagLib::ByteVector->new("bl") + 
	 Audio::TagLib::ByteVector->new("ah");
is($j->data(), "blah")			                                                    or 
	diag("operator+ failed");
# in fact this can NOT check operator=
# Dump the two objects 
# the address of pointer should be different
my $k = Audio::TagLib::ByteVector->new("bl");
$j = $k;
$j += Audio::TagLib::ByteVector->new("ah");
is($j->data(), "blah")			                                                    or 
	diag("operator= failed");
my $x = Audio::TagLib::ByteVector->new("blah");
cmp_ok(Audio::TagLib::ByteVector->fromUInt($x->toUInt())->toUInt(), 
	"==", $x->toUInt())                                                             or
	diag("static method fromUInt failed");
my $y = Audio::TagLib::ByteVector->new("bl");
cmp_ok(Audio::TagLib::ByteVector->fromShort($y->toShort())->toShort(), 
	"==", $y->toShort())                                                            or 
	diag("static method fromShort failed");
my $z1 = Audio::TagLib::ByteVector->new("blahblah");
my $z2 = Audio::TagLib::ByteVector->new("blahblah");
is(Audio::TagLib::ByteVector->fromLongLong($z1->toLongLong())->toLongLong(), 
	Audio::TagLib::ByteVector->fromLongLong($z2->toLongLong())->toLongLong())       or 
	diag("static method fromLongLong failed");
is(Audio::TagLib::ByteVector->fromCString("blah")->data(), "blah")                  or 
	diag("static method fromCString failed");
