#!/usr/bin/env perl
# ex:ts=8 sw=4:
# The SeedQR pipeline (TEST-QR). The tests hold the two 12-word test
# vectors of the SeedQR specification to their digit strings, the 44
# codewords and the matrix of test vector 4 to its reference image,
# the two views to their fixture, and the pause between two zone
# views.
#
# The picture fixture is the reference image of test vector 4, module
# for module. That image is mask 0, so it proves the whole pipeline
# (D-08).

use v5.34;
use warnings;
use experimental 'signatures';
no feature qw(indirect multidimensional bareword_filehandles);
use Test::More;
use FindBin qw($RealBin);
use lib "$RealBin/../../lib";
use App::FuguSeed::Codewords ();
use App::FuguSeed::List      ();
use App::FuguSeed::Matrix    ();
use App::FuguSeed::Mnemonic  ();
use App::FuguSeed::QR        ();
use App::FuguSeed::Text      ();

my $root = "$RealBin/../..";
chdir $root or BAIL_OUT("chdir $root: $!");

use constant SIZE    => 25;
use constant ZONE    => 5;
use constant PICTURE => 't/fuguseed/fixtures/qr/vector4.picture';
use constant OUTPUT  => 't/fuguseed/fixtures/qr/vector4.output';

# The two 12-word test vectors of the SeedQR specification, each with
# the digit stream that the specification prints for it.
my %VECTOR = (
	4 => {
		words =>
		    'forum undo fragile fade shy sign arrest garment culture tube off merit',
		digits => '073318950739065415961602009907670428187212261116',
	},
	5 => {
		words =>
		    'good battle boil exact add seed angle hurry success glad carbon whisper',
		digits => '080301540200062600251559007008931730078802752004',
	},
);

# The 44 codewords of test vector 4. The values come from its
# reference image: the image gives 359 data modules, the mask of
# D-08 turns them back into the 352 codeword bits and the 7
# remainder bits (TEST-QR-2).
my @CODEWORDS = (
	16,  192, 73,  79,  187, 107, 140, 65,  103, 252, 25,
	104, 9,   226, 233, 230, 176, 187, 53,  16,  81,  208,
	0,   236, 17,  236, 17,  236, 17,  236, 17,  236, 17,
	236, 243, 81,  156, 126, 138, 234, 192, 191, 241, 213,
);

# The 15 format bits of QR-MATRIX-5, and the two positions of each
# one (Figure 25 of ISO/IEC 18004). The test states them again, so it
# proves the module against the standard and not against itself.
use constant FORMAT => '111011111000100';
my @FORMAT_ONE = (
	[ 8, 0 ], [ 8, 1 ], [ 8, 2 ], [ 8, 3 ], [ 8, 4 ],
	[ 8, 5 ], [ 8, 7 ], [ 8, 8 ], [ 7, 8 ], [ 5, 8 ],
	[ 4, 8 ], [ 3, 8 ], [ 2, 8 ], [ 1, 8 ], [ 0, 8 ],
);
my @FORMAT_TWO = (
	[ 24, 8 ], [ 23, 8 ], [ 22, 8 ], [ 21, 8 ], [ 20, 8 ],
	[ 19, 8 ], [ 18, 8 ], [ 8, 17 ], [ 8, 18 ], [ 8, 19 ],
	[ 8, 20 ], [ 8, 21 ], [ 8, 22 ], [ 8, 23 ], [ 8, 24 ],
);

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

# _words($number):
#	The 12 words of the test vector $number.
sub _words ($number)
{
	return split q{ }, $VECTOR{$number}{words};
}

# _matrix($number):
#	The matrix of the test vector $number.
sub _matrix ($number)
{
	my @words     = _words($number);
	my $digits    = App::FuguSeed::Mnemonic->digits( \@words );
	my @codewords = App::FuguSeed::Codewords->encode($digits);

	return App::FuguSeed::Matrix->build( \@codewords );
}

# _picture($matrix):
#	The matrix as 25 rows of "#" and ".".
sub _picture ($matrix)
{
	return join q{},
	    map { ( join q{}, map { $_ ? '#' : '.' } @{$_} ) . "\n" } @{$matrix};
}

