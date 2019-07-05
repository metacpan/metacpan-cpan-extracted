use 5.008;
use utf8;
use strictures 2;
use ExtUtils::MakeMaker;

my %args = (
	'NAME'               => 'DBIx::Class::Helper::ResultSet::BooleanMethods',
	'AUTHOR'             => q{Mathieu Arnold <mat@cpan.org>},
	'VERSION_FROM'       => 'lib/DBIx/Class/Helper/ResultSet/BooleanMethods.pm',
	'ABSTRACT_FROM'      => 'lib/DBIx/Class/Helper/ResultSet/BooleanMethods.pm',
	'LICENSE'            => 'artistic_2',
	'MIN_PERL_VERSION'   => '5.008',
	'CONFIGURE_REQUIRES' => {
		'ExtUtils::MakeMaker' => '0',
	},
	'TEST_REQUIRES' => {
		'Test::More' => '0',
	},
	'PREREQ_PM' => {
		'Package::Variant'                   => '1.003',
		'Role::Tiny'                         => '2.0',
		'DBIx::Class::Helper::ResultSet::Me' => '2.033',
	},
	'dist' => {
		'COMPRESS' => 'gzip -9f',
		'SUFFIX'   => 'gz',
	},
	'clean' => {
		'FILES' => 'DBIx-Class-Helper-ResultSet-BooleanMethods-*',
	},
);

WriteMakefile(%args);
