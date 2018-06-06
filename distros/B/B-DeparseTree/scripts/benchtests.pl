#!/usr/bin/env perl
use lib '../lib';
use strict; use warnings;

use File::Basename 'dirname';
use File::Spec;
use English;

#my $pt = 'DeparseTree';
my $pt = 'Deparse';

my $base_dir = "%s/$s", $ENV{'HOME'}, '/perl5/perlbrew/build/perl-5.18.2/';
chdir  $base_dir || die "can't cd to ${base_dir}: $!";
foreach my $dir (glob 't/*') {
    next if $dir eq 'tmp';
    next unless -d $dir;
    system("mkdir -p " . "/tmp/$dir");
    foreach my $test_prog (glob(File::Spec->catfile($dir, '*.t'))) {
	my $outfile = File::Spec->catfile('/tmp', $test_prog);
	my $cmd = "$EXECUTABLE_NAME -MO=\"${pt},sC\" $test_prog >$outfile";
	system($cmd);
	if ($? >> 8 != 0) {
	    print STDERR "Failed on $test_prog\n";
	    unlink $outfile;
	}
    }
    # There is probably a fancier test-runner way to do this.
    system("prove " . File::Spec->catfile('tmp', $dir));
}