# _function_positions():
#	Every function module of a 25 x 25 code (QR-MATRIX-2): the
#	three finder patterns with their separators, the two timing
#	patterns, the alignment pattern, and the dark module. The
#	test builds the map from the standard.
sub _function_positions ()
{
	my ( %seen, @positions );
	my $add = sub ( $row, $column ) {
		push @positions, [ $row, $column ]
		    unless $seen{"$row,$column"}++;
		return;
	};

	for my $corner ( [ 0, 0 ], [ 0, SIZE - 8 ], [ SIZE - 8, 0 ] ) {
		for my $row ( 0 .. 7 ) {
			for my $column ( 0 .. 7 ) {
				$add->(
					$corner->[0] + $row,
					$corner->[1] + $column
				);
			}
		}
	}
	for my $step ( 8 .. SIZE - 9 ) {
		$add->( 6, $step );
		$add->( $step, 6 );
	}
	for my $row ( 16 .. 20 ) {
		for my $column ( 16 .. 20 ) {
			$add->( $row, $column );
		}
	}
	$add->( 17, 8 );

	return @positions;
}

# TEST-QR-1: the digit strings, the failures, and the check word.
for my $number ( sort keys %VECTOR ) {
	my @words = _words($number);

	my $fault = App::FuguSeed::Mnemonic->fault( \@words );

	is( scalar @words, 12,    "vector $number holds 12 words" );
	is( $fault,        undef, "vector $number passes the word check" );
	is( App::FuguSeed::Mnemonic->digits( \@words ),
		$VECTOR{$number}{digits},
		"vector $number gives its digit string" );
	ok( App::FuguSeed::Mnemonic->valid( \@words ),
		"vector $number holds a valid checksum" );
}

my @vector4 = _words(4);

for my $count ( 0, 11, 13, 24 ) {
	my @words = ( @vector4, @vector4 )[ 0 .. $count - 1 ];
	my $fault = App::FuguSeed::Mnemonic->fault( \@words );
	my @named = grep { $fault =~ /\b\Q$_\E\b/ } @words;

	is( $fault, "the input holds $count words, not 12",
		"a count of $count fails and the message names the count" );
	is( "@named", q{}, "the message of $count names no word" );
}

my $outside = App::FuguSeed::List->index('blorp');
is( $outside, undef, 'the replacement word is outside the list' );

for my $position ( 1, 5, 12 ) {
	my @words = @vector4;
	$words[ $position - 1 ] = 'blorp';
	my $fault = App::FuguSeed::Mnemonic->fault( \@words );
	my @named = grep { $fault =~ /\b\Q$_\E\b/ } @words;

	is( $fault, "word $position is not in the word list",
		"an unknown word at $position fails and the message names it" );
	is( "@named", q{}, "the message of position $position names no word" );
}

# TEST-QR-1: word 12 of each vector is the check word of every word
# of its BLUE row. The row holds 16 words, and the RED column of the
# roll gives the 4 checksum bits (D-05), so one word of the row is
# valid (QR-MNEMONIC-4).
for my $number ( sort keys %VECTOR ) {
	my @words = _words($number);
	my $index = App::FuguSeed::List->index( $words[-1] );
	my $row   = $index - $index % 16;
	my @valid;

	for my $column ( 0 .. 15 ) {
		my @typed = @words;
		$typed[-1] = App::FuguSeed::List->word( $row + $column );
		push @valid, $typed[-1]
		    if App::FuguSeed::Mnemonic->valid( \@typed );
		is( App::FuguSeed::Mnemonic->check_word( \@typed ),
			$words[-1],
			"vector $number: column $column of the row names word 12"
		);
	}

	is_deeply( \@valid, [ $words[-1] ],
		"vector $number: one word of the BLUE row is valid" );
}

# TEST-QR-2: the 44 codewords of test vector 4.
my @codewords =
    App::FuguSeed::Codewords->encode( $VECTOR{4}{digits} );
is( scalar @codewords, 44, 'the encoder gives 44 codewords' );
is_deeply( \@codewords, \@CODEWORDS,
	'the codewords of vector 4 are the codewords of its image' );

# TEST-QR-3: the matrix of test vector 4 against its reference image,
# module for module.
my $matrix4 = _matrix(4);
is( _picture($matrix4), _slurp(PICTURE),
	'the matrix of vector 4 equals its reference image' );

# TEST-QR-4: the function modules and the format bits of both
# matrices.
my @positions = _function_positions();
is( scalar @positions, 236, 'the code holds 236 function modules' );
is( length FORMAT,      15, 'the format information is 15 bits' );

