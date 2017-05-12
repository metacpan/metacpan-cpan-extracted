use Test::More tests => 5;

BEGIN { use_ok('Audio::TagLib::ID3v2::Frame') };

# Other documented methods (notwithstanding Frame.h) are virtual or protected'
# In particular, the Frame constructors are protected, which means that a 
# Frame cannot be instantiated here. Consequently, none of the Frame methods,
# other than those that are static, will work. Trying to execute them results 
# in the message:
#   THIS is not of type Audio::TagLib::ID3v2::Frame
# which results from the fact that there is no THIS (a pointer to a Frame) available.

my @methods = qw(DESTROY frameID size setData setText toString render
                 setData frameID  headerSize textDelimiter);
can_ok("Audio::TagLib::ID3v2::Frame", @methods) 							        or 
	diag("can_ok failed");

cmp_ok(Audio::TagLib::ID3v2::Frame->headerSize(), "==", 10) 				        or 
	diag("method headerSize() failed");
cmp_ok(Audio::TagLib::ID3v2::Frame->headerSize(2), "==", 6) 				        or 
	diag("method headerSize() failed");
# Returns ByteVector, whose data() method is use to extract result
cmp_ok(Audio::TagLib::ID3v2::Frame->textDelimiter("Latin1")->Audio::TagLib::ByteVector::data(),
    "eq", "\c@")                                                                    or 
	diag("method textDelimiter(Latin1) failed");
# GCL test frame creation
my $tag = Audio::TagLib::ByteVector->new("TIT2");
my $stringlist = Audio::TagLib::StringList->new(Audio::TagLib::String->new("IS TITLE"));
print "Create frame\n";
my $frame = Audio::TagLib::ID3v2::TextIdentificationFrame->new($tag);
    $frame->setText(Audio::TagLib::String->new('Twas brillig'));
