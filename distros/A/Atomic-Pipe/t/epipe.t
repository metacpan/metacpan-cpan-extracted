use Test2::V0;
use Atomic::Pipe;

BEGIN {
    my $path = __FILE__;
    $path =~ s{[^/]+\.t$}{select_mode.pm};
    require "./$path";
}

for my $use_select (io_select_modes()) {
    subtest "use_io_select=$use_select" => sub {
        my ($r, $w) = Atomic::Pipe->pair(use_io_select => $use_select);

        sub push_buffer {
            my ($w, $data) = @_;

            my $size = $w->fits_in_burst($data);
            push @{$w->{out_buffer} //= []} => [$data, $size];
        };

        push_buffer($w, "aaaaa");
        push_buffer($w, "bbbbb");
        push_buffer($w, "ccccc");

        ok($w->pending_output, "Have output ready to go");

        $r->close();
        $r = undef;

        my $sigpipe = 0;
        like(
            dies {
                local $SIG{PIPE} = sub { $sigpipe++ };
                $w->flush();
            },
            qr/Disconnected pipe/,
            "We saw the pipe disconnect"
        );

        is($sigpipe, 1, "Sigpipe handler was used") unless $w->IS_WIN32;

        ok(!$w->pending_output, "Cleared pending output");

        push_buffer($w, "aaaaa");

        $sigpipe = 0;
        like(
            dies {
                local $SIG{PIPE} = sub { $sigpipe++ };
                $w->flush();
            },
            qr/Disconnected pipe/,
            "Still disconnected"
        );

        ok(!$sigpipe, "No additional sigpipe") unless $w->IS_WIN32;

        delete $w->{out_buffer};
    };
}

done_testing;