for my $number ( sort keys %VECTOR ) {
	my $matrix = _matrix($number);

	is( scalar @{$matrix}, SIZE, "vector $number gives 25 rows" );
	my @wide = grep { scalar @{$_} != SIZE } @{$matrix};
	is( scalar @wide, 0, "vector $number gives 25 modules in each row" );

	my $dark = grep { $matrix->[ $_->[0] ][ $_->[1] ] } @positions;
	is( $dark, 127, "vector $number holds 127 dark function modules" );

	for my $copy ( \@FORMAT_ONE, \@FORMAT_TWO ) {
		my $format = join q{},
		    map { $matrix->[ $_->[0] ][ $_->[1] ] } @{$copy};
		is( $format, FORMAT,
			"vector $number holds the format bits of a copy" );
	}
}

# TEST-QR-5: the grid view and the zone views against the fixture,
# and each zone count against the matrix.
my ( $digit_line, $rest ) = split /\n/, _slurp(OUTPUT), 2;

# Each zone view starts with one empty line, so the views start at
# the line feed before the name of the first zone.
my ( $grid, $views ) = split /(?=\nA-1\n)/, $rest, 2;

is( $digit_line, $VECTOR{4}{digits},
	'the fixture starts with the digit string' );
is( App::FuguSeed::Text->grid($matrix4),
	$grid, 'the grid view of vector 4 equals its fixture' );

my @zones = App::FuguSeed::Text->zones($matrix4);
is( scalar @zones, 25, 'the matrix gives 25 zone views' );
is( join( q{}, @zones ), $views,
	'the zone views of vector 4 equal their fixture' );

my @names;
my @counts;
for my $band ( 0 .. 4 ) {
	for my $stack ( 0 .. 4 ) {
		my $view = $zones[ $band * 5 + $stack ];
		my ($name)  = $view =~ /^([A-E]-[1-5])$/m;
		my ($count) = $view =~ /^dark ([0-9]+)$/m;
		push @names, $name // q{};

		my $dark = 0;
		for my $line ( 0 .. ZONE - 1 ) {
			$dark += grep { $_ }
			    @{ $matrix4->[ $band * ZONE + $line ] }
			    [ $stack * ZONE .. $stack * ZONE + ZONE - 1 ];
		}
		push @counts, ( $count // -1 ) == $dark ? 1 : 0;
	}
}

is_deeply(
	\@names,
	[ map { my $row = $_; map { "$row-$_" } 1 .. 5 } qw(A B C D E) ],
	'the zone views run from A-1 to E-5'
);
is( scalar( grep { $_ } @counts ), 25,
	'each zone count equals the count in the matrix' );

# The keyboard of the pause below. Each read counts the zone views
# on the screen at that moment, so the counts hold the order of the
# reads and the views. The first read takes the 12 words, before any
# view. Each later read follows one more view (QR-TEXT-5).
package Keyboard {

	sub TIEHANDLE ( $class, $lines, $screen, $reads )
	{
		return bless {
			lines  => $lines,
			screen => $screen,
			reads  => $reads,
		}, $class;
	}

	sub READLINE ($self)
	{
		my @views = ${ $self->{screen} } =~ /^[A-E]-[1-5]$/mg;
		push @{ $self->{reads} }, scalar @views;

		return shift @{ $self->{lines} };
	}
}

# QR-TEXT-5: the program reads one line of standard input between
# two zone views. The input below holds the 12 words, one line for
# each of the 24 pauses, and one line after them. A run leaves that
# last line. A run without the pause reads the 12 words alone, so it
# leaves the 24 pause lines as well.
my $typed =
    [ map {"$_\n"} $VECTOR{4}{words}, ( map {"pause $_"} 1 .. 24 ), 'rest' ];
my $printed = q{};
open my $screen, '>', \$printed or BAIL_OUT("the output handle: $!");
my @reads;
{
	local *STDIN;
	tie *STDIN, 'Keyboard', $typed, \$printed, \@reads;
	local *STDOUT = $screen;
	App::FuguSeed::QR->run();
}
is( join( q{}, @{$typed} ), "rest\n",
	'the program leaves the last line of the input' );
is_deeply( \@reads, [ 0 .. 24 ],
	'one read of standard input sits between two zone views' );

done_testing();
