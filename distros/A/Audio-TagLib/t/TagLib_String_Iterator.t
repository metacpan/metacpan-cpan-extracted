use Test::More tests => 19;

BEGIN { use_ok('Audio::TagLib::String::Iterator') };

my @methods = qw(new DESTROY data next last forward backward);
can_ok("Audio::TagLib::String::Iterator", @methods) or diag("can_ok failed");

my $data = "\x{6211}\x{7684}" x 2;
my $v = Audio::TagLib::String->new($data);
my $i = $v->begin();
isa_ok($i, "Audio::TagLib::String::Iterator") 							or 
	diag("method Audio::TagLib::String::begin() failed");
isa_ok(Audio::TagLib::String::Iterator->new(), 
	"Audio::TagLib::String::Iterator") 								or 
	diag("method new() failed");
isa_ok(Audio::TagLib::String::Iterator->new($i), 
	"Audio::TagLib::String::Iterator") 								or 
	diag("method new(i) failed");

is($i->data(), "\x{6211}") 			or 
	diag("method data() failed");
is($$i, "\x{6211}") 				or 
	diag("method data() failed");
$i->next();
is($i->data(), "\x{7684}") 			or 
	diag("method next() failed");
is((++$i)->data(), "\x{6211}") 		or 
	diag("operator++ failed");
is(($i++)->data(), "\x{6211}") 		or 
	diag("operator++(int) and operator = failed");
is($i->data(), "\x{7684}") 			or 
	diag("operator++(int) failed");
$i->last();
is($i->data(), "\x{6211}") 			or 
	diag("method last() failed");
is((--$i)->data(), "\x{7684}") 		or 
	diag("operator-- failed");
is(($i--)->data(), "\x{7684}") 		or 
	diag("operator--(int) and operator = failed");
is($i->data(), "\x{6211}") 			or 
	diag("operator--(int) failed");
$i->forward(1);
is($i->data(), "\x{7684}") 			or 
	diag("method forward(n) failed");
is(($i += 1)->data(), "\x{6211}") 	or 
	diag("operator+= failed");
$i->backward(1);
is($i->data(), "\x{7684}") 			or 
	diag("method backward(n) failed");
is(($i -= 1)->data(), "\x{6211}") 	or 
	diag("operator-= failed");
