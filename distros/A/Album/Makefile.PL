# Makefile.PL -- Makefile for album	-*-perl-*-
# Author          : Johan Vromans
# Created On      : Fri Jul  9 15:45:48 2004
# Last Modified By: Johan Vromans
# Last Modified On: Wed Mar 21 10:22:21 2007
# Update Count    : 25
# Status          : Experimental

use strict;
use ExtUtils::MakeMaker;
use Config;

my @scripts = qw (album);
my $usrbin = "/usr/bin";
my $installscript = $Config{installscript};

print STDERR <<EOD unless $installscript eq $usrbin;

WARNING: This Makefile will install user accessible scripts.
The location for these scripts is $installscript.
You may consider to pass INSTALLSCRIPT=$usrbin (or some other
convenient location) to "make install".
EOD

print STDERR <<EOD;

This program requires some helper programs.

  jpegtran    will be used to rotate JPEG files loslessly.
	      If missing, JPEG files will be rotated by ImageMagick,
	      with possible loss of information.
EOD
checkexec("jpegtran");

print STDERR <<EOD;

  mencoder    is needed to manipulate MPEG files.
	      If missing, MPEG movies will be copied, and cannot be rotated.
EOD
checkexec("mencoder");

print STDERR <<EOD;

  mplayer     is used to extract a still image from MPEG files, and
	      to extract audio from VOICE files.
	      If missing, no stills will be produced, and VOICE files
	      will remain silent.
EOD
checkexec("mplayer");

print STDERR ("\n");

WriteMakefile
  (
   NAME         => ucfirst($scripts[0]),
   VERSION_FROM => "script/$scripts[0]",
   ($] >= 5.005) ?
   ( AUTHOR	=> 'Johan Vromans (jvromans@squirrel.nl)',
     ABSTRACT	=> 'Creates HTML based photo albums' ) : (),
   PREREQ_PM	=> { 'Getopt::Long' => 2.1,
		     'Image::Info' => 1.16,
		     'Image::Magick' => 6,
		     'File::Spec' => 0,
		   },
   EXE_FILES    => [ map { "script/$_" } @scripts ],
 );

sub checkexec {
    my ($exec) = @_;
    my $path = findbin($exec);
    if ( $path ) {
	print STDERR ("\t      Good, found $path\n");
	return 1;
    }
    print STDERR ("\t      Hmm. Couldn't find $exec in PATH\n");
    0;
}

sub findbin {
    my ($bin) = @_;
    foreach ( split(":", $ENV{PATH}) ) {
	return "$_/$bin" if -x "$_/$bin";
    }
    undef;
}
