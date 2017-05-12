use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'ACME::PM::Voronezh',
    AUTHOR              => q{Alexander Nusov <alexander.nusov+cpan@gmail.com>},
    VERSION_FROM        => 'lib/ACME/PM/Voronezh.pm',
    ABSTRACT_FROM       => 'lib/ACME/PM/Voronezh.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'ACME-PM-Voronezh-*' },
);
