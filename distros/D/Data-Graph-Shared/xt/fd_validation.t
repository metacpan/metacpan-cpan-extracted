use strict;
use warnings;
use Test::More;
use File::Temp qw(tempfile);

use Data::Graph::Shared;

# /dev/null rejection
SKIP: {
    open(my $fh, '<', '/dev/null') or skip "no /dev/null", 1;
    my $r = eval { Data::Graph::Shared->new_from_fd(fileno($fh)) };
    ok !defined($r), '/dev/null rejected';
    like $@, qr/(too small|invalid|fstat)/i, 'meaningful error';
}

# Corrupt offsets: magic + version + crazy offsets
{
    my ($fh, $path) = tempfile(UNLINK => 1, SUFFIX => '.shm');
    my $bad = ~0;
    print $fh pack('V V V V Q< Q< Q< Q< Q< Q<',
        0x47525031, 1, 16, 32, 4096,
        $bad, $bad, $bad, $bad, $bad);
    print $fh "\0" x (4096 - tell($fh));
    close $fh;
    open(my $rfh, '+<', $path) or die "open: $!";
    my $r = eval { Data::Graph::Shared->new_from_fd(fileno($rfh)) };
    ok !defined($r), 'corrupted offsets rejected';
    like $@, qr/invalid/i, 'meaningful error';
    close $rfh;
}

# Valid roundtrip
{
    my $g = Data::Graph::Shared->new_memfd("t", 16, 32);
    my $g2 = Data::Graph::Shared->new_from_fd($g->memfd);
    my $n = $g->add_node(100);
    ok $g2->has_node($n), 'valid graph accepted';
}

done_testing;
