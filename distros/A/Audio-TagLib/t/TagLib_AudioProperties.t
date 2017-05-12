use Test::More tests => 6;
use Path::Class;

BEGIN { use_ok('Audio::TagLib::AudioProperties') };

my @methods = qw(DESTROY length bitrate sampleRate channels);
can_ok("Audio::TagLib::AudioProperties", @methods) 		    	or 
	diag("can_ok failed");

# Constructor is protected, so we go around
my $file = Path::Class::file( 'sample', 'guitar.mp3' ) . '';
my $mpegfile = Audio::TagLib::MPEG::File->new($file);
my $i = $mpegfile->audioProperties();
# Length of file, in seconds - used Audacity to verify. 
# Most recently, the length is very slightly less than 7 seconds.
cmp_ok($i->length(), "==", 7) 									or 
	diag("method length() failed");
cmp_ok($i->bitrate(), "==", 183) 								or 
	diag("method bitrate() failed");
cmp_ok($i->sampleRate(), "==", 44100) 							or 
	diag("method sampleRate() failed");
cmp_ok($i->channels(), "==", 2) 								or 
	diag("method channels() failed");
