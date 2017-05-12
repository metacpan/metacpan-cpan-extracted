#!/usr/local/bin/perl -sw
#
# You may distribute under the terms of either the GNU General Public
# License or the Artistic License, as specified in the Perl README file.
#
BEGIN { require 5.004 }  # 5.004 is required for Win32

use Config;
use ExtUtils::MakeMaker 5.16, qw(&WriteMakefile $Verbose);
use Getopt::Long;
use DBI 1.20;  # must be installed first
use DBI::DBD;
use strict;

my %opts =
(
  NAME => 'DBD::ADO',
  VERSION_FROM => 'lib/DBD/ADO.pm',
  clean => {},
  dist => {
    DIST_DEFAULT => 'clean distcheck ci tardist',
    PREOP    => '$(MAKE) -f Makefile.old distdir',
    COMPRESS => 'gzip -v9',
    SUFFIX => 'gz'
  },
);
if ( $ExtUtils::MakeMaker::VERSION >= 5.43 ) {
  $opts{AUTHOR} = 'Tim Bunce, Phlip, Thomas Lowery and Steffen Goeldner ( http://dbi.perl.org )';
  $opts{ABSTRACT} = 'ADO driver for the DBI module.';
  $opts{PREREQ_PM} = { DBI => 0, 'Win32::OLE' => 0.16 };
  $opts{CAPI} = 'TRUE' if $Config{archname} =~ /-object\b/i;
}

$::opt_g = 0;

GetOptions('g!') or die 'Invalid arguments';

$opts{OPTIMIZE} = '-g -O0' if $::opt_g;

die "Currently DBD::ADO only works on Win32 machines!\n"
  if $^O !~ /win32|cygwin/i && $ENV{USER} !~ /tlowery/i;

print <<'TEXT';

Configuring DBD::ADO ...

>>> Remember to actually *READ* the README file!
>>> And re-read it if you have any problems.

TEXT

my $dbi_dir      = dbd_dbi_dir();
my $dbi_arch_dir = dbd_dbi_arch_dir();

WriteMakefile( %opts );

local $^W = 0;

print <<"TEXT";

The DBD::ADO tests will use these values for the database connection:
    DBI_DSN=$ENV{DBI_DSN}		e.g. dbi:ADO:demo
    DBI_USER=$ENV{DBI_USER}
    DBI_PASS=$ENV{DBI_PASS}

TEXT

warn "*** Warning: Not all required environment variables are set.  Using default.\n"
  unless $ENV{DBI_DSN} && $ENV{DBI_USER} && $ENV{DBI_PASS};

warn "*** Warning: DBI_DSN ($ENV{DBI_DSN}) doesn't start with 'dbi:ADO:'\n"
  if $ENV{DBI_DSN} && $ENV{DBI_DSN} !~ m/^dbi:ADO:/;

print "\n";

sub MY::postamble {
  return dbd_postamble( @_ );
}
