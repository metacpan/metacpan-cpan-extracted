#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use FindBin;

use lib "$FindBin::Bin/../lib";
use App::SlimPacker qw(process process_deps minify_file);

# App::SlimPacker::process's optional rewrite pass (rewrite => 1) makes code
# shorter while provably preserving its value.  These tests pin down what the
# pass rewrites, what it must NOT touch, and (for two programs) that minified
# and original run identically.  The pass is opt-in: rewrite => 0 (the default)
# leaves everything as-is.

# compile-only check: run the minified output through the Perl parser by
# wrapping it in an anonymous sub (so nothing is executed).
sub compiles_ok {
    my ($label, $code) = @_;
    my $ok = eval "no strict; no warnings; my \$probe = sub { $code 1 }";
    ok(!$@, "$label (compiles)") or diag $@;
}

# ── foreach -> for ──────────────────────────────────────────────────────────
{
    my $src = 'foreach my $i (@a) { print $i }';
    my $out = process($src, rewrite => 1);
    like $out, qr/\bfor\b/,       'foreach rewritten to for';
    unlike $out, qr/foreach/,      'no foreach left';
    compiles_ok('foreach->for', $out);
}

# ── rewrite is opt-in; default keeps foreach ───────────────────────────────
{
    my $src = 'foreach my $i (@a) { print $i }';
    my $out = process($src);
    like $out, qr/foreach/, 'default (rewrite=>0) leaves foreach alone';
}

# ── foreach NOT rewritten after -> or { (method name / hash key) ───────────
{
    my $src = '$o->foreach(@a); my $h = { foreach => 1 }; print $h->{foreach};';
    my $out = process($src, rewrite => 1);
    like $out, qr/->foreach/,   'method call kept';
    like $out, qr/\{foreach=>1\}/, 'hash key kept';
    compiles_ok('foreach guard', $out);
}

# ── m/.../ -> /.../ only after =~ or !~ and only with / delimiters ─────────
{
    my $src = '$x =~ m/foo/i; my $y = "x"; $y !~ m/bar/; $z =~ m{a};';
    my $out = process($src, rewrite => 1);
    like $out,   qr/=~\/foo\//i,  'm stripped after =~';
    like $out,   qr/!~\/bar\//,   'm stripped after !~';
    unlike $out, qr/=~m\//,       'no =~m/ left';
    like $out,   qr/=~m\{a\}/,    'm kept for m{} delimiters';
    unlike $out, qr/m\/foo/,      'full m/foo gone';
    compiles_ok('m-strip', $out);
}

# ── m NOT stripped without a surrounding match operator ────────────────────
{
    my $src = 'my $x = 5; $x = 3 / 2;';
    my $out = process($src, rewrite => 1);
    like $out, qr{3 /\s*2}, 'division untouched';
    compiles_ok('division untouched', $out);
}

# ── trailing `;` before `}` dropped; for(;;) semicolons kept ───────────────
{
    my $src = '{ $x = 1; $y = 2; } for (;;) { last; }';
    my $out = process($src, rewrite => 1);
    like $out, qr/\$x=1;\$y=2\}/, 'last `;` before } gone';
    like $out, qr/for\(;;\)/,     'for(;;) keeps its semicolons';
    compiles_ok('semicolon drop', $out);
}

# ── $x += 1 mid-block -> $x++, $x -= 1 -> $x-- ──────────────────────────────
{
    my $src = 'my $n = 0; $n += 1; $n -= 1; print $n;';
    my $out = process($src, rewrite => 1);
    like $out, qr/\$n\+\+;\$n--;/, '+= 1 / -= 1 rewritten mid-block';
    compiles_ok('incdec', $out);
}

# ── last statement of a block is NOT rewritten (return value would change) ─
{
    my $src = 'sub f { my $x = 1; $x += 1 } print f;';
    my $out = process($src, rewrite => 1);
    like $out, qr/\$x\+=\s?1\}/, 'last-statement += 1 kept (return value)';
    unlike $out, qr/\$x\+\+/,    'no ++ for the tail statement';
    compiles_ok('incdec guard', $out);
}

# ── $x = $x OP $y -> $x OP= $y for . + - * / % ──────────────────────────────
{
    my $src = '$a = $a + $b; $s = $s . $t; $x = $x * 2;';
    my $out = process($src, rewrite => 1);
    like $out, qr/\$a\+=/, '+=  rewrite';
    like $out, qr/\$s\.=/, '.=  rewrite';
    like $out, qr/\$x\*=/, '*=  rewrite';
    compiles_ok('opassign', $out);
}
{
    my $src = '$y = $y - $z;';
    my $out = process($src, rewrite => 1);
    like $out, qr/\$y-=/, '`-=` rewrite (left-assoc single-token RHS)';
    compiles_ok('opassign minus', $out);
}

