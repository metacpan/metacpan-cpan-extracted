use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'CGI::Struct',
    AUTHOR              => q{Matthew Fuller <fullermd@over-yonder.net>},
    VERSION_FROM        => 'lib/CGI/Struct.pm',
    ABSTRACT_FROM       => 'lib/CGI/Struct.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'bsd')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Storable'   => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
        'Test::Deep' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'CGI-Struct-*' },
);
