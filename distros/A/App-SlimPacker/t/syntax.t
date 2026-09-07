#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use FindBin;
use File::Temp ();

use lib "$FindBin::Bin/../lib";
use App::SlimPacker qw(process);

# Whitespace-collapse can only be tested against real Perl semantics: rewrite
# /home to the exact minimum (no newlines except where one is *required*) and
# prove the result still compiles and behaves identically.  These tests are
# the regression net for whitespace-sensitive constructs -- __DATA__ / __END__
# markers (which need their own line), heredoc terminators, and the block/`;`
# statement terminators that the collapser must never merge together.

sub compiles {
    my ($code) = @_;
    my ($fh, $f) = File::Temp::tempfile(SUFFIX => '.pl');
    print $fh $code;
    close $fh;
    my $inc = `$^X -c "$f" 2>&1`;   # -c reports through STDERR; harvest it
    my $rc  = $? >> 8;
    unlink $f;
    return $rc == 0;
}

sub run_perl {
    my ($code) = @_;
    my ($fh, $f) = File::Temp::tempfile(SUFFIX => '.pl');
    print $fh $code;
    close $fh;
    my $got = `$^X $f 2>&1`;
    my $rc  = $? >> 8;
    unlink $f;
    return ($got, $rc);
}

# ── __DATA__ marker must keep its own line ─────────────────────────────────
# The marker's line is where the DATA section ends; collapsing the newline
# folds the first data line onto the marker line (changing <DATA>) or, when
# the data starts with punctuation, glues it to the marker itself.
{
    my $src = q{use strict;} . qq{\n}
            . q{my @d = <DATA>;} . qq{\n}
            . q{print scalar @d, ":", join('|', @d);} . qq{\n}
            . q{__DATA__} . qq{\n}
            . q{line one} . qq{\n}
            . q{line two} . qq{\n};
    my $out = process($src);
    like $out, qr/__DATA__\n/, '__DATA__ keeps its own line (plain data)';

    my $punct = q{use strict;} . qq{\n}
              . q{my @d = <DATA>;} . qq{\n}
              . q{print scalar @d;} . qq{\n}
              . q{__DATA__} . qq{\n}
              . q{{"json": 1}} . qq{\n};
    my $out2 = process($punct);
    like $out2, qr/__DATA__\n/, '__DATA__ keeps its own line (punct-start data)';
}

# ── __DATA__ / __END__ behave identically to the original at runtime ────────
{
    for my $case (
        [ plain  => q{my @d = <DATA>;} . qq{\n} . q{print scalar @d, ":", join('|', @d);} . qq{\n} . q{__DATA__} . qq{\n} . q{one} . qq{\n} . q{two} . qq{\n} ],
        [ latent => q{my @d = <DATA>;} . qq{\n} . q{print scalar @d;} . qq{\n} . q{__DATA__} . qq{\n} . q{{"json": 1}} . qq{\n} ],
        [ end    => q{print "before";} . qq{\n} . q{__END__} . qq{\n} . q{this is ignored} . qq{\n} ],
    ) {
        my ($name, $src) = @$case;
        my $min = process($src, rename => 0);
        ok compiles($min), "$name: minified __DATA__/__END__ still compiles";
        my ($got_o, $rc_o) = run_perl($src);
        my ($got_m, $rc_m) = run_perl($min);
        is $rc_m, $rc_o, "$name: exit status preserved";
        is $got_m, $got_o, "$name: <DATA>/behavior identical";
    }
}

# ── heredocs: terminators survive, bodies intact, following code runs ──────
{
    my $one = q{print <<'A';} . qq{\n} . q{hello} . qq{\n} . q{A} . qq{\n} . q{print "done";} . qq{\n};
    my $two = q{print <<"A";} . qq{\n} . q{x} . qq{\n} . q{A} . qq{\n}
            . q{print <<"B";} . qq{\n} . q{y} . qq{\n} . q{B} . qq{\n}
            . q{print "done";} . qq{\n};
    for my $case ([ 'single-heredoc', $one ], [ 'double-heredoc', $two ]) {
        my ($name, $src) = @$case;
        my $min = process($src, rename => 0);
        ok compiles($min), "$name: minified heredoc compiles";
        my (undef, $rc_m) = run_perl($min);
        my (undef, $rc_o) = run_perl($src);
        is $rc_m, $rc_o, "$name: heredoc + following statement behaves identically";
    }
}

