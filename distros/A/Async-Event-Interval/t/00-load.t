use 5.006;
use strict;
use warnings;

use IPC::Shareable;
use Test::More;

my ($segs_before, $sems_before);
BEGIN {
    IPC::Shareable->testing_set('Async::Event::Interval');

    my $removed = IPC::Shareable::clean_up_testing('Async::Event::Interval');
    diag "Removed $removed orphaned AEI testing segments from a prior run"
        if $removed;

    $segs_before = IPC::Shareable::seg_count();
    $sems_before = IPC::Shareable::sem_count();
}

use_ok('Async::Event::Interval') || print "Bail out!\n";

use Async::Event::Interval;

diag("Testing Async::Event::Interval $Async::Event::Interval::VERSION, Perl $], $^X");

warn "Segs Before: $segs_before\n" if $ENV{PRINT_SEGS};
warn "Sems Before: $sems_before\n" if $ENV{PRINT_SEGS};

my $tmpfile = '/tmp/async_event_interval_seg_count';

unlink $tmpfile if -e $tmpfile;

open my $fh, '>', $tmpfile or die "Can't open $tmpfile for write: $!";
print $fh "$segs_before\n$sems_before\n";
close $fh;

{
    my $e = Async::Event::Interval->new(0, sub {});
}

done_testing;
