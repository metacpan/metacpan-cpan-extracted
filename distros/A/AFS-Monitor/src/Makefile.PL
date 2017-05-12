#------------------------------------------------------------------------------
# RCS-Id: "@(#)$Id: Makefile.PL,v 1.21 2007/05/14 18:24:17 alfw Exp $"
#
# Copyright © 2001-2004 Norbert E. Gruener <nog@MPA-Garching.MPG.de>
#             2004-2006 Alf Wachsmann <alfw@slac.stanford.edu>
#                       and Elizabeth Cassell
# This library is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#------------------------------------------------------------------------------

use strict;
use English;

use ExtUtils::MakeMaker;
use Config;

my $archname = $Config{'archname'};
# if ($archname =~ /thread/i) { die "Threaded Perl is not supported ...\n"; }

my $VERSION = "0.3.2";

# give me the path to the AFS system libraries
# used to build the AFS extension module
my $guess_path;
if    (-r "/usr/local/include/afs/afs.h") { $guess_path = '/usr/local'; }
elsif (-r "/usr/afsws/include/afs/afs.h") { $guess_path = '/usr/afsws'; }
elsif (-r "/usr/include/afs/afs.h")       { $guess_path = '/usr'; }
elsif (-r "/Library/OpenAFS/Tools/include/afs/afs.h") { $guess_path = '/Library/OpenAFS/Tools'; }

my $AFSPath;
if (defined $ENV{AFSPATH}) {
  $AFSPath = $ENV{AFSPATH};
} else {
  my $mess = "\nPath to the AFS installation (libraries, binaries, \n"
           . "header files) to be used for this installation? \t$AFSPath] ";
  $AFSPath = prompt($mess, $guess_path);
}

$AFSPath =~ s\/$\\;

# find out the AFS version of the AFS system libraries
open FILE, ">fotav.c";
print FILE <<'EOF';

#include <stdio.h>

int main(void) {
  extern char *AFSVersion;
  printf(">%s<\n",AFSVersion);
}
EOF
close FILE;

system("$Config::Config{cc} fotav.c -L$AFSPath/lib -lubik");
if ($CHILD_ERROR) {
  unlink 'fotav.c';
  die "\nCould not compile test code to retrieve the version of AFS system libraries...\n";
}
my $version = `./a.out` || die "\nCould not run test code to retrieve the version of AFS system libraries...\n";
unlink 'a.out', 'fotav.c';
print "AFS Version = $version \n";

if ($version =~ /3.[4,5]/) {
  die("This release does not support AFS 3.4/3.5 system libraries ...\n");
}

# set the compiler flag "-D$version" according to the AFS version
my ($d_flag, $a_flag) = ('', '');
if    ($version =~ /3.4/)   { $d_flag = 'AFS 3.4'; }
elsif ($version =~ /3.5/)   { $d_flag = 'AFS 3.5'; }
elsif ($version =~ /3.6/)   { $d_flag = 'AFS 3.6'; }
elsif ($version =~ /1.0/)   { $d_flag = 'OpenAFS 1.0'; }
elsif ($version =~ /1.1/)   { $d_flag = 'OpenAFS 1.1'; }
elsif ($version =~ /1.2/)   { $d_flag = 'OpenAFS 1.2'; }
elsif ($version =~ /1.4/)   { $d_flag = 'OpenAFS 1.4'; }
elsif ($version =~ /devel/) { $d_flag = 'OpenAFS devel'; }

if ($version =~ /openafs/)  { $a_flag = '-DOpenAFS'; }

$version =~ s/(<|>)//g;
if(version("openafs 1.2.8", $version) > 0) {
  $a_flag .= " -DUSE_GETCELLNAME";
}
if(version("openafs 1.2.5", $version) > 0) {
  $a_flag .= " -DGETREALCELLBYINDEX";
}
if(version("openafs 1.0.3", $version) > 0) {
  $a_flag .= " -DUSE_VOTEXDEBUG";
}
if($version =~ /devel/) {
  $a_flag .= " -DNOAFS_XSTATSCOLL_CBSTATS";
}
if($version =~ /openafs 1.4.0/) {
  $a_flag .= " -DNOAFS_XSTATSCOLL_CBSTATS";
}
if ($version =~ /openafs 1.4.1-rc/) {
  $a_flag .= " -DNOAFS_XSTATSCOLL_CBSTATS";
}
if ($version =~ /openafs 1.4.2/) {
  $a_flag .= " -DEXT2=extern";
}
if ($version !~ /1.4./) {
  $a_flag .= " -DNOAFS_XSTATSCOLL_CBSTATS";
}
$version = $d_flag;
$d_flag =~ tr/\. /__/;
$d_flag = '-D' . $d_flag;
$d_flag .= ' -DRXDEBUG';

# determine the alpha_sys value
my $alpha_sys = `$AFSPath/bin/fs sysname 2>&1` || 'unknown';
if ($alpha_sys =~ s/Current sysname (list|) is? //) {
  $alpha_sys =~ /(\w+)/;
  $alpha_sys = $1;
}

