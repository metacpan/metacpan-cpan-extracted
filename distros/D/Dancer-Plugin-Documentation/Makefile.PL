use strict;
use warnings;

use ExtUtils::MakeMaker;
use ExtUtils::MakeMaker::CPANfile;

WriteMakefile(
	NAME          => 'Dancer::Plugin::Documentation',
	AUTHOR        => q{Aaron Cohen <aarondcohen@gmail.com>},
	VERSION_FROM  => 'lib/Dancer/Plugin/Documentation.pm',
	ABSTRACT_FROM => 'lib/Dancer/Plugin/Documentation.pm',
	LICENSE       => 'perl',
	META_MERGE => {
		resources => {
			homepage => 'http://github.com/aarondcohen/perl-dancer-plugin-documentation',
			repository => 'git://github.com/aarondcohen/perl-dancer-plugin-documentation.git',
			bugtracker => 'http://github.com/aarondcohen/perl-dancer-plugin-documentation/issues',
		}
	},
);
