#!/usr/bin/env perl
use strict; use warnings;

use File::Basename 'dirname';
use File::Spec;
use English;

my $pt = 'DeparseTree';
#my $pt = 'Deparse';

my $base_dir = dirname(__FILE__);
chdir  $base_dir || die "can't cd to ${base_dir}: $!";
my $libdir = File::Spec->catfile('..', 'lib');
foreach my $dir (glob '*') {
    next if $dir eq 'tmp';
    next unless -d $dir;
    foreach my $test_prog (glob(File::Spec->catfile($dir, '*.t'))) {
	my $outfile = File::Spec->catfile('tmp', $test_prog);
	my $cmd = "$EXECUTABLE_NAME -I${libdir} -MO=\"${pt},sC\" $test_prog >$outfile";
	system($cmd);
	if ($? >> 8 != 0) {
	    print STDERR "Failed on $test_prog\n";
	    unlink $outfile;
	}
    }
    foreach my $test_prog (glob(File::Spec->catfile('tmp', '*/*.t'))) {
	my $cmd = "$EXECUTABLE_NAME -c $test_prog";
	system($cmd);
	if ($? >> 8 != 0) {
	    my $new_bad;
	    ($new_bad=$test_prog) =~ s/t$/t-bad/;
	    system("mv $test_prog $new_bad");
	}
    }
    # There is probably a fancier test-runner way to do this.
    system("prove " . File::Spec->catfile('tmp', $dir));

}
