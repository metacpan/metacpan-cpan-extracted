#------------------------------------------------------------------------------
# RCS-Id: "@(#)$RCS-Id: src/Makefile.PL 09f1168 Mon Jan 7 08:10:19 2013 +0100 Norbert E Gruener$"
#
# © 2001-2012 Norbert E. Gruener <nog@MPA-Garching.MPG.de>
#
# This library is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#------------------------------------------------------------------------------
use strict;
use English;

use lib qw(./inc);

use ExtUtils::MakeMaker;
use Config;
use Cwd;
use version 0.77; # get latest bug-fixes and API

my $dir = getcwd;
if ($dir !~ /src$/) { die "Ooops, the Makefile.PL is not sitting in the proper directory\n";}

my $libs;
my $p_flag = '';

if ($Config{usethreads}) {
    # use the threaded version of the AFS libraries for threaded Perl...
    $libs = join (" ", qw(
                          -lbos
                          -lvolser
                          -lvldb
                          -lcmd
                          -lusd
                          -laudit
                          -lc -lafsauthent -lc
                          -lc -lafsrpc -lc
                          -lutil
                         )
                 );
    $p_flag = '-DAFS_PTHREAD_ENV';
}
else {
    # use the unthreaded version of the AFS libraries for unthreaded Perl...
    $libs = join (" ", qw(
                          -lkauth
                          -lprot
                          -lbos
                          -lrx
                          -lvolser
                          -lvldb

                          -lcmd
                          -lubik
                          -lauth

                          -lrxkad
                          -lrxstat
                          -lrx

                          -lsys
                          -ldes
                          -llwp
                          -lcom_err
                          -lutil
                          -lusd
                          -laudit
                         )
                 );
}

# give me the path to the AFS system libraries
# used to build the AFS extension module
my $guess_path;
if    (-r "/usr/local/include/afs/afs.h") { $guess_path = '/usr/local'; }
elsif (-r "/usr/afsws/include/afs/afs.h") { $guess_path = '/usr/afsws'; }
elsif (-r "/usr/include/afs/afs.h")       { $guess_path = '/usr'; }
else                                      { $guess_path = 'unknown'; }

my $AFSPath = $ENV{AFSPATH} || $guess_path;
my $msg = "\nPath to the AFS installation (libraries, binaries, \n"
        . "header files) to be used for this installation? \t ";
$AFSPath = prompt($msg, $AFSPath);
$AFSPath =~ s\/$\\;
if ($AFSPath eq 'unknown') {
    warn "Most probabley you have not installed the AFS system libraries \n";
    if ($ENV{AUTOMATED_TESTING}) { exit 0; }
    die "Script terminated ...\n";
}

# determine the alpha_sys value
my $alpha_sys = 'unknown';
if ($ENV{AFS_SYSNAME}) {
    $alpha_sys = $ENV{AFS_SYSNAME};
}
elsif (-e "$AFSPath/bin/fs") {
    my $fs_sysname = `$AFSPath/bin/fs sysname 2>&1`;
    if ($fs_sysname =~ s/Current sysname is:? //) {
        $fs_sysname =~ s/list? //;
        $fs_sysname =~ /(\w+)/;
        $alpha_sys  = $1;
    }
    else {
        warn "Unknown value for your AFS sysname value: $fs_sysname \n";
        if ($ENV{AUTOMATED_TESTING}) { exit 0; }
        die "Script terminated ...\n";
    }
}
else {
    warn "Could not find the AFS binary 'fs' at $AFSPath/bin \n";
    if ($ENV{AUTOMATED_TESTING}) { exit 0; }
    die "Script terminated ...\n";
}

if ($alpha_sys eq 'unknown') {
    warn "Could not determine the AFS sysname value for your system \n" .
         "But you should never reach this place \n";
    if ($ENV{AUTOMATED_TESTING}) { exit 0; }
    die "Script terminated ...\n";
}

