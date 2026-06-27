######################################################################
#
# 0013-sh-case.t  SH case..esac pattern branching
#
# Covers multiple patterns (|), the default *) clause, glob and
# character-class patterns ([abc] [a-z] [!abc]), quoted/literal patterns,
# the bash fall-through terminators ;& and ;;&, multi-line and
# fully-inline forms, and empty bodies.
#
# COMPATIBILITY: Perl 5.005_03 and later
#
######################################################################
use strict;
BEGIN { if ($] < 5.006 && !defined(&warnings::import)) {
        $INC{'warnings.pm'} = 'stub'; eval 'package warnings; sub import {}' } }
use warnings; local $^W = 1;
BEGIN { pop @INC if $INC[-1] eq '.' }
use FindBin ();
use File::Spec ();
use lib "$FindBin::Bin/../lib";

eval { require BATsh } or die "Cannot load BATsh: $@";

# Capture STDOUT produced by running a list of SH lines.
sub _run_capture {
    my (@lines) = @_;
    BATsh::Env::init();
    my $cap = "$FindBin::Bin/_case_cap_$$.tmp";
    local *OLDOUT;
    open(OLDOUT, ">&STDOUT") or die "cannot dup STDOUT: $!";
    close(STDOUT);
    open(STDOUT, "> $cap")
        or do { open(STDOUT, ">&OLDOUT"); die "cannot redirect STDOUT: $!" };
    BATsh::SH->exec_block([@lines]);
    close(STDOUT);
    open(STDOUT, ">&OLDOUT") or die "cannot restore STDOUT: $!";
    close(OLDOUT);
    my $out = '';
    local *RF;
    if (open(RF, $cap)) { local $/; $out = <RF>; close(RF) }
    unlink($cap);
    $out = '' unless defined $out;
    return $out;
}

my @tests = (

    # C1: multiple patterns separated by |
    sub {
        my $o = _run_capture('x=b', 'case $x in',
            'a|b|c) echo abc ;;', '*) echo other ;;', 'esac');
        _ok($o eq "abc\n", 'C1: a|b|c multiple patterns');
    },

    # C2: the *) default clause is the catch-all
    sub {
        my $o = _run_capture('x=zzz', 'case $x in',
            'a) echo A ;;', '*) echo default ;;', 'esac');
        _ok($o eq "default\n", 'C2: *) default catch-all');
    },

    # C3: glob pattern with *
    sub {
        my $o = _run_capture('x=apple', 'case $x in',
            'a*) echo "starts-a" ;;', '*) echo other ;;', 'esac');
        _ok($o eq "starts-a\n", 'C3: a* glob pattern');
    },

    # C4: character class [0-9]
    sub {
        my $o = _run_capture('x=5', 'case $x in',
            '[0-9]) echo digit ;;', '*) echo nondigit ;;', 'esac');
        _ok($o eq "digit\n", 'C4: [0-9] character class');
    },

    # C5: negated character class [!0-9]
    sub {
        my $o = _run_capture('x=A', 'case $x in',
            '[!0-9]) echo notdigit ;;', '*) echo digit ;;', 'esac');
        _ok($o eq "notdigit\n", 'C5: [!0-9] negated class');
    },

    # C6: range class [a-z]
    sub {
        my $o = _run_capture('x=m', 'case $x in',
            '[a-z]) echo lower ;;', '[A-Z]) echo upper ;;', '*) echo other ;;', 'esac');
        _ok($o eq "lower\n", 'C6: [a-z] range class');
    },

    # C7: ;& falls through to the next clause body unconditionally
    sub {
        my $o = _run_capture('x=a', 'case $x in',
            'a) echo is-a ;&', 'b) echo and-b ;;', '*) echo other ;;', 'esac');
        _ok($o eq "is-a\nand-b\n", 'C7: ;& falls through to next body');
    },

    # C8: ;;& continues testing subsequent patterns
    sub {
        my $o = _run_capture('x=ab', 'case $x in',
            'a*) echo A ;;&', '*b) echo B ;;', '*) echo other ;;', 'esac');
        _ok($o eq "A\nB\n", 'C8: ;;& continues testing later patterns');
    },

    # C9: fully-inline case .. esac on one line
    sub {
        my $o = _run_capture('x=two',
            'case $x in one) echo 1 ;; two) echo 2 ;; *) echo n ;; esac');
        _ok($o eq "2\n", 'C9: fully-inline case on one line');
    },

    # C10: a quoted pattern matches literally (no glob)
    sub {
        my $o = _run_capture('x=*', 'case $x in',
            '"*") echo literal-star ;;', '*) echo wildcard ;;', 'esac');
        _ok($o eq "literal-star\n", 'C10: quoted pattern is literal');
    },

    # C11: an empty body runs nothing and does not fall through
    sub {
        my $o = _run_capture('x=a', 'case $x in',
            'a) ;;', '*) echo other ;;', 'esac', 'echo done');
        _ok($o eq "done\n", 'C11: empty body matches and runs nothing');
    },

    # C12: multi-line bodies with a multi-pattern head
    sub {
        my $o = _run_capture('x=2', 'case $x in',
            '1|2|3)', 'echo small', 'echo num', ';;',
            '*)', 'echo big', ';;', 'esac');
        _ok($o eq "small\nnum\n", 'C12: multi-line multi-pattern body');
    },

    # C13: a leading ( before the pattern list is accepted
    sub {
        my $o = _run_capture('x=y', 'case $x in',
            '(y) echo paren ;;', '*) echo no ;;', 'esac');
        _ok($o eq "paren\n", 'C13: leading-paren clause');
    },

    # C14: the word "esac" inside a body does not end the construct early
    sub {
        my $o = _run_capture('x=q', 'case $x in',
            'q) echo "running esac body" ;;', '*) echo other ;;', 'esac');
        _ok($o eq "running esac body\n", 'C14: esac inside body not premature');
    },

    # C15: only the first matching clause runs under plain ;;
    sub {
        my $o = _run_capture('x=a', 'case $x in',
            'a) echo first ;;', 'a) echo second ;;', '*) echo other ;;', 'esac');
        _ok($o eq "first\n", 'C15: first match wins with ;;');
    },

    # C16: ;& can fall through into the *) default
    sub {
        my $o = _run_capture('x=a', 'case $x in',
            'a) echo got-a ;&', '*) echo default ;;', 'esac');
        _ok($o eq "got-a\ndefault\n", 'C16: ;& falls into *) default');
    },

    # C17: a variable used inside the matched body still expands
    sub {
        my $o = _run_capture('x=hi', 'name=world', 'case $x in',
            'hi) echo "hello $name" ;;', '*) echo other ;;', 'esac');
        _ok($o eq "hello world\n", 'C17: body expansion inside matched clause');
    },

);

print "1.." . scalar(@tests) . "\n";
my ($run, $fail) = (0, 0);
sub _ok {
    my ($ok, $name) = @_;
    $run++; $fail++ unless $ok;
    print +($ok ? '' : 'not ') . "ok $run - $name\n";
}
$_->() for @tests;
END { exit 1 if $fail }
