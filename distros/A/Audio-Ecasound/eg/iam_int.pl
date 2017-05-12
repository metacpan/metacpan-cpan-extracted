#!/usr/bin/perl -w

use ExtUtils::testlib;


use Audio::Ecasound qw(:simple :iam);


use strict;
# :iam is nicer without strict 'subs'
no strict 'subs';
on_error('');

# no strict 'subs' lets you do this:
cs_add play_chainsetup;
c_add chain1;
eci("-i:some_file.wav
        -o:/dev/dsp");
cop_add '-efl:100';
cop_select 1;
copp_select 1;
defined(cs_connect) 
    or die "Setup error, you need 'some_file.wav' in the current directory\n\n"
                        . errmsg();

on_error('die');
start;

my $cutoff_inc = 500.0;
while (1) {
    sleep(1);
    last if engine_status ne "running";

    my $curpos = get_position;
    last if $curpos > 15;

    my $next_cutoff = $cutoff_inc + copp_get;
    # keep float precision
    eci("copp-set", $next_cutoff);
}
stop;
cs_disconnect;
print cop_status, "\n";
