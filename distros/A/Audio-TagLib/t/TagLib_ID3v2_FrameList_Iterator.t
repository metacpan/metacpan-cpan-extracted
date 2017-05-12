use Test::More tests => 8;

BEGIN { use_ok('Audio::TagLib::ID3v2::FrameList::Iterator') };

my @methods = qw(new DESTROY data next last);
can_ok("Audio::TagLib::ID3v2::FrameList::Iterator", @methods) 		or 
	diag("can_ok failed");

my $tag = Audio::TagLib::ID3v2::Tag->new();
$tag->setTitle(Audio::TagLib::String->new("title"));
$tag->setArtist(Audio::TagLib::String->new("artist"));
$tag->setYear(1981);
my $list = $tag->frameList();

my $i = $list->begin();
isa_ok($i, "Audio::TagLib::ID3v2::FrameList::Iterator") 			or 
	diag("method Audio::TagLib::ID3v2::Tag::FrameList() failed");
isa_ok(Audio::TagLib::ID3v2::FrameList::Iterator->new(), 
	"Audio::TagLib::ID3v2::FrameList::Iterator") 					or 
	diag("method new() failed");
isa_ok(Audio::TagLib::ID3v2::FrameList::Iterator->new($i), 
	"Audio::TagLib::ID3v2::FrameList::Iterator") 					or 
	diag("method new(i) failed");

like($i->data()->render()->data(), qr/^TIT2.*?title$/) 				or 
	diag("method data() failed");
like($i->next()->data()->render()->data(), qr/^TPE1.*?artist$/) 	or 
	diag("method next() failed");
like((--$i)->data()->render()->data(), qr/^TIT2.*?title$/) 			or 
	diag("method last() failed");
