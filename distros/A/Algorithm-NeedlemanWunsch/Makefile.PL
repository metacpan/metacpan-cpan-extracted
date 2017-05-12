use strict;
use warnings;

require 5.006_000; # $VERSION declaration apparently fails on 5.00505

use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Algorithm::NeedlemanWunsch',
    AUTHOR              => 'Vaclav Barta <vbar@comp.cz>',
    VERSION_FROM        => 'lib/Algorithm/NeedlemanWunsch.pm',
    ABSTRACT_FROM       => 'lib/Algorithm/NeedlemanWunsch.pm',
    PL_FILES            => {},
    PREREQ_PM => {
	'Carp' => 0,
	'List::Util' => 0,
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Algorithm-NeedlemanWunsch-*' },
);
