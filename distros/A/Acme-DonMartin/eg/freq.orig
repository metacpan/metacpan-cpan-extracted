#! /usr/local/bin/perl -w

use lib qw{ blib/lib ../blib/lib };
use Acme::DonMartin;

my %f;
for my $f (@ARGV) {
    open my $fh, '<', $f or next;
    while( <$fh> ) {
        $f{$_}++ for split //;
    }
    close $fh;
}
print "$_ $f{$_}\n" for sort keys %f;
