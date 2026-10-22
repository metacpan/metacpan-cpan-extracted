use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use Time::HiRes qw(time sleep);
use POSIX qw(_exit WNOHANG);
use Data::Queue::Shared;

my $dir = tempdir(CLEANUP => 1);
sub word {
    my ($fh, $offset, $format, @value) = @_;
    sysseek($fh, $offset, 0) // die $!;
    if (@value) { my $bytes = pack($format, @value); syswrite($fh, $bytes) == length($bytes) or die $!; return }
    my $size = length(pack($format, 0));
    sysread($fh, my $bytes, $size) == $size or die $!;
    return unpack($format, $bytes);
}
for my $variant (qw(Int Int32 Int16)) {
    for my $method (qw(push_wait pop_wait)) {
        my $path = "$dir/$variant-$method";
        my $q = "Data::Queue::Shared::$variant"->new($path, 2);
        $q->push(1) for $method eq 'push_wait' ? (1 .. $q->capacity) : ();
        open my $raw, '+<', $path or die $!;
        my $slots = word($raw, 24, 'Q');
        my $seq = $variant eq 'Int' ? 'Q' : 'L';
        my $value = $variant eq 'Int' ? 'q' : $variant eq 'Int32' ? 'l' : 's';
        my $pid = fork // die $!;
        if (!$pid) {
            local $SIG{ALRM} = sub { _exit(2) };
            alarm 6;
            my $result = $method eq 'push_wait' ? $q->push_wait(9) : $q->pop_wait;
            _exit(defined($result) && ($method eq 'push_wait' ? $result : $result == 9) ? 0 : 1);
        }
        my $offset = $method eq 'push_wait' ? 136 : 72;
        my $deadline = time + 1;
        sleep .001 while !word($raw, $offset, 'L') && time < $deadline;
        ok word($raw, $offset, 'L'), "$variant $method is parked";
        # Publish the state a peer leaves if killed before its futex wake.
        if ($method eq 'push_wait') {
            word($raw, 64, 'Q', 1);
            word($raw, $slots, $seq, $q->capacity);
        } else {
            word($raw, 128, 'Q', 1);
            word($raw, $slots + length(pack($seq, 0)), $value, 9);
            word($raw, $slots, $seq, 1);
        }
        waitpid($pid, 0);
        is $?, 0, "$variant $method retries without a futex notification";
    }
}
done_testing;
