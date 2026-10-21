use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use Fcntl qw(O_RDWR SEEK_SET SEEK_END);
use POSIX qw(_exit);
use Data::CuckooFilter::Shared;

my $dir = tempdir(CLEANUP => 1);

for my $interrupted (qw(remove add)) {
    my $path = "$dir/$interrupted.cf";
    my $cf = Data::CuckooFilter::Shared->new($path, 1);
    is $cf->add_many([('x') x 8]), 8, 'fill both candidate buckets';

    my $pid = fork // die "fork: $!";
    unless ($pid) {
        sysopen my $fh, $path, O_RDWR or _exit(2);
        # The state left between a slot store and its count update.
        if ($interrupted eq 'remove') {
            sysseek($fh, -16, SEEK_END) or _exit(2);
            syswrite($fh, pack('S<', 0)) == 2 or _exit(2);
        } else {
            sysseek($fh, 40, SEEK_SET) or _exit(2);
            syswrite($fh, pack('Q<', 7)) == 8 or _exit(2);
        }
        sysseek($fh, 80, SEEK_SET) or _exit(2);
        syswrite($fh, pack('L<', 0x80000000 | $$)) == 4 or _exit(2);
        _exit(0);
    }
    waitpid($pid, 0);
    is $?, 0, "$interrupted: writer leaves an interrupted update";

    my $ok = eval {
        local $SIG{ALRM} = 'DEFAULT';
        alarm 10;
        is $cf->count, $interrupted eq 'remove' ? 7 : 8,
            "$interrupted: recovery restores the live count";
        if ($interrupted eq 'remove') {
            is $cf->add('x'), 1, 'refill the cleared slot';
        } else {
            is $cf->add('x'), 0, 'the intact table is still full';
        }
        is $cf->count, 8, "$interrupted: count stays within the slot limit";
        my $reopened = Data::CuckooFilter::Shared->new($path, 1);
        is $reopened->count_of('x'), 8, "$interrupted: all copies survive reopening";
        1;
    };
    my $err = $@;
    alarm 0;
    ok $ok, "$interrupted: recovery and reopening finish" or diag $err;
}

done_testing;
