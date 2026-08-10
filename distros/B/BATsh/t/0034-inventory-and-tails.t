######################################################################
#
# 0034-inventory-and-tails.t
#
# Two families of check, both added in 0.11 after a pre-release audit
# found defects that no existing test could have caught.
#
#   INV*  Builtin inventory.  _sh_name_kind() is the one authoritative
#         table of aliases/keywords/functions/builtins in BATsh::SH, and
#         "type -t" reports from it.  A second, hand-maintained copy of
#         that table lived in _sh_word_is_foreground() and had fallen
#         behind, so "declare -i n=1 &" was treated as an EXTERNAL
#         command and handed to a real /bin/sh -- which does not exist
#         on the machines this interpreter is written for.  These cases
#         assert the two views agree, for every name, in both roles.
#
#   TAIL* Commands written after a control structure that closes on the
#         same physical line.  Before 0.11 everything after the closing
#         fi/done/esac (and after a one-line function body or subshell
#         group) was silently discarded, and the block collector then
#         swallowed the following lines as well.
#
# Every case runs in-process; nothing is written outside t/ and no
# external shell is required.
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
use lib "$FindBin::Bin/../lib";
use lib "$FindBin::Bin/lib";
use File::Spec ();
use BATsh_TestOS qw(have_external shell_safe_path tap_diag);
use BATsh;
use BATsh::SH;

# Rule R10: a pipeline case has to send its output somewhere, and every
# obvious filter ("cat", "head", "wc") is absent from a plain Windows
# installation.  "sort" ships with both Windows and Unix, but that is
# still an assumption about the machine, so it is probed rather than
# trusted -- BATsh-0.11 drew a FAIL on MSWin32 for naming "cat".
my $HAVE_SORT = have_external('sort');

my $n_run = 0;

# _capture(SOURCE): run SOURCE through BATsh, returning its STDOUT as a
# single string with newlines preserved.  STDOUT is redirected at the Perl
# level (no shell, no temp file in the distribution root) and restored
# even when the interpreter dies.
sub _capture {
    my ($src) = @_;
    my $tmp = File::Spec->catfile($FindBin::Bin, "_0034_out_$$.tmp");
    my $saved = 0;
    $saved = 1 if open(SAVED_OUT, '>&STDOUT');
    if (!open(STDOUT, ">$tmp")) {
        close(SAVED_OUT) if $saved;
        return '';
    }
    eval { BATsh->run_string($src); 1 };
    my $err = $@;
    close(STDOUT);
    if ($saved) { open(STDOUT, '>&SAVED_OUT'); close(SAVED_OUT) }
    select(STDOUT); $| = 1;
    my $out = '';
    if (open(GOT, $tmp)) { local $/; $out = <GOT>; close(GOT) }
    unlink $tmp;
    $out = '' unless defined $out;
    $out .= "DIED: $err" if $err;
    return $out;
}

# The names _sh_name_kind() classifies as builtins and keywords.  Kept as
# literal text on purpose: if the table in SH.pm changes, this list has to
# be updated with it, which is exactly the review step that was missing.
my @BUILTINS = qw(
    alias break cd command continue declare echo eval exec exit export
    false getopts hash let local mapfile printf pwd read readarray
    readonly return set shift shopt source test true trap type typeset
    umask unalias unset
);
my @KEYWORDS = qw(
    if then else elif fi for while until do done case esac function in
    select
);

my @tests;

# ---------------------------------------------------------------- INV
# INV01/INV02: every documented builtin and keyword is reported as such
# by "type -t".  One case per name so a failure names the offender.
for my $name (@BUILTINS) {
    push @tests, sub {
        my $out = _capture("type -t $name");
        $out = '' unless defined $out;
        $out =~ s/\s+\z//;
        _ok(($out eq 'builtin') ? 1 : 0, "INV01: type -t $name is builtin")
            or _diag("type -t $name", $out);
    };
}
for my $name (@KEYWORDS) {
    push @tests, sub {
        my $out = _capture("type -t $name");
        $out = '' unless defined $out;
        $out =~ s/\s+\z//;
        _ok(($out eq 'keyword') ? 1 : 0, "INV02: type -t $name is keyword")
            or _diag("type -t $name", $out);
    };
}

# INV03: a builtin with a trailing '&' runs in the foreground and is NOT
# handed to an external shell.  An external shell would answer with a
# "not found" diagnostic and, on a machine without one, with nothing at
# all -- either way the builtin's effect would be missing.  "declare" and
# "shopt" are the two that were actually broken; the others guard the
# same code path.
my @BG = (
    ['declare -i bgn=6+1 & ; echo "[$bgn]"',            '[7]'],
    ['shopt -s extglob & ; shopt',                       'extglob'],
    ['alias bga=echo & ; alias bga',                    'bga'],
    ['bgv=1 & ; echo "[$bgv]"',                         '[1]'],
);
for my $c (@BG) {
    my ($src, $want) = @{$c};
    push @tests, sub {
        my $out = _capture($src);
        _ok((index($out, $want) >= 0) ? 1 : 0,
            "INV03: backgrounded builtin stays internal ($want)")
            or _diag($src, $out);
    };
}

