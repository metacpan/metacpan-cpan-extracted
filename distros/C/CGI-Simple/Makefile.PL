use strict;
use ExtUtils::MakeMaker;

my %conf = (
    NAME          => 'CGI::Simple',
    AUTHOR        => 'Andy Armstrong <andy@hexten.net>',
    VERSION_FROM  => 'lib/CGI/Simple.pm',
    ABSTRACT_FROM => 'lib/CGI/Simple.pm',
    TEST_REQUIRES     => {
        'Test::More'       => 0,
        'Test::NoWarnings' => 0,
        'Test::Exception'  => 0,
        'File::Temp'       => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES    => 'CGI-Simple-*' },
);

if (eval { ExtUtils::MakeMaker->VERSION(6.3002) }) {
    $conf{LICENSE} = 'perl';
}

if (eval { ExtUtils::MakeMaker->VERSION(6.46) }) {
    $conf{META_MERGE} = {
        'meta-spec' => { version => 2 },
        resources => {
            repository => {
                type    => 'git',
                url     => 'http://github.com/manwar/CGI--Simple.git',
                web     => 'http://github.com/manwar/CGI--Simple',
                license => 'http://dev.perl.org/licenses/',
            },
        },
    };
}

if (!eval { ExtUtils::MakeMaker->VERSION(6.64) }) {
    $conf{BUILD_REQUIRES} = {
        %{ $conf{BUILD_REQUIRES} || {} },
        %{ delete $conf{TEST_REQUIRES} || {} },
    };
}

if (!eval { ExtUtils::MakeMaker->VERSION(6.5503) }) {
    $conf{PREREQ_PM} = {
        %{ $conf{PREREQ_PM} || {} },
        %{ delete $conf{BUILD_REQUIRES} || {} },
    };
}

WriteMakefile(%conf);
