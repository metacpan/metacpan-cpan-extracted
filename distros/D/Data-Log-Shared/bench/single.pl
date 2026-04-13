#!/usr/bin/env perl
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";
use Time::HiRes qw(time);
use Data::Log::Shared;

my $N = shift || 1_000_000;

sub bench {
    my ($label, $n, $code) = @_;
    my $t0 = time;
    $code->();
    my $dt = time - $t0;
    printf "  %-35s %10.0f/s  (%.3fs)\n", $label, $n / $dt, $dt;
}

printf "Data::Log::Shared single-process benchmark (%d ops)\n\n", $N;

# small entries
my $log = Data::Log::Shared->new(undef, $N * 20);
bench "append (12B entries)", $N, sub {
    $log->append("hello world!") for 1..$N;
};

bench "read_entry sequential", $N, sub {
    my $pos = 0;
    for (1..$N) {
        my ($d, $next) = $log->read_entry($pos);
        last unless defined $d;
        $pos = $next;
    }
};

# larger entries — separate log sized for 200B payloads
my $big = "x" x 200;
my $big_n = int($N / 5);
my $big_log = Data::Log::Shared->new(undef, $big_n * 210);
bench "append (200B entries)", $big_n, sub {
    $big_log->append($big) for 1..$big_n;
};
