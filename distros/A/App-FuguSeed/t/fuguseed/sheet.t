#!/usr/bin/env perl
# ex:ts=8 sw=4:
# The word sheet (WORDS-BUILD, WORDS-CHECK, TEST-SHEET, LIST-SHARE).
# The test builds the sheet of the shipped list on a fixed date, and
# it holds that text to the fixture. Then it runs the check on the
# built sheet and on each corrupted sheet.
#
# Each corruption is one mutation of a correct sheet, and each one
# names the defect that it must raise. A check that cannot fail
# passes every mutation, so the table below is the proof of the
# checker.

use v5.34;
use warnings;
use experimental 'signatures';
no feature qw(indirect multidimensional bareword_filehandles);
use Test::More;
use File::Temp ();
use FindBin    qw($RealBin);

my $root = "$RealBin/../..";
chdir $root or BAIL_OUT("chdir $root: $!");

# fuguseed-words builds on the Fugu library (D-06). Without it, no
# module of the program loads.
plan skip_all => 'the Fugu library is absent'
    unless eval { require Fugu::Log; require Fugu::File; 1 };

require App::FuguSeed::Check;
require App::FuguSeed::ListFile;
require App::FuguSeed::Sheet;
require App::FuguSeed::Words;

use constant FIXTURE => 't/fuguseed/fixtures/sheet.html';
use constant DATE    => '2026-01-01';

# The digest of the source list (LIST-SOURCE-1). The value comes
# from spec/list.md, never from the module under test.
use constant DIGEST =>
    '2f5eed53a4727b4bf8880d8f3f199efc90e58503646d9ff8eff3a2ed3b24dbda';

# _slurp($path):
#	The whole file as text.
sub _slurp ($path)
{
	open my $fh, '<', $path or BAIL_OUT("$path: $!");
	local $/ = undef;
	my $text = <$fh>;
	close $fh or BAIL_OUT("close $path: $!");

	return $text;
}

# LIST-SHARE-2: the three share files resolve through
# Fugu::File->share_path, in this checkout.
my %share;
for my $name (qw(english.txt sheet.html sheet.css)) {
	my $path = App::FuguSeed::Words->share($name);
	ok( defined $path && -f $path, "the share file $name resolves" );
	$share{$name} = $path;
}

# LIST-SHARE-3: the reader proves the digest of the list file.
my $list = App::FuguSeed::ListFile->read( $share{'english.txt'} );
ok( defined $list, 'the reader takes the shipped word list' );
is( $list->{digest}, DIGEST, 'the shipped word list has the pinned digest' );
is( scalar @{ $list->{words} }, 2048, 'the list holds 2048 words' );

my $template = _slurp( $share{'sheet.html'} );
my $style    = _slurp( $share{'sheet.css'} );

# WORDS-BUILD-7: a build of the shipped list on a fixed date equals
# the fixture, and two builds of one list on one date are byte-equal.
my %build = (
	list     => $list,
	template => $template,
	style    => $style,
	date     => DATE
);
my $sheet = App::FuguSeed::Sheet->build(%build);
is( $sheet, _slurp(FIXTURE), 'the build of the shipped list is the fixture' );
is( $sheet, App::FuguSeed::Sheet->build(%build), 'two builds are byte-equal' );

# The date reaches the sheet, so the byte-equality above holds one
# date, not every date.
isnt( $sheet, App::FuguSeed::Sheet->build( %build, date => '2026-01-02' ),
	'another build date gives another sheet' );

# TEST-SHEET-1: the check passes on the built sheet.
my @clean = App::FuguSeed::Check->defects( $sheet, $list, $style );
is( "@clean", q{}, 'the check reports no defect on the built sheet' );

