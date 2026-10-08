#!/usr/bin/env perl
# ex:ts=8 sw=4:
# The program fuguseed-last (LAST-PROGRAM, LAST-WORD, TEST-LAST,
# SEC-CHANNELS). The tests run bin/fuguseed-last as a child, and they
# hold each of the three streams and the exit code. They hold the
# check word of three vectors, the rows of the 128 face pairs, and
# each failure line to its exact text. t/fuguseed/trust.t holds the
# module set of the program, and it scans each source (SEC-TRUST-3).

use v5.34;
use warnings;
use experimental 'signatures';
no feature qw(indirect multidimensional bareword_filehandles);
use Test::More;
use IPC::Open3 qw(open3);
use Symbol     qw(gensym);
use FindBin    qw($RealBin);
use lib "$RealBin/../../lib";
use App::FuguSeed::Last ();
use App::FuguSeed::List ();
use App::FuguSeed::QR   ();

my $root = "$RealBin/../..";
chdir $root or BAIL_OUT("chdir $root: $!");

use constant PROGRAM => 'bin/fuguseed-last';

# The three vectors of TEST-LAST-1: words 1 to 11, the YELLOW face
# and the BLUE face of word 12, and word 12. The faces come from the
# index of word 12 and D-05: "merit" is index 1116, "whisper" is 2004,
# and "about" is 3. The vectors are the two 12-word test vectors of
# the SeedQR specification and the first vector of BIP39.
my @VECTOR = (
	[
		'forum undo fragile fade shy sign arrest garment culture tube off',
		'5 6', 'merit'
	],
	[
		'good battle boil exact add seed angle hurry success glad carbon',
		'8 14', 'whisper'
	],
	[ join( q{ }, ('abandon') x 11 ), '1 1', 'about' ],
);

# The child gets no PERL5LIB and no PERL5OPT of this environment, so
# no module comes from outside this checkout.
delete local @ENV{qw(PERL5LIB PERL5OPT)};

