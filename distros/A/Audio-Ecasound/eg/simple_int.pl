#!/usr/bin/perl -w

use ExtUtils::testlib;

use strict;

use Audio::Ecasound qw(:simple);

on_error('');
$_ = eci("
         cs-add play_chainsetup
        c-add 1st_chain
        -i:some_file.wav
        -o:/dev/dsp
        cop-add -efl:100
        cop-select 1
        copp-select 1
        cs-connect
        start
");
if(!defined) {
    die "Setup error, you need 'some_file.wav' in the current directory\n\n"
            . errmsg();
}

on_error('die');
my $cutoff_inc = 500.0;
while (1) {
    sleep(1);
    last if eci("engine-status") ne "running";

    my $curpos = eci("get-position");
    last if $curpos > 15;

    my $next_cutoff = $cutoff_inc + eci("copp-get");
    eci("copp-set", $next_cutoff);
}
eci("stop");
eci("cs-disconnect");
print eci("cop-status"), "\n";
