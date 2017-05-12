use Test::More tests => 2;
use Path::Class;

BEGIN { use_ok('Audio::TagLib::Ogg::Vorbis::Properties') };

my @methods = qw(DESTROY length bitrate sampleRate channels);
can_ok("Audio::TagLib::Ogg::Vorbis::Properties", @methods) 				or 
	diag("can_ok failed");

=if 0
TODO: {
    local $TODO = "Audio::TagLib::Ogg::Vorbis::Properties has no new()";

    can_ok("Audio::TagLib::Ogg::Vorbis::Properties", "new")             or
        diag("can_ok failed");

    my $file = Path::Class::file( 'sample', 'guitar.mp3' ) . '';
    # CPAN perl 5.17.2  Can't locate object method "new" via package "Audio::TagLib::Ogg::Vorbis::File"`
    my $oggfile = Audio::TagLib::Vorbis::File->new($file)               or
        diag("Audio::TagLib::Vorbis::File->new() failed");
    my $i = $oggfile->audioProperties();
    isa_ok($i, "Audio::TagLib::Ogg::Vorbis::Properties") 				or 
        diag("method Audio::TagLib::Ogg::Vorbis::audioProperties() failed");
    cmp_ok($i->length(), "==", 6) 										or 
        diag("method length() failed");
    cmp_ok($i->bitrate(), "==", 160) 									or 
        diag("method bitrate() failed");
    cmp_ok($i->sampleRate(), "==", 44100) 								or 
        diag("method sampleRate() failed");
    cmp_ok($i->channels(), "==", 2) 									or 
        diag("method channels() failed");
    cmp_ok($i->vorbisVersion(), "==", 0) 								or 
        diag("method vorbisVersion() failed");
    cmp_ok($i->bitrateMaximum(), "==", 0) 							    or 
        diag("method bitrateMaximum() failed");
    cmp_ok($i->bitrateNominal(), "==", 160000) 							or 
        diag("method bitrateNominal() failed");
    cmp_ok($i->bitrateMinimum(), "==", 0) 							    or 
	diag("method bitrateMinimum() failed");
}
=cut
