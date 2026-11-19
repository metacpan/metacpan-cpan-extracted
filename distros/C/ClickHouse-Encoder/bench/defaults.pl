use strict;
use warnings;
use Time::HiRes qw(time);
use Digest::SHA qw(sha1_hex);
use ClickHouse::Encoder;

my $count = shift || 100_000;
my $baseline_only = (shift || '') eq 'baseline';
my @types = (('UInt32') x 30, ('Int64') x 10, ('Decimal64(6)') x 8,
             ('String') x 12, ('LowCardinality(String)') x 6,
             ('Array(UInt32)') x 4, ('DateTime') x 2);
my @schema = map { ["c$_", $types[$_]] } 0 .. $#types;
my @default = ((0) x 40, ('0.000000') x 8, ('') x 18, (map { [] } 1 .. 4), (0) x 2);
my (@full, @empty);
for my $r (0 .. $count - 1) {
    my (@a, @b);
    for my $c (0 .. $#types) {
        my $value = $c < 40 ? $r + $c : $c < 48 ? '123.456789' : $c < 66 ? "value$c" : $c < 70 ? [$r] : 1700000000;
        if (($r * 7 + $c * 3) % 10 < 3) {
            push @a, $default[$c];
            push @b, $c >= 48 && $c < 66 || ($r + $c) % 2 ? undef : '';
        } else {
            push @a, $value;
            push @b, $value;
        }
    }
    push @full, \@a;
    push @empty, \@b;
}
my $plain = ClickHouse::Encoder->new(columns => \@schema);
my $defaults = ClickHouse::Encoder->new(columns => \@schema, empty_as_default => 1);
my @cases = (['baseline', $plain, \@full]);
push @cases, ['enabled', $defaults, \@full], ['30% empty', $defaults, \@empty] unless $baseline_only;
my (%times, %hashes);
for (1 .. 5) {
    for my $case (@cases) {
        my ($name, $enc, $rows) = @$case;
        my $start = time;
        my $bytes = $enc->encode($rows, positions => [0 .. 71]);
        my $elapsed = time - $start;
        $times{$name} = $elapsed if !exists $times{$name} || $elapsed < $times{$name};
        $hashes{$name} = sha1_hex($bytes);
    }
}
if ($baseline_only) {
    printf "%d rows x 72: baseline %.4f s\n", $count, $times{baseline};
    exit;
}
die "default bytes differ\n" if $hashes{baseline} ne $hashes{enabled} || $hashes{baseline} ne $hashes{'30% empty'};
printf "%d rows x 72: baseline %.4f s, enabled %.4f s, 30%% empty %.4f s (ratio %.3f)\n",
    $count, @times{'baseline', 'enabled', '30% empty'}, $times{'30% empty'} / $times{baseline};
