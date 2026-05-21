#!/usr/bin/perl
# Benchmark plhasa listing against lhasa
# Usage: perl -Iblib/lib -Iblib/arch bench/benchmark_list.pl [archive.lha ...]

use strict;
use warnings;
use Benchmark qw( cmpthese timethese );
use File::Basename;
use File::Spec;

my @archives = @ARGV ? @ARGV : glob('t/archive/*.lzh t/archive/*.lha');

my $lhasa  = do { chomp(my $p = `which lhasa 2>/dev/null`);  $p } || 'lhasa';
my $plhasa = File::Spec->rel2abs('blib/script/plhasa');

for my $archive (sort @archives) {
    next unless -f $archive;
    my $name = basename($archive);

    # count entries via lhasa
    my $n = 0;
    { open my $fh, '-|', $lhasa, 'l', $archive or die $!; $n++ while <$fh>; close $fh; }

    printf "\n=== %s (~%d lines) ===\n", $name, $n;

    my $results = timethese(-3, {
        'plhasa' => sub {
            open my $fh, '-|', $^X, '-Iblib/lib', '-Iblib/arch', $plhasa, 'l', $archive or die $!;
            1 while <$fh>;
            close $fh;
        },
        'lhasa' => sub {
            open my $fh, '-|', $lhasa, 'l', $archive or die $!;
            1 while <$fh>;
            close $fh;
        },
    });
    cmpthese($results);
}
