use Test2::V0;
use Atomic::Pipe;

my $HAVE_ZSTD = eval { require Compress::Zstd; 1 };

subtest 'from_fh accepts constructor params' => sub {
    skip_all "requires Compress::Zstd" unless $HAVE_ZSTD;

    my ($r, $w) = Atomic::Pipe->pair;
    my $wp = Atomic::Pipe->from_fh('>&', $w->wh, compression => 'zstd');
    my $rp = Atomic::Pipe->from_fh('<&', $r->rh, compression => 'zstd');

    is($wp->compression, 'zstd', "writer stored the compression param");
    is($rp->compression, 'zstd', "reader stored the compression param");

    $wp->write_message("hello compression");
    is($rp->read_message, "hello compression", "compressed round trip works");
};

subtest 'from_fd accepts constructor params' => sub {
    skip_all "requires Compress::Zstd" unless $HAVE_ZSTD;

    my ($r, $w) = Atomic::Pipe->pair;
    my $wp = Atomic::Pipe->from_fd('>&', fileno($w->wh), compression => 'zstd');
    my $rp = Atomic::Pipe->from_fd('<&', fileno($r->rh), compression => 'zstd');

    is($wp->compression, 'zstd', "writer stored the compression param");

    $wp->write_message("fd round trip");
    is($rp->read_message, "fd round trip", "compressed round trip works");
};

subtest 'params are validated' => sub {
    my ($r, $w) = Atomic::Pipe->pair;
    like(
        dies { Atomic::Pipe->from_fh('>&', $w->wh, compression => 'nope') },
        qr/Unknown compression algorithm 'nope'/,
        "from_fh validates params",
    );
    like(
        dies { Atomic::Pipe->from_fd('>&', fileno($w->wh), compression => 'nope') },
        qr/Unknown compression algorithm 'nope'/,
        "from_fd validates params",
    );
};

subtest 'mixed_data_mode param works on all constructors' => sub {
    my $p = Atomic::Pipe->new(mixed_data_mode => 1);
    is($p->{message_key}, "\x10", "new() honors mixed_data_mode");

    my ($r, $w) = Atomic::Pipe->pair;
    my $wp = Atomic::Pipe->from_fh('>&', $w->wh, mixed_data_mode => 1);
    is($wp->{message_key}, "\x10", "from_fh honors mixed_data_mode");

    my $rp = Atomic::Pipe->from_fd('<&', fileno($r->rh), mixed_data_mode => 1);
    is($rp->{message_key}, "\x10", "from_fd honors mixed_data_mode");
};

done_testing;
