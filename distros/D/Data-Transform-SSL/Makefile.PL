use inc::Module::Install;

perl_version	'5.006';
all_from	'lib/Data/Transform/SSL.pm';

requires	'Carp'			=> '0';
requires	'POE'			=> '0';
requires	'Net::SSLeay'           => '1.30';
requires        'Data::Transform'       => '0.05_01';

test_requires	'Test::More'	=> '0';

author_tests('t/author');

auto_provides;

WriteAll;
