use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Acme::AsciiArtFarts',
    AUTHOR              => q{Luke Poskitt <ltp@cpan.org>},
    VERSION_FROM        => 'lib/Acme/AsciiArtFarts.pm',
    ABSTRACT_FROM       => 'lib/Acme/AsciiArtFarts.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'LWP'		=> 0,
        'Test::More'	=> 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Acme-AsciiArtFarts-*' },
);
