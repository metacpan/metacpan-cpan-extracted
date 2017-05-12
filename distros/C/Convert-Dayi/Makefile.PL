use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Convert::Dayi',
    AUTHOR              => 'Cornelius <cornelius.howl_at_gmail.com>',
    VERSION_FROM        => 'lib/Convert/Dayi.pm',
    ABSTRACT_FROM       => 'lib/Convert/Dayi.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Convert-Dayi-*' },
);