# INV04: "time" is not implemented, so it must not claim to be a keyword.
push @tests, sub {
    my $out = _capture('type -t time');
    $out = '' unless defined $out;
    $out =~ s/\s+\z//;
    _ok(($out ne 'keyword') ? 1 : 0,
        'INV04: unimplemented "time" is not reported as a keyword')
        or _diag('type -t time', $out);
};

# --------------------------------------------------------------- TAIL
# Each case is SOURCE => expected STDOUT (exactly, newline-separated).
my @TAIL = (
    ['if true; then echo A; fi; echo B',                 "A\nB\n"],
    ['if false; then echo A; fi; echo B',                "B\n"],
    ['while false; do echo n; done; echo after',         "after\n"],
    ['case a in a) echo A;; esac; echo B',               "A\nB\n"],
    ['for i in 1 2; do echo $i; done; echo tail',        "1\n2\ntail\n"],
    ['if true; then echo A; fi && echo B',               "A\nB\n"],
    ['if true; then echo A; fi || echo C',               "A\n"],
    ['for i in 1; do echo $i; done && echo ok',          "1\nok\n"],
    ['f(){ echo F; }; echo G',                           "G\n"],
    ['f(){ echo F; }; f',                                "F\n"],
    ['f(){ echo F; }; f && echo H',                      "F\nH\n"],
    ['( echo A ); echo B',                               "A\nB\n"],
    ['( echo A ) && echo B',                             "A\nB\n"],
    ['for i in 1 2 3; do if [ "$i" = "2" ]; then break; fi; echo $i; done',
                                                          "1\n"],
    ['if true; then echo A; fi; while false; do echo n; done; echo Z',
                                                          "A\nZ\n"],
);
my $tn = 0;
for my $c (@TAIL) {
    my ($src, $want) = @{$c};
    $tn++;
    my $label = sprintf('TAIL%02d', $tn);
    push @tests, sub {
        my $out = _capture($src);
        _ok(($out eq $want) ? 1 : 0, "$label: $src")
            or _diag($src, $out, $want);
    };
}

# TAIL: a compound piped into another command.  Skipped, not failed,
# where no filter is installed (rule R10).
for my $c (['for i in 3 1 2; do echo $i; done | sort', "1\n2\n3\n"],
           ['if true; then echo A; fi | sort',         "A\n"]) {
    my ($src, $want) = @{$c};
    push @tests, sub {
        if (!$HAVE_SORT) {
            _ok(1, "TAIL-pipe: skipped, no external \"sort\" on PATH");
            return;
        }
        my $out = _capture($src);
        $out =~ s/\r\n/\n/g;   # Windows sort.exe ends its lines with CRLF
        _ok(($out eq $want) ? 1 : 0, "TAIL-pipe: $src")
            or _diag($src, $out, $want);
    };
}

# TAIL: a redirection after a one-line structure still binds to the
# structure itself (it is not a trailing command), as in bash.
push @tests, sub {
    my $f = File::Spec->catfile($FindBin::Bin, "_0034_redir_$$.tmp");

    # Rule R8: the build directory's spelling belongs to the tester.  Two
    # separate hazards had to be handled here, and BATsh-0.11 shipped
    # this case handling neither:
    #
    #   * a Windows path is spelled with backslashes, and SH mode reads a
    #     backslash as an escape exactly as bash does, so an unquoted
    #     "t\_0034_redir_1.tmp" redirects into "t_0034_redir_1.tmp" and
    #     the case then reads an empty file and blames lib/.  BATsh
    #     accepts '/' as a separator on Windows too, so the operand is
    #     rewritten before it is put into shell source.
    #   * the path very often contains a space on Windows, so it is
    #     double-quoted, and a spelling that cannot survive quoting at
    #     all is skipped with a reason rather than failed.
    my $shell_f = $f;
    $shell_f =~ s{\\}{/}g;
    if (!shell_safe_path($shell_f)) {
        _ok(1, 'TAIL18: skipped, build path cannot be quoted into shell source');
        tap_diag('TAIL18', "path: $shell_f");
        return;
    }

    _capture(qq{for i in 1 2; do echo \$i; done > "$shell_f"});
    my $got = '';
    if (open(RD, $f)) { local $/; $got = <RD>; close(RD) }
    unlink $f;
    $got = '' unless defined $got;
    $got =~ s/\r\n/\n/g;
    _ok(($got eq "1\n2\n") ? 1 : 0,
        'TAIL18: redirection after "done" still binds to the loop')
        or _diag(qq{for ... done > "$shell_f"}, $got, "1\n2\n");
};

print '1..' . scalar(@tests) . "\n";
$_->() for @tests;

# --------------------------------------------------------------------
sub _ok {
    my ($cond, $name) = @_;
    $n_run++;
    print(($cond ? '' : 'not '), "ok $n_run - $name\n");
    return $cond ? 1 : 0;
}

# _diag: never let an assertion fail without saying what it saw (rule R3
# in t/lib/BATsh_TestOS.pm).  A bare "not ok" cannot be diagnosed from a
# CPAN Testers report.
sub _diag {
    my ($src, $got, $want) = @_;
    $got  = '(undef)' unless defined $got;
    $want = undef unless defined $want;
    my $show = $got;  $show =~ s/\n/\\n/g;
    print "# source: $src\n";
    print "# got   : $show\n";
    if (defined $want) { my $w = $want; $w =~ s/\n/\\n/g; print "# want  : $w\n" }
    print "# perl  : $] on $^O\n";
    return 0;
}
