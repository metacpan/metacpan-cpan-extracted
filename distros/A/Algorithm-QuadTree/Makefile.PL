use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
	NAME => 'Algorithm::QuadTree',
	VERSION_FROM => 'lib/Algorithm/QuadTree.pm',
	ABSTRACT_FROM => 'lib/Algorithm/QuadTree.pm',

	AUTHOR => 'Ala Qumsieh <aaqumsieh@cpan.org>',
	LICENSE => 'perl',

	META_MERGE => {
		'meta-spec' => { version => 2 },
		resources => {
			license => 'https://dev.perl.org/licenses',
			bugtracker => {
				web => 'https://github.com/bbrtj/perl-algorithm-quadtree/issues',
			},
			repository => {
				type => 'git',
				url => 'https://github.com/bbrtj/perl-algorithm-quadtree.git',
				web => 'https://github.com/bbrtj/perl-algorithm-quadtree',
			},
		},
	},

	PREREQ_PM => {},
);

