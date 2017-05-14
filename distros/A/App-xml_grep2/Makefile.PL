use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'App::xml_grep2',
    AUTHOR              => q{mirod <mirod@cpan.org>},
    VERSION_FROM        => 'bin/xml_grep2',
    ABSTRACT            => 'use XPath to grep XML files',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'Pod::Usage' => 0, 
        'Getopt::Long' => 0,
        'File::Find::Rule' => 0,
        'XML::LibXML' => 0,
        'XML::LibXML::XPathContext' => 0,

    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'App-xml_grep2-*' },
    EXE_FILES           => [ 'bin/xml_grep2' ],
);
