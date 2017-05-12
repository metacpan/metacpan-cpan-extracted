use strict;
use warnings;

use inc::Module::Install;

name			'AtteanX-Endpoint';
all_from		'lib/AtteanX/Endpoint.pm';
author			'Gregory Todd Williams <gwilliams@cpan.org>';
license			'perl';

test_requires	'Test::Exception'				=> 0;
test_requires	'Test::Modern'					=> 0;
test_requires	'Test::Moose'					=> 0;
test_requires	'Test::More'					=> 0.88;
test_requires	'Test::Roo'						=> 0;
test_requires	'HTTP::Message::PSGI'			=> 0;
test_requires	'Test::LWP::UserAgent'			=> 0;
test_requires	'Test::WWW::Mechanize::PSGI'	=> 0;
perl_version	'5.014';

requires		'Attean'						=> 0.013;
requires		'File::ShareDir'				=> 0;
requires		'HTML::HTML5::Parser'			=> 0;
requires		'HTML::HTML5::Writer'			=> 0;
requires		'HTTP::Negotiate'				=> 0;
requires		'IO::Compress::Gzip'			=> 0;
requires		'JSON'							=> 0;
requires		'List::MoreUtils'				=> 0;
requires		'Moo'							=> 1.006000;
requires		'MooX::Log::Any'				=> 0;
requires		'namespace::clean'				=> 0;
requires		'Plack'							=> 0;
requires		'TryCatch'						=> 0;
requires		'Types::Standard'				=> 0;

resources(
	'homepage'   => "http://search.cpan.org/dist/AtteanX-Endpoint/",
	'repository' => "http://github.com/kasei/atteanx-endpoint/",
	'bugtracker' => "https://github.com/kasei/atteanx-endpoint/issues",
	'IRC'        => "irc://irc.perl.org/#perlrdf",
);

author_tests('xt');

install_share;

write_doap_changes "meta/changes.ttl", "Changes", "turtle";

sign;
WriteAll;
