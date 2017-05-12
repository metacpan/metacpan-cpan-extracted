use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Cluster::Similarity',
    AUTHOR              => 'Ingrid Falk <ingrid.falk@loria.fr>',
    VERSION_FROM        => 'lib/Cluster/Similarity.pm',
    ABSTRACT_FROM       => 'lib/Cluster/Similarity.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
	'Test::Deep' => 0,
	'version' => 0,
	'Carp' => 0,
	'Math::Combinatorics' => 0,
	'List::Util' => 0,
	'Class::Std' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Cluster-Similarity-*' },
);
