use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Catalyst::Plugin::ConfigurablePathTo',
    AUTHOR              => 'Nilson Santos Figueiredo Júnior <nilsonsfj@cpan.org>',
    VERSION_FROM        => 'lib/Catalyst/Plugin/ConfigurablePathTo.pm',
    ABSTRACT_FROM       => 'lib/Catalyst/Plugin/ConfigurablePathTo.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More'	=> 0,
		'Path::Class'	=> 0,
		'Catalyst'		=> 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Catalyst-Plugin-ConfigurablePathTo-*' },
);
