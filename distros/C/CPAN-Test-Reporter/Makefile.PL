#!/usr/bin/perl

use ExtUtils::MakeMaker;

WriteMakefile(
		'MAKEFILE'=> 'Makefile',
		'VERSION_FROM' => 'lib/CPAN/Test/Reporter.pm',
		'NAME'    => 'CPAN::Test::Reporter', 
		'PREREQ_PM'  => { # e.g., Module::Name => 1.1
		},
	      );

open(MANIFEST, "MANIFEST");
foreach my $file (grep /\.pm$/, <MANIFEST>) {
    chomp $file;
    my($module) = $file =~ m|^lib/(.*)\.pm$|;
    $module =~ s|/|-|g;
    system("pod2test $file t/embedded-$module.t");
}
