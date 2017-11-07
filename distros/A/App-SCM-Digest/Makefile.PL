use strict;
use warnings;

use ExtUtils::MakeMaker;
use ExtUtils::MakeMaker::Config;

my $output = WriteMakefile(
    NAME          => 'App::SCM::Digest',
    AUTHOR        => 'Tom Harrison <tomhrr@cpan.org>',
    VERSION_FROM  => 'lib/App/SCM/Digest.pm',
    ABSTRACT      => 'Send repository commit digest emails',
    LICENSE       => 'perl_5',
    PL_FILES      => {},
    EXE_FILES     => ['bin/scm-digest'],
    MIN_PERL_VERSION => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
    },
    PREREQ_PM => {
        'autodie'                    => 0,
        'DateTime'                   => 0,
        'DateTime::Format::Strptime' => 0,
        'Getopt::Long'               => 0,
        'Email::MIME'                => 0,
        'File::ReadBackwards'        => 0,
        'File::Path'                 => 0,
        'File::Temp'                 => 0,
        'List::Util'                 => 0,
        'Pod::Usage'                 => 0,
        'Test::More'                 => 0,
        'YAML'                       => 0,
        'IO::Capture::Stderr'        => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'App-SCM-Digest-*' },
    META_MERGE     => {
        resources => {
            repository => 'https://github.com/tomhrr/p5-App-SCM-Digest'
        }
    },
);

1;
