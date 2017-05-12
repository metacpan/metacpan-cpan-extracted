#!/usr/bin/perl -w

use ExtUtils::testlib;

use strict;

use Audio::Ecasound ':std';

# WARNING NO ERROR CHECKING!!

command("cs-add play_chainsetup");
command("c-add 1st_chain");
command("-i:some_file.wav");
command("-o:/dev/dsp");
command("cop-add -efl:100");
command("cop-select 1");
command("copp-select 1");
command("cs-connect");
if(error()) {
    die "Setup error, you need 'some_file.wav' in the current directory\n\n"
                            . last_error();
}
command("start");
my $cutoff_inc = 500.0;
while (1) {
    sleep(1);
    command("engine-status");
    last if last_string() ne "running";

    command("get-position");
    my $curpos = last_float();
    last if $curpos > 15;

    command("copp-get");
    my $next_cutoff = $cutoff_inc + last_float();
    command_float_arg("copp-set", $next_cutoff);
}
command("stop");
command("cs-disconnect");
command("cop-status");
print last_string(), "\n";
