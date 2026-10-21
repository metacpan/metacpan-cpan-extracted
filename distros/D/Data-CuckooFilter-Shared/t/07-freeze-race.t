use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use Time::HiRes qw(usleep);
use POSIX qw(_exit);
use Data::CuckooFilter::Shared;

my $dir = tempdir(CLEANUP => 1);
my $path = "$dir/published.cf";
my $cf = Data::CuckooFilter::Shared->new($path, 10_000);
pipe my $ready, my $signal or die "pipe: $!";
my $pid = fork // die "fork: $!";
unless ($pid) {
    close $ready;
    local $SIG{ALRM} = sub { _exit(2) };
    alarm 10;
    syswrite($signal, 'r') == 1 or _exit(2);
    close $signal;
    my $ro;
    until ($ro) {
        $ro = eval { Data::CuckooFilter::Shared->new_readonly($path) };
        _exit(3) if !$ro && $@ !~ /not frozen/;
        usleep(1000) unless $ro;
    }
    _exit(4) unless $ro->count == 8000;
    for (1..8000) { _exit(5) unless $ro->contains("published-$_") }
    _exit(0);
}
close $signal;
sysread($ready, my $byte, 1) == 1 or die "child not ready";
close $ready;
is $cf->add_many([map { "published-$_" } 1..8000]), 8000, 'populate while a consumer opens';
$cf->freeze;
waitpid($pid, 0);
is $?, 0, 'the consumer sees the complete table once the seal is published';

done_testing;
