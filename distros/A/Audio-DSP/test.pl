# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

BEGIN { $| = 1; print "1..5\n"; }
END { print "not ok 1\n" unless $loaded; }

#### load ####
print "Loading Audio::DSP... ";
use Audio::DSP;
$loaded = 1;
print "ok 1\n";

#### construct, initialize ####
print "Initializing audio device... ";
my ($buf, $chan, $fmt, $rate) = (4096, 1, 8, 8192);
my $dsp = new Audio::DSP(buffer   => $buf,
                         channels => $chan,
                         format   => $fmt,
                         rate     => $rate);

my $seconds = 2;
my $length  = ($chan * $fmt * $rate * $seconds) / 8;

$dsp->init() || die "not ok 2 (" . $dsp->errstr . ")\n";
print "ok 2\n";

#### read 2 seconds ####
print "Recording $seconds seconds of sound (it won't be played back)... ";
for (my $i = 0; $i < $length; $i += $buf) {
    $dsp->read() || die "not okay 3 (" . $dsp->errstr . ")\n";
}
if ($dsp->datalen != 16384) {
    print "not ok 3 (" . $dsp->datalen . " bytes recorded\; should've been 16384\n";
} else {
    print "ok 3\n";
}

#### load/play test file ####
print "Loading and playing test file... ";
$dsp->clear;
$dsp->audiofile('kazan.raw') || die "not okay 4 (" . $dsp->errstr . ")\n";
for (;;) {
    $dsp->write || last;
}
print "ok 4\n";

#### close ####
print "Closing device... ";
$dsp->close() || die "not okay 5 (" . $dsp->errstr . ")\n";
print "ok 5\n";
