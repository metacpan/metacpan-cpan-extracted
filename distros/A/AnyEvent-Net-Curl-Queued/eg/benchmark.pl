#!/usr/bin/env perl
use strict;
use utf8;
use warnings qw(all);

use Benchmark::Forking qw(cmpthese);
use Class::Load qw(load_class);
use File::Basename;
use File::Slurp;
use Getopt::Long;
use List::Util qw(shuffle);
use POSIX qw(nice);

GetOptions(
    q(count=i)      => \my $count,
    q(parallel=i)   => \my $parallel,
    q(repeat=i)     => \my $repeat,
    q(queue=s)      => \my $queue,
);

my @queue = read_file($queue // q(queue), chomp => 1);

if ($repeat) {
    my @new_queue;
    for my $j (1 .. $repeat) {
        for (my $i = 0; $i <= $#queue; $i++) {
            push @new_queue, $queue[$i] . qq(?$j);
        }
    }
    @queue = shuffle @new_queue;
}

my $tests = {};

for my $file (glob q(Gauge/*.pm)) {
    next if $file =~ /\bRole\b/x;

    my $class = $file;
    $class =~ s{/}{::}gx;
    $class =~ s{\.pm$}{}x;

    my $name = $class;
    $name =~ s{^.+::}{}x;
    $name =~ s{_}{::}gx;

    $tests->{$name} = sub {
        load_class($class);
        local $0 = $name;
        my $obj = $class->new({
            parallel    => $parallel // 4,
            queue       => \@queue,
        });
        $obj->run;
    };
}

nice(-20);
cmpthese($count // 10 => $tests);
