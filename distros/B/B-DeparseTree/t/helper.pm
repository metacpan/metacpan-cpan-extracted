# Routines common to tests

use English;
use File::Basename qw(dirname basename); use File::Spec;
use constant data_dir => File::Spec->catfile(dirname(__FILE__), 'testdata');
use Text::Diff;

use rlib '../lib';
use strict; use warnings;
use B::DeparseTree;
use vars qw($deparse $deparse_orig %SEEN %SEEN_STRENGTH %infix_map);
$deparse = new B::DeparseTree;
use B::Deparse;
$deparse_orig = new B::Deparse;

use Test::More;
BEGIN {
    require Config;
    if (($Config::Config{extensions} !~ /\bB\b/) ){
        print "1..0 # Skip -- Perl configured without B module\n";
        exit 0;
    }
}

# Deparse can't distinguish 'and' from '&&' etc
%infix_map = qw(and && or ||);

my (%SEEN, %SEEN_STRENGTH);


# test a keyword that is a binary infix operator, like 'cmp'.
# $parens - "$a op $b" is deparsed as "($a op $b)"
# $strong - keyword is strong

sub open_data($)
{
    my ($default_fn) = @_;
    my $short_name = $ARGV[0] || $default_fn;
    my $test_data = File::Spec->catfile(data_dir, $short_name);
    open(my $data_fh, "<", $test_data) || die "Can't open $test_data: $!";

    my $lineno;
    # Skip to __DATA__
    for ($lineno = 1; <$data_fh> !~ /__DATA__/; $lineno++) {
	;
    }
    return ($data_fh, $lineno);
}

use constant MAX_CORE_ERROR_COUNT => 1;

my $error_count = 0;

sub testit_full($$$$$$)
{
    my ($keyword, $expr, $expected_expr, $lexsub, $filename, $lineno) = @_;

    $expected_expr //= $expr;
    $SEEN{$keyword} = 1;

    # lex=0:   () = foo($a,$b,$c)
    # lex=1:   my ($a,$b); () = foo($a,$b,$c)
    # lex=2:   () = foo(my $a,$b,$c)
    #for my $lex (0, 1, 2) {
    for my $lex (0, 1) {
	# FIXME: we don't handle lexsub right now
	next if $lexsub;
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
	$desc .= " (lex sub)" if $lexsub;

	my $code_ref;
	my $code_text;
	if ($] > 5.022 && 0) {
	    package lexsubtest;
	    eval q{
		no warnings 'experimental::lexical_subs';
		use feature 'lexical_subs';
		no strict 'vars';
		$code_ref =
		    eval "sub { state sub $keyword; ${vars}() = $expr }"
		    || die "$@ in $expr";
	    };
	} else {
	    package test;
	    no warnings;
	    use subs ();
	    import subs $keyword;
	    $code_text = qq|
no strict 'vars';
sub {
    ${vars}() = $expr
    }|;
	    $code_ref = eval $code_text or die "$@ in $expr";
	}
	# print $code_text;
	my $got_info = $deparse->coderef2info($code_ref);
	my $got_text = $got_info->{text};

	# B::Deparse and B::DeparseTree output is inconsequtially different.
	# Also that's not what we want to test here. So the below regexp
	# is a bit more liberal than the original.
	my $CODE_PAT = q|\n*\{\s*package test;\s+no warnings;\s*use strict 'refs', 'subs'\s*;
.* = ([^\n]+)|;

	unless ($got_text =~ /$CODE_PAT/s) {
	    ::fail($desc);
	    my $mess = "couldn't extract line from boilerplate";
	    $mess .= ", file: $filename" if $filename;
	    $mess .= ", line: $lineno" if $lineno;
	    ::diag("$mess\n");
	    ::diag($got_text);
	    if (++$error_count >= MAX_CORE_ERROR_COUNT) {
		done_testing;
		exit $error_count;
	    }
	}

	my $got_expr = $1;

	# Ignore trailing semicolons. B::Deparse has them and
	# we don't.
	$expected_expr =~ s/;$//;

	if ($got_expr ne $expected_expr) {
	    my $deparse_text = $deparse_orig->coderef2text($code_ref);
	    if ($deparse_text =~ /$CODE_PAT/s) {
		my $deparse_expr = $1;
		$deparse_expr =~ s/;$//;
		if ($got_expr eq $deparse_expr) {
		    my $mess = "bad setup expectation";
		    $mess .= ", file: $filename" if $filename;
		    $mess .= ", line: $lineno" if $lineno;
		    ::diag("$mess\n");
		    next;
		} else {
		    ::diag($deparse_expr);
		}
	    }

	    # B::DeparseTree::Fragment::dump($deparse);
	    is $got_expr, $expected_expr, $desc;
	    if (++$error_count >= MAX_CORE_ERROR_COUNT) {
		done_testing;
		exit $error_count;
	    }
	}
	is $got_expr, $expected_expr, $desc;
    }
}

