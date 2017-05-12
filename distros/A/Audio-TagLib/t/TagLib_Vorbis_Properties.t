use Test::More tests => 2;
use Path::Class;

BEGIN { use_ok('Audio::TagLib::Vorbis::Properties') };

my @methods = qw(DESTROY length bitrate sampleRate channels);
can_ok("Audio::TagLib::Vorbis::Properties", @methods) 					or 
	diag("can_ok failed");

=if 0
TODO: {
    local $TODO = "Audio::TagLib::Vorbis::File has no new" if 1;

    my @failing_methods = qw(new vorbisVersion
                             bitrateMaximum bitrateNominal bitrateMinimum);
    can_ok("Audio::TagLib::Vorbis::File", @failing_methods)             or
        diag("can_ok failed");
    my $file = Path::Class::file( 'sample', 'guitar.ogg' ) . '';
    # CPAN perl 5.17.2  Can't locate object method "new" via package "Audio::TagLib::Ogg::Vorbis::File"`
    my $oggfile = Audio::TagLib::Vorbis::File->new($file);
    my $i = $oggfile->audioProperties();
    isa_ok($i, "Audio::TagLib::Vorbis::Properties") 					or 
        diag("method Audio::TagLib::Vorbis::audioProperties() failed");
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
