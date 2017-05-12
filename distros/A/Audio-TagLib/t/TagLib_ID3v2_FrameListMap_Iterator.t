use Test::More tests => 8;

BEGIN { use_ok('Audio::TagLib::ID3v2::FrameListMap::Iterator') };

my @methods = qw(new DESTROY data next last);
can_ok("Audio::TagLib::ID3v2::FrameListMap::Iterator", @methods) 			    or 
	diag("can_ok failed");

my $tag = Audio::TagLib::ID3v2::Tag->new();
$tag->setTitle(Audio::TagLib::String->new("title"));
$tag->setArtist(Audio::TagLib::String->new("artist"));
$tag->setYear(1981);

my $item = $tag->frameList();
my $key = Audio::TagLib::ByteVector->new("key");
my $key2 = Audio::TagLib::ByteVector->new("key2");
my $map = Audio::TagLib::ID3v2::FrameListMap->new();
$map->insert($key, $item);
$map->insert($key2, $item);

my $i = $map->begin();
isa_ok($i, "Audio::TagLib::ID3v2::FrameListMap::Iterator") 				        or 
	diag("method Audio::TagLib::ID3v2::Tag::frameListMap failed");
isa_ok(Audio::TagLib::ID3v2::FrameListMap::Iterator->new(), 
	"Audio::TagLib::ID3v2::FrameListMap::Iterator") 						    or 
	diag("method new() failed");
isa_ok(Audio::TagLib::ID3v2::FrameListMap::Iterator->new($i), 
	"Audio::TagLib::ID3v2::FrameListMap::Iterator") 						    or 
	diag("method new(i) failed");

like($i->data()->begin()->data()->render()->data(), qr/^TIT2.*?title$/)         or
    diag("method data() failed");
like($i->next()->data()->begin()->data()->render()->data(), qr/^TIT2.*?title$/) or
    diag("method next() failed");
like((--$i)->data()->begin()->data()->render()->data(), qr/^TIT2.*?title$/)     or
    diag("method last() failed");