# find out the AFS version of the AFS system libraries
open FILE, ">fotav.c";
print FILE <<'EOF';
#include <stdio.h>

int main(void)
{
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

my ($v_string, $v_numb) = ('', '');
if ($version =~ />(\S+?)\s+(\S+)</) {
    $v_string = $1;
    $v_numb   = version->new($2);
}
elsif ($version =~ />(\S+?)</) {
    $v_string = 'Transarc/IBM AFS';
    $v_numb   = version->new($1);
}

if ($v_numb =~ /3.[4,5]/) {
    warn "This release does not support AFS 3.4/3.5 system libraries ...\n";
    if ($ENV{AUTOMATED_TESTING}) { exit 0; }
    die "Script terminated ...\n";
}
#elsif ($alpha_sys =~ /amd64_linux2/) {
#    warn "\nAFS modules on AMD Opteron platforms are currently not supported ...\n";
#    if ($ENV{AUTOMATED_TESTING}) { exit 0; }
#    die "Script terminated ...\n";
#}
elsif ($Config{usethreads} and $v_string !~ /openafs/) {
    warn "\nAFS modules (Threaded Perl) in conjunction with Transarc/IBM AFS is not supported ...\n";
    if ($ENV{AUTOMATED_TESTING}) { exit 0; }
    die "Script terminated ...\n";
}
elsif ($Config{usethreads} and $alpha_sys =~ /amd64_linux2/) {
    if (! -e "$AFSPath/lib/libafsauthent_pic.a" or ! -e "$AFSPath/lib/libafsrpc_pic.a") {
        warn "\nAFS system libraries libafsrpc and/or libafsauthent (PIC) not found ...\n";
        if ($ENV{AUTOMATED_TESTING}) { exit 0; }
        die "Script terminated ...\n";
    }
}
elsif ($Config{usethreads} and $alpha_sys =~ /rs_aix4/) {
    warn "\nAFS modules (Threaded Perl) on AIX platforms are currently not supported ...\n";
    if ($ENV{AUTOMATED_TESTING}) { exit 0; }
    die "Script terminated ...\n";
}

my $m_version = '';
if    ($v_numb =~ /3.4/)   { $m_version = 'AFS 3.4'; }
elsif ($v_numb =~ /3.5/)   { $m_version = 'AFS 3.5'; }
elsif ($v_numb =~ /3.6/)   { $m_version = 'AFS 3.6'; }
elsif ($v_numb =~ /1.0/)   { $m_version = 'OpenAFS 1.0'; }
elsif ($v_numb =~ /1.1/)   { $m_version = 'OpenAFS 1.1'; }
elsif ($v_numb =~ /1.2/)   { $m_version = 'OpenAFS 1.2'; }
elsif ($v_numb =~ /1.3/)   { $m_version = 'OpenAFS 1.3'; }
elsif ($v_numb =~ /1.4/)   { $m_version = 'OpenAFS 1.4'; }
elsif ($v_numb =~ /1.5/)   { $m_version = 'OpenAFS 1.5'; }
elsif ($v_numb =~ /devel/) { $m_version = 'OpenAFS devel'; }

if ($m_version eq '') {
    warn "Could not determine OpenAFS version: $version \n";
    if ($ENV{AUTOMATED_TESTING}) { exit 0; }
    die "Script terminated ...\n";
}

# set the different compiler flags according to the AFS version
my ($d_flag, $a_flag, $e_flag, $i_flag) = ('', '', '', '');
if ($v_string =~ /openafs/)  { $a_flag = '-DOpenAFS'; }

$d_flag = $m_version;
$d_flag =~ tr/\. /__/;
$d_flag = '-D' . $d_flag;

if ($v_numb gt v1.4.4 and $v_string =~ /openafs/) {
    $e_flag = '-DAFS_OLD_COM_ERR';
    $i_flag = '-I ./ ';
    $d_flag .= ' -DOpenAFS_1_4_05';
}

if ($v_numb gt v1.4.6 and $v_string =~ /openafs/) {
    $d_flag .= ' -DOpenAFS_1_4_07';
}

if ($v_numb gt v1.4.7 and $v_string =~ /openafs/) {
    $d_flag .= ' -DOpenAFS_1_4_64';
}

if ($v_numb gt v1.4.11 and $v_string =~ /openafs/) {
    $d_flag .= ' -DOpenAFS_1_4_12';
}

# print out a summary of determined data
print "AFS Version = $v_string v$v_numb \n";
print "Your AFS system libraries are located at:  $AFSPath \n";
print "                  their major version is:  $m_version \n";
print "                  and their type is:       \"pthreaded\"\n" if ($Config{usethreads});
print "Your AFS system type seems to be:          $alpha_sys \n\n";
print "The Compile Flags are set to:              $a_flag \n";
print "                                           $d_flag \n";
print "                                           $e_flag \n";
print "                                           $p_flag\n\n";

# set the Makefile values
my $ccflags = $Config::Config{ccflags} || '';
my %MakefileArgs = (
    'NAME'         => 'AFS',
    'VERSION_FROM' => 'AFS.pm',
    'CCFLAGS'      => "-Wall $ccflags",
    'DEFINE'	   => "$d_flag $p_flag $a_flag $e_flag",
    'INC'          => $i_flag . "-I$AFSPath/include",
    'LIBS'         => [
                       "-L$AFSPath/lib -L$AFSPath/lib/afs "
                       . $libs
                      ],
    'realclean'    => {FILES => 'Makefile.bak lib'},
                   );

if ($Config{osname} =~ /aix/) {
    $MakefileArgs{LIBS}->[0] .= ' -ldl';
}
elsif ($Config{osname} =~ /irix/) {
   # just the default LIBS
}
elsif ($Config{osname} =~ /solaris/) {
    $MakefileArgs{DEFINE} .= ' -Dint32=afs_int32 -Duint32=afs_uint32' if $alpha_sys eq 'sun4x_56'; # From Peter@PSDT.com
    $MakefileArgs{LIBS}->[0] .= ' -lresolv -lsocket -lnsl -lintl -ldl';
    $MakefileArgs{CC} = 'gcc';
    #$MakefileArgs{LD} = 'gcc';
    $MakefileArgs{CCCDLFLAGS} = '-fPIC';
}
elsif ($Config{osname} =~ /linux/) {
    $MakefileArgs{LIBS}->[0] .= ' -lresolv';
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
# my $command = "\'s#-lvlib#$AFSPath/lib/afs/vlib.a#\'";
# system("perl -p -i.bak -e $command Makefile") unless -f "$AFSPath/lib/afs/libvlib.a";

# change the library name of the AFS system library "libcom_err"
$command = "\'s#-lcom_err#$AFSPath/lib/afs/libcom_err.a#\'";
system("perl -p -i.bak -e $command Makefile");

# change the library name of the AFS system library "-lafsrpc"
if ($alpha_sys =~ /linux/ && $alpha_sys !~ /i386_linux2/) {
    $command = "\'s#-lc -lafsrpc -lc#$AFSPath/lib/libafsrpc_pic.a#g\'";
}
else {
    $command = "\'s#-lc -lafsrpc -lc#$AFSPath/lib/libafsrpc.a#g\'";
}
system("perl -p -i.bak -e $command Makefile");

# change the library name of the AFS system library "-lafsauthent"
if ($alpha_sys =~ /linux/ && $alpha_sys !~ /i386_linux2/) {
    $command = "\'s#-lc -lafsauthent -lc#$AFSPath/lib/libafsauthent_pic.a#g\'";
}
else {
    $command = "\'s#-lc -lafsauthent -lc#$AFSPath/lib/libafsauthent.a#g\'";
}
system("perl -p -i.bak -e $command Makefile");

# make changes to the typemap file if Perl < 5.6.0
$command = "\'s#T_UV#T_IV#\'";
system("perl -p -i.bak -e $command typemap") unless $] >= 5.006;
