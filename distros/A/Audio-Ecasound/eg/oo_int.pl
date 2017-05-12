#!/usr/bin/perl -w

use ExtUtils::testlib;

use strict;

use Audio::Ecasound;

my $e = new Audio::Ecasound;
$e->on_error('die');

$e->eci("cs-add play_chainsetup");
$e->eci("c-add 1st_chain");
$e->eci("-i:some_file.wav");
$e->eci("-o:/dev/dsp");
$e->eci("cop-add -efl:100");
$e->eci("cop-select 1");
$e->eci("copp-select 1");

if(!defined(eval { $e->eci("cs-connect") })) {
    die "Setup error, you need 'some_file.wav' in the current directory\n\n"
            . $e->errmsg();
}

$e->on_error('die');
$e->eci("start");
my $cutoff_inc = 500.0;
while (1) {
    sleep(1);
    last if $e->eci("engine-status") ne "running";

    my $curpos = $e->eci("get-position");
    last if $curpos > 15;

    my $next_cutoff = $cutoff_inc + $e->eci("copp-get");
    $e->eci("copp-set", $next_cutoff);
}
$e->eci("stop");
$e->eci("cs-disconnect");
print $e->eci("cop-status"), "\n";
