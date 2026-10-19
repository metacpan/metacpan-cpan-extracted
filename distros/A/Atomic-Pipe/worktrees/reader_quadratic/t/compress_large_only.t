use Test2::V0;
use Test2::Util qw/CAN_REALLY_FORK/;
use Atomic::Pipe;

plan skip_all => 'Compress::Zstd not installed'
    unless eval { require Compress::Zstd; 1 };

my $SMALL = 'small message ' x 10;
my $LARGE = join ',' => map { "{\"id\":$_,\"name\":\"item $_\"}" } 1 .. 2000;    # compressible, multi-part

# Read the raw headers a writer produced, to see which parts carry the flag.
sub wire_parts {
    my ($w_params, @msgs) = @_;
    my ($r, $w) = Atomic::Pipe->pair(%$w_params);
    $r->read_size(1 << 20);
    my $pid = fork // die "fork: $!";
    unless ($pid) {
        $r->close;
        $w->write_message($_) for @msgs;
        $w->close;
        exit 0;
    }
    $w->close;
    my $raw = '';
    1 while sysread($r->rh, $raw, 1 << 20, length $raw);
    waitpid($pid, 0);

    my @parts;
    while (length $raw) {
        my ($pid, $tid, $id, $size) = unpack('l2L2', substr($raw, 0, 16, ''));
        my $flag = $size & 0x80000000 ? 1 : 0;
        $size &= 0x7FFFFFFF;
        substr($raw, 0, $size, '');
        push @parts => {id => $id, flag => $flag, size => $size};
    }
    return @parts;
}

subtest validation => sub {
    like(
        dies { Atomic::Pipe->new(compression_threshold => 'big') },
        qr/compression_threshold must be a non-negative integer/,
        'threshold must be an integer',
    );
    like(
        dies { Atomic::Pipe->new(compress_large_only => 1, compression => 'bogus') },
        qr/Unknown compression algorithm 'bogus'/,
        'explicit algorithm is still validated',
    );
};

subtest enables_compression => sub {
    my $p = Atomic::Pipe->new(compress_large_only => 1);
    is($p->compression,           'zstd', 'compress_large_only turns on zstd');
    is($p->compress_large_only,   1,      'large-only mode on');
    is($p->compression_threshold, Atomic::Pipe::PIPE_BUF() - 16, 'default threshold is one atomic part');

    my $m = Atomic::Pipe->new(compress_large_only => 1, mixed_data_mode => 1);
    is($m->compression_threshold, Atomic::Pipe::PIPE_BUF() - 19, 'mixed mode default accounts for its 3 delimiter bytes');

    $p = Atomic::Pipe->new(compression_threshold => 100);
    is($p->compression, 'zstd', 'compression_threshold turns on zstd');

    my ($r, $w) = Atomic::Pipe->pair(compress_large_only => 1);
    is($r->compression, 'zstd', 'pair reader gets zstd');
    is($w->compression, 'zstd', 'pair writer gets zstd');

    $p = Atomic::Pipe->new(compression => 'zstd', compression_level => 7, compress_large_only => 1);
    is($p->compression_level, 7, 'explicit compression settings are kept');

    $p = Atomic::Pipe->new;
    $p->set_compress_large_only(1);
    is($p->compression,         'zstd', 'setter turns on zstd');
    is($p->compress_large_only, 1,      'setter enables large-only mode');

    $p = Atomic::Pipe->new;
    is($p->compression, undef, 'compression still off by default');
};

subtest turning_off_undoes_what_it_enabled => sub {
    my $p = Atomic::Pipe->new(compress_large_only => 1);
    $p->set_compress_large_only(0);
    is($p->compression, undef, 'compression it switched on (constructor) is switched off');

    $p = Atomic::Pipe->new;
    $p->set_compress_large_only(1);
    $p->set_compress_large_only(0);
    is($p->compression, undef, 'compression it switched on (setter) is switched off');

    $p = Atomic::Pipe->new(compression => 'zstd', compress_large_only => 1);
    $p->set_compress_large_only(0);
    is($p->compression, 'zstd', 'explicit compression stays on (back to compressing everything)');

    $p = Atomic::Pipe->new(compress_large_only => 1);
    $p->set_compression('zstd', 5);
    $p->set_compress_large_only(0);
    is($p->compression, 'zstd', 'compression set explicitly afterwards counts as explicit');
};

