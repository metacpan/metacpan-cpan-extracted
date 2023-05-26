use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Crypt::URandom',
    AUTHOR              => 'David Dick <ddick@cpan.org>',
    VERSION_FROM        => 'lib/Crypt/URandom.pm',
    ABSTRACT_FROM       => 'lib/Crypt/URandom.pm',
    ( $ExtUtils::MakeMaker::VERSION >= 6.3002
        ? ( 'LICENSE' => 'perl' )
        : () ),
    (
        $ExtUtils::MakeMaker::VERSION >= 6.48
        ? ( 'MIN_PERL_VERSION' => '5.006' )
        : ()
    ),
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources   => {
            repository => {
                url  => 'https://github.com/david-dick/crypt-urandom',
                web  => 'https://github.com/david-dick/crypt-urandom',
                type => 'git',
            },
            bugtracker => {
                web => 'https://github.com/david-dick/crypt-urandom/issues'
            },
        },
    },
    PL_FILES            => {},
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    TEST_REQUIRES => {
        'Test::More'  => 0,
        'Test::Pod'  => 1.14,
    },
    PREREQ_PM => {
	'Exporter'   => 0,
	'Carp'       => 0,
	'English'    => 0,
	($^O eq 'MSWin32') ? ( 'Win32::API' => 0 ) : ( 'FileHandle' => 0 ),
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Crypt-URandom-*' },
);
