use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Catalyst::Helper::InitScript::FreeBSD',
    AUTHOR              => 'Tomohiro Hosaka <bokutin@cpan.org>',
    VERSION_FROM        => 'lib/Catalyst/Helper/InitScript/FreeBSD.pm',
    ABSTRACT_FROM       => 'lib/Catalyst/Helper/InitScript/FreeBSD.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Term::Prompt' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Catalyst-Helper-InitScript-FreeBSD-*' },
);
