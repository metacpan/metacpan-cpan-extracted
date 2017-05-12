use Test::More tests => 12;
use Path::Class;

BEGIN { use_ok('Audio::TagLib::MPEG::Properties') };

my @methods = qw(new DESTROY length bitrate sampleRate channels
                 version layer channelMode isCopyrighted isOriginal protectionEnabled);
can_ok("Audio::TagLib::MPEG::Properties", @methods) 			or 
	diag("can_ok failed");

my $file = Path::Class::file( 'sample', 'guitar.mp3' ) . '';
my $mpegfile = Audio::TagLib::MPEG::File->new($file);
my $i = $mpegfile->audioProperties();
cmp_ok($i->length(), "==", 7) 									or 
	diag("method length() failed");
cmp_ok($i->bitrate(), "==", 183) 								or 
	diag("method bitrate() failed");
cmp_ok($i->sampleRate(), "==", 44100) 							or 
	diag("method sampleRate() failed");
cmp_ok($i->channels(), "==", 2) 								or 
	diag("method channels() failed");
is($i->version(), "Version1") 									or 
	diag("method version() failed");
cmp_ok($i->layer(), "==", 3) 									or 
	diag("method layer() failed");
is($i->channelMode(), "Stereo") 								or 
	diag("method channelMode() failed");
ok(not $i->isCopyrighted()) 									or 
	diag("method isCopyrighted() failed");
ok($i->isOriginal()) 											or 
	diag("method isOriginal() failed");
ok(not $i->protectionEnabled()) 								or 
	diag("method protectionEnabled() failed");
