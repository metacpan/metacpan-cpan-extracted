use Test2::V0;
use Atomic::Pipe;

my ($r, $w) = Atomic::Pipe->pair();

sub push_buffer {
    my $data = shift;

    my $size = $w->fits_in_burst($data);
    push @{$w->{out_buffer} //= []} => [$data, $size];
};

push_buffer("aaaaa");
push_buffer("bbbbb");
push_buffer("ccccc");

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

push_buffer("aaaaa");

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

done_testing;
