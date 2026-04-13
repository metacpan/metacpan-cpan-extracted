#!/usr/bin/env perl
# Event sourcing: append state-change events, replay to reconstruct state
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";
use Data::Log::Shared;
$| = 1;

my $log = Data::Log::Shared->new(undef, 100_000);

# append domain events
my @events = (
    "account:create id=1001 name=Alice",
    "account:create id=1002 name=Bob",
    "account:deposit id=1001 amount=500",
    "account:deposit id=1002 amount=300",
    "account:transfer from=1001 to=1002 amount=150",
    "account:withdraw id=1002 amount=100",
);
$log->append($_) for @events;

printf "log: %d events, %d bytes\n\n", $log->entry_count, $log->tail_offset;

# replay: reconstruct account balances
my %accounts;
$log->each_entry(sub {
    my ($ev) = @_;
    if ($ev =~ /^account:create id=(\d+) name=(\w+)/) {
        $accounts{$1} = { name => $2, balance => 0 };
    } elsif ($ev =~ /^account:deposit id=(\d+) amount=(\d+)/) {
        $accounts{$1}{balance} += $2;
    } elsif ($ev =~ /^account:withdraw id=(\d+) amount=(\d+)/) {
        $accounts{$1}{balance} -= $2;
    } elsif ($ev =~ /^account:transfer from=(\d+) to=(\d+) amount=(\d+)/) {
        $accounts{$1}{balance} -= $3;
        $accounts{$2}{balance} += $3;
    }
});

printf "reconstructed state:\n";
for my $id (sort keys %accounts) {
    printf "  %s (id=%s): balance=%d\n",
        $accounts{$id}{name}, $id, $accounts{$id}{balance};
}
