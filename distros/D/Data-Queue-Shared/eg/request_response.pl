#!/usr/bin/env perl
# Request/response pattern: main sends requests, workers send results back
use strict;
use warnings;
use POSIX ();
use FindBin;
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";
use Data::Queue::Shared;

my $num_workers = 2;

# Shared request and result queues
my $requests = Data::Queue::Shared::Int->new(undef, 256);
my $results  = Data::Queue::Shared::Int->new(undef, 256);

# Fork workers
my @pids;
for my $w (1..$num_workers) {
    my $pid = fork // die "fork: $!";
    if ($pid == 0) {
        while (1) {
            my $req = $requests->pop_wait(2);
            last unless defined $req;
            last if $req == 0;  # shutdown signal
            # "Process": compute fibonacci-ish result
            my $result = $req * $req + 1;
            $results->push($result);
        }
        POSIX::_exit(0);
    }
    push @pids, $pid;
}

# Send requests
my $n = 20;
$requests->push($_) for 1..$n;
$requests->push(0) for 1..$num_workers;  # shutdown signals

# Collect responses
my @responses;
for (1..$n) {
    my $r = $results->pop_wait(5);
    last unless defined $r;
    push @responses, $r;
}

waitpid($_, 0) for @pids;

@responses = sort { $a <=> $b } @responses;
printf "sent %d requests, got %d responses\n", $n, scalar @responses;
printf "responses: %s\n", join(' ', @responses[0..9]);
