use lib qw(inc);
use Devel::CheckLib;
use ExtUtils::MakeMaker;
use Config;
use strict;
use warnings;
use 5.006000;

my $nettle_libpath = '';
my $nettle_incpath = '';

# let's check for NETTLELIBPATH and NETTLINCPATH options
# removing them from @ARGV
foreach (@ARGV) {
    /^NETTLELIBPATH=(.+)/ && ($nettle_libpath = $1);
    /^NETTLEINCPATH=(.+)/ && ($nettle_incpath = $1);
}
@ARGV = grep !/^NETTLE(?:LIB|INC)PATH=/, @ARGV;

# if we still need $nettle_libpath let's try the default
# locations
if (not $nettle_libpath and $] >= 5.006001) {
  require ExtUtils::Liblist;
  ($nettle_libpath) = ExtUtils::Liblist->ext('-lnettle');
}

# let's check with Devel::CheckLib; we want at least the version of
# Nettle that can handle SHA-512  (I believe this is Nettle 2.1 or later)
check_lib_or_exit(
                  function => 'if (&nettle_sha512) return 0; else return 1;',
                  lib => 'nettle',
                  header => 'nettle/nettle-meta.h',
                  libpath => $nettle_libpath,
                  incpath => $nettle_incpath,
);

# now build the options list for WriteMakefile()
my @extras = $nettle_incpath ? (INC => "-I$nettle_incpath") : ();
my $libs = $nettle_libpath ? "-L$nettle_libpath -lnettle -lhogweed" : '-lnettle -lhogweed';

WriteMakefile(
    'NAME'         => 'Crypt::Nettle',
    'ABSTRACT'     => 'Perl interface to the Nettle cryptographic library',
    'AUTHOR'       => 'Daniel Kahn Gillmor <dkg@fifthhorseman.net>',
    'VERSION_FROM' => 'lib/Crypt/Nettle.pm',
    'LIBS'         => $libs,
    'DEFINE'       => '',
    'CCFLAGS'      => '-funsigned-char',
    'dist'         => { COMPRESS => 'gzip', SUFFIX => 'gz' },
    @extras
);
