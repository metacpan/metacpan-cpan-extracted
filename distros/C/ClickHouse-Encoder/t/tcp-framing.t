use strict;
use warnings;
use Errno ();
my $interrupt_read = 0;
BEGIN {
    no warnings 'once';
    *CORE::GLOBAL::sysread = sub {
        if ($interrupt_read) { $interrupt_read--; $! = Errno::EINTR(); return undef }
        return CORE::sysread($_[0], $_[1], $_[2]);
    };
}
use Test::More;
use File::Temp qw(tempfile);
use lib 'blib/lib', 'blib/arch';
use ClickHouse::Encoder;
use ClickHouse::Encoder::TCP;
my $tcp = 'ClickHouse::Encoder::TCP';
my $info = ClickHouse::Encoder::TCP::pack_block_info();
my ($bi, $bi_end) = ClickHouse::Encoder::TCP::unpack_block_info($info, 0);
is_deeply($bi, {is_overflows => 0, bucket_num => -1}, 'default BlockInfo fields');
is($bi_end, length($info), 'BlockInfo byte count');

my $enc = ClickHouse::Encoder->new(columns => [['v','UUID']]);
my $uuid = '123e4567-e89b-12d3-a456-426614174000';
my $block = $enc->encode([map { [$uuid] } 1 .. 400]);
sub input_handle {
    my $body = shift;
    my ($fh, $name) = tempfile(UNLINK => 1);
    binmode $fh; print $fh $body; close $fh;
    open my $in, '<:raw', $name or die $!;
    return $in;
}
{
    my $buf = '';
    my $fh = input_handle("\x01\x00" . $info . $block . "\x04");
    $interrupt_read = 1;
    my $pkt = $tcp->read_packet($fh, buffer => \$buf);
    is($pkt->{block}{nrows}, 400, 'wide TCP block survives short reads and EINTR');
    is($pkt->{block_bytes}, $block, 'TCP payload excludes BlockInfo');
    is($tcp->read_packet($fh, buffer => \$buf)->{type}, 4, 'next packet preserved');
    close $fh;
}
{
    my $plain = $info . $block;
    my $frames = '';
    while (length $plain) {
        $frames .= ClickHouse::Encoder->compress_native_block(substr($plain, 0, 1500, ''), mode => 'none');
    }
    my $fh = input_handle("\x01\x00" . $frames . "\x04");
    my $buf = '';
    my $pkt = $tcp->read_packet($fh, buffer => \$buf, compressed => 1);
    is($pkt->{block_bytes}, $block, 'compressed frame chain reconstructs one block');
    is($pkt->{compressed_consumed}, length $frames, 'all frames consumed exactly');
    is($tcp->read_packet($fh, buffer => \$buf)->{type}, 4, 'packet after compressed chain retained');
    close $fh;
}
{
    my $hello = "\x00" . ClickHouse::Encoder::TCP::pack_string('server')
        . join('', map { ClickHouse::Encoder::TCP::pack_varint($_) } 26,9,54429)
        . ClickHouse::Encoder::TCP::pack_string('UTC')
        . ClickHouse::Encoder::TCP::pack_string('server') . "\x00";
    pipe(my $r, my $w) or die $!;
    my $partial = substr($hello, 0, 4);
    syswrite $w, $partial;
    my $buf = '';
    eval { $tcp->read_packet($r, buffer => \$buf, timeout => .02) };
    like($@, qr/timed out/, 'partial packet times out');
    is($buf, $partial, 'timeout retains all received bytes');
    syswrite $w, substr($hello, 4); close $w;
    is($tcp->read_packet($r, buffer => \$buf, timeout => 1)->{name}, 'server', 'retry resumes partial packet');
    close $r;
}
{
    my $body = pack('l<', 7) . ClickHouse::Encoder::TCP::pack_string('E')
        . ClickHouse::Encoder::TCP::pack_string('failed') . "\x00";
    my $wire = "\x02" . $body . "\x01" . $body . "\x00\x04";
    my $fh = input_handle($wire);
    my $buf = '';
    my $pkt = $tcp->read_packet($fh, buffer => \$buf);
    is($pkt->{nested}{code}, 7, 'nested exception decoded');
    is($tcp->read_packet($fh, buffer => \$buf)->{type}, 4, 'packet after nested exception retained');
    close $fh;
}
{
    my $fh = input_handle("\x0a\x00" . $info . $block);
    is($tcp->read_packet($fh, compressed => 1)->{block}{nrows}, 400, 'Log remains uncompressed on compressed connections');
    close $fh;
    my $query = $tcp->pack_query(query => 'select 1');
    is(substr($query, -12), "\x02\x00" . $info . "\x00\x00", 'query sends external-table terminator');
    my $raw = "caf\xc3\xa9";
    is(ClickHouse::Encoder::TCP::pack_string($raw), chr(length($raw)) . $raw, 'TCP UTF-8 bytes preserved');
}
done_testing();
