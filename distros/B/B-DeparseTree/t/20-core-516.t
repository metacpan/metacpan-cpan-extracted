#!./perl

# Test the core keywords.
#
# Initially this test file just checked that CORE::foo got correctly
# deparsed as CORE::foo, hence the name. It's since been expanded
# to fully test both CORE:: verses none, plus that any arguments
# are correctly deparsed. It also cross-checks against regen/keywords.pl
# to make sure we've tested all keywords, and with the correct strength.
#
# A keyword can be either weak or strong. Strong keywords can never be
# overridden, while weak ones can. So deparsing of weak keywords depends
# on whether a sub of that name has been created:
#
# for both:         keyword(..) deparsed as keyword(..)
# for weak:   CORE::keyword(..) deparsed as CORE::keyword(..)
# for strong: CORE::keyword(..) deparsed as keyword(..)
#
# Three permutations of lex/nonlex args are checked for:
#
#   foo($a,$b,$c,...)
#   foo(my $a,$b,$c,...)
#   my ($a,$b,$c,...); foo($a,$b,$c,...)
#
# Note that tests for prefixing feature.pm-enabled keywords with CORE:: when
# feature.pm is not enabled are in deparse.t, as they fit that format better.

use rlib '.';
use helper;

BEGIN {
    use Test::More;
    if ($] < 5.016 || $] > 5.0169) {
	plan skip_all => 'Customized to Perl 5.16 interpreter';
    }
}

use strict;
use English;


use feature (sprintf(":%vd", $^V)); # to avoid relying on the feature
                                    # logic to add CORE::

# for a given keyword, create a sub of that name, then
# deparse "() = $expr", and see if it matches $expected_expr

