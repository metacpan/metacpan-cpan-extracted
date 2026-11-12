use 5.012;
use strict;
use warnings;
use Time::HiRes qw(time);
use Digest::SHA qw(sha256_hex);
use Data::Dump::Streamer;

# Run from a built checkout with: perl -Mblib maint/memory-benchmark.pl
# Arguments: wide|deep, record count|depth, optional callback flag.
# Linux reports RSS in KiB; elsewhere use the platform's external time tool.
my ($kind, $size, $callback)= @ARGV;
$kind //= 'wide';
$size //= $kind eq 'wide' ? 100_000 : 2_000;
die "Expected wide or deep and a positive size\n"
    unless $kind =~ /\A(?:wide|deep)\z/ && $size =~ /\A[1-9][0-9]*\z/;

my $value;
if ($kind eq 'wide') {
    $value=
        [ map { { id => $_, name => "n$_", tags => [ 1, 2 ] } } 1 .. $size ];
}
else {
    $value= [];
    $value= { k => 1, n => [$value] } for 1 .. $size;
}

sub peak_kib {
    open my $fh, '<', '/proc/self/status' or return;
    while (<$fh>) { return $1 if /^VmHWM:\s+(\d+)/ }
    return;
}

my $dumper= Data::Dump::Streamer->new->Indent(0);
$dumper->SortKeys(sub { [ sort keys %{ $_[0] } ] }) if $callback;
my $before= peak_kib();
my $start= time;
my $text= $dumper->Data($value)->Out;
my $elapsed= time - $start;
my $after= peak_kib();
printf "%s size=%d callback=%d seconds=%.3f bytes=%d sha256=%s",
    $kind, $size, !!$callback, $elapsed, length($text), sha256_hex($text);
printf " peak_growth_kib=%d", $after - $before
    if defined($before) && defined($after);
print "\n";

# Avoid recursive Perl destruction becoming the benchmark's depth limit.
if ($kind eq 'deep') {
    while (ref($value) eq 'HASH') {
        my $next= $value->{n}[0];
        delete $value->{n};
        $value= $next;
    }
}
