use Test::More tests => 19;

BEGIN { use_ok('Audio::TagLib::ByteVector::Iterator') };

my @methods = qw(new DESTROY data next last forward backward);
can_ok("Audio::TagLib::ByteVector::Iterator", @methods)             or
    diag("can_ok failed");

my $v = Audio::TagLib::ByteVector->new("blah blah blah");
my $i = $v->begin();
isa_ok($i, "Audio::TagLib::ByteVector::Iterator") 					or 
	diag("method Audio::TagLib::ByteVector::begin() failed");
isa_ok(Audio::TagLib::ByteVector::Iterator->new(), 
	"Audio::TagLib::ByteVector::Iterator") 							or 
	diag("method new() failed");
isa_ok(Audio::TagLib::ByteVector::Iterator->new($i), 
	"Audio::TagLib::ByteVector::Iterator") 							or 
	diag("method new(i) failed");

is($i->data(), "b") 			                                    or 
	diag("method data() failed");
is($$i, "b") 					                                    or 
	diag("method data() failed");
$i->next();
is($i->data(), "l") 			                                    or 
	diag("method next() failed");
is((++$i)->data(), "a") 			                                or 
	diag("operator++ failed");
is(($i++)->data(), "a") 			                                or 
	diag("operator++(int) and operator = failed");
is($i->data(), "h") 				                                or 
	diag("operator++(int) failed");
$i->last();
is($i->data(), "a") 				                                or 
	diag("method last() failed");
is((--$i)->data(), "l") 			                                or 
	diag("operator-- failed");
is(($i--)->data(), "l") 			                                or 
	diag("operator--(int) and operator = failed");
is($i->data(), "b") 				                                or 
	diag("operator--(int) failed");
$i->forward(1);
is($i->data(), "l") 				                                or 
	diag("method forward(n) failed");
is(($i += 1)->data(), "a") 			                                or 
	diag("operator+= failed");
$i->backward(1);
is($i->data(), "l") 				                                or 
	diag("method backward(n) failed");
is(($i -= 1)->data(), "b") 			                                or 
	diag("operator-= failed");
