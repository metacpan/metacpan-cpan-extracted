use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'App::AutoBuild',
    AUTHOR              => q{Joel Jensen <yobert@gmail.com>},
    VERSION_FROM        => 'lib/App/AutoBuild.pm',
    ABSTRACT_FROM       => 'lib/App/AutoBuild.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    MIN_PERL_VERSION => '5.10.0',
    PREREQ_PM => {
        'Test::More' => 0,
        'autodie' => 0,
        'IPC::System::Simple' => 0, # needed for autodie::system()
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'App-AutoBuild-*' },
);
