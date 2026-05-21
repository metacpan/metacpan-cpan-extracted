use Test2::V0;
use Atomic::Pipe;
BEGIN { *PIPE_BUF = Atomic::Pipe->can('PIPE_BUF') }

BEGIN {
    my $path = __FILE__;
    $path =~ s{[^/]+\.t$}{worker.pm};
    require "./$path";
}

BEGIN {
    my $path = __FILE__;
    $path =~ s{[^/]+\.t$}{select_mode.pm};
    require "./$path";
}

for my $use_select (io_select_modes()) {
    subtest "use_io_select=$use_select" => sub {
        my ($r, $w) = Atomic::Pipe->pair(use_io_select => $use_select);

        $r->blocking(1);
        $w->blocking(0);

        # Test 1: non-blocking writes overflow into the internal buffer.
        # Worker waits for a "go" signal so the parent can fill the pipe
        # without the reader draining it.
        my $sync = make_sync();
        worker {
            sync_signal($sync->{from_worker_w});
            sync_wait($sync->{to_worker_r});
            while (my $msg = $r->read_message) { last if $msg =~ m/END/i }
        };
        sync_wait($sync->{from_worker_r});

        my $count = 0;
        until ($w->{out_buffer} && @{$w->{out_buffer}}) {
            $w->resize(PIPE_BUF * 2);    # Might not work, but nicer on systems where it does
            $w->write_message("aa" x PIPE_BUF);
            $count++;

            next unless $count > 1000;
            fail "Count got too high!";
            last;
        }
        ok(@{$w->{out_buffer}} > 0, "Non-blocking writes filled the internal buffer");

        $w->write_message("END");

        sync_signal($sync->{to_worker_w});

        # Clear the buffer
        while (@{$w->{out_buffer}}) {
            $w->flush;
        }

        ok(1, "Was able to flush the buffer");

        cleanup();

        # Test 2: blocking flush on destroy. Worker writes a single message
        # and lets $w go out of scope, which performs a blocking flush.
        $sync = make_sync();
        worker {
            sync_signal($sync->{from_worker_w});
            sync_wait($sync->{to_worker_r});
            $w->write_message("zz" x PIPE_BUF);
            do { $w = undef };
        };
        sync_wait($sync->{from_worker_r});
        sync_signal($sync->{to_worker_w});

        my $msg = $r->read_message;
        is($msg, "zz" x PIPE_BUF, "Got expected message when writing is non-blocking");

        cleanup();

        # Test 3: blocking writes succeed once the reader drains. Fill the OS
        # pipe so further writes would block, verify via select(), then release
        # the worker and complete the writes in blocking mode.
        $sync = make_sync();
        worker {
            sync_signal($sync->{from_worker_w});
            sync_wait($sync->{to_worker_r});
            while (my $msg = $r->read_message) { last if $msg =~ m/END/i }
        };
        sync_wait($sync->{from_worker_r});

        $w->blocking(0);
        for (0 .. $count) {
            $w->write_message("aa" x PIPE_BUF);
        }

        ok(!can_write_now($w->wh), "OS pipe is full; a blocking write would block");

        $w->blocking(1);
        sync_signal($sync->{to_worker_w});

        for (0 .. $count) {
            $w->write_message("aa" x PIPE_BUF);
        }
        ok(1, "Blocking writes completed once reader drained");

        $w->write_message("END");

        delete $w->{out_buffer};

        cleanup();
    };
}

done_testing;
