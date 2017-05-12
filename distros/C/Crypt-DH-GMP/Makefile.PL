use inc::Module::Install;

my @DEFINES;
if (grep { $_ eq '--very-verbose' } @ARGV) {
    push @DEFINES, '-DVERY_VERBOSE';
}

my @CCFLAGS = split(' ', $ENV{CCFLAGS} || '');
my @LDFLAGS = split(' ', $ENV{LDFLAGS} || '');
my @INCLUDES;
my @LIBPATHS;

if ($^O eq 'darwin') {
    if (! exists $ENV{USE_MACPORTS}) {
        print 
            "======\n\n",
            "Automatically enabling pushing MacPorts into our path(s)...\n",
            "Set USE_MACPORTS=0 if you don't want me to do this\n\n",
            "======\n"
        ;
        $ENV{USE_MACPORTS} = 1;
    }
    if ($ENV{USE_MACPORTS}) {
        if ( ! -d '/opt/local/include' ) {
            print " * Attempted to push /opt/local/include in our path, but it wasn't there.\n";
        } else {
            push @INCLUDES , '/opt/local/include';
        }

        if ( ! -d '/opt/local/lib') {
            print " * Attempted to push /opt/local/lib in our path, but it wasn't there.\n";
        } else {
            push @LIBPATHS, '/opt/local/lib';
        }
    }
} 

# Stolen from Math::BigInt::GMP
if (($Config::Config{'osname'} eq 'darwin') && ! (join (' ', @ARGV) =~ /LDDLFLAGS/))
{
    ### reads pre-existing LDDLFLAGS for a darwin system as defined in
    ###  /System/Library/Perl/x.x.x/darwin-thread-multi-2level/Config.pm
    ###  where x.x.x is the perl version, which is 5.8.1 for MacOS X 10.3,
    ###  and appends ' -read_only_relocs suppress' 
    ### default behavior if LDDLFLAGS is defined
    push @ARGV, sprintf "LDDLFLAGS=%s -read_only_relocs suppress", $Config::Config{'lddlflags'};
}

name 'Crypt-DH-GMP';
all_from 'lib/Crypt/DH/GMP.pm';
use_ppport;
cc_libs @LDFLAGS;
cc_include_paths @INCLUDES;
cc_append_to_ccflags @CCFLAGS if @CCFLAGS;
cc_define @DEFINES;
cc_assert_lib libpath => \@LIBPATHS, incpath => \@INCLUDES, lib => 'gmp', header => 'gmp.h';
cc_libs 'gmp', map { "-L$_" } @LIBPATHS;
cc_src_paths 'xs';
author_tests 'xt';

repository 'https://github.com/lestrrat/Crypt-DH-GMP';

test_requires 'Test::More';
test_requires 'Test::Requires';
WriteAll;
