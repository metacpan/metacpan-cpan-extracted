use strict;
use warnings;

use inc::Module::Install;

name			'AtteanX-RDFQueryTranslator';
all_from		'lib/AtteanX/RDFQueryTranslator.pm';
author			'Gregory Todd Williams <gwilliams@cpan.org>';
license			'perl';

test_requires	'Test::Exception'			=> 0;
test_requires	'Test::Modern'				=> 0;
test_requires	'Test::Moose'				=> 0;
test_requires	'Test::More'				=> 0.88;
test_requires	'Test::Roo'					=> 0;
test_requires	'Test::LWP::UserAgent'		=> 0;

perl_version	'5.014';

requires		'Attean'					=> 0.016;
requires		'RDF::Query'				=> 2.910;

resources(
	'homepage'   => "http://search.cpan.org/dist/AtteanX-RDFQueryTranslator/",
	'repository' => "http://github.com/kasei/atteanx-rdfquerytranslator/",
	'bugtracker' => "https://github.com/kasei/atteanx-rdfquerytranslator/issues",
	'IRC'        => "irc://irc.perl.org/#perlrdf",
);

author_tests('xt');

write_doap_changes "meta/changes.ttl", "Changes", "turtle";

sign;
WriteAll;
