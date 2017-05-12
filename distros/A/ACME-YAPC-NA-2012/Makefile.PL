use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'ACME::YAPC::NA::2012',
    AUTHOR              => q{Jacinta Richardson <jarich@cpan.org>},
    VERSION_FROM        => 'lib/ACME/YAPC/NA/2012.pm',
    ABSTRACT_FROM       => 'lib/ACME/YAPC/NA/2012.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'ACME-YAPC-NA-2012-*' },
);