sub testit($$$)
{
    my ($keyword, $expr, $expected_expr) = @_;
    my ($pkg, $filename, $line) = caller;
    testit_full($keyword, $expr, $expected_expr, 0, $filename, $line);
}

# for a given keyword, create a sub of that name, then
# deparse "() = $expr", and see if it matches $expected_expr

# test a keyword that is a binary infix operator, like 'cmp'.
# $parens - "$a op $b" is deparsed as "($a op $b)"
# $strong - keyword is strong

sub do_infix_keyword($$$$$$)
{
    my ($keyword, $parens, $strong, $filename, $line, $min_version) = @_;
    print "WOOT $min_version" if defined($min_version);
    return if defined($min_version) && $] <= $min_version;

    $SEEN_STRENGTH{$keyword} = $strong;
    my $expr = "(\$a $keyword \$b)";
    my $nkey = $infix_map{$keyword} // $keyword;
    my $exp = "\$a $nkey \$b";
    $exp = "($exp)" if $parens;
    $exp .= ";";
    # with infix notation, a keyword is always interpreted as core,
    # so no need for Deparse to disambiguate with CORE::
    testit_full $keyword, "(\$a CORE::$keyword \$b)", $exp, 0, $filename, $line;
    testit_full $keyword, "(\$a $keyword \$b)", $exp,       0, $filename, $line;
    testit_full $keyword, "(\$a CORE::$keyword \$b)", $exp, 1, $filename, $line;
    testit_full $keyword, "(\$a $keyword \$b)", $exp,       1, $filename, $line;
    if (!$strong) {
	# B::Deparse fully qualifies any sub whose name is a keyword,
	# imported or not, since the importedness may not be reproduced by
	# the deparsed code.  x is special.
	my $pre = "test::" x ($keyword ne 'x');
	## testit_full $keyword, "$keyword(\$a, \$b)", "$pre$keyword(\$a, \$b);";
	testit_full $keyword, "$keyword(\$a, \$b)", "$keyword(\$a, \$b);", 0, $filename, $line;
    }
    testit_full $keyword, "$keyword(\$a, \$b)", "$keyword(\$a, \$b);", 1, $filename, $line;
}

# test a keyword that is a standard op/function, like 'index(...)'.
# narg    - how many args to test it with
# $parens - "foo $a, $b" is deparsed as "foo($a, $b)"
# $dollar - an extra '$_' arg will appear in the deparsed output
# $strong - keyword is strong


sub do_std_keyword($$$$$$$$)
{
    my ($keyword, $narg, $parens, $dollar, $strong, $filename, $line, $min_version) = @_;
    return if defined($min_version) && $] <= $min_version;

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
						       	. "$keyword$args";
	}
	# code[0]: to run; code[1]: expected
	testit_full $keyword, $code[0], $code[1], 0, $filename, $line;
    }
}

sub test_ops($)
{
    my($filename) = @_;
    my ($data_fh, $line) = open_data($filename);
    while (<$data_fh>) {
	$line ++;
	chomp;
	s/#.*//;
	next unless /\S/;

	my @fields = split;
	die "not at least 3 fields" unless @fields >= 3;
	my ($keyword, $args, $flags, $min_version) = @fields;
	$min_version = undef if defined($min_version) && $min_version eq '#';

	$args = '012' if $args eq '@';

	my $parens  = $flags =~ s/p//;
	my $invert1 = $flags =~ s/1//;
	my $dollar  = $flags =~ s/\$//;
	my $strong  = $flags =~ s/\+//;
	die "unrecognized flag(s): '$flags'" unless $flags =~ /^-?$/;

	if ($args eq 'B') { # binary infix
	    die "$keyword: binary (B) op can't have '\$' flag\\n" if $dollar;
	    die "$keyword: binary (B) op can't have '1' flag\\n" if $invert1;
	    do_infix_keyword($keyword, $parens, $strong, $filename, $line, $min_version);
	} else {
	    my @narg = split //, $args;
	    for my $n (0..$#narg) {
		my $narg = $narg[$n];
		my $p = $parens;
		$p = !$p if ($n == 0 && $invert1);
		do_std_keyword($keyword, $narg, $p, (!$n && $dollar),
			       $strong, $filename, $line, $min_version);
	    }
	}
    }
    close($data_fh);
}

1;
