#!/usr/bin/perl -w
die "Run this script in your session dir!" if ! -f "00000000000000000000000000000000";
use strict;
system('find . -type f -a -atime 1 -a ! -name 00000000000000000000000000000000 -maxdepth 1 -print0 | xargs -0 rm &> /dev/null');
my @locks = split /\0/, `find ./locks -type f -a -atime 1 -maxdepth 1 -print0`;
foreach my $lock (@locks) {
        my $session = $lock;
        $session =~ s{locks/Apache-Session-}{};
        $session =~ s{\.lock$}{};
        unlink $session if ! -f  $session;
}
