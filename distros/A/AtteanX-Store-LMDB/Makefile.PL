use strict;
use warnings;

use lib '.';
use inc::Module::Install;
use Module::Install::DOAPChangeSets;
use Module::Install::AuthorTests;
use Module::Install::Scripts;

name			'AtteanX-Store-LMDB';
all_from		'lib/AtteanX/Store/LMDB.pm';
author			'Gregory Todd Williams <gwilliams@cpan.org>';
license			'perl';

test_requires	'Test::Exception'			=> 0;
test_requires	'Test::Modern'				=> 0;
test_requires	'Test::Moose'				=> 0;
test_requires	'Test::More'				=> 0.88;
test_requires	'Test::Roo'					=> 0;

perl_version	'5.014';

requires		'Attean'					=> 0.013;
requires		'Math::Cartesian::Product'	=> 1.008;
requires		'Moo'						=> 1.006000;
requires		'namespace::clean'			=> 0;
requires		'Try::Tiny'					=> 0;
requires		'Type::Tiny'				=> 0;
requires		'LMDB_File'					=> 0;
requires		'DateTime::Format::W3CDTF'	=> 0;

resources(
	'homepage'   => "https://metacpan.org/release/AtteanX-Store-LMDB/",
	'repository' => "https://github.com/kasei/atteanx-store-lmdb/",
	'bugtracker' => "https://github.com/kasei/atteanx-store-lmdb/issues",
	'IRC'        => "irc://irc.perl.org/#perlrdf",
);

author_tests('xt');
install_script 'bin/attean_lmdb_create';

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
