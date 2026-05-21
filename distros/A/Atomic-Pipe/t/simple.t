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
        my $p = Atomic::Pipe->new(use_io_select => $use_select);

        my $w1 = $p->clone_writer;
        my $w2 = $p->clone_writer;
        my $w3 = $p->clone_writer;

        $p->reader;

        $w1->write_message("aaa");
        $w2->write_message("bbb");
        $w3->write_message("ccc");

        is($p->read_message, "aaa", "Got first message");
        is($p->read_message, "bbb", "Got second message");
        is($p->read_message, "ccc", "Got third message");
    };
}

done_testing;
