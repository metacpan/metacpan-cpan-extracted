use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'COPS::Client',
    AUTHOR              => 'shamrock@cpan.org <shamrock@cpan.org>',
    VERSION_FROM        => 'lib/COPS/Client.pm',
    ABSTRACT_FROM       => 'lib/COPS/Client.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'COPS-Client-*' },
);
