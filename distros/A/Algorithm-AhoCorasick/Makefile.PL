require 5.005_640;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Algorithm::AhoCorasick',
    AUTHOR              => 'Vaclav Barta <vbar@comp.cz>',
    VERSION_FROM        => 'lib/Algorithm/AhoCorasick.pm',
    ABSTRACT_FROM       => 'lib/Algorithm/AhoCorasick.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Algorithm-AhoCorasick-*' },
);
