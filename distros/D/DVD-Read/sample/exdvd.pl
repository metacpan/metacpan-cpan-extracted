#!/bin/env perl

use strict;
use warnings;
use DVD::Read;
use Getopt::Long;

GetOptions(
    'c|chapter=i' => \my @chapters,
);

my ($location, $titleno, $file) = @ARGV;

my $dvd = DVD::Read->new($location) or do {
    warn "Cant read $location\n";
    next;
};

print ($dvd->volid || '');
printf(" %d titles\n",
    $dvd->titles_count);

my $title = $dvd->get_title($titleno);

$| = 1;
if (@chapters) {
    $title->extract_chapter([ @chapters ], $file,
    sub {
        my ($chc, $cht, $bc, $bt) = @_;
        $bt ||= 1; $bc ||= 1;
        printf("\rch: %2d/%2d [%s%s] ",
            $chc + ($chc == $cht ? 0 : 1),
            $cht, '#' x ($bc * 60 / $bt),
            ' ' x (60 - ($bc * 60 / $bt))
        );
    }
    );
} else {
    $title->extract($file,
    sub {
        my ($cc, $ct, $bc, $bt) = @_;
        $bt ||= 1; $bc ||= 1;
        printf("\r[%s%s] [%s%s]  ",
            '#' x ($bc * 20 / $bt), ' ' x (20 - ($bc * 20 / $bt)),
            '#' x ($cc * 60 / $ct), ' ' x (60 - ($cc * 60 / $ct)),
        );
    }
    );
}
print "\n";
