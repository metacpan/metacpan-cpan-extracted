use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Data::Printer::Filter::JSON',
    AUTHOR              => q{Nuba Princigalli <nuba@stastu.org>},
    VERSION_FROM        => 'lib/Data/Printer/Filter/JSON.pm',
    ABSTRACT_FROM       => 'lib/Data/Printer/Filter/JSON.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'Data::Printer' => 0.32,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Data-Printer-Filter-JSON-*' },
);
