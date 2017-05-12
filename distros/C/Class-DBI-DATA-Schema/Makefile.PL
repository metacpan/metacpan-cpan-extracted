use ExtUtils::MakeMaker;

use strict;
use warnings;

my $PACKAGE = "Class::DBI::DATA::Schema";
my $LOCN    = "lib/Class/DBI/DATA/Schema.pm";

WriteMakefile(
	AUTHOR        => 'Tony Bowden <tony@tmtm.com>',
	NAME          => $PACKAGE,
	ABSTRACT_FROM => $LOCN,
	VERSION_FROM  => $LOCN,
	PREREQ_PM     => {
		'Class::DBI' => 0.94,
		'Test::More' => 0.45,
	},
	dist => {
		COMPRESS     => 'gzip -9',
		SUFFIX       => '.gz',
		DIST_DEFAULT => 'all tardist',
	},

);
