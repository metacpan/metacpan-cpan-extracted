use 5.006; use strict; use warnings;

use Test::More;

BEGIN {
	plan eval { require utf8 } ? ( tests => 1 ) : ( skip_all => 'need utf8 pragma' );
	utf8->import;
}

use Config::INI::Tiny ();

my $cfg = eval { Config::INI::Tiny->new->to_hash( <<'' ) } || $@;
[Δ Lady]
Place = Reichwaldstraße
Class = Πηληϊάδεω Ἀχιλῆος

my $expected = { "\x{394} Lady" => {
	Place => "Reichwaldstra\x{DF}e",
	Class => (
		"\x{3A0}\x{3B7}\x{3BB}\x{3B7}\x{3CA}\x{3AC}\x{3B4}\x{3B5}\x{3C9}"
		. " \x{1F08}\x{3C7}\x{3B9}\x{3BB}\x{1FC6}\x{3BF}\x{3C2}"
	),
} };

is_deeply $cfg, $expected, 'Unicode-laden config';