# ── simpler $sym = $sym OP $literal not rewritten when RHS is complex ───────
{
    my $src = '$a = $a + length($b);';
    my $out = process($src, rewrite => 1);
    unlike $out, qr/\$a\+=/, 'multi-token RHS left alone';
    compiles_ok('opassign complex RHS', $out);
}

# ── paren drop: print($x) -> print $x etc. ─────────────────────────────────
{
    my $src = 'print($x); return($y); push(@a, $x); shift(@_); chomp($n); keys(%h);';
    my $out = process($src, rewrite => 1);
    like $out, qr/print \$x/,   'print parens dropped';
    like $out, qr/return \$y/,  'return parens dropped';
    like $out, qr/push \@a,\$x/, 'push parens dropped';
    like $out, qr/shift \@_/,   'shift parens dropped';
    like $out, qr/chomp \$n/,   'chomp parens dropped';
    like $out, qr/keys \%h/,    'keys parens dropped';
    unlike $out, qr/print\(/,   'no print() left';
    unlike $out, qr/return\(/,  'no return() left';
    compiles_ok('paren drop', $out);
}

# ── my(...) list-assignment parens are NOT dropped (semantics) ──────────────
{
    my $src = 'my ($a, $b) = @_;';
    my $out = process($src, rewrite => 1);
    like $out, qr/my\(\$a,\$b\)/, 'my(...) kept (list assignment)';
    compiles_ok('my() kept', $out);
}

# ── parens NOT dropped where precedence/tokenization could change ─────────
{
    my $src = 'print($a) . "x"; print(1); print("n=$a");';
    my $out = process($src, rewrite => 1);
    like $out, qr/print\(\$a\)\./,  'parens before `.` kept';
    unlike $out, qr/print \(\$a\)/, 'no space-rewrite of that';
    like $out, qr/print\(1\)/,       'literal arg parens kept';
    like $out, qr/print\("n=\$a"\)/, 'quote arg parens kept';
    compiles_ok('paren drop guards', $out);
}

# ── strings / tokens with ';}' or 'foreach' inside are untouched ───────────
{
    my $src = 'my $s = "x}; "; print $s, "foreach and m/foo/";';
    my $out = process($src, rewrite => 1);
    like $out, qr/"x}; "/,        'literal ";}" preserved';
    like $out, qr/"foreach/,      'literal "foreach" preserved';
    compiles_ok('string safety', $out);
}

# ── runtime equivalence: original and rewritten print the same output ──────
{
    my $src = <<'PERL';
my @data = qw(alpha beta gamma);
my $sum = 0;
foreach my $item (@data) {
    $sum = $sum + length($item);
    $n += 1 if defined $item;
}
my $joined = join('-', @data);
my $first = shift(@data);
my $s = "hi";
$s = $s . $first;
my $m = "foo bar baz";
my $n = 1;
$n += 1;
$n -= 1;
print($sum); print($joined); print($first); print($s);
print($m =~ m/foo/); print($m =~ m{bar}); print("n=$n");
{ my $inner = 9; $inner += 1; print($inner); }
sub add { my ($a, $b) = @_; return($a + $b) }
print(add(3, 4));
foreach my $k (keys %ENV) { last }
print "\n";
PERL
    my $min = process($src, rewrite => 1);

    require File::Temp;
    my $run = sub {
        my ($fh, $f) = File::Temp::tempfile(SUFFIX => '.pl');
        print $fh $_[0]; close $fh or return "write-fail";
        my $got = `$^X $f 2>&1`; unlink $f; return $got;
    };
    is $run->($min), $run->($src), 'rewritten program runs identically';
}

# ── process_deps applies the rewrite and still reports dependencies ────────
{
    my ($min, @deps) = process_deps(
        'use App::Foo; foreach my $i (1..2) { print($i) } 1;',
        rewrite => 1,
    );
    is_deeply \@deps, ['App::Foo'], 'deps still extracted with rewrite';
    unlike $min, qr/foreach/, 'rewrite applied inside process_deps';
    unlike $min, qr/print\(/, 'paren drop applied inside process_deps';
}

# ── minify_file honors rewrite and keeps the shebang ───────────────────────
{
    require File::Temp;
    my ($fh, $f) = File::Temp::tempfile(SUFFIX => '.pl');
    print $fh "#!/usr/bin/perl\nforeach my \$i (\@a) { print \$i }\n";
    close $fh;
    my $min = minify_file($f, rewrite => 1);
    my $kept = eval { minify_file($f, rewrite => 1); 1 };
    like $min, qr/^#!\/usr\/bin\/perl/, 'shebang preserved';
    unlike $min, qr/foreach/,           'rewrite applied via minify_file';
    unlink $f;
}

done_testing;