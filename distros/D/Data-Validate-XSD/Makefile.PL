use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Data::Validate::XSD',
    AUTHOR              => 'Martin Owens <doctormo@cpan.org>',
    VERSION_FROM        => 'lib/Data/Validate/XSD.pm',
    ABSTRACT_FROM       => 'lib/Data/Validate/XSD.pm',
    PL_FILES            => {},
    PREREQ_PM => {
      'Test::More'  => 0,
      'Date::Parse' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Data-Validate-XSD-*' },
);
