use Test::More tests => 8;
use Devel::Peek;
BEGIN { use_ok('Audio::TagLib::ID3v2::FrameFactory') };

my @methods = qw(createFrame defaultTextEncoding
                 setDefaultTextEncoding instance);
can_ok("Audio::TagLib::ID3v2::FrameFactory", @methods) 					or 
	diag("can_ok failed");

# The constructor for FrameFactory is protected. Use this instead
my $ff = Audio::TagLib::ID3v2::FrameFactory->instance();
isa_ok($ff, "Audio::TagLib::ID3v2::FrameFactory") 						or 
	diag("method instance() failed");
# TIT2 - title
my $data = Audio::TagLib::ByteVector->new ("TIT2" .               # Frame ID
                                           "\x00\x00\x00\x13" .   # Frame size
                                           "\x00\x00" .           # Frame flags
                                           "\x00" .               # Encoding
                                           "(4)Eurodisco", 23);   # Text

isa_ok($data, "Audio::TagLib::ByteVector") 					        	or 
	diag("method new ByteVector() failed");
my $header = Audio::TagLib::ID3v2::Header->new($data);
isa_ok($header, "Audio::TagLib::ID3v2::Header") 					   	or 
	diag("method new Header() failed");
my $frame = $ff->createFrame($data, $header);
isa_ok($frame, "Audio::TagLib::ID3v2::Frame")                           or
        diag("method createFrame(data, header) failed");
$frame->setText(Audio::TagLib::String->new('Twas brillig'));
cmp_ok($ff->defaultTextEncoding(), 'eq', 'Latin1')                      or
    diag("method defaultTextEncoding() failed");
$ff->setDefaultTextEncoding('UTF8');
cmp_ok($ff->defaultTextEncoding(), 'eq', 'UTF8')                        or
    diag("method defaultTextEncoding() failedcreateFrame");
