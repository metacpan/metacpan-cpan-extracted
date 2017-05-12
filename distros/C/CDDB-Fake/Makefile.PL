use strict;
use 5.005;
use ExtUtils::MakeMaker;
use Config;

my @scripts = qw(ls2nocddb);
my $usrbin = "/usr/bin";
my $installscript = $Config{installscript};

print STDERR <<EOD unless $installscript eq $usrbin;

WARNING: This Makefile will install user accessible scripts.
The location for these scripts is $installscript.
You may consider to pass INSTALLSCRIPT=$usrbin (or some other
convenient location) to "make install".

EOD

eval {
    require MP3::Audio::Frame;
};
if ( $@ ) {
    print STDERR <<EOD;

NOTICE: The ls2nocddb program that comes with this package can provide
playing time for MP3 files if you install the package
MP3::Info (preferred) or MPEG::Audio::Frame (version 1.08 or later)
from CPAN.

URL: http://search.cpan.org/search?query=MP3::Info&mode=dist
URL: http://search.cpan.org/search?query=MP3::Audio::Frame&mode=dist

EOD
}

WriteMakefile(
    NAME		=> 'CDDB::Fake',
    VERSION_FROM	=> 'lib/CDDB/Fake.pm',
    PREREQ_PM		=> { 'Getopt::Long' => 2.00,
			     'Test::More' => 0.00,
			   },
   EXE_FILES		=> [ map { "script/$_" } @scripts ],
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'lib/CDDB/Fake.pm', # retrieve abstract from module
       AUTHOR        => 'Johan Vromans <jv@cpan.org>') : ()),
);
