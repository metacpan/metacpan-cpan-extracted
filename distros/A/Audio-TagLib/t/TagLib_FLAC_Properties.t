use Test::More tests => 7;
use Path::Class;

BEGIN { use_ok('Audio::TagLib::FLAC::Properties') };

my @methods = qw(new DESTROY length bitrate sampleRate channels
sampleWidth);
can_ok("Audio::TagLib::FLAC::Properties", @methods) 			or 
	diag("can_ok failed");

my $file = Path::Class::file( 'sample', 'guitar.flac' ) . '';
my $flacfile = Audio::TagLib::FLAC::File->new($file);
my $i = $flacfile->audioProperties();
cmp_ok($i->length(), "==", 6) 									or 
	diag("method length() failed");
cmp_ok($i->bitrate(), "==", 452) 								or 
	diag("method bitrate() failed");
cmp_ok($i->sampleRate(), "==", 44100) 							or 
	diag("method sampleRate() failed");
cmp_ok($i->channels(), "==", 2) 								or 
	diag("method channels() failed");
cmp_ok($i->sampleWidth(), "==", 16) 							or 
	diag("method sampleWidth() failed");
