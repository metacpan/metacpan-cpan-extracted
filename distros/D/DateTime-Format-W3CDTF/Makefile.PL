use strict;
use warnings;

use lib '.';
use inc::Module::Install;
use Module::Install::DOAPChangeSets;

name				'DateTime-Format-W3CDTF';
all_from			'lib/DateTime/Format/W3CDTF.pm';
author				'Gregory Todd Williams <gwilliams@cpan.org>';
license				'perl';

test_requires		'Test::More'				=> 0.61;

perl_version		'5.008';

requires			'DateTime'					=> 0;

resources(
	'homepage'   => "https://metacpan.org/release/DateTime-Format-W3CDTF/",
	'repository' => "https://github.com/kasei/datetime-format-w3cdtf",
	'bugtracker' => "https://github.com/kasei/datetime-format-w3cdtf/issues",
);

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
