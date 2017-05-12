use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Bib::Tools',
    AUTHOR              => q{Doug Leith <dougleith@cpan.org>},
    VERSION_FROM        => 'lib/Bib/Tools.pm',
    ABSTRACT_FROM       => 'lib/Bib/Tools.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
    'Test::More' => 0,
    'Bib::CrossRef' =>  0.08,
    'LWP::UserAgent' =>  0,
    'JSON' =>  0,
    'URI::Escape' =>  0,
    'HTML::Entities' =>  0,
    'HTML::TreeBuilder::XPath' =>  0,
    'XML::Simple' =>  0,
    'BibTeX::Parser' =>  0,
    'IO::File' =>  0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Bib-Tools-*' },
);
