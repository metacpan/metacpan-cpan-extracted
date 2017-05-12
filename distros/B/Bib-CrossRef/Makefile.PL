use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Bib::CrossRef',
    AUTHOR              => q{Doug Leith <dougleith@cpan.org>},
    VERSION_FROM        => 'lib/Bib/CrossRef.pm',
    ABSTRACT_FROM       => 'lib/Bib/CrossRef.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
    'Test::More' => 0,
    'LWP::UserAgent' =>  0,
    'JSON' =>  0,
    'URI::Escape' =>  0,
    'HTML::Entities' =>  0
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Bib-CrossRef-*' },
);
