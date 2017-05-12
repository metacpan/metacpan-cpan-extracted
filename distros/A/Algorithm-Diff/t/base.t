# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl base.t'
use strict;
$^W++;
use lib qw(blib lib);
use Algorithm::Diff qw(diff LCS traverse_sequences traverse_balanced sdiff);
use Data::Dumper;
use Test;

BEGIN
{
	$|++;
	plan tests => 35;
	$SIG{__DIE__} = sub # breakpoint on die
	{
		$DB::single = 1;
		$DB::single = 1;	# avoid complaint
		die @_;
	}
}

my @a = qw(a b c e h j l m n p);
my @b = qw(b c d e f j k l m r s t);
my @correctResult = qw(b c e j l m);
my $correctResult = join(' ', @correctResult);
my $skippedA = 'a h n p';
my $skippedB = 'd f k r s t';

# From the Algorithm::Diff manpage:
my $correctDiffResult = [
	[ [ '-', 0, 'a' ] ],

	[ [ '+', 2, 'd' ] ],

	[ [ '-', 4, 'h' ], [ '+', 4, 'f' ] ],

	[ [ '+', 6, 'k' ] ],

	[
		[ '-', 8,  'n' ], 
		[ '+', 9,  'r' ], 
		[ '-', 9,  'p' ],
		[ '+', 10, 's' ],
		[ '+', 11, 't' ],
	]
];

# Result of LCS must be as long as @a
my @result = Algorithm::Diff::_longestCommonSubsequence( \@a, \@b );
ok( scalar(grep { defined } @result),
	scalar(@correctResult),
	"length of _longestCommonSubsequence" );

# result has b[] line#s keyed by a[] line#
# print "result =", join(" ", map { defined($_) ? $_ : 'undef' } @result), "\n";

my @aresult = map { defined( $result[$_] ) ? $a[$_] : () } 0 .. $#result;
my @bresult =
  map { defined( $result[$_] ) ? $b[ $result[$_] ] : () } 0 .. $#result;

ok( "@aresult", $correctResult, "A results" );
ok( "@bresult", $correctResult, "B results" );

my ( @matchedA, @matchedB, @discardsA, @discardsB, $finishedA, $finishedB );

sub match
{
	my ( $a, $b ) = @_;
	push ( @matchedA, $a[$a] );
	push ( @matchedB, $b[$b] );
}

sub discard_b
{
	my ( $a, $b ) = @_;
	push ( @discardsB, $b[$b] );
}

sub discard_a
{
	my ( $a, $b ) = @_;
	push ( @discardsA, $a[$a] );
}

sub finished_a
{
	my ( $a, $b ) = @_;
	$finishedA = $a;
}

sub finished_b
{
	my ( $a, $b ) = @_;
	$finishedB = $b;
}

traverse_sequences(
	\@a,
	\@b,
	{
		MATCH     => \&match,
		DISCARD_A => \&discard_a,
		DISCARD_B => \&discard_b
	}
);

ok( "@matchedA", $correctResult);
ok( "@matchedB", $correctResult);
ok( "@discardsA", $skippedA);
ok( "@discardsB", $skippedB);

@matchedA = @matchedB = @discardsA = @discardsB = ();
$finishedA = $finishedB = undef;

traverse_sequences(
	\@a,
	\@b,
	{
		MATCH      => \&match,
		DISCARD_A  => \&discard_a,
		DISCARD_B  => \&discard_b,
		A_FINISHED => \&finished_a,
		B_FINISHED => \&finished_b,
	}
);

ok( "@matchedA", $correctResult);
ok( "@matchedB", $correctResult);
ok( "@discardsA", $skippedA);
ok( "@discardsB", $skippedB);
ok( $finishedA, 9, "index of finishedA" );
ok( $finishedB, undef, "index of finishedB" );

my @lcs = LCS( \@a, \@b );
ok( "@lcs", $correctResult );

# Compare the diff output with the one from the Algorithm::Diff manpage.
my $diff = diff( \@a, \@b );
$Data::Dumper::Indent = 0;
my $cds = Dumper($correctDiffResult);
my $dds = Dumper($diff);
ok( $dds, $cds );

##################################################
# <Mike Schilli> m@perlmeister.com 03/23/2002: 
# Tests for sdiff-interface
#################################################

