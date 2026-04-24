use strict;
use warnings;

use ExtUtils::MakeMaker;

my $version     = MM->parse_version('lib/Crypt/RIPEMD160.pm');
my $mac_version = MM->parse_version('lib/Crypt/RIPEMD160/MAC.pm');

WriteMakefile(
    'DISTNAME'     => 'Crypt-RIPEMD160',
    'NAME'                => 'Crypt::RIPEMD160',
    'AUTHOR'              => 'Christian H. Geuer-Pollmann',
    'VERSION_FROM'  => 'lib/Crypt/RIPEMD160.pm',
    'ABSTRACT_FROM' => 'lib/Crypt/RIPEMD160.pm',
    'MIN_PERL_VERSION'    => '5.010',
    'PL_FILES'            => {},
    ($ExtUtils::MakeMaker::VERSION >= 6.3002 ? ('LICENSE'        => 'perl', ) : ()),
    PREREQ_PM => {
        'XSLoader'   => 0,
    },
    ($ExtUtils::MakeMaker::VERSION >= 6.64 ? (TEST_REQUIRES => {
        'Test::More' => 0,
    }) : ()),
    'dist'                => {
        COMPRESS => 'gzip -9f',
        SUFFIX   => 'gz',
        ($^O eq 'darwin' ? (TAR => 'gtar') : ()),
    },
    'clean'               => { FILES => 'Crypt-RIPEMD160-*' },

    'OBJECT'       => q[RIPEMD160$(OBJ_EXT) rmd160$(OBJ_EXT) wrap_160$(OBJ_EXT)],

    META_MERGE  => {
        'meta-spec' => { version => 2 },
        provides => {
            'Crypt::RIPEMD160' => {
                file    => 'lib/Crypt/RIPEMD160.pm',
                version => $version,
            },
            'Crypt::RIPEMD160::MAC' => {
                file    => 'lib/Crypt/RIPEMD160/MAC.pm',
                version => $mac_version,
            },
        },
        resources => {
            license    => ['https://dev.perl.org/licenses/'],
            homepage   => 'https://github.com/cpan-authors/Crypt-RIPEMD160',
            bugtracker => {
                web => 'https://github.com/cpan-authors/Crypt-RIPEMD160/issues',
            },
            repository => {
                type => 'git',
                url  => 'https://github.com/cpan-authors/Crypt-RIPEMD160.git',
                web  => 'https://github.com/cpan-authors/Crypt-RIPEMD160',
            },
        },
    },
);

