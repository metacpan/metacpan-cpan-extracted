use Test2::V0;
use Atomic::Pipe;

# The reader must only pull data from the pipe when the buffer cannot satisfy
# the next step. get_line_burst_or_data() used to call eof() (which reads) on
# every pass, so it drained the whole pipe into memory; combined with
# split-based consumption that made mixed-mode reads quadratic.
#
# Everything is written before reading starts so the result does not depend on
# scheduling: with the old behavior in_buffer grows to the whole stream.

my $READ_SIZE = 4096;
my $STREAM    = 48 * 1024;

for my $mixed (1, 0) {
    subtest($mixed ? 'mixed_data_mode' : 'read_message' => sub {
        my ($r, $w) = Atomic::Pipe->pair($mixed ? (mixed_data_mode => 1) : ());

        # Build the stream first and count its exact size on the wire, so the
        # skip below can guarantee everything fits in the pipe (writing more
        # than fits before reading would deadlock).
        my $dsize = $w->_adjusted_dsize;
        my $frame = 16 + ($mixed ? 3 : 0);    # header, plus key and delimiters in mixed mode
        my (@expect, $total);
        my $i = 0;
        while (($total // 0) < $STREAM) {
            # Mix of single-part and multi-part messages, lines between them.
            my $msg = join '' => ("$i-" x (1 + ($i * 997) % 2500));
            my $parts = int((length($msg) + $dsize - 1) / $dsize);
            push @expect => [message => $msg];
            $total += length($msg) + $parts * $frame;

            if ($mixed) {
                my $line = "line $i\n";
                push @expect => [line => $line];
                $total += length $line;
            }
            $i++;
        }

        my $size = $w->size;
        skip_all "Cannot query pipe size on this platform" unless $size;
        skip_all "Pipe too small ($size) to hold the $total byte test stream" if $size < $total;

        $r->read_size($READ_SIZE);

        for my $item (@expect) {
            my ($type, $data) = @$item;
            if ($type eq 'message') { $w->write_message($data) }
            else                    { syswrite($w->wh, $data) }
        }
        $w->close;

        my ($max, @got) = (0);
        if ($mixed) {
            while (1) {
                my %m = $r->get_line_burst_or_data;
                $max = $r->{in_buffer_size} if ($r->{in_buffer_size} // 0) > $max;
                last if !%m && $r->eof;
                my ($k) = keys %m;
                push @got => [$k => $m{$k}];
            }
        }
        else {
            while (defined(my $m = $r->read_message)) {
                $max = $r->{in_buffer_size} if ($r->{in_buffer_size} // 0) > $max;
                push @got => [message => $m];
            }
        }

        is(\@got, \@expect, "got every message and line in order");
        ok($max <= 3 * $READ_SIZE, "in_buffer stayed bounded ($max bytes for a $total byte stream)");
    });
}

done_testing;
