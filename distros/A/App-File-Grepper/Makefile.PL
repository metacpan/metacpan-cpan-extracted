#! perl

use strict;
use warnings;
use ExtUtils::MakeMaker;
use Config;

my @scripts = qw( afg );
my $usrbin = "/usr/bin";
my $installscript = $Config{installscript};

print STDERR <<EOD unless $installscript eq $usrbin;

WARNING: This Makefile will install user accessible scripts.
The location for these scripts is $installscript.
You may consider to pass INSTALLSCRIPT=$usrbin (or some other
convenient location) to "make install".

EOD

WriteMakefile(
    NAME                => 'App::File::Grepper',
    AUTHOR              => 'Johan Vromans <jv@cpan.org>',
    VERSION_FROM        => 'lib/App/File/Grepper.pm',
    ABSTRACT_FROM       => 'lib/App/File/Grepper.pm',
    PL_FILES            => {},
    EXE_FILES		=> [ map { "script/$_" } @scripts ],
    PREREQ_PM => {
		  'Getopt::Long'     => '2.13',
		  'File::Find'	     => 0,
		  'Term::ANSIColor'  => 0,
		  'Test::More'	     => 0,
		  'Encode'	     => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'App-File-Grepper-*' },
);
