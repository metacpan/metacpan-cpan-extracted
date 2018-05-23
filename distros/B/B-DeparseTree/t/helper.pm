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

sub testit {
    my ($keyword, $expr, $expected_expr, $filename, $lineno) = @_;

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
	    no warnings;
	    use subs ();
	    import subs $keyword;
	    $code_ref = eval "no strict 'vars'; sub { ${vars}() = $expr }"
			    or die "$@ in $expr";
	}

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


1;
