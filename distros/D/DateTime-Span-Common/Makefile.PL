use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'DateTime::Span::Common',
    AUTHOR              => 'Terrence Brannon <metaperl@gmail.com>',
    VERSION_FROM        => 'lib/DateTime/Span/Common.pm',
    ABSTRACT_FROM       => 'lib/DateTime/Span/Common.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'DateTime-Span-Common-*' },
);
