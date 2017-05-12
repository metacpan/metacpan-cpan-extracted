use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Dancer::Plugin::Hosts',
    AUTHOR              => q{Perlover <perlover@perlover.com>},
    VERSION_FROM        => 'lib/Dancer/Plugin/Hosts.pm',
    ABSTRACT_FROM       => 'lib/Dancer/Plugin/Hosts.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Dancer'     => 1.3071
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Dancer-Plugin-Hosts-*' },
);
