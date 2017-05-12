use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Acme::Grep2D',
    AUTHOR              => 'X Cramps <cramps.the@gmail.com>',
    VERSION_FROM        => 'lib/Acme/Grep2D.pm',
    ABSTRACT_FROM       => 'lib/Acme/Grep2D.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'Perl6::Attributes' => '0.04',
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Acme-Grep2D-*' },
);
