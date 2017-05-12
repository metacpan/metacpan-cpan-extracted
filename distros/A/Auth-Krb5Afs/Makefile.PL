#! /usr/bin/perl

use ExtUtils::MakeMaker;

WriteMakefile(
	      'NAME'		=> 'Auth::Krb5Afs',
	      'VERSION_FROM'	=> 'Krb5Afs.pm', # finds $VERSION
	      'PREREQ_PM'		=> {}, # e.g., Module::Name => 1.1
	      ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
	       (ABSTRACT_FROM => 'Krb5Afs.pm', # retrieve abstract from module
		AUTHOR     => 'Noel Burton-Krahn <noel@bkbox.com>') : ()),
	      EXE_FILES => [ 'authkrb5afs' ],
);

@l = stat("Makefile") or die("stat: $!");
open(F, "+<Makefile") or die("open: $!");
read(F, $_, $l[7]);
close(F);

s/Auth::authkrb5afs/authkrb5afs/g;
s/authkrb5afs.pod \\\s+\$\(INST_LIBDIR\)\/authkrb5afs.pod\s+//mg;

open(F, ">Makefile") or die("open: $!");
print(F $_);
close(F);

