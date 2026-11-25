use strict;
use warnings;

use lib '.';
use inc::Module::Install;
use Module::Install::DOAPChangeSets;
use Module::Install::AuthorTests;

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
test_requires	'DBD::SQLite'				=> 0;

perl_version	'5.014';

requires		'Attean'					=> 0.041;
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

# On MacOS, prefer homebrew-installed GNU tar so that we don't include Mac-specific
# extended header data (which results in "Ignoring unknown extended header keyword"
# messages on non-Mac systems when extracting data.
if (-x '/opt/homebrew/bin/gtar') {
	makemaker_args(
		dist => {
			TAR => '/opt/homebrew/bin/gtar'
		}
	);
}

sign if ! exists $ENV{CI};
WriteAll;
