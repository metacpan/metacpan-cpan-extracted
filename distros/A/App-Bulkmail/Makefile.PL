use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'App::Bulkmail',
    AUTHOR              => q{Peter Makholm <peter@makholm.net>},
    VERSION_FROM        => 'lib/App/Bulkmail.pm',
    ABSTRACT_FROM       => 'lib/App/Bulkmail.pm',
    EXE_FILES           => [ qw(bin/bulkmail) ],
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'Template'   => 0,
        'File::Slurp' => 0,
        'YAML'        => 0,
        'Any::Moose'  => 0,
    },
    META_MERGE          => {
        resources => {
            repository => 'http://github.com/pmakholm/app-bulkmail-perl',
            license    => 'http://dev.perl.org/licenses/',
        },
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'App-Bulkmail-*' },
);
