#!/usr/bin/perl -w
use strict;

use Compress::Zlib;
use IO::File;

my $file = 'log-parser.txt';
my %counts;

for my $archive (glob('logs/builder-run.log*')) {
    if($archive =~ /\.gz$/) {
        my $line;
        my $fh = gzopen($archive, 'r') ;
        while($fh->gzreadline($line)) {
            next    unless($line =~ m!(\d{4}/\d{2}/\d{2}) [\d:]+ .. processing.*?=> (\d+)\s+(\d+)!);
            my ($date,$count,$sum) = ($1,$2,$3);
            $date =~ s!\D+!!g;
            $counts{$date}{weight} += $sum;
            $counts{$date}{unique} += $count;
        }
        $fh->gzclose();

    } else {
        my $fh = IO::File->new($archive, 'r') ;
        while(<$fh>) {
            next    unless(m!(\d{4}/\d{2}/\d{2}) [\d:]+ .. processing.*?=> (\d+)\s+(\d+)!);
            my ($date,$count,$sum) = ($1,$2,$3);
            $date =~ s!\D+!!g;
            $counts{$date}{weight} += $sum;
            $counts{$date}{unique} += $count;
        }
        $fh->close();
    }
}

my $fh = IO::File->new($file,'w+') or die "Cannot open file [$file]: $!\n";
for my $date (sort keys %counts) {
    $counts{$date}{weight} ||= 0;
    $counts{$date}{unique} ||= 0;
    print $fh "$date,$counts{$date}{weight},$counts{$date}{unique}\n";
}
$fh->close;

