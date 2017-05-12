use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Acme::Very::Modern::Perl',
    AUTHOR              => q{Frank Wiegand <frank.wiegand@gmail.com>},
    VERSION_FROM        => 'lib/Acme/Very/Modern/Perl.pm',
    ABSTRACT_FROM       => 'lib/Acme/Very/Modern/Perl.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'Modern::Perl' => 0,
        'Toolkit' => 0,
        'latest' => 0,
        'uni::perl' => 0,
        'common::sense' => 0,
        'perl5i' => 'v1.0.0',
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Acme-Very-Modern-Perl-*' },
);
