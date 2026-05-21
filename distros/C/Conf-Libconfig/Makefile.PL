use strict;
use warnings;
use ExtUtils::MakeMaker;

my @inc_paths;
my @lib_paths;
if (eval { require ExtUtils::PkgConfig; 1 }) {
    my $cflags = eval { ExtUtils::PkgConfig->cflags_only_I('libconfig') };
    my $libs   = eval { ExtUtils::PkgConfig->libs_only_L('libconfig') };
    if ($cflags) {
        @inc_paths = map { s/-I//; $_ } split(' ', $cflags);
    }
    if ($libs) {
        @lib_paths = map { s/-L//; $_ } split(' ', $libs);
    }
}

if (eval { require Devel::CheckLib; 1 }) {
    Devel::CheckLib->import;
    check_lib_or_exit(
        lib     => 'config',
        header  => 'libconfig.h',
    );
}

WriteMakefile(
    NAME          => 'Conf::Libconfig',
    VERSION_FROM  => 'lib/Conf/Libconfig.pm',
    ABSTRACT      => 'Perl extension for libconfig',
    AUTHOR        => 'Cnangel <cnangel@gmail.com>',
    LICENSE       => 'bsd',
    MIN_PERL_VERSION => '5.006001',
    INC           => join(' ', map {"-I$_"} @inc_paths),
    LIBS          => [join(' ', map {"-L$_"} @lib_paths) . ' -lconfig'],
    PREREQ_PM     => {
        'XSLoader' => '0.05',
    },
    TEST_REQUIRES => {
        'Test::Deep'      => '0.10',
        'Test::More'      => '0.60',
        'Test::Warn'      => '0.10',
        'Test::Exception' => '0.25',
    },
    CONFIGURE_REQUIRES => {
        'Devel::CheckLib' => '1.16',
    },
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources => {
            repository => {
                type => 'git',
                url  => 'http://github.com/cnangel/Conf-Libconfig',
            },
        },
    },
    clean => { FILES => 'MYMETA.yml MYMETA.json' },
);