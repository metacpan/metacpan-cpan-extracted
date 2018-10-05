#!/home/ben/software/install/bin/perl
use warnings;
use strict;
use utf8;
use FindBin '$Bin';
use Deploy 'do_system';
my @files = ('lib/Data/Kanji/Kanjidic.pod');
for my $file (@files) {
    if (-f $file) {
	unlink $file or warn "Could not remove $file: $!";
    }
}
do_system ("purge -r");
exit;
