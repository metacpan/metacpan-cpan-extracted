use strict;
use warnings;
use Test::More;
use File::Temp qw(tempfile);

use Data::ReqRep::Shared;

SKIP: {
    open(my $fh, '<', '/dev/null') or skip "no /dev/null", 2;
    my $r = eval { Data::ReqRep::Shared->new_from_fd(fileno($fh)) };
    ok !defined($r), '/dev/null rejected';
    like $@, qr/(too small|invalid|fstat)/i, 'meaningful error';
}

{
    my ($fh, $path) = tempfile(UNLINK => 1, SUFFIX => '.shm');
    my $srv = Data::ReqRep::Shared->new($path, 4, 4, 128, 4096);
    ok eval { Data::ReqRep::Shared->new_from_fd(fileno($fh)) }, 'file descriptor with a valid current header accepted';
    sysseek($fh, 28, 0) == 28 or die $!;
    sysread($fh, my $arena_off, 4) == 4 or die $!;
    sysseek($fh, 44, 0) == 44 or die $!;
    syswrite($fh, pack('L', unpack('L', $arena_off) + 64)) == 4 or die $!;
    my $r = eval { Data::ReqRep::Shared->new_from_fd(fileno($fh)) };
    ok !defined($r), 'resp_off inside arena rejected (v0.04 regression)';
    like $@, qr/invalid or incompatible/, 'rejected for the layout, not the format version';
}

{
    my $s = Data::ReqRep::Shared->new_memfd("t", 8, 4, 128);
    my $s2 = Data::ReqRep::Shared->new_from_fd($s->memfd);
    ok $s2, 'valid reqrep accepted';
}

done_testing;
