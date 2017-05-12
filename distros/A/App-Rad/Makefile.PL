use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'App::Rad',
    AUTHOR              => 'Breno G. de Oliveira <garu at cpan.org>',
    VERSION_FROM        => 'lib/App/Rad.pm',
    ABSTRACT_FROM       => 'lib/App/Rad.pm',
    LICENSE             => 'perl',
    PL_FILES            => {},

# Our dependencies are all core modules, so you shouldn't have
# to install anything besides Perl 5.8!
    PREREQ_PM => {
        'Test::More'          => 0,
        'Getopt::Long'        => 2.36,
        'Carp'                => 0,
        'File::Temp'          => 0,
        'FindBin'             => 0,
        'Attribute::Handlers' => 0,
        'B::Deparse'          => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'App-Rad-*' },
);
