use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Acme::AsciiArt2HtmlTable',
    AUTHOR              => 'Jose Castro <cog@cpan.org>',
    VERSION_FROM        => 'lib/Acme/AsciiArt2HtmlTable.pm',
    ABSTRACT_FROM       => 'lib/Acme/AsciiArt2HtmlTable.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Acme-AsciiArt2HtmlTable-*' },
);
