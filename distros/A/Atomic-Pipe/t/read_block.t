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

        # Test 1: blocking read waits until writer writes.
        # Sync replaces wall-clock timing: worker signals ready, parent verifies
        # the read end is not currently readable (proving a read would block),
        # then releases the worker to perform the write.
        my $sync = make_sync();
        worker {
            sync_signal($sync->{from_worker_w});
            sync_wait($sync->{to_worker_r});
            $w->write_message("aaa\n");
        };

        sync_wait($sync->{from_worker_r});
        ok(!can_read_now($r->rh), "Read would block (no data yet)");

        sync_signal($sync->{to_worker_w});
        my $msg = $r->read_message;
        is($msg, "aaa\n", "got the message");

        cleanup();

        # Test 2: non-blocking read returns immediately when no data is available.
        $sync = make_sync();
        worker {
            sync_signal($sync->{from_worker_w});
            sync_wait($sync->{to_worker_r});
            $w->write_message("bbb\n");
        };

        sync_wait($sync->{from_worker_r});

        $r->blocking(0);
        $msg = $r->read_message;
        ok(!$msg, "No message (did not block)");

        sync_signal($sync->{to_worker_w});
        cleanup();
    };
}

done_testing;
