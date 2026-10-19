use Test2::V0;
use Atomic::Pipe;

# Closing the write side with pending (non-blocking) output must flush it,
# not silently drop it and then croak from DESTROY.

my @warnings;
local $SIG{__WARN__} = sub { push @warnings => @_ };

subtest 'close() flushes pending output' => sub {
    my ($r, $w) = Atomic::Pipe->pair;
    $w->write_blocking(0);
    $r->read_blocking(0);

    # Write numbered bursts until one actually hits EAGAIN and gets buffered.
    my $n = 0;
    until ($w->pending_output) {
        $w->write_burst(sprintf("%06d\n", $n++)) or die "burst too big";
        die "pipe never filled" if $n > 1_000_000;
    }

    # Drain the pipe so the flush inside close() can succeed.
    my %seen;
    my $consume = sub {
        while ($r->fill_buffer) { }
        my $buff = delete $r->{in_buffer};
        $r->{in_buffer_size} = 0;
        $seen{$1}++ while defined($buff) && $buff =~ /(\d{6})\n/g;
    };
    $consume->();

    $w->close;
    ok(!$w->pending_output, "no pending output after close()");

    $consume->();

    is([grep { $seen{$_} != 1 } keys %seen], [], "no missing or duplicated bursts");
    is(scalar(keys %seen), $n, "every burst written before close() was received");
};

subtest 'reader() flushes pending output before discarding writer' => sub {
    my $p = Atomic::Pipe->new;
    $p->blocking(0);

    my $n = 0;
    until ($p->pending_output) {
        $p->write_burst(sprintf("%06d\n", $n++)) or die "burst too big";
        die "pipe never filled" if $n > 1_000_000;
    }

    # Drain so the flush has room.
    my $bytes = 0;
    while ($p->fill_buffer) { }
    $bytes += length(delete $p->{in_buffer} // '');
    $p->{in_buffer_size} = 0;

    $p->reader;
    ok(!$p->pending_output, "no pending output after reader()");
    ok($p->is_reader, "now a reader");

    while ($p->fill_buffer) { }
    $bytes += length(delete $p->{in_buffer} // '');
    $p->{in_buffer_size} = 0;

    is($bytes, $n * 7, "all written bytes were received");
};

is(\@warnings, [], "no warnings (no croak-in-cleanup from DESTROY)");

done_testing;
