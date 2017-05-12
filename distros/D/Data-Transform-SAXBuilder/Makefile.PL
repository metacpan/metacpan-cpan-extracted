use inc::Module::Install;

all_from	'lib/Data/Transform/SAXBuilder.pm';


requires	'Data::Transform'	                => '0.05_01';
requires	'XML::SAX::IncrementalBuilder::LibXML'	=> '0.02';
requires	'XML::LibXML'		                => '1.63';
requires	'Class::InsideOut'	                => '0';

test_requires	'Test::More'	=> '0';
author_tests('t/author');

auto_provides;

WriteAll;

