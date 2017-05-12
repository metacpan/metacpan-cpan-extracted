#!/usr/bin/perl
use strict;
use warnings;

# Git commits by week by author
use ANSI::Heatmap;
use List::Util qw(max min);

my $LIMIT = 20;
my $PER_ROW = 4;

my $i;
my %day2idx = map { $_ => $i++ } qw(Mon Tue Wed Thu Fri Sat Sun);
my %map;
my %commit_count;

my $repo = shift or die "usage: $0 /path/to/git-repo";
chdir $repo;
open my $log, '-|', 'git', 'log', '--no-merges', '--remove-empty', "--format=%cN\t%cD";
while (<$log>) {
    /\A([^\t]+)\t(\w+), \d+ \w+ \d+ (\d+):\d+:\d+ [-+]\d+\Z/ or die "invalid line '$_'";
    my ($name, $day, $hour) = ($1, $2, $3);
    $day = $day2idx{$day}; defined $day or die "Invalid day";

    $commit_count{$name}++;
    if (!$map{$name}) {
        $map{$name} = ANSI::Heatmap->new(
            min_x => 0,
            max_x => 23,
            min_y => 0,
            max_y => 6,
            half => 1,
        );
    }
    $map{$name}->inc($hour, $day);
}

my @order = sort { $commit_count{$b} <=> $commit_count{$a} } keys %commit_count;
@order = splice @order, 0, $LIMIT;

my %header = map { $_ => "$_ (" . $commit_count{$_} . ")" } @order;
my @hdrlens = map { length $_ } values %header;
my $hdrwidth = max(@hdrlens);
my $colwidth = max($hdrwidth, 24) + 2;
my $pad = ' ' x ($colwidth - 24);

binmode STDOUT, ':utf8';
while ( my @row = splice @order, 0, $PER_ROW ) {
    my $fmt = (('%-' . $colwidth . 's') x @row) . "\n";
    printf $fmt, map { $header{$_} } @row;

    my @maps = @map{@row};
    my @split = map { [ split /\n/, $_ ] } @maps;
    for my $line (0..$#{$split[0]}) {
        print join '', map { $split[$_][$line] . $pad } 0..$#split;
        print "\n";
    }
}
