use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'CMS::Joomla',
    AUTHOR              => 'EPIPE Communications <epipe at cpan.org>',
  ($ExtUtils::MakeMaker::VERSION >= 6.3002 ?
    ('LICENSE'          => 'perl', ) : ()),
    VERSION_FROM        => 'lib/CMS/Joomla.pm',
    ABSTRACT_FROM       => 'lib/CMS/Joomla.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'DBI' => 0,
        'IO::File' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'CMS-Joomla-*' },
);
