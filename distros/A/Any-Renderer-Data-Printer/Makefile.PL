use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Any::Renderer::Data::Printer',
    AUTHOR              => q{Kevin McGrath <kmcgrath@baknet.com>},
    VERSION_FROM        => 'lib/Any/Renderer/Data/Printer.pm',
    ABSTRACT_FROM       => 'lib/Any/Renderer/Data/Printer.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More'    => 0,
        'Any::Renderer' => 1.014,
        'Data::Printer' => 0.18,
    },
    META_MERGE => { 
        resources => {
            repository => 'https://github.com/kmcgrath/perl5-Any-Renderer-Data-Printer',
        },
    },

    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Any-Renderer-Data-Printer-*' },
);
