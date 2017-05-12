use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'CGI::Struct::XS',
    AUTHOR              => q{Dmitry Smal <mialinx@gmail.com>},
    VERSION_FROM        => 'lib/CGI/Struct/XS.pm',
    ABSTRACT_FROM       => 'lib/CGI/Struct/XS.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'bsd')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Storable'           => 0,
        'XSLoader'           => 0,
        'Test::More'         => 0,
        'Test::Deep'         => 0,
        'Test::Deep::NoTest' => 0,
        'Test::LeakTrace'    => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'CGI-Struct-XS-*' },
);
