use ExtUtils::MakeMaker;
use inc::Module::Install;

requires Catalyst			=> '5.7';
requires Catalyst::View::TT	=> 0;

WriteMakefile(
    NAME                => 'Catalyst::Helper::View::TTSimple',
    AUTHOR              => 'Victor Igumnov <victori@lamer0.com>',
    VERSION_FROM        => 'lib/Catalyst/Helper/View/TTSimple.pm',
    ABSTRACT_FROM       => 'lib/Catalyst/Helper/View/TTSimple.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Catalyst-Helper-View-TTSimple-*' },
);
