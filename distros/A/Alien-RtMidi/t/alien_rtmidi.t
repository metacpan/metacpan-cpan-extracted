use Test2::V0;
use Test::Alien;
use Alien::RtMidi;

alien_ok 'Alien::RtMidi';
ffi_ok { symbols => [ 'rtmidi_api_display_name' ], api => 1 }, with_subtest {
    my($ffi) = @_;
    my $rtmidi_api_display_name = $ffi->function( rtmidi_api_display_name => [ 'enum' ] => 'string' );
    is $rtmidi_api_display_name->call(2), 'ALSA', 'rtmidi_api_display_name works';
};

done_testing;
