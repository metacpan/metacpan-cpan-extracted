use 5.022;
use strict;
use warnings;
use Time::HiRes qw(time);
use Scalar::Util qw(refaddr);
use Digest::SHA qw(sha1_hex);
use feature 'refaliasing';
no warnings 'experimental::refaliasing';
use ClickHouse::Encoder;

my $n = shift || 100_000;
my $layout = shift || 'copy';
die "layout must be copy or alias\n" unless $layout eq 'copy' || $layout eq 'alias';
my @types = (('UInt32') x 30, ('Int64') x 10, ('Decimal(18, 6)') x 8,
             ('String') x 12, ('LowCardinality(String)') x 6,
             ('Array(UInt32)') x 4, ('DateTime') x 2);
my @schema = map { ["c$_", $types[$_]] } 0 .. $#types;
my (@rows, %cols);
for my $r (0 .. $n - 1) {
    my @row = ((map { $r + $_ } 1 .. 30), (map { -$r - $_ } 1 .. 10),
               (map { "$_" . '234.567890' } 1 .. 8),
               (map { "message $_ row $r" } 1 .. 12),
               (map { 'category' . ($_ % 3) } 1 .. 6),
               (map { [$r, $r + 1] } 1 .. 4), (1700000000) x 2);
    push @rows, \@row;
}
for my $c (0 .. $#types) {
    if ($layout eq 'copy') {
        $cols{"c$c"} = [map { $_->[$c] } @rows];
    } else {
        my (@refs, @column);
        for my $row (@rows) { push @refs, \$row->[$c] }
        \(@column) = @refs;
        $cols{"c$c"} = sub { \@_ }->(@column);
    }
    my $same = refaddr(\$cols{"c$c"}[0]) == refaddr(\$rows[0][$c]);
    die "unexpected SV layout for c$c\n" if $same != ($layout eq 'alias');
}
my $enc = ClickHouse::Encoder->new(columns => \@schema);
my (%times, %hashes);
for my $kind (qw(columns rows)) {
    for (1 .. 4) {
        my $start = time;
        my $bytes = $kind eq 'rows' ? $enc->encode(\@rows)
                                  : $enc->encode_columns(\%cols);
        my $elapsed = time - $start;
        $times{$kind} = $elapsed
            if !exists $times{$kind} || $elapsed < $times{$kind};
        $hashes{$kind} = sha1_hex($bytes) if $_ == 4;
    }
}
die "row and column bytes differ\n" if $hashes{rows} ne $hashes{columns};
printf "%d rows x 72 (%s): rows %.4f s, columns %.4f s, ratio %.2f\n",
    $n, $layout, @times{qw(rows columns)}, $times{rows} / $times{columns};
if (open my $status, '<', '/proc/self/status') {
    while (<$status>) { print "peak RSS: $1 kB\n" if /^VmHWM:\s+(\d+)/ }
    close $status;
}
