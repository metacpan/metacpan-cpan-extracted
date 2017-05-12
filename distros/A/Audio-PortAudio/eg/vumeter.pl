#!/usr/local/bin/perl -w
use strict;

BEGIN {
    eval {
        require Audio::PortAudio;
    } || die "Can't find Audio::PortAudio. 
If you've build Audio::PortAudio but haven't installed it yet, use
perl -Mblib vumeter.pl [program options]
";
}
use Getopt::Long;

my $samplefrequency = 22050;
my $updatefrequency = 50;
my $help = 0;
my $avgchar = "#";
my $peakchar = "|";
my $blankchar = " ";
my $verbose=0;
my $channelcount = 1;
my $api_name = "";
my $device_name = "";
my $s = GetOptions(
    "samplefrequency=i",\$samplefrequency,
    "updatefrequency=i",\$updatefrequency,
    "avgchar=s",\$avgchar,
    "peakchar=s",\$peakchar,
    "blankchar=s",\$blankchar,
    "verbose",\$verbose,
    "channelcount=i",\$channelcount,
    "api=s",\$api_name,
    "device=s",\$device_name,
    "help",\$help
);
if (!$s || $help) {
    print "usage: $0 [options]
options:
  --samplefrequency VALUE   audio input rate. default = 22050
  --updatefrequency VALUE   display update rate. default = 40
  --peakchar        CHAR    character to display peak value. default = |
  --avgchar         CHAR    character to display average power. default = #
  --blankchar       CHAR    character to fill. default = ' ' (space)
  --channelcount    NUM     number of input channels. default = 1
  --api             NAME    API to use (ALSA, OSS ...)
  --device          NAME    input device to use
  --verbose                 be verbose
  --help                    show this message

example (default values):
   vumeter.pl -u 40 -s 22050 -p '|' -av '#' -b ' '
";
    exit $s;
}


if ($verbose) {
    print "Available APIs: ",join(", ",map { $_->name } Audio::PortAudio::host_apis()),"\n";
}

my $api;
if ($api_name) {
    ($api) = grep { lc($_->name) eq lc($api_name) } Audio::PortAudio::host_apis();
}
else {
    $api = Audio::PortAudio::default_host_api();
}
die "No api found" unless $api;

print "Using ".$api->name."\n" if $verbose;

if ($verbose) {
    print "Available devices: ",join(", ", map { $_->name } $api->devices ),"\n";
}
my $device;
if ($device_name) {
    ($device) = grep { $_->name eq $device_name } $api->devices;
}
else {
    $device = $api->default_input_device;
}
die "No device found" unless $device;
print "Using ".$device->name."\n" if $verbose;

print "max input channels: ",$device->max_input_channels,"\n" if $verbose;
die "too many channels" if $device->max_input_channels < $channelcount;


print "$avgchar = avg power, $peakchar = sample peak\n" if $verbose;

my $instream = $device->open_read_stream( { channel_count => $channelcount, sample_format => 'float32' }, $samplefrequency, 100, 0);


$|=1;


my $E = "\x{1b}"; # escape char

my $log10_10 = 10 / log(10);
my $buffer = "";
$instream->start;

my $frames = int($samplefrequency / $updatefrequency);
print "-40db     -30db     -20db     -10dB      0dB
 .         .         .         .         .", "\n" x ($channelcount+1);



while (1) {
    my $ok = $instream->read($buffer,$frames);
    my @avg = map { 0 } 1 .. $channelcount;
    my @peak = @avg;
    my $c = 0;
    my $t =0;
    for (unpack "f".($frames * $channelcount),$buffer) {
        $avg[$c] += abs($_);
        $peak[$c] = abs($_) if $peak[$c] < abs($_);
        $c = ++$c % $channelcount;
	$t++;
    }
    for (@avg) {
        $_ /= $frames;
    }
    print "$E\[".($channelcount)."A";
    for (0 .. $channelcount -1) {
        my $logged  = $avg[$_] ? 40 + $log10_10 * log($avg[$_]) : 0;
        $logged = 0 if $logged <0;
        my $peak = $peak[$_] ? 40 + $log10_10 * log($peak[$_]) : 0;
        $peak = 0 if $peak < 0;
        my $ddelta = int($peak) - int($logged);
        my $line = ($avgchar x int($logged)).($peakchar x ($ddelta)).($blankchar x (41 - (int($logged) + $ddelta)));
        print "[$E\[32m",substr($line,0,20),"$E\[33m",substr($line,20,10),"$E\[31m",substr($line,30,10),"$E\[0m]\n";
    }
    print "$t\r";
    print "Buffer overflow @ ".localtime(time)."\r" if !$ok;
}

exit;

