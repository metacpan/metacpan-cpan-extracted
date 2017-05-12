use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
    NAME           => 'DBIx::Class::InflateColumn::Boolean',
    VERSION_FROM   => 'lib/DBIx/Class/InflateColumn/Boolean.pm',
    ABSTRACT       => 'Auto-create boolean objects from columns',
    AUTHOR         => 'Bernhard Graf',
    LICENSE        => 'perl_5',
    META_MERGE     => {
	requires  => {perl => '5.008003'},
	resources => {
	    license    => 'http://dev.perl.org/licenses/',
	    bugtracker => 'https://github.com/augensalat/DBIx-Class-InflateColumn-Boolean/issues',
	    repository => 'https://github.com/augensalat/DBIx-Class-InflateColumn-Boolean.git',
	},
    },
    PREREQ_PM => {
	'DBIx::Class' => '0.08',
    },
    TEST_REQUIRES => {
	'DBIx::Class'     => '0.08',
	'Path::Class'     => 0,
	'Scalar::Util'    => 0,
	'SQL::Translator' => 0,
	'Test::More'      => 0,
    },
    test           => {TESTS => 't/*.t'}
);
