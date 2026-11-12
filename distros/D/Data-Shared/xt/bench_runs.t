use strict;
use warnings;
use Test::More;
use FindBin;
use File::Temp qw(tempfile);
plan skip_all => 'author test' unless $ENV{AUTHOR_TESTING};

my $root = "$FindBin::Bin/..";

sub run_clean {
    my ($script, %env) = @_;
    my ($errfh, $errfile) = tempfile(UNLINK => 1);
    local @ENV{ keys %env } = values %env;
    my $out = do {
        open my $saved, '>&', \*STDERR or die $!;
        open STDERR, '>&', $errfh or die $!;
        open my $fh, '-|', $^X, "-I$root/lib", $script or die $!;
        my $o = do { local $/; <$fh> };
        close $fh;
        open STDERR, '>&', $saved or die $!;
        $o;
    };
    my $status = $?;
    my $err = do { open my $e, '<', $errfile or die $!; local $/; <$e> };
    return ($status, $out, $err);
}

my @bench = sort glob "$root/bench/*.pl";
cmp_ok scalar @bench, '>=', 5, 'the benchmarks are populated';
for my $script (@bench) {
    my ($name) = $script =~ m{([^/]+)$};
    my ($status, $out, $err) = run_clean($script,
        DS_BENCH_TIME => 0.2, DS_BENCH_CHILDREN => 8, DS_BENCH_KEYS => 200,
        DS_BENCH_REPLAY => 10, DS_BENCH_SIZES => '50', DS_BENCH_WORKING_SET => 16,
        DS_BENCH_ITERATIONS => 50, DS_BENCH_WORKERS => 2);
    is $status, 0, "$name exits 0";
    is $err, '', "$name writes nothing to stderr" or diag $err;
}

my %published;
{
    open my $fh, '<', "$root/lib/Data/Shared.pm" or die $!;
    while (my $l = <$fh>) {
        last if %published && $l !~ /us\/op/;
        $published{$1} = $2 if $l =~ /^\s{4}(\S+(?: \S+)?)\s+([\d.]+)\s+us\/op\s*$/;
    }
}
is_deeply [sort keys %published],
    [sort 'array path', 'compiled', 'native handle', 'shared_call', 'string path'],
    'the published table names the five tiers';

my ($status, $out) = run_clean("$root/bench/overhead.pl", DS_BENCH_TIME => 0.3);
my %measured = $out =~ /^(\S+)\s+\S+\/s\s+([\d.]+) us\/op$/mg;
my %label = ('native handle' => 'native', 'compiled' => 'compiled',
             'array path' => 'array', 'shared_call' => 'call', 'string path' => 'string');
# Absolute timing claims wait for a quiet host; the ordering is relative and keeps running.
my ($load) = (do { open my $fh, '<', '/proc/loadavg' or die $!; <$fh> } =~ /\A([\d.]+)/);
for my $tier (sort keys %published) {
    my $got = $measured{ $label{$tier} };
    ok defined $got, "overhead.pl still reports '$label{$tier}' for '$tier'" or next;
    SKIP: {
        skip "load $load leaves no room for an absolute timing claim", 2 if $load > 2;
        # Wide on purpose: this asks whether the table still describes the code, not the clock.
        cmp_ok $got, '<', $published{$tier} * 4, "$tier is within 4x of its published cost";
        cmp_ok $got, '>', $published{$tier} / 4, "$tier is not four times cheaper than published";
    }
}
# The POD's advice to use compiled paths in hot loops rests on this order.
my ($native, $compiled, $array, $string) = map { $measured{$_} } qw(native compiled array string);
if (ok !grep({ !defined } $native, $compiled, $array, $string), 'every tier was measured') {
    cmp_ok $native, '<', $compiled, 'a native handle beats a compiled path';
    cmp_ok $compiled, '<', $array, 'a compiled path beats an array path';
    cmp_ok $compiled, '<', $string, 'a compiled path beats a string path';
}

done_testing;
