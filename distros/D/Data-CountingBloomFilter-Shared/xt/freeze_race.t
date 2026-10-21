use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use POSIX qw(_exit);
use Data::CountingBloomFilter::Shared;

plan skip_all => 'author test' unless $ENV{AUTHOR_TESTING};
my $dir = tempdir(CLEANUP => 1);
for my $round (1 .. 10) {
    my $path = "$dir/frozen-$round.cbf";
    my $h = Data::CountingBloomFilter::Shared->new($path, 5000);
    pipe my $ready, my $signal or die $!;
    my $pid = fork // die $!;
    if (!$pid) {
        close $ready;
        syswrite $signal, '1';
        close $signal;
        alarm 10;
        my $ro;
        until ($ro) {
            $ro = eval { Data::CountingBloomFilter::Shared->new_readonly($path) };
            _exit(2) if !$ro && $@ !~ /not frozen/;
        }
        my $miss = 0;
        $ro->contains("key-$_") or $miss++ for 1 .. 5000;
        _exit($miss || $ro->stats->{ops} != 5000 ? 1 : 0);
    }
    close $signal;
    sysread $ready, my $byte, 1;
    close $ready;
    $h->add("key-$_") for 1 .. 5000;
    $h->freeze;
    waitpid $pid, 0;
    is $?, 0, "round $round: opening during freeze sees every completed write";
}
done_testing;