# TEST-SHEET-1: the corrupted sheets. Each row holds a name, the
# corruption of the built sheet, and the defect that the check must
# report. The check runs over each corrupted sheet, and the report
# must hold that defect.
my @corrupt = (
	[
		'a wrong word',
		sub ($text) {
			$text =~ s{<td>able</td>}{<td>ability</td>};
			return $text;
		},
		qr{\AYELLOW 1 BLUE 1 RED 3: the sheet holds ability, and the list holds able\z}
	],
	[
		'a swapped pair',
		sub ($text) {
			$text =~
			    s{<td>about</td><td>above</td>}{<td>above</td><td>about</td>};
			return $text;
		},
		qr{\AYELLOW 1 BLUE 1 RED 4: the sheet holds above, and the list holds about\z}
	],
	[
		'a wrong label',
		sub ($text) {
			$text =~ s{<th>BLUE 7</th>}{<th>BLUE 8</th>};
			return $text;
		},
		qr{\Abyte [0-9]+: the sheet holds "8</th>.*", and the sheet must hold "7</th>"\z}
	],
	[
		'a duplicated block',
		sub ($text) {
			my @table = $text =~ m{(<table>\n.*?</table>\n)}gs;
			my $at    = index $text, $table[3];
			substr $text, $at, length $table[3], $table[2];
			return $text;
		},
		qr{\Abyte [0-9]+: the sheet holds "3</caption>.*", and the sheet must hold "4</caption>.*"\z}
	],
	[
		'an extra attribute',
		sub ($text) {
			$text =~ s{<table>}{<table border="1">};
			return $text;
		},
		qr{\Abyte [0-9]+: the sheet holds " border="1">.*", and the sheet must hold ">.*"\z}
	],
	[
		'a comment',
		sub ($text) {
			$text =~ s{</body>}{<!-- a comment -->\n</body>};
			return $text;
		},
		qr{\Abyte [0-9]+: the sheet holds "!-- a comment --", and the sheet must hold "/body>.*"\z}
	],
	[
		'a script',
		sub ($text) {
			$text =~ s{</body>}{<script>1</script>\n</body>};
			return $text;
		},
		qr{\Abyte [0-9]+: the sheet holds "script>1</script", and the sheet must hold "/body>.*"\z}
	],
	[
		'a soft hyphen',
		sub ($text) {
			$text =~ s{<td>abandon</td>}{<td>aban\xADdon</td>};
			return $text;
		},
		qr{\Abyte [0-9]+: the sheet holds "\\xaddon.*", and the sheet must hold "</td>"\z}
	],
	[
		'a changed style rule',
		sub ($text) {
			$text =~ s{font-size: 7pt;}{font-size: 4pt;};
			return $text;
		},
		qr{\Abyte [0-9]+: the sheet holds "4pt;.*", and the sheet must hold "7pt;.*"\z}
	],
	[
		'a wrong footer digest',
		sub ($text) {
			$text =~ s{2f5eed53}{2f5eed54};
			return $text;
		},
		qr{\Aside 1: the footer names the SHA-256 2f5eed54[0-9a-f]+, and the list file has the SHA-256 @{[DIGEST]}\z}
	],
	[
		'two build dates',
		sub ($text) {
			$text =~ s{(The build date is )2026-01-01(\.</p>\n</footer>\n</section>\n</body>)}{${1}2026-01-02$2};
			return $text;
		},
		qr{\Athe two sides name two build dates\z}
	],
	[
		'a byte after the last one',
		sub ($text) { return $text . "\n"; },
		qr{\Abyte [0-9]+: the sheet holds a byte after the last byte of the grammar\z}
	],
);

for my $case (@corrupt) {
	my ( $name, $corrupt, $defect ) = @{$case};
	my $text = $corrupt->($sheet);
	isnt( $text, $sheet, "$name changes the sheet" );

	my @defects = App::FuguSeed::Check->defects( $text, $list, $style );
	ok( scalar @defects, "the check fails on $name" );
	my @named = grep { $_ =~ $defect } @defects;
	is( scalar @named, 1, "the check names $name" )
	    or diag( join "\n", @defects );
}

# The swapped pair gives one defect for each of the two cells, and
# no duplicate: each word still appears once.
my $swapped = $sheet =~
    s{<td>about</td><td>above</td>}{<td>above</td><td>about</td>}r;
my @two = App::FuguSeed::Check->defects( $swapped, $list, $style );
is( scalar @two, 2, 'a swapped pair gives one defect for each cell' );

# LIST-SHARE-3: the reader refuses a list with another digest. The
# logger goes quiet first, because the refusal reports through it.
Fugu::Log->set_default( Fugu::Log->new( mode => 'quiet' ) );
my $temporary = File::Temp->new;
print {$temporary} "abandon\nability\n"
    or BAIL_OUT('the temporary file takes no text');
$temporary->flush;
is( App::FuguSeed::ListFile->read( $temporary->filename ),
	undef, 'the reader refuses a list with another digest' );
is( App::FuguSeed::ListFile->read('t/fuguseed/no-such-list.txt'),
	undef, 'the reader refuses a list that it cannot read' );

done_testing();