# _run($input, @argument):
#	Run the program with $input on standard input. The result is
#	the standard output, the standard error, and the exit code.
sub _run ( $input, @argument )
{
	local $SIG{PIPE} = 'IGNORE';
	my $fault = gensym;
	my $pid = open3( my $in, my $out, $fault, $^X, '-Ilib', PROGRAM,
		@argument );

	print {$in} $input or BAIL_OUT('the child takes no input');
	close $in;

	local $/ = undef;
	my $output = <$out>;
	my $error  = <$fault>;
	waitpid $pid, 0;
	my $status = $? >> 8;
	close $out;
	close $fault;

	return ( $output // q{}, $error // q{}, $status );
}

# _fails($input, $line, $name):
#	The program fails on $input with the exact failure line $line
#	(LAST-PROGRAM-4). The exact text proves that the line holds
#	no word and no face of the input (SEC-CHANNELS-2).
sub _fails ( $input, $line, $name )
{
	my ( $output, $error, $status ) = _run($input);

	return is_deeply(
		[ $output, $error, $status ],
		[ q{}, "fuguseed-last: $line\n", 1 ], $name
	);
}

# TEST-LAST-1: the check word of each vector, on standard output.
for my $vector (@VECTOR) {
	my ( $words, $faces, $last ) = @{$vector};
	my ( $output, $error, $status ) = _run("$words\n$faces\n");

	is_deeply(
		[ $output, $error, $status ],
		[ "$last\n", q{}, 0 ],
		"the faces $faces give the check word $last"
	);
}

# LAST-PROGRAM-2: an argument is a usage error (D-12).
my ( $none, $usage, $code ) = _run( q{}, 'merit' );
is_deeply(
	[ $none, $usage, $code ],
	[ q{}, "usage: fuguseed-last\n", 2 ],
	'an argument gives one usage line and exits 2'
);

# TEST-LAST-2: the face check accepts each of the 128 face pairs. Each
# pair gives a word of its row, and the 11 words and that word pass
# the checksum of fuguseed-qr.
my @eleven = split q{ }, $VECTOR[0][0];
my @wrong;
for my $yellow ( 1 .. 8 ) {
	for my $blue ( 1 .. 16 ) {
		my $word =
		    App::FuguSeed::Last->check_word( \@eleven, $yellow, $blue );
		my $index = App::FuguSeed::List->index($word) // -1;
		my $row   = ( $yellow - 1 ) * 256 + ( $blue - 1 ) * 16;

		push @wrong, "$yellow $blue"
		    if defined App::FuguSeed::Last->fault( [ "$yellow", "$blue" ] )
		    || $index < $row
		    || $index >= $row + 16
		    || !App::FuguSeed::QR->valid( [ @eleven, $word ] );
	}
}
is( "@wrong", q{},
	'each face pair passes the face check and gives the valid word of its row'
);

# TEST-LAST-2: the program accepts the highest faces, 8 and 16. "zone"
# is index 2046, in YELLOW block 8 and BLUE row 16.
my ( $edge, $calm, $exit ) = _run("$VECTOR[0][0]\n8 16\n");
is_deeply(
	[ $edge, $calm, $exit ],
	[ "zone\n", q{}, 0 ],
	'the faces 8 16 give the check word zone'
);

# TEST-LAST-3: a wrong count and an unknown word (LAST-WORD-1).
my $faces = $VECTOR[0][1];
for my $count ( 0, 10, 12 ) {
	my @words = ( @eleven, @eleven )[ 0 .. $count - 1 ];
	_fails( "@words\n$faces\n", "the input holds $count words, not 11",
		"a count of $count fails" );
}

is( App::FuguSeed::List->index('blorp'),
	undef, 'the replacement word is outside the list' );
for my $position ( 1, 5, 11 ) {
	my @words = @eleven;
	$words[ $position - 1 ] = 'blorp';
	_fails( "@words\n$faces\n", "word $position is not in the word list",
		"an unknown word at $position fails" );
}

# TEST-LAST-3: a missing second line, and a missing or an extra field
# (LAST-WORD-2).
_fails( "$VECTOR[0][0]\n", 'the second line holds 0 fields, not 2',
	'a missing second line fails' );
for my $case ( [ '5', 1 ], [ '5 6 7', 3 ], [ '5 6 merit', 3 ] ) {
	my ( $line, $count ) = @{$case};
	_fails( "$VECTOR[0][0]\n$line\n",
		"the second line holds $count fields, not 2",
		"the fields '$line' fail" );
}

# TEST-LAST-3: each bad face (LAST-WORD-2). A face outside its range,
# a leading zero, a sign, and a form that is not a decimal number
# fail. The failure line names the die.
for my $yellow ( '0', '9', '08', '+8', '-1', '1.0', '0x1', 'one' ) {
	_fails( "$VECTOR[0][0]\n$yellow 6\n", 'the YELLOW face is not 1 to 8',
		"the YELLOW face '$yellow' fails" );
}
for my $blue ( '0', '17', '06', '+6', '-6', '6.0', '1e1', 'six' ) {
	_fails( "$VECTOR[0][0]\n5 $blue\n", 'the BLUE face is not 1 to 16',
		"the BLUE face '$blue' fails" );
}

# LAST-PROGRAM-3: the whitespace rule of QR-PROGRAM-3. A run of
# spaces and tabs separates two fields, and the program ignores them
# at the start and at the end of each line.
( my $tabbed = $VECTOR[0][0] ) =~ tr/ /\t/;
my ( $spaced, $quiet, $status ) = _run(" \t$tabbed \t\n\t 5 \t 6 \t\n");
is_deeply(
	[ $spaced, $quiet, $status ],
	[ "merit\n", q{}, 0 ],
	'runs of spaces and tabs separate the fields of each line'
);

done_testing();