# print out a summary of determined data
print "Your AFS system library is located at:  $AFSPath \n";
print "              and it is major version:  $version \n";
print "Your AFS system type seems to be:       $alpha_sys \n\n";

# set the Makefile values
my %MakefileArgs = (
    'NAME'         => 'AFS::Monitor',
    'VERSION'      => "$VERSION",
    'DEFINE'	   => "$d_flag $a_flag",
    'INC'          => "-I$AFSPath/include",
    'LIBS'         => [
                       "-L$AFSPath/lib -L$AFSPath/lib/afs "
                       . join (
                                   " ", qw(
                                           -lfsprobe
                                           -lvolser
                                           -lvldb

                                           -lkauth
                                           -lprot
                                           -lrx

                                           -lcmd
                                           -lubik
                                           -lauth

                                           -lrxkad
                                           -lrxstat
                                           -lxstat_fs
                                           -lxstat_cm
                                           -lafsint
                                           -lrx

                                           -lsys
                                           -ldes
                                           -llwp
                                           -lcom_err
                                           -lutil
                                           -lusd
                                           -laudit
                                          )
                              )
                      ],
    'realclean'    => {FILES => 'Makefile.bak lib'},
                   );

if ($Config{osname} =~ /aix/) {
  $MakefileArgs{LIBS}->[0] .= ' -ldl';
} elsif ($Config{osname} =~ /irix/) {
  # just the default LIBS
} elsif ($Config{osname} =~ /solaris/) {
  $MakefileArgs{DEFINE} .= ' -Dint32=afs_int32 -Duint32=afs_uint32' if $alpha_sys eq 'sun4x_56'; # From Peter@PSDT.com
  $MakefileArgs{LIBS}->[0] .= ' -lresolv -lsocket -lnsl -lintl -ldl';
  $MakefileArgs{CC} = 'gcc';
  #$MakefileArgs{LD} = 'gcc';
  $MakefileArgs{CCCDLFLAGS} = '-fPIC';
  $MakefileArgs{LIBS}->[0] .= " -R$AFSPath/lib";
} elsif ($Config{osname} =~ /linux/) {
  $MakefileArgs{LIBS}->[0] .= ' -lresolv';
###  $MakefileArgs{LDFLAGS} = "-Wl,-rpath -Wl,$AFSPath/lib";
} elsif ($Config{osname} =~ /darwin/) {
  $MakefileArgs{LDDLFLAGS} = $Config{lddlflags} . ' -lresolv -multiply_defined suppress -read_only_relocs suppress';
}
# elsif ($Config{osname} =~ /dec_osf/) {
# # hier fehlt noch was !!!!!
# }
else {
  warn("System type '$Config{osname}' not yet tested with this Makefile.PL...\n\n"
       . "Using the default values, which may or may not work\n"
       . "If it is working, please inform the maintainer of this package.\n"
       . "Thank you.\n\n");
}

WriteMakefile(%MakefileArgs);

# change the library name of the AFS system library "util.a"
my $command = "\'s#-lutil#$AFSPath/lib/afs/util.a#\'";
system("perl -p -i.bak -e $command Makefile") unless -f "$AFSPath/lib/afs/libutil.a";

# change the library name of the AFS system library "vlib.a"
$command = "\'s#-lvlib#$AFSPath/lib/afs/vlib.a#\'";
system("perl -p -i.bak -e $command Makefile") unless -f "$AFSPath/lib/afs/libvlib.a";

# change the library name of the AFS system library "libcom_err"
$command = "\'s#-lcom_err#$AFSPath/lib/afs/libcom_err.a#\'";
system("perl -p -i.bak -e $command Makefile");

# change the library name of the AFS system library "libsys"
$command = "\'s#-lsys#$AFSPath/lib/afs/libsys.a#\'";
system("perl -p -i.bak -e $command Makefile");

# change the library name of the AFS system library "libcmd"
$command = "\'s#-lcmd#$AFSPath/lib/afs/libcmd.a#\'";
system("perl -p -i.bak -e $command Makefile");

# make changes to the typemap file if Perl < 5.6.0
$command = "\'s#T_UV#T_IV#\'";
system("perl -p -i.bak -e $command typemap") unless $] >= 5.006;



sub version {
  my ($testver, $compver) = @_;

  $compver = $ENV{VERSION} unless defined $compver;

  # Remove possible package name from both strings.
  $testver =~ s/^([a-zA-Z][^-]*-)*//;
  $compver =~ s/^([a-zA-Z][^-]*-)*//;

  for my $char ('-', '\.') {
    if ("$testver$compver" =~ /$char/) {
      my @testlist = split(/$char/, $testver);
      my @complist = split(/$char/, $compver);

      my $result = 0;
      for my $comp (@complist) {
        my $test = shift(@testlist);

        return $result unless defined $test;

        $result = version($test, $comp);
        return $result unless $result == 0;
      }
      return $result;
    }
  }

   if ("$testver$compver" =~ /^\d+$/) { return $compver <=> $testver }
   else                               { return $compver cmp $testver }
}
