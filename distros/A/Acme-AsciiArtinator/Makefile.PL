use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Acme::AsciiArtinator',
    AUTHOR              => q{Marty O'Brien <mob@cpan.org>},
    VERSION_FROM        => 'lib/Acme/AsciiArtinator.pm',
    ABSTRACT_FROM       => 'lib/Acme/AsciiArtinator.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Acme-AsciiArtinator-*' },
);
