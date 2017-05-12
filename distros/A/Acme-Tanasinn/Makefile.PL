use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Acme::Tanasinn',
    AUTHOR              => q{Squeeks <squeek@cpan.org>},
    VERSION_FROM        => 'lib/Acme/Tanasinn.pm',
    ABSTRACT_FROM       => 'lib/Acme/Tanasinn.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Acme-Tanasinn-*' },
);
