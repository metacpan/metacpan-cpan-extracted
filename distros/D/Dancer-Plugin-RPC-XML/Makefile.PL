use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Dancer::Plugin::RPC::XML',
    AUTHOR              => 'Jesper Dalberg <jdalberg@gmail.com>',
    VERSION_FROM        => 'lib/Dancer/Plugin/RPC/XML.pm',
    ABSTRACT_FROM       => 'lib/Dancer/Plugin/RPC/XML.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'RPC::XML' => 0.69,
        'Dancer' => 0,
        'Dancer::Plugin' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Dancer-Plugin-RPC-XML-*' },
);
