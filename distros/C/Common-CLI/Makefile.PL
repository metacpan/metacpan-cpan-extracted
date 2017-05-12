use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Common::CLI',
    AUTHOR              => 'Igor Sutton <izut@cpan.org>',
    VERSION_FROM        => 'lib/Common/CLI.pm',
    ABSTRACT_FROM       => 'lib/Common/CLI.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'Data::FormValidator' => 0,
        'Getopt::Long' => 0,
        'File::Basename' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Common-CLI-*' },
);
