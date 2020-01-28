use strict;
use warnings;

use lib '.';
use inc::Module::Install;

name			'AtteanX-Parser-JSONLD';
all_from		'lib/AtteanX/Parser/JSONLD.pm';
author			'Gregory Todd Williams <gwilliams@cpan.org>';
license			'perl';

test_requires	'Test::More'				=> 0.88;
test_requires	'Test::Exception'			=> 0;
test_requires	'Test::Modern'				=> 0.012;

perl_version	'5.014';

requires		'Attean'					=> 0;
requires		'JSONLD'					=> 0.001;
requires		'JSON'						=> 4.02;

resources(
	'homepage'		=> "http://search.cpan.org/dist/AtteanX-Parser-JSONLD/",
	'repository'	=> "http://github.com/kasei/atteanx-parser-jsonld/",
	'bugtracker'	=> "https://github.com/kasei/atteanx-parser-jsonld/issues",
	'IRC'			=> "irc://irc.perl.org/#perlrdf",
);

author_tests('xt');

write_doap_changes "meta/changes.ttl", "Changes", "turtle";

sign;
WriteAll;
