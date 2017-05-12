#!/usr/bin/perl

use strict;
use warnings;

@ARGV == 4 or die <<EOU;
Usage:
  $0 user dbname p_one p_all
EOU

my ($user, $db, $p_one, $p_all) = @ARGV;

$user = quotemeta $user;
$db   = quotemeta $db;

$p_one = eval "$p_one" / 100;
$p_all = eval "$p_all" / 100;

my $re = qr/^\s*(\d+)\s+\S*\s+\S+\s+\S+\s+postgres:\s+$user\s+$db\s+/;

my $speed = 10;
my $sleep = 1.0/$speed;

my $last = time;

while (1) {
    my $all = (rand() < $sleep * $p_all);
    for (`ps xa`) {
        if (/^\s*(\d+)\s+\S*\s+\S+\s+\S+\s+postgres:\s+$user\s+$db\s+/o) {
            my $signal;
            if ($all) {
                $signal = 'STOP';
            }
            elsif(rand() < $sleep * $p_one) {
                $signal = (qw(KILL TERM STOP CONT))[rand 4];
            }
            if ($signal) {
                kill $signal, $1;
                print "process $1 killed with signal $signal\n";
            }
            else {
                # print "process $1 running\n";
            }
        }
    }
    select undef, undef, undef, $sleep;
    if ($last != time) {
        $last = time;
        print "$last ---\n"
    }
    else {
        print "---------\n";
    }
}
