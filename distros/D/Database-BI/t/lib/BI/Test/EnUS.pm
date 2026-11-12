package BI::Test::EnUS;

# The American English templates, templates/<platform>/en-us/, are made from
# the British ones, templates/<platform>/en/, by the word list below: they are
# the same pages with American spelling.  Nobody edits en-us by hand.  Change
# the en template, then run
#
#   perl author/make-en-us
#
# and t/en-us.t fails until the two agree, so the copies cannot drift apart.
#
# Only prose is respelled.  A word that is part of a name the code reads -- a
# JavaScript identifier (txColour, o.colour), an element id (tx-colour), a
# stored key ({ colour: ... }, field('colour')), aria-labelledby -- keeps its
# spelling, because the pages, the canvases already saved and the server all
# use that name.  The rule is in americanize().

use strict;
use warnings;

use Carp qw(croak);
use Exporter qw(import);
use File::Find ();
use File::Spec ();

our @EXPORT_OK = qw(americanize source_language target_language expected_tree);

sub source_language { 'en' }
sub target_language { 'en-us' }

# British spelling => American, in lower case.  A word written with a capital
# first letter, or in capitals, is matched and respelled in the same case.
# Words that are the same in both, or that are one spelling of two words
# ("analyses" is the plural of analysis as well as a verb), are left out.
my %WORDS = (
	colour => 'color', colours => 'colors', coloured => 'colored',
	colouring => 'coloring', recolour => 'recolor', recoloured => 'recolored',
	centre => 'center', centres => 'centers', centred => 'centered',
	centring => 'centering',
	behaviour => 'behavior', behaviours => 'behaviors',
	neighbour => 'neighbor', neighbours => 'neighbors',
	neighbourhood => 'neighborhood', neighbourhoods => 'neighborhoods',
	favour => 'favor', favourite => 'favorite', favourites => 'favorites',
	honour => 'honor', labour => 'labor',
	grey => 'gray', greyed => 'grayed',
	analyse => 'analyze', analysed => 'analyzed', analysing => 'analyzing',
	cancelled => 'canceled', cancelling => 'canceling',
	cancellable => 'cancelable',
	labelled => 'labeled', labelling => 'labeling', unlabelled => 'unlabeled',
	modelled => 'modeled', modelling => 'modeling',
	travelled => 'traveled', travelling => 'traveling',
	judgement => 'judgment',
	catalogue => 'catalog', catalogues => 'catalogs',
	licence => 'license', licences => 'licenses',
	defence => 'defense', offence => 'offense',
	totalled => 'totaled', totalling => 'totaling',
	whilst => 'while', amongst => 'among',
	(map { my ($b, $a) = @{$_}; map { ("$b$_" => "$a$_") } qw(e es ed ing er ers ation ations) }
		[ summaris => 'summariz' ], [ recognis => 'recogniz' ],
		[ serialis => 'serializ' ], [ initialis => 'initializ' ],
		[ normalis => 'normaliz' ], [ organis => 'organiz' ],
		[ customis => 'customiz' ], [ visualis => 'visualiz' ],
		[ categoris => 'categoriz' ], [ prioritis => 'prioritiz' ],
		[ optimis => 'optimiz' ], [ minimis => 'minimiz' ],
		[ maximis => 'maximiz' ], [ standardis => 'standardiz' ],
		[ authoris => 'authoriz' ], [ finalis => 'finaliz' ],
		[ synchronis => 'synchroniz' ], [ sanitis => 'sanitiz' ],
		[ utilis => 'utiliz' ], [ apologis => 'apologiz' ],
		[ realis => 'realiz' ], [ emphasis => 'emphasiz' ]),
);

my $WORD_RE = do {
	my $alt = join '|', sort { length $b <=> length $a } keys %WORDS;
	qr/\b($alt)\b/i;
};

# americanize($text) -> $text
#
# The template text with each British word in %WORDS respelled, where it is
# prose.  A word is left alone when it is part of a longer name:
#   * a letter, digit, _, $, ., -, # or / touches it on the left
#     (txColour, o.colour, tx-colour, #colour, path/centre);
#   * a letter, digit, _ or - touches it on the right (colour_auto, Colour-coded
#     is left too, which only a comment uses);
#   * it is a lower-case quoted string on its own ('colour', "colour") -- a key
#     or a name (a capital, "Colours", is a label);
#   * it is a key in a script's object ({ colour: x }, , colour: x): a colon
#     straight after it, and a brace or a comma before it.
sub americanize {
	my ($text) = @_;

	# The replacement looks at the characters round each match, so it reads a
	# copy: the positions are those of the text before any word changed.
	my $orig = $text;
	$text =~ s{
		(?<! [\w\$.\-\#/] )
		$WORD_RE
		(?! [\w\-] )
	}{
		_respell($1, $orig, $-[0], $+[0])
	}gex;

	# The embed page declares its language itself rather than through the
	# layout's [% language %].
	$text =~ s{<html lang="en">}{<html lang="en-us">}g;

	return $text;
}

# The text just before position $start: enough to see what a word follows.
sub _before {
	my ($text, $start) = @_;
	my $from = $start > 40 ? $start - 40 : 0;
	return substr($text, $from, $start - $from);
}

sub _respell {
	my ($word, $text, $start, $end) = @_;

	my $before = $start > 0 ? substr($text, $start - 1, 1) : '';
	my $after  = substr($text, $end, 1);

	return $word if length $before && ($before eq q{'} || $before eq q{"}) && $after eq $before
		&& $word =~ /\A[a-z]/;
	return $word if $after eq ':' && _before($text, $start) =~ /[{,]\s*\z/;

	my $us = $WORDS{ lc $word };
	return uc $us        if $word =~ /\A[A-Z]{2,}\z/;
	return ucfirst $us   if $word =~ /\A[A-Z]/;
	return $us;
}

# expected_tree($templates_dir) -> { "<platform>/en-us/<rel>" => $text, ... }
#
# What every en-us template should hold, generated from the en templates of
# each platform under $templates_dir.
sub expected_tree {
	my ($templates) = @_;

	my %out;
	opendir(my $dh, $templates) or croak "Cannot read $templates: $!";
	for my $platform (sort grep { !/\A\./ } readdir $dh) {
		my $src = File::Spec->catdir($templates, $platform, source_language());
		next unless -d $src;
		File::Find::find({
			no_chdir => 1,
			wanted   => sub {
				return unless -f $_ && /\.tt\z/;
				my $rel = File::Spec->abs2rel($_, $src);
				$rel =~ s{\\}{/}g;
				open(my $fh, '<:raw', $_) or croak "Cannot read $_: $!";
				local $/;
				my $text = <$fh>;
				close $fh;
				$out{ join '/', $platform, target_language(), $rel } = americanize($text);
			},
		}, $src);
	}
	closedir $dh;

	return \%out;
}

1;
