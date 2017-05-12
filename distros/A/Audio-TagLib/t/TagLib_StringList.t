use Test::More tests => 9;

BEGIN { use_ok('Audio::TagLib::StringList') };

my @methods = qw(new DESTROY toString append split);
can_ok("Audio::TagLib::StringList", @methods) 								or 
	diag("method can_ok failed");

my $i = Audio::TagLib::StringList->new();
ok($i->toString()->isEmpty()) 										or 
	diag("method new() failed");
my $j = Audio::TagLib::StringList->new(Audio::TagLib::String->new("blah blah"));
is($j->toString()->toCString(), "blah blah") 						or 
	diag("method new(String) failed");
my $k = Audio::TagLib::StringList->new($j);
is($k->toString()->toCString(), "blah blah") 						or 
	diag("method new(StringList) failed");
my $vl = Audio::TagLib::ByteVectorList->split(
	Audio::TagLib::ByteVector->new("blah blah"), Audio::TagLib::ByteVector->new(" "));
my $l = Audio::TagLib::StringList->new($vl);
is($l->toString(Audio::TagLib::String->new("_"))->toCString(), "blah_blah") 
	or diag("method new(ByteVectorList) failed");
my $m = $i->append($j);
is($m->toString()->toCString(), "blah blah") 						or 
	diag("method append(StringList) failed");
my $n = $m->append(Audio::TagLib::String->new("blah blah"));
is($n->toString()->toCString(), "blah blah blah blah") 				or 
	diag("method append(String) failed");
my $o = Audio::TagLib::StringList->split(
	Audio::TagLib::String->new("This is a test"), Audio::TagLib::String->new(" "));
is($o->toString(Audio::TagLib::String->new("_"))->toCString(), 
	"This_is_a_test") or diag("method split(string, pattern) failed");
