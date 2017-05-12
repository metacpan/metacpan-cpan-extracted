use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Dancer::Plugin::XML::RSS',
    AUTHOR              => q{Lee Carmichael <lcarmich@cpan.org>},
    VERSION_FROM        => 'lib/Dancer/Plugin/XML/RSS.pm',
    ABSTRACT_FROM       => 'lib/Dancer/Plugin/XML/RSS.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'Dancer'     => 0,
        'XML::RSS'   => 0
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Dancer-Plugin-XML-RSS-*' },
);
