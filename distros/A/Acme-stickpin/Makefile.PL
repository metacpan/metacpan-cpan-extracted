use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Acme::stickpin',
    AUTHOR              => q{B. McMahon <stickpin@cpan.org>},
    VERSION_FROM        => 'lib/Acme/stickpin.pm',
    ABSTRACT_FROM       => 'lib/Acme/stickpin.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Acme-stickpin-*' },
);
