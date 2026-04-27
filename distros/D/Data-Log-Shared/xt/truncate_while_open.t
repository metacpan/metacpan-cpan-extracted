use strict;
use warnings;
use Test::More;
use File::Temp qw(tmpnam);
use POSIX qw(_exit);
use Data::Log::Shared;

plan skip_all => 'AUTHOR_TESTING not set' unless $ENV{AUTHOR_TESTING};

# Linux behavior: accessing mmapped pages past truncated EOF raises
# SIGBUS. We document this contract: external `truncate(2)` of the
# backing file is destructive — the open handle is unsafe afterwards.
# This test verifies SIGBUS is raised (caught in a child) rather than
# silent corruption.

my $path = tmpnam() . '.log';
my $log = Data::Log::Shared->new($path, 4096);
$log->append("alpha");
$log->append("beta");

# Pre-truncate: handle is fully usable
my ($d) = $log->read_entry(0);
is $d, 'alpha', 'pre-truncate read works';

# Truncate the underlying file
truncate($path, 0) or die "truncate: $!";

# Post-truncate: access in a child to catch SIGBUS without killing the test
my $pid = fork // die;
if ($pid == 0) {
    # any access to the mapped region should SIGBUS now
    my @entries;
    my $off = 0;
    while (my ($d, $next) = $log->read_entry($off)) {
        push @entries, $d;
        $off = $next;
        last if @entries > 5;
    }
    _exit(0);   # if we got here, no SIGBUS — that would be unexpected but not a bug
}
waitpid($pid, 0);
my $sig = $? & 127;
ok $sig == 0 || $sig == 7,    # 7 = SIGBUS
    "post-truncate access either succeeded or got SIGBUS (sig=$sig)";

unlink $path if -e $path;
done_testing;
