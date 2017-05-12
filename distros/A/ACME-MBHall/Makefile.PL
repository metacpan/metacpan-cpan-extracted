use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'ACME::MBHall',
    AUTHOR              => q{Matthew Hall <MBHall@cpan.org>},
    VERSION_FROM        => 'lib/ACME/MBHall.pm',
    ABSTRACT_FROM       => 'lib/ACME/MBHall.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'ACME-MBHall-*' },
);
