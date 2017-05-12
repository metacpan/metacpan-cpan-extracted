use 5.008;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Bio::Tools::Alignment::Overview',
    AUTHOR              => q{Leprevost <leprevostfv@gmail.com>},
    VERSION_FROM        => 'lib/Bio/Tools/Alignment/Overview.pm',
    ABSTRACT_FROM       => 'lib/Bio/Tools/Alignment/Overview.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0.98,
		'GD::Simple' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Bio-Tools-Alignment-Overview-*' },
);
