#!perl -T

use Algorithm::NeedlemanWunsch;
use Test::More tests => 38;

# sequences & scoring from
# http://www.ludwig.edu.au/course/lectures2005/Likic.pdf

sub simple_scheme {
    if (!@_) {
        return 0;
    }

    return ($_[0] eq $_[1]) ? 1 : -1;
}

sub evo_scheme {
    if (!@_) {
        return 0;
    }

    my ($a, $b) = @_;

    if ($a eq $b) {
        return 2;
    }

    my $au = ($a eq 'A') || ($a eq 'G');
    my $bu = ($b eq 'A') || ($b eq 'G');
    return (($au && $bu) || (!$au && !$bu)) ? 1 : -1;
}

my @a = qw(A T G G C G T);
my @b = qw(A T G A G T);

sub prepend_align {
    my ($i, $j) = @_;

    unshift @alignment, [$a[$i], $b[$j]];
}

sub prepend_first_only {
    my $i = shift;

    unshift @alignment, [$a[$i], undef];
}

sub prepend_second_only {
    my $j = shift;

    unshift @alignment, [undef, $b[$j]];
}

my $simple = Algorithm::NeedlemanWunsch->new(\&simple_scheme);

@alignment = ();
my $score = $simple->align(\@a, \@b,
			   {
			    align => \&prepend_align,
			    shift_a => \&prepend_first_only,
			    shift_b => \&prepend_second_only
			   });
my $expected = [ [ 'A', 'A' ], [ 'T', 'T' ], [ 'G', 'G' ], [ undef, 'A' ],
	    [ 'G', undef ], [ 'C', undef ], [ 'G', 'G' ], [ 'T', 'T' ] ];
is($score, 5);
is_deeply(\@alignment, $expected);

$simple->local(1);
@alignment = ();
$score = $simple->align(\@a, \@b,
			{
			 align => \&prepend_align,
			 shift_a => \&prepend_first_only,
			 shift_b => \&prepend_second_only
			});
is($score, 5);
is_deeply(\@alignment, $expected);

$simple = Algorithm::NeedlemanWunsch->new(\&simple_scheme, -5);

@alignment = ();
$score = $simple->align(\@a, \@b,
			   {
			    align => \&prepend_align,
			    shift_a => \&prepend_first_only,
			    shift_b => \&prepend_second_only
			   });
is($score, -1);
is_deeply(\@alignment,
	  [ [ 'A', 'A' ], [ 'T', 'T' ], [ 'G', undef ], [ 'G', 'G' ],
	    [ 'C', 'A' ], [ 'G', 'G' ], [ 'T', 'T' ] ]);

$simple->local(1);
@alignment = ();
$score = $simple->align(\@a, \@b,
			   {
			    align => \&prepend_align,
			    shift_a => \&prepend_first_only,
			    shift_b => \&prepend_second_only
			   });
is($score, 0);
is_deeply(\@alignment,
	  [ [ 'A', undef ], [ 'T', 'A' ], [ 'G', 'T' ], [ 'G', 'G' ],
	    [ 'C', 'A' ], [ 'G', 'G' ], [ 'T', 'T' ] ]);

sub postpone_gap {
    my $arg = shift;

    if (exists($arg->{shift_a})) {
        prepend_first_only($arg->{shift_a});
	return 'shift_a';
    } elsif (exists($arg->{shift_b})) {
        prepend_second_only($arg->{shift_b});
	return 'shift_b';
    } else {
        prepend_align(@{$arg->{align}});
	return 'align';
    }
}

$simple->local(0);

@alignment = ();
$score = $simple->align(\@a, \@b,
			   {
			    align => \&prepend_align,
			    shift_a => \&prepend_first_only,
			    shift_b => \&prepend_second_only,
			    select_align => \&postpone_gap
			   });
is($score, -1);
is_deeply(\@alignment,
	  [ [ 'A', 'A' ], [ 'T', 'T' ], [ 'G', 'G' ], [ 'G', 'A' ],
	    [ 'C', undef ], [ 'G', 'G' ], [ 'T', 'T' ] ]);

$simple->local(1);

@alignment = ();
$score = $simple->align(\@a, \@b,
			   {
			    align => \&prepend_align,
			    shift_a => \&prepend_first_only,
			    shift_b => \&prepend_second_only,
			    select_align => \&postpone_gap
			   });
is($score, 0);
is_deeply(\@alignment,
	  [ [ 'A', 'A' ], [ 'T', 'T' ], [ 'G', 'G' ], [ 'G', 'A' ],
	    [ 'C', 'G' ], [ 'G', 'T' ], [ 'T', undef ] ]);

my $evo = Algorithm::NeedlemanWunsch->new(\&evo_scheme);

@alignment = ();
$score = $evo->align(\@a, \@b,
			   {
			    align => \&prepend_align,
			    shift_a => \&prepend_first_only,
			    shift_b => \&prepend_second_only
			   });
