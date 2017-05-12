use strict;
use Test::More tests => 3;
use Config;

use_ok('Audio::PortAudio');


ok(Audio::PortAudio::version(),"version");
ok(Audio::PortAudio::version_text(),"version_text");


my $api = Audio::PortAudio::default_host_api();

my $device  = $api->default_output_device;



my $pi = 3.14159265358979323846;
my $sine = pack "f*", map { sin( $pi * $_ / 100 ) / 8 } 0 .. 399;

my $stream = $device->open_write_stream(
    {
        channel_count => 1,
    },
    44100,
    400,
    0
);
for (0 .. 400) {
    $stream->write($sine);
}


