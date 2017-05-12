use lib qw(inc);
use Devel::CheckLib;

# Prompt the user here for any paths and other configuration

check_lib_or_exit(
    # fill in what you prompted the user for here
    lib => [qw()]
);


use lib qw(inc);
use Devel::CheckLib;
use ExtUtils::MakeMaker;
use Config;
use strict;
use warnings;
use 5.006000;

my $gcrypt_libpath = '';
my $gcrypt_incpath = '';

# let's check for GCRYPTLIBPATH and GCRYPTINCPATH options
# removing them from @ARGV
foreach (@ARGV) {
    /^GCRYPTLIBPATH=(.+)/ && ($gcrypt_libpath = $1);
    /^GCRYPTINCPATH=(.+)/ && ($gcrypt_incpath = $1);
}
@ARGV = grep !/^GCRYPT(?:LIB|INC)PATH=/, @ARGV;

# if we still need $gcrypt_libpath let's try the default 
# locations
if (not $gcrypt_libpath and $] >= 5.006001) {
  require ExtUtils::Liblist;
  ($gcrypt_libpath) = ExtUtils::Liblist->ext('-lgcrypt');
}

# let's check with Devel::CheckLib; we need version 1.3.0 or later
# because earlier libgcrypt versions have broken message digest
# calculations for HMAC of some members of the SHA-2 family (including
# SHA-512)
check_lib_or_exit(
    function => 'if (gcry_check_version("1.3.0")) return 0; else return 1;',
    lib => [qw(gcrypt)],
    libpath => $gcrypt_libpath
);

# now build the options list for WriteMakefile()
my @extras = $gcrypt_incpath ? (INC => "-I$gcrypt_incpath") : ();
my $libs = $gcrypt_libpath ? "-L$gcrypt_libpath -lgcrypt" : '-lgcrypt';

WriteMakefile(
    'NAME'         => 'Crypt::GCrypt',
    'ABSTRACT'     => 'Perl interface to the GNU libgcrypt library',
    'AUTHOR'       => 'Alessandro Ranellucci <aar@cpan.org>',
    'VERSION_FROM' => 'lib/Crypt/GCrypt.pm',
    'LIBS'         => $libs,
    'DEFINE'       => '',
    'CCFLAGS'      => "-funsigned-char $Config{ccflags}",
    'dist'         => { COMPRESS => 'gzip', SUFFIX => 'gz' },
    'DISTNAME' => 'Crypt-GCrypt',
    'LICENSE' => 'perl',
    'test' => {
        'TESTS' => 't/*.t'
    },
    'META_MERGE' => {
        resources => {
            repository => 'git://github.com/alexrj/Crypt-GCrypt.git',
        },
    },
    @extras
);
