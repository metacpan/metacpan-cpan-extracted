use strict;

BEGIN {
   $^W = 1;
   print "Checking the system: Perl $] found ... ";
   require 5.6.1 or do { print "you should upgrade your installation.\nMakefile.PL aborted\n"; exit 0 };
   print "ok\n";
}

use vars qw ($VERSION);
$VERSION = 0.1.6;

use ExtUtils::MakeMaker;

goto &WriteMakefile if -f 'MANIFEST';

my @manifest = qw( Makefile.PL
                   README
                   lib/Cache/RamDisk.pm
                   lib/Cache/RamDisk/Functions.pm
                   t/test.t
                  );
print "writing MANIFEST... ";
open MF, ">MANIFEST" or die $!;
print MF join("\n", sort(@manifest))."\n" or die $!;
close MF or die $!;
print "ok\n";

WriteMakefile (
                NAME           => 'Cache',
                DISTNAME       => 'Cache-RamDisk',
                VERSION        => '0.1.6',
               # VERSION_FROM   => 'Makefile.PL',
                ABSTRACT       => 'Cache-RamDisk: Sharing of Perl Objects Between Processes',
                dist           => { 'COMPRESS' => 'gzip -9f ',
                                    'SUFFIX'   => '.gz'
                                  },
                PREREQ_PM      => { 'IPC::Shareable'  => '0.60',
                                    'IPC::SysV'       => '1.03',
                                    'Filesys::Df'     => '0.68',
                                    'Filesys::Statvfs'=> '0.68',
                                    'POSIX'           => '1.03'
                                  },
                AUTHOR         => 'Martin Haase-Thomas <njarl@punkass.com>',
                INSTALLDIRS    => 'site'
               );

# eof(Makefile.PL)
