use strict;
use warnings;

use inc::Module::Install;

name			'AtteanX-Store-DBI';
all_from		'lib/AtteanX/Store/DBI.pm';
author			'Gregory Todd Williams <gwilliams@cpan.org>';
license			'perl';

test_requires	'Test::Exception'			=> 0;
test_requires	'Test::Modern'				=> 0;
test_requires	'Test::Moose'				=> 0;
test_requires	'Test::More'				=> 0.88;
test_requires	'Test::Roo'					=> 0;
test_requires	'HTTP::Message::PSGI'		=> 0;
test_requires	'Test::LWP::UserAgent'		=> 0;

perl_version	'5.014';

requires		'Attean'					=> 0.013;
requires		'List::MoreUtils'			=> 0;
requires		'Math::Cartesian::Product'	=> 1.008;
requires		'Moo'						=> 1.006000;
requires		'MooX::Log::Any'			=> 0;
requires		'namespace::clean'			=> 0;
requires		'Try::Tiny'					=> 0;
requires		'Type::Tiny'				=> 0;
requires		'File::Slurp'				=> 0;
requires		'File::ShareDir'			=> 0;

requires		'DBI'						=> 0;
requires		'Cache::LRU'				=> 0;
requires		'DBI'						=> 0;
requires		'DBIx::MultiStatementDo'	=> 0;

resources(
	'homepage'   => "https://metacpan.org/release/AtteanX-Store-DBI/",
	'repository' => "https://github.com/kasei/atteanx-store-dbi/",
	'bugtracker' => "https://github.com/kasei/atteanx-store-dbi/issues",
	'IRC'        => "irc://irc.perl.org/#perlrdf",
);

author_tests('xt');

install_share;
install_script glob('bin/attean_*');

write_doap_changes "meta/changes.ttl", "Changes", "turtle";

sign;
WriteAll;
