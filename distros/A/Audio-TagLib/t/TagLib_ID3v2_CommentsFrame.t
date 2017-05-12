use Test::More tests => 9;

BEGIN { use_ok('Audio::TagLib::ID3v2::CommentsFrame') };

my @methods = qw(new DESTROY toString language description text
                 setLanguage setDescription setText textEncoding setTextEncoding
                 frameID size setData setText render headerSize textDelimiter);
can_ok("Audio::TagLib::ID3v2::CommentsFrame", @methods) 			or 
	diag("can_ok failed");

my $i = Audio::TagLib::ID3v2::CommentsFrame->new();
isa_ok($i, "Audio::TagLib::ID3v2::CommentsFrame") 					or 
	diag("method new() failed");
$i->setTextEncoding("UTF8");
isa_ok(Audio::TagLib::ID3v2::CommentsFrame->new($i->render()), 
	"Audio::TagLib::ID3v2::CommentsFrame") 							or 
	diag("method new(data) failed");
is($i->textEncoding(), "UTF8") 										or 
	diag("method setTextEncoding(encode) and textEncoding() failed");
$i->setLanguage(Audio::TagLib::ByteVector->new("1"));
is($i->language()->data(), "1") 									or 
	diag("method setLanuage(code) and language() failed");
$i->setText(Audio::TagLib::String->new("blah blah"));
is($i->text()->toCString(), "blah blah") 							or 
	diag("method setText(s) and text() failed");
$i->setDescription(Audio::TagLib::String->new("description"));
is($i->description()->toCString(), "description") 					or 
	diag("method setDescription(desc) and description() failed");
is($i->toString()->toCString(), "blah blah") 						or 
	diag("method toString() failed");