# ── statement-terminator fusions ────────────────────────────────────────────
# Statements end on `;` or `}` (never on a newline except EOF, which Perl
# leaves up to the minifier to preserve).  Blocks, compounds, anon subs and
# sub definitions close on `}` and must stay closed: `}sub`, `}print`, ... are
# all valid and must never gain a stray terminator (or lose one).
my @terminator_cases = (
    [ 'sub-then-stmt'   => q{sub hi { return 'hi' } } . qq{\n} . q{print hi;} . qq{\n} ],
    [ 'if-block-stmt'   => q{if (1) { print 'y' } } . qq{\n} . q{print 'z';} . qq{\n} ],
    [ 'bare-block-stmt' => q{{ print 'block' } } . qq{\n} . q{print 'after';} . qq{\n} ],
    [ 'foreach-stmt'    => q{foreach (1, 2) { } } . qq{\n} . q{print 'after';} . qq{\n} ],
    [ 'hashref-stmt'    => q{my $x = { a => 1 };} . qq{\n} . q{print $x->{a};} . qq{\n} ],
    [ 'do-block'        => q{my $g = do { 5 };} . qq{\n} . q{print $g;} . qq{\n} ],
    [ 'anon-sub'        => q{my $f = sub { 3 };} . qq{\n} . q{print $f->();} . qq{\n} ],
    [ 'eof-no-semi'     => q{print 'eof'} . qq{\n} ],
    [ 'close-then-close' => q{{ my $x = 1 } } . qq{\n} . q{{ my $y = 2 }} . qq{\n} ],
);
for my $case (@terminator_cases) {
    my ($name, $src) = @$case;
    my $min = process($src, rename => 0);    # rename might touch only my-vars;
    ok compiles($min), "$name: minified compiles";        # equivalence below is rename-free
    my (undef, $rc_m) = run_perl($min);
    my (undef, $rc_o) = run_perl($src);
    is $rc_m, $rc_o, "$name: behaves identically";
}

# ── differential corpus: valid Perl in, equivalent Perl out ────────────────
# Every one of these must (a) still compile after default minification
# (renaming ON) and (b) run with byte-identical STDOUT after whitespace-only
# minification.  This is the net that catches any future over-eager
# whitespace/newline collapse.
my @corpus = (
    heredoc_stmts   => q{my $x = 7;} . qq{\n} . q{my $who = "world";} . qq{\n}
        . q{print <<"A", "|";} . qq{\n} . q{hello $who count=$x} . qq{\n} . q{A} . qq{\n}
        . q{print "end\n";} . qq{\n},
    for_loop        => q{my $s = 0;} . qq{\n} . q{for my $i (1 .. 5) { $s += $i } } . qq{\n} . q{print "$s\n";} . qq{\n},
    while_postfix   => q{my @a = (1,2,3);} . qq{\n} . q{while (my $x = shift @a) { print $x } } . qq{\n} . qq{\n} . q{1;} . qq{\n},
    use_version_list => q{use Exporter 5.57 (qw/import/);} . qq{\n} . q{print "ok\n";} . qq{\n},
    regex_ops        => q{my $line = "foo bar";} . qq{\n} . q{$line =~ s/foo/FIZZ/;} . qq{\n}
        . q{print "match\n" if $line =~ /FIZZ/;} . qq{\n},
    hash_slice       => q{my %h = (a=>1, b=>2);} . qq{\n} . q{print @h{qw(a b)}, "\n";} . qq{\n},
    ternary_chain    => q{my $x = 3;} . qq{\n} . q{print $x > 2 ? 'big' : 'small';} . qq{\n},
    list_assign      => q{my ($left, $right) = (1, 2);} . qq{\n} . q{print $left + $right, "\n";} . qq{\n},
    state_var        => q{use feature 'state';} . qq{\n} . q{my $r;} . qq{\n}
        . q{state $n = 0;} . qq{\n} . q{$n += 1; print $n;} . qq{\n},
    multi_stmt_seq   => q{my $total = 0;} . qq{\n} . q{for my $n (1 .. 3) {} } . qq{\n}
        . q{$total = 6; print $total + 1, "\n";} . qq{\n},
    git_style        => q{package Foo; my $VERSION = 1;} . qq{\n}
        . q{sub new { bless {}, shift } } . qq{\n} . q{sub meth { 'hi' } } . qq{\n} . q{1;} . qq{\n}
        . q{package main; my $o = Foo->new; print $o->meth, "\n";} . qq{\n},
);
while (@corpus) {
    my $name = shift @corpus;
    my $src  = shift @corpus;
    my $min  = process($src);
    ok compiles($min), "corpus $name: default-minified compiles";
    my $whitespace_only = process($src, rename => 0);
    my ($got_o, $rc_o) = run_perl($src);
    my ($got_m, $rc_m) = run_perl($whitespace_only);
    is $rc_m, $rc_o, "corpus $name: exit status preserved";
    is $got_m, $got_o, "corpus $name: STDOUT identical";
}

# ── regression: a real module from this tree survives minification ─────────
{
    my $file = "$FindBin::Bin/../lib/App/SlimPacker.pm";
    open my $fh, '<', $file or die "cannot read $file";
    local $/;
    my $src = <$fh>;
    close $fh;
    ok compiles($src), 'unminified App::SlimPacker.pm compiles (sanity)';
    ok compiles(process($src)), 'minified App::SlimPacker.pm still compiles';
}

done_testing;