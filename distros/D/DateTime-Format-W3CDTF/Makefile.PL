use strict;
use warnings;

use lib '.';
use inc::Module::Install;

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

sign;
WriteAll;
