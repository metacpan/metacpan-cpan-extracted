use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Algorithm::Functional::BFS',
    AUTHOR              => q{Colin Wetherbee <cww@cpan.org>},
    VERSION_FROM        => 'lib/Algorithm/Functional/BFS.pm',
    ABSTRACT_FROM       => 'lib/Algorithm/Functional/BFS.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'mit')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'common::sense' => 0,
        'Carp' => 0,

        'Test::More' => 0,
        'Test::Most' => 0,
        'Test::Class' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Algorithm-Functional-BFS-*' },
);
