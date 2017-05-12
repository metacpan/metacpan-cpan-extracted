use Test::More tests => 16;
use Path::Class;

BEGIN { use_ok('Audio::TagLib::MPEG::Header') };

my @methods = qw(new DESTROY isValid version layer protectionEnabled
                 samplesPerFrame sampleRate 
                 bitrate sampleRate isPadded channelMode isCopyrighted isOriginal
                 frameLength );

can_ok("Audio::TagLib::MPEG::Header", @methods)                      or 
        diag("can_ok failed");

my $file = Path::Class::file( 'sample', 'guitar.mp3' ) . '';
my $mpeg_file = Audio::TagLib::MPEG::File->new($file);

isa_ok($mpeg_file, "Audio::TagLib::MPEG::File")                      or 
        diag("method File::new() failed");

# Need offset = firstFrameOffset(file)
my $header = Audio::TagLib::MPEG::Header->new($mpeg_file, $mpeg_file->firstFrameOffset(), 0);
isa_ok($header, "Audio::TagLib::MPEG::Header")                       or 
        diag("method Header::new() failed");

cmp_ok($header->version(), 'eq', 'Version1')                         or
        diag("method version() failed");
 
cmp_ok($header->layer(), '==', 3 )                                   or
	diag("method layer() failed");

# Table lookup [layer][version]
cmp_ok($header->samplesPerFrame(), '==', 1152)                       or
	diag("method samplesPerFrame() failed");

cmp_ok($header->sampleRate(), '==', 44100)                           or
	diag("method sampleRate() failed");

cmp_ok($header->protectionEnabled(), '==', 0)                        or
	diag("method protectionEnabled() failed");

cmp_ok($header->isValid(), '==', 1)                                  or
	diag("method isValid() failed");

cmp_ok($header->isPadded(), 'eq', '')                                or
	diag("method isPadded() failed");

cmp_ok($header->isOriginal(), '==', 1)                               or
	diag("method isOriginal() failed");

cmp_ok($header->isCopyrighted(), '==', 0)                            or
	diag("method isCopyrighted() failed");

cmp_ok($header->frameLength(), '==', 417)                            or
	diag("method frameLength() failed");

cmp_ok($header->channelMode(), 'eq', 'Stereo')                       or
	diag("method channelMode() failed");

cmp_ok($header->bitrate(), '==', 128)                                or
	diag("method bitrate() failed");
