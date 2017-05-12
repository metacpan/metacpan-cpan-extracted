use inc::Module::Install;

name		'Catalyst-Plugin-Cache-HTTP';
license		'perl';
all_from	'lib/Catalyst/Plugin/Cache/HTTP.pm';
author		'Bernhard Graf <graf@cpan.org>';

build_requires	'Catalyst::Runtime';
build_requires	'HTTP::Status';
build_requires	'Test::WWW::Mechanize::Catalyst';
build_requires	'Test::More';
build_requires	'ok';

requires	'Class::Accessor::Fast';
requires	'HTTP::Headers::ETag';
requires	'List::Util';
requires	'MRO::Compat';

WriteAll;
