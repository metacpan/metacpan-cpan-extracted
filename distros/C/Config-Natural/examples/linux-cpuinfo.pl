#!/usr/bin/perl
# 
# This example shows you that Config::Natural can be also used to 
# parse files like /proc/cpuinfo on Linux-based systems. 
# 
# Here, a prefilter is used to replace spaces by underscores in 
# the labels, because Config::Natural does not parse names with 
# spaces. 
# 
# It's quick and dirty so it doesn't work on SMP systems but it 
# could by testing whether the parameters are arrayrefs, but it's 
# supposed to be a simple example and I'm lazy ;-)
# 
use strict;
use Config::Natural;

sub space2underscore {
    my $self = shift;
    my $data = shift;
    $data =~ s/^(\w+) (\w+)/${1}_$2/;
    return $data
}

my $cpuinfo = new Config::Natural {
        affectation_symbol => ':', 
        prefilter => \&space2underscore, 
        quiet => 1, 
    }, '/proc/cpuinfo';

print <<'' if ref $cpuinfo->param('processors');
Looks like you have an SMP system. This example script is too cheap 
to work on such machine. Please try it on a UMP system. 

print <<"END";
Okay, lemme guess.. You have an @{[ $cpuinfo->param('model_name') ]}, which seems 
to be running at approximately @{[ $cpuinfo->param('cpu_MHz') ]} MHz. 
@{[ join(' ', $cpuinfo->param(qw(fdiv_bug hlt_bug f00f_bug coma_bug))) eq "no no no no" ?
"It seem to be sane (no stupid bugs)." :
"It has quite some stupid bugs, but Linux will take them into account." ]}
Linux evaluates its speed of execution at @{[ $cpuinfo->param('bogomips') ]} BogoMIPS, 
which isn't very meaningful anyway. 
END
