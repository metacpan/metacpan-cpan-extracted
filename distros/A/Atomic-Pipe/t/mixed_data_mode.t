use Test2::V0;
use Atomic::Pipe;
use Time::HiRes qw/sleep/;
BEGIN { *PIPE_BUF = Atomic::Pipe->can('PIPE_BUF') }

BEGIN {
    my $path = __FILE__;
    $path =~ s{[^/]+\.t$}{worker.pm};
    require "./$path";
}

subtest get_line_burst_or_data => sub {
    my ($r, $w) = Atomic::Pipe->pair(mixed_data_mode => 1);
    open(my $wh, '>&=', $w->wh) or die "Could not clone write handle: $!";
    $wh->autoflush(1);

    worker {
        print $wh "A Line\n";
        print $wh "Line start ...";
        $wh->flush();

        $w->write_burst("Interrupting cow!\n\n\n");

        print $wh "... line end\n";
        $wh->flush;

        print $wh "not terminated but EOF";
        $wh->flush;
    };

    my @got;
    while (@got != 3) {
        my ($type, $text) = $r->get_line_burst_or_data();
        if (!$type) {
            sleep 0.2;
            next;
        }
        push @got => [$type, $text];
    }

    is(
        shift @got,
        [line => "A Line\n"],
        "Got the first line"
    );

    is(
        shift @got,
        [burst => "Interrupting cow!\n\n\n"],
        "Got the burst between line fragments"
    );

    is(
        shift @got,
        [line => "Line start ...... line end\n"],
        "Got the interrupted line"
    );

    ok(!$r->eof, "Not EOF");

    is(
        [$r->get_line_burst_or_data()],
        [],
        "No Data"
    );

    ok(!$r->eof, "Not EOF");

    # Get to EOF
    $w->close;
    close($wh);
    cleanup();

    ok(!$r->eof, "Not EOF");

    is(
        [$r->get_line_burst_or_data()],
        [line => "not terminated but EOF"],
        "Got unterminated line"
    );

    ok($r->eof, "EOF");

    is(
        [$r->get_line_burst_or_data()],
        [],
        "No Data"
    );

    ok($r->eof, "EOF");

    ($r, $w) = Atomic::Pipe->pair(mixed_data_mode => 1);
    open($wh, '>&=', $w->wh) or die "Could not clone write handle: $!";
    $wh->autoflush(1);

    worker {
        no warnings 'redefine';
        print $wh "A Line\n";
        $wh->flush();

        my $iter = 0;
        my $wb   = Atomic::Pipe->can('_write_burst');
        *Atomic::Pipe::_write_burst = sub {
            $iter++;
            print $wh "Line start ..." if $iter == 2;
            $wb->(@_);
        };

        $w->write_message("aa" x PIPE_BUF);

        print $wh "... line end\n";

        print $wh "not terminated but EOF";
        $wh->flush;
    };

    @got = ();
    while (@got != 3) {
        my ($type, $text) = $r->get_line_burst_or_data();
        if (!$type) {
            sleep 0.2;
            next;
        }
        push @got => [$type, $text];
    }

    is(
        shift @got,
        [line => "A Line\n"],
        "Got the first line"
    );

    is(
        shift @got,
        [message => ("aa" x PIPE_BUF)],
        "Got the message between line fragments"
    );

    is(
        shift @got,
        [line => "Line start ...... line end\n"],
        "Got the interrupted line"
    );

    ok(!$r->eof, "Not EOF");

    is(
        [$r->get_line_burst_or_data()],
        [],
        "No Data"
    );

    ok(!$r->eof, "Not EOF");

    # Get to EOF
    $w->close;
    close($wh);
    cleanup();

    ok(!$r->eof, "Not EOF");

    is(
        [$r->get_line_burst_or_data()],
        [line => "not terminated but EOF"],
        "Got unterminated line"
    );

    ok($r->eof, "EOF");

    is(
        [$r->get_line_burst_or_data()],
        [],
        "No Data"
    );

    ok($r->eof, "EOF");
};

subtest incomplete_burst => sub {
    my ($r, $w) = Atomic::Pipe->pair(mixed_data_mode => 1);
    open(my $wh, '>&=', $w->wh) or die "Could not clone write handle: $!";
    $wh->autoflush(1);

    worker {
        print $wh $w->{burst_prefix}, "xxxxx";
        $wh->flush();
    };
    close($wh);
    $w->close;
    cleanup();

    ok(!$r->eof, "Not EOF");

    like(
        dies { $r->get_line_burst_or_data },
        qr/Incomplete burst data received before end of pipe/,
        "Incomplete burst data"
    );

    like(
        dies { $r->eof },
        qr/Incomplete burst data received before end of pipe/,
        "EOF is invalid when the pipe is invalid"
    );
};

subtest incomplete_message => sub {
    my ($r, $w) = Atomic::Pipe->pair(mixed_data_mode => 1);

    worker {
        no warnings 'redefine';

        # Only write part 1
        my $wb   = Atomic::Pipe->can('_write_burst');
        my $iter = 0;
        *Atomic::Pipe::_write_burst = sub {
            if ($iter++) {
                @{$w->{out_buffer}} = ();
                return;
            }

            $wb->(@_);
        };

        $w->write_message("AA" x PIPE_BUF);
    };

    $w->close;
    cleanup();

    ok(!$r->eof, "Not EOF");

    like(
        dies { $r->get_line_burst_or_data },
        qr/Incomplete message received before EOF/,
        "Incomplete message data"
    );

    like(
        dies { $r->eof },
        qr/Incomplete message received before EOF/,
        "EOF is invalid when pipe is invalid"
    );
};

done_testing;

