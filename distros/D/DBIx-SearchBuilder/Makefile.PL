use inc::Module::Install;

name ('DBIx-SearchBuilder');
all_from('lib/DBIx/SearchBuilder.pm');
requires('DBI');
requires('Want');
requires('Encode' => '1.99');
requires('Class::ReturnValue', 0.40);
requires('Cache::Simple::TimedExpiry' => '0.21');
requires('Clone');
requires('Scalar::Util');
build_requires('Test::More' => 0.52);
build_requires('DBD::SQLite');
build_requires('File::Temp');
features(
	'Lower case API' => [
		-default => 0,
		'capitalization' => '0.03',
	],
	'Schema generation' => [
	  -default => 1,
	  'DBIx::DBSchema' => '',
	  'Class::Accessor' => '',
	],
);
auto_install();

no_index directory => 't';
no_index directory => 'ex';

sign;
WriteAll();
