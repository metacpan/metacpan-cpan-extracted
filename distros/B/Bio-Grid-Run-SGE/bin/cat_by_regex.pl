#!/usr/bin/env perl

use warnings;
use strict;

use Carp;

my $dir = '.';
opendir( my $dh, $dir ) || die "can't opendir $dir $!";

my $file_regex = shift;

for ( readdir($dh) ) {
    next unless (/$file_regex/);
    open my $fh, '<', $_ or confess "Can't open filehandle: $!";
    do { local $/; print <$fh> };
    $fh->close;
}
closedir $dh;

