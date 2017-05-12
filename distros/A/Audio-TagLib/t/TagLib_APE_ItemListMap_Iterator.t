use Test::More tests => 8;

BEGIN { use_ok('Audio::TagLib::APE::ItemListMap::Iterator') };

my @methods = qw(new DESTROY data next last);
can_ok("Audio::TagLib::APE::ItemListMap::Iterator", @methods)       or
    diag("can_ok failed");
my $apetag = Audio::TagLib::APE::Tag->new();
$apetag->setTitle(Audio::TagLib::String->new("title"));
$apetag->setArtist(Audio::TagLib::String->new("artist"));
$apetag->setYear(1981);
my $map = $apetag->itemListMap();
my $i = $map->begin();
isa_ok($i, "Audio::TagLib::APE::ItemListMap::Iterator") 			or 
	diag("method Audio::TagLib::APE::Tag::itemListMap() failed");
isa_ok(Audio::TagLib::APE::ItemListMap::Iterator->new(), 
	"Audio::TagLib::APE::ItemListMap::Iterator") 					or 
	diag("method new() failed");
isa_ok(Audio::TagLib::APE::ItemListMap::Iterator->new($i), 
	"Audio::TagLib::APE::ItemListMap::Iterator") 					or 
	diag("method new(i) failed");

is($i->data()->toString()->toCString(), "artist") 					or 
	diag("method data() failed");
is($i->next()->data()->toString()->toCString(), "title") 			or 
	diag("method next() failed");
is((--$i)->data()->toString()->toCString(), "artist") 				or 
	diag("method last() failed");