sub testit {
    my ($keyword, $expr, $expected_expr) = @_;

    $expected_expr //= $expr;
    $SEEN{$keyword} = 1;


    # lex=0:   () = foo($a,$b,$c)
    # lex=1:   my ($a,$b); () = foo($a,$b,$c)
    # lex=2:   () = foo(my $a,$b,$c)
    #for my $lex (0, 1, 2) {
    for my $lex (0, 1) {
	if ($lex) {
	    next if $keyword =~ /local|our|state|my/;
	}
	my $vars = $lex == 1 ? 'my($a, $b, $c, $d, $e);' . "\n    " : "";

	if ($lex == 2) {
	    my $repl = 'my $a';
	    if ($expr =~ /\bmap\(\$a|CORE::(chomp|chop|lstat|stat)\b/) {
		# for some reason only these do:
		#  'foo my $a, $b,' => foo my($a), $b, ...
		#  the rest don't parenthesize the my var.
		$repl = 'my($a)';
	    }
	    s/\$a/$repl/ for $expr, $expected_expr;
	}

	my $desc = "$keyword: lex=$lex $expr => $expected_expr";


	my $code_ref;
	{
	    package test;
	    use subs ();
	    import subs $keyword;
	    $code_ref = eval "no strict 'vars'; sub { ${vars}() = $expr }"
			    or die "$@ in $expr";
	}

	my $got_text = $deparse->coderef2text($code_ref);

	unless ($got_text =~ /^{
    package test;
    use strict 'refs', 'subs';
    use feature [^\n]+
    \Q$vars\E\(\) = (.*)
}/s) {
	    ::fail($desc);
	    ::diag("couldn't extract line from boilerplate\n");
	    ::diag($got_text);
	    return;
	}

	my $got_expr = $1;
	is $got_expr, $expected_expr, $desc;
    }
}

# test a keyword that is a binary infix operator, like 'cmp'.
# $parens - "$a op $b" is deparsed as "($a op $b)"
# $strong - keyword is strong

sub do_infix_keyword {
    my ($keyword, $parens, $strong) = @_;
    $SEEN_STRENGTH{$keyword} = $strong;
    my $expr = "(\$a $keyword \$b)";
    my $nkey = $infix_map{$keyword} // $keyword;
    my $exp = "\$a $nkey \$b";
    $exp = "($exp)" if $parens;
    $exp .= ";";
    # with infix notation, a keyword is always interpreted as core,
    # so no need for Deparse to disambiguate with CORE::
    testit $keyword, "(\$a CORE::$keyword \$b)", $exp;
    testit $keyword, "(\$a $keyword \$b)", $exp;
    if (!$strong) {
	testit $keyword, "$keyword(\$a, \$b)", "$keyword(\$a, \$b);";
    }
}

# test a keyword that is as tandard op/function, like 'index(...)'.
# narg    - how many args to test it with
# $parens - "foo $a, $b" is deparsed as "foo($a, $b)"
# $dollar - an extra '$_' arg will appear in the deparsed output
# $strong - keyword is strong


sub do_std_keyword {
    my ($keyword, $narg, $parens, $dollar, $strong) = @_;

    $SEEN_STRENGTH{$keyword} = $strong;

    for my $core (0,1) { # if true, add CORE:: to keyword being deparsed
	my @code;
	for my $do_exp(0, 1) { # first create expr, then expected-expr
	    my @args = map "\$$_", (undef,"a".."z")[1..$narg];
	    push @args, '$_' if $dollar && $do_exp && ($strong || $core);
	    my $args = join(', ', @args);
	    $args = ((!$core && !$strong) || $parens)
			? "($args)"
			:  @args ? " $args" : "";
	    push @code, (($core && !($do_exp && $strong)) ? "CORE::" : "")
						       	. "$keyword$args;";
	}
	testit $keyword, @code; # code[0]: to run; code[1]: expected
    }
}


my $data_fh = open_data('P516-core.pm');

while (<$data_fh>) {
    chomp;
    s/#.*//;
    next unless /\S/;

    my @fields = split;
    die "not 3 fields" unless @fields == 3;
    my ($keyword, $args, $flags) = @fields;

    $args = '012' if $args eq '@';

    my $parens  = $flags =~ s/p//;
    my $invert1 = $flags =~ s/1//;
    my $dollar  = $flags =~ s/\$//;
    my $strong  = $flags =~ s/\+//;
    die "unrecognized flag(s): '$flags'" unless $flags =~ /^-?$/;

    if ($args eq 'B') { # binary infix
	die "$keyword: binary (B) op can't have '\$' flag\\n" if $dollar;
	die "$keyword: binary (B) op can't have '1' flag\\n" if $invert1;
	do_infix_keyword($keyword, $parens, $strong);
    }
    else {
	my @narg = split //, $args;
	for my $n (0..$#narg) {
	    my $narg = $narg[$n];
	    my $p = $parens;
	    $p = !$p if ($n == 0 && $invert1);
	    do_std_keyword($keyword, $narg, $p, (!$n && $dollar), $strong);
	}
    }
}


# Special cases

testit dbmopen  => 'CORE::dbmopen(%foo, $bar, $baz);';
testit dbmclose => 'CORE::dbmclose %foo;';

testit delete   => 'CORE::delete $h{\'foo\'};', 'delete $h{\'foo\'};';
testit delete   => 'delete $h{\'foo\'};',       'delete $h{\'foo\'};';

# do is listed as strong, but only do { block } is strong;
# do $file is weak,  so test it separately here
## testit do       => 'CORE::do $a;';
## testit do       => 'do $a;',                     'do($a);';
## testit do       => 'CORE::do { 1 }',
##		   "do {\n        1\n    };";
##testit do       => 'do { 1 };',
		   "do {\n        1\n    };";

testit each     => 'CORE::each %bar;';

testit eof      => 'CORE::eof();';

testit exists   => 'CORE::exists $h{\'foo\'};', 'exists $h{\'foo\'};';
testit exists   => 'exists $h{\'foo\'};',       'exists $h{\'foo\'};';

testit exec     => 'CORE::exec($foo $bar);';

testit glob     => 'glob;',                       'glob($_);';
testit glob     => 'CORE::glob;',                 'CORE::glob($_);';
testit glob     => 'glob $a;',                    'glob($a);';
testit glob     => 'CORE::glob $a;',              'CORE::glob($a);';

testit grep     => 'CORE::grep { $a } $b, $c',    'grep({ $a; } $b, $c);';

testit keys     => 'CORE::keys %bar;';

testit map      => 'CORE::map { $a } $b, $c',    'map({ $a; } $b, $c);';

testit not      => '3 unless CORE::not $a && $b;';

testit readline => 'CORE::readline $a . $b;';

testit readpipe => 'CORE::readpipe $a + $b;';

testit reverse  => 'CORE::reverse sort(@foo);';

# note that the test does '() = split...' which is why the
# limit is optimised to 1
testit split    => 'split;',                     q{split(/ /u, $_, 1);};
testit split    => 'CORE::split;',               q{split(/ /u, $_, 1);};
testit split    => 'split $a;',                  q{split(/$a/u, $_, 1);};
testit split    => 'CORE::split $a;',            q{split(/$a/u, $_, 1);};
testit split    => 'split $a, $b;',              q{split(/$a/u, $b, 1);};
testit split    => 'CORE::split $a, $b;',        q{split(/$a/u, $b, 1);};
testit split    => 'split $a, $b, $c;',          q{split(/$a/u, $b, $c);};
testit split    => 'CORE::split $a, $b, $c;',    q{split(/$a/u, $b, $c);};

testit sub      => 'CORE::sub { $a, $b }',
			"sub {\n        \$a, \$b;\n    };";

testit system   => 'CORE::system($foo $bar);';

testit values   => 'CORE::values %bar;';


# XXX These are deparsed wrapped in parens.
# whether they should be, I don't know!

testit dump     => '(CORE::dump);';

testit dump     => 'CORE::dump FOO;';
testit goto     => 'CORE::goto;',     '(goto);';
testit goto     => 'CORE::goto FOO;', 'goto FOO;';
testit last     => 'CORE::last;',     '(last);';
testit last     => 'CORE::last FOO;', 'last FOO;';
testit next     => 'CORE::next;',     '(next);';
testit next     => 'CORE::next FOO;', 'next FOO;';
testit redo     => 'CORE::redo;',     '(redo);';
testit redo     => 'CORE::redo FOO;', 'redo FOO;';
testit redo     => 'CORE::redo;',     '(redo);';
testit redo     => 'CORE::redo FOO;', 'redo FOO;';
testit return   => 'return;',         '(return);';
testit return   => 'CORE::return;',   '(return);';

# these are the keywords I couldn't think how to test within this framework

my %not_tested = map { $_ => 1} qw(
    __DATA__
    __END__
    __FILE__
    __LINE__
    __PACKAGE__
    __SUB__
    AUTOLOAD
    BEGIN
    CHECK
    CORE
    DESTROY
    END
    INIT
    UNITCHECK
    default
    else
    elsif
    for
    foreach
    format
    given
    if
    m
    no
    package
    q
    qq
    qr
    qw
    qx
    require
    s
    tr
    unless
    until
    use
    when
    while
    y
);



# Sanity check against keyword data:
# make sure we haven't missed any keywords,
# and that we got the strength right.

SKIP:
{
    skip "sanity checks when not PERL_CORE", 1 unless defined $ENV{PERL_CORE};
    my $count = 0;
    my $file = '../regen/keywords.pl';
    my $pass = 1;
    if (open my $fh, '<', $file) {
	while (<$fh>) {
	    last if /^__END__$/;
	}
	while (<$fh>) {
	    next unless /^([+\-])(\w+)$/;
	    my ($strength, $key) = ($1, $2);
	    $strength = ($strength eq '+') ? 1 : 0;
	    $count++;
	    if (!$SEEN{$key} && !$not_tested{$key}) {
		diag("keyword '$key' seen in $file, but not tested here!!");
		$pass = 0;
	    }
	    if (exists $SEEN_STRENGTH{$key} and $SEEN_STRENGTH{$key} != $strength) {
		diag("keyword '$key' strengh as seen in $file doen't match here!!");
		$pass = 0;
	    }
	}
    }
    else {
	diag("Can't open $file: $!");
	$pass = 0;
    }
    # insanity check
    if ($count < 200) {
	diag("Saw $count keywords: less than 200!");
	$pass = 0;
    }
    ok($pass, "sanity checks");
}


done_testing();
