use inc::Module::Install;

name		'Data-Transform';
perl_version	'5.005';
all_from	'lib/Data/Transform.pm';

requires	'Carp'			=> '0';

test_requires	'Test::More'	=> '0';
test_requires   'Storable'      => '0';

author_tests('t/author');

auto_provides;
repository 'git://martijn.at/data-transform.git';

WriteAll;