is($score, 11);
$expected = [ [ 'A', 'A' ], [ 'T', 'T' ], [ 'G', 'G' ], [ 'G', 'A' ],
	    [ 'C', undef ], [ 'G', 'G' ], [ 'T', 'T' ] ];
is_deeply(\@alignment, $expected);

$evo->local(1);
@alignment = ();
$score = $evo->align(\@a, \@b,
			   {
			    align => \&prepend_align,
			    shift_a => \&prepend_first_only,
			    shift_b => \&prepend_second_only
			   });
is($score, 11);
is_deeply(\@alignment,, $expected);

# sequences & scoring from
# http://sedefcho.icnhost.net/web/algorithms/needleman_wunsch.html

my $index = { A => 0, G => 1, C => 2, T => 3 };
my $matrix = [ ];
push @$matrix, [ qw(10 -1 -3 -4) ];
push @$matrix, [ qw(-1 7 -5 -3) ];
push @$matrix, [ qw(-3 -5 9 0) ];
push @$matrix, [ qw(-4 -3 0 8) ];

sub fine_scheme {
    if (!@_) {
        return -5;
    }

    my ($a, $b) = @_;
    return $matrix->[$index->{$a}]->[$index->{$b}];
}

my $oa;
my $ob;

sub prepend_align2 {
    my ($i, $j) = @_;

    $oa = $a[$i] . $oa;
    $ob = $b[$j] . $ob;
}

sub prepend_first_only2 {
    my $i = shift;

    $oa = $a[$i] . $oa;
    $ob = "-$ob";
}

sub prepend_second_only2 {
    my $j = shift;

    $oa = "-$oa";
    $ob = $b[$j] . $ob;
}

$evo = Algorithm::NeedlemanWunsch->new(\&fine_scheme);

$oa = '';
$ob = '';
@a = qw(A G A C T A G T T A C);
@b = qw(C G A G A C G T);
$score = $evo->align(\@a, \@b,
			   {
			    align => \&prepend_align2,
			    shift_a => \&prepend_first_only2,
			    shift_b => \&prepend_second_only2
			   });
is($score, 16);
is($oa, '--AGACTAGTTAC');
is($ob, 'CGAGAC--G-T--');

$evo->local(1);
$oa = '';
$ob = '';
$score = $evo->align(\@a, \@b,
			   {
			    align => \&prepend_align2,
			    shift_a => \&prepend_first_only2,
			    shift_b => \&prepend_second_only2
			   });
is($score, 31);
is($oa, '--AGACTAGTTAC');
is($ob, 'CGAGAC--GT---');

$evo->local(0);

sub select_align2 {
    my $arg = shift;

    if (exists($arg->{align})) {
        prepend_align2(@{$arg->{align}});
	return 'align';
    } elsif (exists($arg->{shift_a})) {
        prepend_first_only2($arg->{shift_a});
	return 'shift_a';
    } else {
        prepend_second_only2($arg->{shift_b});
	return 'shift_b';
    }
}

$oa = '';
$ob = '';
@a = qw(A A G T A G A G);
@b = qw(T A C C G A T A T T A T);
$score = $evo->align(\@a, \@b, { select_align => \&select_align2 });
is($score, 16);
is($oa, '-A-AG-TA-GAG');
is($ob, 'TACCGATATTAT');

$score = $evo->align(\@a, \@b, { });
is($score, 16);

$oa = '';
$ob = '';
@a = qw(T A G C A C A C A A C);
@b = qw(A C G T A C G C G A C T A G T C);
$score = $evo->align(\@a, \@b,
			   {
			    align => \&prepend_align2,
			    shift_a => \&prepend_first_only2,
			    shift_b => \&prepend_second_only2
			   });
is($score, 38);
is($oa, 'TA-GCA--C-AC-AA-C');
is($ob, '-ACGTACGCGACTAGTC');

$oa = '';
$ob = '';
$evo->local(1);
$score = $evo->align(\@a, \@b,
			   {
			    align => \&prepend_align2,
			    shift_a => \&prepend_first_only2,
			    shift_b => \&prepend_second_only2
			   });
is($score, 43);
is($oa, 'TA-GCA--C-AC-AA-C');
is($ob, '-ACGTACGCGACTAGTC');
$evo->local(0);

$oa = '';
$ob = '';
@a = qw(A A G G A T A T A T G C);
@b = qw(T A C C G C T A);
$score = $evo->align(\@a, \@b,
			   {
			    align => \&prepend_align2,
			    shift_a => \&prepend_first_only2,
			    shift_b => \&prepend_second_only2
			   });
is($score, -3);
is($oa, '-AAGGATATATGC');
is($ob, 'TACCG-C-TA---');

$oa = '';
$ob = '';
@a = qw(G C C T A T G C C T);
@b = qw(A G T C T A G C T G A T A T T G);
$score = $evo->align(\@a, \@b,
			   {
			    align => \&prepend_align2,
			    shift_a => \&prepend_first_only2,
			    shift_b => \&prepend_second_only2
			   });
is($score, 27);
is($oa, '-GCCTA--TG-C-CT-');
is($ob, 'AGTCTAGCTGATATTG');

