#!/usr/bin/env perl
use strict; use warnings;

use File::Basename;
use File::Path 'rmtree';
use File::Spec;
use English;

my $pt = 'DeparseTree';
#my $pt = 'Deparse';

my $base_dir = dirname(__FILE__);
chdir  $base_dir || die "can't cd to ${base_dir}: $!";
chomp($base_dir = `pwd`);
rmtree("tmp");
mkdir("tmp");
system('cp test.pl tmp');

use Cwd 'abs_path';
my $libdir = abs_path(File::Spec->catfile('..', '..', 'lib'));
my @subdirs = ();
my $short_version = substr($], 0, 5);
foreach my $dir ((glob "$short_version/*"), ) {
    next if $dir eq 'tmp';
    next unless -d $dir;

    my $short_dir = File::Basename::basename($dir);
    mkdir "tmp/$short_dir";
    # Test programs need to be run from the directory they reside in
    chdir  "$base_dir/$dir" || die "can't cd to ${base_dir}/${dir}: $!";
    push @subdirs, $dir;

    foreach my $test_prog (glob('*.t')) {
	my $outfile = File::Spec->catfile("..", "..", "tmp", $short_dir,
					  $test_prog);

	# See if the command checks on its own out before we muck with it...
	my $cmd = "$EXECUTABLE_NAME $test_prog >$outfile";
	system($cmd);
	if ($? >> 8 != 0) {
	    print STDERR "Skipping $test_prog since it fails on its own\n";
	    unlink $outfile;
	    next;
	}

	$cmd = "$EXECUTABLE_NAME -I${libdir} -MO=\"${pt},sC\" $test_prog >$outfile";
	system($cmd);
	if ($? >> 8 != 0) {
	    print STDERR "Failed decompiling $test_prog\n";
	    unlink $outfile;
	}
    }

    # Test programs need to be run from the directory they reside in
    chdir  "$base_dir/tmp" || die "can't cd to ${base_dir}/${dir}: $!";
    foreach my $dir (@subdirs) {
	chdir  "$base_dir/tmp/$short_dir" ||
	    die "can't cd to ${base_dir}/tmp/${short_dir}: $!";
	foreach my $test_prog (glob('*.t')) {
	    my $cmd = "$EXECUTABLE_NAME -c $test_prog";
	    system($cmd);
	    if ($? >> 8 != 0) {
		my $new_bad;
		($new_bad=$test_prog) =~ s/t$/t-bad/;
		system("mv $test_prog $new_bad");
	    }
	}
	# To run some of the tests we need to in the directory of the test.
	system("prove  .");
    }
    chdir  "$base_dir" || die "can't cd to ${base_dir}: $!";

}