@a = qw(abc def yyy xxx ghi jkl);
@b = qw(abc dxf xxx ghi jkl);
$correctDiffResult = [ ['u', 'abc', 'abc'],
                       ['c', 'def', 'dxf'],
                       ['-', 'yyy', ''],
                       ['u', 'xxx', 'xxx'],
                       ['u', 'ghi', 'ghi'],
                       ['u', 'jkl', 'jkl'] ];
@result = sdiff(\@a, \@b);
ok(Dumper(\@result), Dumper($correctDiffResult));


#################################################
@a = qw(a b c e h j l m n p);
@b = qw(b c d e f j k l m r s t);
$correctDiffResult = [ ['-', 'a', '' ],
                       ['u', 'b', 'b'],
                       ['u', 'c', 'c'],
                       ['+', '',  'd'],
                       ['u', 'e', 'e'],
                       ['c', 'h', 'f'],
                       ['u', 'j', 'j'],
                       ['+', '',  'k'],
                       ['u', 'l', 'l'],
                       ['u', 'm', 'm'],
                       ['c', 'n', 'r'],
                       ['c', 'p', 's'],
                       ['+', '',  't'],
                     ];
@result = sdiff(\@a, \@b);
ok(Dumper(\@result), Dumper($correctDiffResult));

#################################################
@a = qw(a b c d e);
@b = qw(a e);
$correctDiffResult = [ ['u', 'a', 'a' ],
                       ['-', 'b', ''],
                       ['-', 'c', ''],
                       ['-', 'd', ''],
                       ['u', 'e', 'e'],
                     ];
@result = sdiff(\@a, \@b);
ok(Dumper(\@result), Dumper($correctDiffResult));

#################################################
@a = qw(a e);
@b = qw(a b c d e);
$correctDiffResult = [ ['u', 'a', 'a' ],
                       ['+', '', 'b'],
                       ['+', '', 'c'],
                       ['+', '', 'd'],
                       ['u', 'e', 'e'],
                     ];
@result = sdiff(\@a, \@b);
ok(Dumper(\@result), Dumper($correctDiffResult));

#################################################
@a = qw(v x a e);
@b = qw(w y a b c d e);
$correctDiffResult = [ 
                       ['c', 'v', 'w' ],
                       ['c', 'x', 'y' ],
                       ['u', 'a', 'a' ],
                       ['+', '', 'b'],
                       ['+', '', 'c'],
                       ['+', '', 'd'],
                       ['u', 'e', 'e'],
                     ];
@result = sdiff(\@a, \@b);
ok(Dumper(\@result), Dumper($correctDiffResult));

#################################################
@a = qw(x a e);
@b = qw(a b c d e);
$correctDiffResult = [ 
                       ['-', 'x', '' ],
                       ['u', 'a', 'a' ],
                       ['+', '', 'b'],
                       ['+', '', 'c'],
                       ['+', '', 'd'],
                       ['u', 'e', 'e'],
                     ];
@result = sdiff(\@a, \@b);
ok(Dumper(\@result), Dumper($correctDiffResult));

#################################################
@a = qw(a e);
@b = qw(x a b c d e);
$correctDiffResult = [ 
                       ['+', '', 'x' ],
                       ['u', 'a', 'a' ],
                       ['+', '', 'b'],
                       ['+', '', 'c'],
                       ['+', '', 'd'],
                       ['u', 'e', 'e'],
                     ];
@result = sdiff(\@a, \@b);
ok(Dumper(\@result), Dumper($correctDiffResult));

#################################################
@a = qw(a e v);
@b = qw(x a b c d e w x);
$correctDiffResult = [ 
                       ['+', '', 'x' ],
                       ['u', 'a', 'a' ],
                       ['+', '', 'b'],
                       ['+', '', 'c'],
                       ['+', '', 'd'],
                       ['u', 'e', 'e'],
                       ['c', 'v', 'w'],
                       ['+', '',  'x'],
                     ];
@result = sdiff(\@a, \@b);
ok(Dumper(\@result), Dumper($correctDiffResult));

#################################################
@a = qw();
@b = qw(a b c);
$correctDiffResult = [ 
                       ['+', '', 'a' ],
                       ['+', '', 'b' ],
                       ['+', '', 'c' ],
                     ];
@result = sdiff(\@a, \@b);
ok(Dumper(\@result), Dumper($correctDiffResult));

#################################################
@a = qw(a b c);
@b = qw();
$correctDiffResult = [ 
                       ['-', 'a', '' ],
                       ['-', 'b', '' ],
                       ['-', 'c', '' ],
                     ];
