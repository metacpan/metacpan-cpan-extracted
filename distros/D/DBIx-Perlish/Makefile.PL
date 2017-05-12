use inc::Module::Install;
BEGIN { require 5.008002 } # please CPAN::Reporter

name			'DBIx-Perlish';
license			'bsd';
all_from		'lib/DBIx/Perlish.pm';

requires		perl => '5.8.2';
requires		'DBI';
requires		'PadWalker';
build_requires	'Test::More' => '0.42';

no_index		directory => 'devel';

repository 'https://github.com/tobez/DBIx-Perlish';

WriteAll;
