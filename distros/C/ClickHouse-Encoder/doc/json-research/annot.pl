#!/usr/bin/env perl
use strict;
use warnings;

my $file = shift or die "usage: $0 file.bin";
open my $fh, '<:raw', $file or die;
local $/;
my $bin = <$fh>;

sub varint {
    my ($buf, $off) = @_;
    my ($n, $s) = (0, 0);
    while (1) {
        my $b = ord substr $$buf, $$off++, 1;
        $n |= ($b & 0x7f) << $s;
        last unless $b & 0x80;
        $s += 7;
    }
    return $n;
}
sub U64 { unpack 'Q<', substr $_[0], $_[1], 8 }

my $off = 0;
my $ncols = varint(\$bin, \$off);
my $nrows = varint(\$bin, \$off);
printf "block: ncols=%d nrows=%d\n", $ncols, $nrows;

for my $c (1..$ncols) {
    my $nl = varint(\$bin, \$off); my $name = substr($bin, $off, $nl); $off += $nl;
    my $tl = varint(\$bin, \$off); my $type = substr($bin, $off, $tl); $off += $tl;
    printf "col %s : %s\n", $name, $type;
    next unless $type eq 'JSON';

    my $version = U64($bin, $off); $off += 8;
    my $paths_count = varint(\$bin, \$off);
    printf "  version=%d paths=%d\n", $version, $paths_count;
    my @paths;
    for (1..$paths_count) {
        my $nl = varint(\$bin, \$off);
        push @paths, substr($bin, $off, $nl);
        $off += $nl;
    }
    printf "  path names: @paths\n";
    printf "  remaining bytes (%d): %s\n",
        length($bin) - $off, unpack('H*', substr($bin, $off));
}
