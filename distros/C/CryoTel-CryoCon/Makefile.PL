use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'CryoTel::CryoCon',
    AUTHOR              => 'Sam Kerr <kerr@cpan.org>',
    VERSION_FROM        => 'lib/CryoTel/CryoCon.pm',
    ABSTRACT_FROM       => 'lib/CryoTel/CryoCon.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'CryoTel-CryoCon-*' },
);