subtest accessors => sub {
    my $p = Atomic::Pipe->new(compression => 'zstd');
    is($p->compress_large_only,   0,     'off by default');
    is($p->compression_threshold, undef, 'no threshold by default');

    $p->set_compress_large_only(1);
    is($p->compress_large_only,   1,     'enabled by setter');
    is($p->compression_threshold, Atomic::Pipe::PIPE_BUF() - 16, 'default threshold');

    $p->set_compress_large_only(1, 500);
    is($p->compression_threshold, 500, 'threshold set');

    $p->set_compress_large_only(0);
    is($p->compress_large_only,   0,     'disabled');
    is($p->compression_threshold, undef, 'no threshold when large-only is off');

    $p = Atomic::Pipe->new(compression => 'zstd', compression_threshold => 0);
    is($p->compress_large_only, 1, 'compression_threshold alone enables it');
};

subtest wire_format => sub {
    skip_all "needs a real fork()" unless CAN_REALLY_FORK;
    my @parts = wire_parts({compress_large_only => 1}, $SMALL, $LARGE);
    is($parts[0], {id => 0, flag => 0, size => length($SMALL)}, 'small message sent plain, unflagged');
    ok(@parts > 1, 'large message present');
    ok((!grep { !$_->{flag} } @parts[1 .. $#parts]), 'every part of the large message is flagged');
    my $part_size = Atomic::Pipe::PIPE_BUF() - 16;
    ok(length($LARGE) > $part_size, 'large message would need splitting uncompressed');

    @parts = wire_parts({compression => 'zstd'}, $SMALL);
    is($parts[0]->{flag}, 0, 'legacy compression never sets the flag');

    @parts = wire_parts({compression_threshold => 10}, $SMALL);
    is($parts[0]->{flag}, 1, 'custom threshold compresses smaller messages');

    my $noise = join '' => map { chr(int rand 256) } 1 .. 20_000;
    @parts = wire_parts({compression => 'zstd', compress_large_only => 1}, $noise);
    ok((!grep { $_->{flag} } @parts), 'incompressible data is sent plain');
    is(scalar(@parts), int((length($noise) + $part_size - 1) / $part_size), 'incompressible data split normally');
};

for my $mixed (0, 1) {
    subtest($mixed ? 'roundtrip_mixed' : 'roundtrip_read_message' => sub {
        skip_all "needs a real fork()" unless CAN_REALLY_FORK;
        my @mode = $mixed ? (mixed_data_mode => 1) : ();

        for my $large_reader (1, 0) {
            my $label = $large_reader ? 'large_only reader' : 'reader without compression';

            my ($r, $w) = Atomic::Pipe->pair(@mode);
            $w->set_compress_large_only(1);
            $r->set_compress_large_only(1) if $large_reader;
            $r->set_keep_compressed(1);

            my $pid = fork // die "fork: $!";
            unless ($pid) {
                $r->close;
                $w->write_message($SMALL);
                $w->write_burst("a burst\n") if $mixed;
                $w->write_message($LARGE);
                $w->close;
                exit 0;
            }
            $w->close;

            my @got;
            if ($mixed) {
                while (1) {
                    my %m = $r->get_line_burst_or_data;
                    last if !%m && $r->eof;
                    push @got => \%m if %m;
                }
                is(
                    \@got,
                    [
                        {message => $SMALL},
                        {burst   => "a burst\n"},
                        {message => $LARGE, compressed => D()},
                    ],
                    "$label: plain and compressed messages, burst untouched",
                );
            }
            else {
                while (my ($m, $c) = $r->read_message) { push @got => [$m, $c] }
                is(
                    \@got,
                    [[$SMALL, undef], [$LARGE, D()]],
                    "$label: only the large message reports a compressed form",
                );
            }
            waitpid($pid, 0);
        }
    });
}

done_testing;
