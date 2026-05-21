use Test2::V0;
use Atomic::Pipe;
BEGIN { *PIPE_BUF = Atomic::Pipe->can('PIPE_BUF') }

BEGIN {
    my $path = __FILE__;
    $path =~ s{[^/]+\.t$}{select_mode.pm};
    require "./$path";
}

for my $use_select (io_select_modes()) {
    subtest "use_io_select=$use_select" => sub {
        my ($rh, $wh);
        pipe($rh, $wh) or die "Could not make a pipe: $!";

        subtest from_fh => sub {
            my $r = Atomic::Pipe->from_fh('<&', $rh);
            my $w = Atomic::Pipe->from_fh('>&', $wh);

            $r->use_io_select($use_select);

            ok($r->is_reader, "Made Reader");
            ok($w->is_writer, "Made Writer");

            $w->write_message("aaa");
            is($r->read_message, "aaa", "Got message");
        };

        # Some platforms cannot do it this way
        if (eval {Atomic::Pipe->_fh_mode($rh) && Atomic::Pipe->_fh_mode($wh)}) {
            subtest from_fh_auto_mode => sub {
                my $r = Atomic::Pipe->from_fh($rh);
                my $w = Atomic::Pipe->from_fh($wh);

                $r->use_io_select($use_select);

                ok($r->is_reader, "Made Reader");
                ok($w->is_writer, "Made Writer");

                $w->write_message("aaa");
                is($r->read_message, "aaa", "Got message");
            };
        }

        subtest from_fd => sub {
            my $r = Atomic::Pipe->from_fd('<&', fileno($rh));
            my $w = Atomic::Pipe->from_fd('>&', fileno($wh));

            $r->use_io_select($use_select);

            ok($r->is_reader, "Made Reader");
            ok($w->is_writer, "Made Writer");

            $w->write_message("aaa");
            is($r->read_message, "aaa", "Got message");
        };

        subtest from_fd_reuse => sub {
            my $r = Atomic::Pipe->from_fd('<&=', fileno($rh));
            my $w = Atomic::Pipe->from_fd('>&=', fileno($wh));

            $r->use_io_select($use_select);

            is(fileno($r->{rh}), fileno($rh), "Kept fileno (rh)");
            is(fileno($w->{wh}), fileno($wh), "Kept fileno (wh)");

            ok($r->is_reader, "Made Reader");
            ok($w->is_writer, "Made Writer");

            $w->write_message("aaa");
            is($r->read_message, "aaa", "Got message");
        };
    };
}

done_testing;
