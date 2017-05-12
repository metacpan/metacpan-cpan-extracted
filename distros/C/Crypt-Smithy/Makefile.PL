use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Crypt::Smithy',
    AUTHOR              => q{Andreas Faafeng <aff@cpan.org>},
    VERSION_FROM        => 'lib/Crypt/Smithy.pm',
    ABSTRACT_FROM       => 'lib/Crypt/Smithy.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'gpl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Crypt-Smithy-*' },
);