@result = sdiff(\@a, \@b);
ok(Dumper(\@result), Dumper($correctDiffResult));

#################################################
@a = qw(a b c);
@b = qw(1);
$correctDiffResult = [ 
                       ['c', 'a', '1' ],
                       ['-', 'b', '' ],
                       ['-', 'c', '' ],
                     ];
@result = sdiff(\@a, \@b);
ok(Dumper(\@result), Dumper($correctDiffResult));

#################################################
@a = qw(a b c);
@b = qw(c);
$correctDiffResult = [ 
                       ['-', 'a', '' ],
                       ['-', 'b', '' ],
                       ['u', 'c', 'c' ],
                     ];
@result = sdiff(\@a, \@b);
ok(Dumper(\@result), Dumper($correctDiffResult));

#################################################
@a = qw(a b c);
@b = qw(a x c);
my $r = "";
traverse_balanced( \@a, \@b, 
                   { MATCH     => sub { $r .= "M @_";},
                     DISCARD_A => sub { $r .= "DA @_";},
                     DISCARD_B => sub { $r .= "DB @_";},
                     CHANGE    => sub { $r .= "C @_";},
                   } );
ok($r, "M 0 0C 1 1M 2 2");

#################################################
# No CHANGE callback => use discard_a/b instead
@a = qw(a b c);
@b = qw(a x c);
$r = "";
traverse_balanced( \@a, \@b, 
                   { MATCH     => sub { $r .= "M @_";},
                     DISCARD_A => sub { $r .= "DA @_";},
                     DISCARD_B => sub { $r .= "DB @_";},
                   } );
ok($r, "M 0 0DA 1 1DB 2 1M 2 2");

#################################################
@a = qw(a x y c);
@b = qw(a v w c);
$r = "";
traverse_balanced( \@a, \@b, 
                   { MATCH     => sub { $r .= "M @_";},
                     DISCARD_A => sub { $r .= "DA @_";},
                     DISCARD_B => sub { $r .= "DB @_";},
                     CHANGE    => sub { $r .= "C @_";},
                   } );
ok($r, "M 0 0C 1 1C 2 2M 3 3");

#################################################
@a = qw(x y c);
@b = qw(v w c);
$r = "";
traverse_balanced( \@a, \@b, 
                   { MATCH     => sub { $r .= "M @_";},
                     DISCARD_A => sub { $r .= "DA @_";},
                     DISCARD_B => sub { $r .= "DB @_";},
                     CHANGE    => sub { $r .= "C @_";},
                   } );
ok($r, "C 0 0C 1 1M 2 2");

#################################################
@a = qw(a x y z);
@b = qw(b v w);
$r = "";
traverse_balanced( \@a, \@b, 
                   { MATCH     => sub { $r .= "M @_";},
                     DISCARD_A => sub { $r .= "DA @_";},
                     DISCARD_B => sub { $r .= "DB @_";},
                     CHANGE    => sub { $r .= "C @_";},
                   } );
ok($r, "C 0 0C 1 1C 2 2DA 3 3");

#################################################
@a = qw(a z);
@b = qw(a);
$r = "";
traverse_balanced( \@a, \@b, 
                   { MATCH     => sub { $r .= "M @_";},
                     DISCARD_A => sub { $r .= "DA @_";},
                     DISCARD_B => sub { $r .= "DB @_";},
                     CHANGE    => sub { $r .= "C @_";},
                   } );
ok($r, "M 0 0DA 1 1");

#################################################
@a = qw(z a);
@b = qw(a);
$r = "";
traverse_balanced( \@a, \@b, 
                   { MATCH     => sub { $r .= "M @_";},
                     DISCARD_A => sub { $r .= "DA @_";},
                     DISCARD_B => sub { $r .= "DB @_";},
                     CHANGE    => sub { $r .= "C @_";},
                   } );
ok($r, "DA 0 0M 1 0");

#################################################
@a = qw(a b c);
@b = qw(x y z);
$r = "";
traverse_balanced( \@a, \@b, 
                   { MATCH     => sub { $r .= "M @_";},
                     DISCARD_A => sub { $r .= "DA @_";},
                     DISCARD_B => sub { $r .= "DB @_";},
                     CHANGE    => sub { $r .= "C @_";},
                   } );
ok($r, "C 0 0C 1 1C 2 2");
