use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Acme::TextLayout',
    AUTHOR              => 'X Cramps <cramps.the@gmail.com>',
    VERSION_FROM        => 'lib/Acme/TextLayout.pm',
    ABSTRACT_FROM       => 'lib/Acme/TextLayout.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'Perl6::Attributes' => '0.04',
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Acme-TextLayout-*' },
);
