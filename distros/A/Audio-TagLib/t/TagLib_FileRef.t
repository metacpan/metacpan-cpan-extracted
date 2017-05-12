use Test::More tests => 15;
use Path::Class;

BEGIN { use_ok('Audio::TagLib::FileRef') };

my @methods = qw(new DESTROY tag audioProperties file save isNull 
                 addFileTypeResolver copy _equal);
can_ok("Audio::TagLib::FileRef", @methods) 						    or 
	diag("can_ok failed");

ok(Audio::TagLib::FileRef->new()->isNull()) 						or 
	diag("method new() failed");

my $file = Path::Class::file( 'sample', 'guitar.mp3' ) . '';
my $i = Audio::TagLib::FileRef->new($file);
my $j = Audio::TagLib::FileRef->new($file, 0, "Fast");
my $File = Audio::TagLib::FileRef->create($file);
is($File->name(), $file) 									        or 
	diag("method create(file) failed");
my $k = Audio::TagLib::FileRef->new($File);
my $l = Audio::TagLib::FileRef->new($i);
isa_ok($i, "Audio::TagLib::FileRef") 								or 
	diag("method new(file) failed");
isa_ok($j, "Audio::TagLib::FileRef") 								or 
	diag("method new(file, readAudioProperties, ReadStyle) failed");
isa_ok($k, "Audio::TagLib::FileRef") 								or 
	diag("method new(File *) failed");
isa_ok($l, "Audio::TagLib::FileRef") 								or 
	diag("method new(FileRef) failed");
isa_ok($i->tag(), "Audio::TagLib::Tag") 							or 
	diag("method tag() failed");
isa_ok($i->audioProperties(), "Audio::TagLib::AudioProperties") 	or 
	diag("method audioProperties() failed");
isa_ok($i->file(), "Audio::TagLib::File") 							or 
	diag("method file() failed");
ok(not $i->isNull()) 										        or 
	diag("method isNull() failed");
ok($i == $l) 												        or 
	diag("method _equal(ref) failed");
ok($i != $j) 												        or 
	diag("method _equal(ref) failed");
$i->copy($j);
ok($i == $j) 												        or 
	diag("method copy(ref) failed");
# GCL - This result will undoubtedly change from relese to release of taglib
# CPAN perl 5.17.2 
#    ogg flac oga mp3 mpc wv spx tta m4a m4b m4p 3g2 mp4 wma asf aif aiff wav ape'
=if 0
is(Audio::TagLib::FileRef->defaultFileExtensions()->toString()->toCString(), 
	"ogg flac oga mp3 mpc wv spx tta aif aiff wav ape") 								or 
	diag("method defaultFileExtensions() failed");
=cut
