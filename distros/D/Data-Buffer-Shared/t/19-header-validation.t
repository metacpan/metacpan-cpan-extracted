use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use IO::Handle ();
use Data::Buffer::Shared::I64;

my $dir = tempdir(CLEANUP => 1);
my $path = "$dir/buffer";
{ my $buf = Data::Buffer::Shared::I64->new($path, 4); $buf->set(0, 42) }
open my $source, '<:raw', $path or die "open: $!";
my $original = do { local $/; <$source> };
close $source;

my @cases = (
    ['reader-slot offset', 40, unpack('Q', substr($original, 40, 8)) + 16],
    ['data overlaps occupancy bitmap', 32, unpack('Q', substr($original, 32, 8)) - 128],
    ['unaligned data offset', 32, unpack('Q', substr($original, 32, 8)) - 1],
    ['recorded size', 24, length($original) + 1],
    ['extra file byte'],
);

for my $case (@cases) {
    my ($name, $off, $value) = @$case;
    my $data = $original;
    if (defined $off) { substr($data, $off, 8) = pack('Q', $value) }
    else { $data .= "\0" }
    open my $fh, '+>:raw', $path or die "open: $!";
    print {$fh} $data or die "write: $!";
    $fh->flush;
    for my $via (qw(path fd)) {
        my $buf = eval {
            $via eq 'path'
                ? Data::Buffer::Shared::I64->new($path, 4)
                : Data::Buffer::Shared::I64->new_from_fd(fileno($fh));
        };
        ok(!$buf, "$via rejects $name");
        like($@, qr/corrupt header/, "$via reports corrupt geometry");
    }
    seek($fh, 0, 0) or die "seek: $!";
    my $after = do { local $/; <$fh> };
    is($after, $data, "$name rejection preserves the file");
    close $fh;
}

done_testing;
