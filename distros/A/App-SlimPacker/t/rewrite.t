#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use FindBin;

use lib "$FindBin::Bin/../lib";
use App::SlimPacker qw(process process_deps minify_file collect_bundle_globals);

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

# ── bundle-aware global renaming ─────────────────────────────────────────────
# collect_bundle_globals() builds a package => { old => short } map from the
# sources that will share one bundle; process() with global_rename => $map
# rewrites `our` declarations and every reference, qualified or not.  This is
# the whole point of packing: the bundle controls its full dependency graph, so
# renaming package globals — too dangerous for a lone file — becomes safe.
{
    my $keeper = q{package App::Keeper;
our $hits; our $VERSION = '1.2';
sub bump { $hits++ }
1;
};
    my $reader = q{package App::ReadLine;
use App::Keeper ();
my $tmp;
sub total_plus { my $n = $App::Keeper::hits + $tmp; return $n }
1;
};
    my ($map, $lex) = collect_bundle_globals($keeper, $reader);
    is_deeply $map, { 'App::Keeper' => { hits => 'c' } },
        'map covers only our-declared globals; short name c (a,b reserved)';
    is_deeply $lex, { tmp => 1, n => 1 }, 'bundle lexicals collected (my vars)';

    my $m1 = process($keeper, global_rename => $map, global_lexicals => $lex, rewrite => 1);
    like $m1, qr/our\$c/,                 'our declaration renamed';
    like $m1, qr/our\$VERSION='1\.2'/,    'VERSION deny-listed, untouched';
    like $m1, qr/sub bump\{\$c\+\+\}/,    'unqualified ref renamed (decl package)';

    my $m2 = process($reader, global_rename => $map, global_lexicals => $lex, rewrite => 1);
    like $m2, qr/App::Keeper::c\+/, 'qualified $Pkg::old ref renamed across modules';
    unlike $m2, qr/\$hits/,   'no $hits reference survives anywhere';
    unlike $m2, qr/\$c,/ ,    'lexical my not shadowed: $tmp renamed past reserved c/d';
    like $m2, qr/my\$d;/,     '... to the next free short';

    # default (no map): our globals must stay untouched exactly as before
    my $plain = process($keeper, rewrite => 1);
    like $plain, qr/our\$hits/, 'without the map, our globals are left alone';
}

# ── global renaming refuses ambiguous cases ───────────────────────────────────
{
    # a `my $hits` anywhere in the bundle blocks renaming the global: an
    # unqualified reference could then hit the lexical instead
    my $x = q{package T; our $hits; 1;};
    my $y = q{package T; sub tweak { my $hits = 3; return $hits } 1;};
    my ($map) = collect_bundle_globals($x, $y);
    ok !exists $map->{T}{hits},
        'global skipped when a bundle `my` has the same name';

    # a global that shows up inside a string cannot be renamed either
    my $s = q{package R; our $note; sub say { "note=$note" } 1;};
    my ($map2) = collect_bundle_globals($s);
    ok !exists $map2->{R}{note}, 'global inside a string not renamed';

    # ALL_CAPS and single-char names are never renamed
    my $caps = q{package U; our $DEBUG; our $x; 1;};
    my ($map3) = collect_bundle_globals($caps);
    is_deeply $map3, {}, 'ALL_CAPS and single-char globals skipped';
}

# ── my-variable shorts never collide with bundle-global shorts ────────────────
{
    my $u = q{package Uu; our $hits; sub u { $hits } 1;};
    my $v = q{package Vv; my $temp; sub v { $temp } 1;};
    my ($gmap, $glex) = collect_bundle_globals($u, $v);
    my $gu = process($u, global_rename => $gmap, global_lexicals => $glex);
    my $gv = process($v, global_rename => $gmap, global_lexicals => $glex);
    like $gu, qr/our\$c;/, 'global renamed to c';
    like $gv, qr/my\$d;/,  'my renamed PAST the global short (c reserved)';
    unlike $gv, qr/my\$c;/, 'no lexical/global short collision';
}

# ── postfix `our` declarations are collected and renamed too ─────────────────
# `return if our $x` is parsed by PPI as a Statement::Break, not Variable, so
# the collector must not depend on ->isa('PPI::Statement::Variable') or the
# declaration (and every reference to it) silently stays long.
{
    my $src = q{package Po;
sub import { return if our $ready; }
our $plain;
1;
};
    my ($map, $lex) = collect_bundle_globals($src);
    is_deeply $map, { Po => { plain => 'c', ready => 'd' } },
        'postfix our $ready collected alongside a plain our (alphabetical shorts)';
    my $out = process($src, global_rename => $map, global_lexicals => $lex, rewrite => 1);
    like $out, qr/our\$c;/,         'plain our renamed to c';
    like $out, qr/return if our\$d/, 'postfix our declaration+read renamed to d';
    unlike $out, qr/our\$ready/,     'no long $ready survives';
}

# ── postfix `my` feeds the bundle lexical list, blocking a same-named global ──
{
    my $a = q{package Ta; sub f { return if my $temp; } 1;};
    my $b = q{package Tb; our $temp; sub g { $temp } 1;};
    my ($map) = collect_bundle_globals($a, $b);
    ok !exists $map->{Tb}{temp},
        'postfix my counts as a bundle lexical, so the global is refused';
}

# ── perl special variables ($^X, %^H, ${^...}) are never rewritten ───────────
# Control-variable names are tokens perl itself owns by name; even a declared
# `our` on them never compiles, so nothing that looks like one may ever be
# turned into a short name.
{
    my $src = q{package Sp; our $^INIT = 1; our $normal; $^INIT++; 1;};
    my ($map) = collect_bundle_globals($src);
    ok !exists $map->{Sp}{'^INIT'}, 'caret-prefixed global never collected';
    is $map->{Sp}{normal}, 'c',     'non-caret global still mapped';
    my $out = process($src, global_rename => $map, global_lexicals => {}, rewrite => 1);
    like $out, qr/our\$c;/,     'normal renamed';
    like $out, qr/our\$\^INIT/, 'caret variable left exactly as-is';
}

# ── import/export protocol words + `$var` imports rename in step ───────────────
# With rename_exports, @EXPORT_OK qw() lists, the matching use ... qw() at the
# consumer, the can('name') dispatch strings, and $-exported package globals all
# agree on one short name across the whole bundle.
{
    my $lib = q{package App::ExpLib;
our @EXPORT_OK = qw(is_valid_module_name $motd);
sub import {
    my $class = shift; no strict 'refs';
    for my $name (@_) {
        my $code = $class->can($name);
        *{caller() . '::' . $name} = $code if $code;
    }
}
our $motd = 'hi';
sub is_valid_module_name { return 'ok' }
sub greet { return $motd }
1;
};
    my $app = q{package App::UseLib;
use App::ExpLib qw(is_valid_module_name $motd);
print is_valid_module_name(), $motd, "\n";
1;
};
    my ($map, $lex, $subs, $mods) =
        collect_bundle_globals($lib, $app, { rename_exports => 1 });
    my $mlib = process($lib, global_rename => $map, global_lexicals => $lex,
        global_subs => $subs, global_modules => $mods,
        rename_exports => 1, rewrite => 1);
    my $mapp = process($app, global_rename => $map, global_lexicals => $lex,
        global_subs => $subs, global_modules => $mods,
        rename_exports => 1, rewrite => 1);
    like $mlib, qr/\@EXPORT_OK=qw\(\w+ \$\w+\)/, 'export list renamed (sub + $var)';
    like $mlib, qr/can\(\$\w+\)/,                 'can() dispatch string receives var';
    like $mapp, qr/use \w+::\w+ qw\(\w+ \$\w+\)/, 'consumer use list $var renamed in step';
    unlike $mlib, qr/is_valid_module_name/, 'long exported sub gone';
    unlike $mlib, qr/\$motd/,              'long $-exported global gone';
    unlike $mapp, qr/is_valid_module_name/, 'long imported name gone';
}

# ── typeglob aliases follow the renamed sub (and stay behind a \&) ────────────
# *alias = \&sub installs a second symbol for the same code; the alias name is
# collected into the sub map so a data-only glob (no \&) is never touched.
{
    my $src = q{package App::Alias;
sub is_valid_module_name { return 1 }
*is_also_valid  = \&is_valid_module_name;
*keeps_name     = q{raw};   # data glob: no \&, must not be renamed
my %g;
*g_array = \%g;              # array glob, not a sub alias
1;
};
    my ($map, $lex, $subs, $mods) =
        collect_bundle_globals($src, { rename_exports => 1 });
    ok exists $subs->{is_also_valid},  'alias name collected into sub map';
    ok exists $subs->{is_valid_module_name}, 'originating sub collected';
    my $out = process($src, global_subs => $subs, global_modules => $mods,
        rename_exports => 1, rewrite => 1);
    like $out, qr/sub \w+\{/,          'originating sub renamed';
    like $out, qr/\*\w+\s*=\s*\\&/,      'alias glob rewritten to short \& short';
    unlike $out, qr/is_valid_module_name|is_also_valid/, 'all long sub+alias names gone';
    like $out, qr/\*keeps_name\s*=\s*q\{raw\}/, 'data glob left verbatim';
    like $out, qr/\*\w+\s*=\s*\\%g/,       'array glob not treated as sub alias';
}

# Sub::Quote installs constant subs by glob assignment without a \&
# (*_CAN_X = defined &builtin::is_bool ? $TRUE : $FALSE).  The glob and its
# callers must be renamed together, or the callers end up calling a sub that
# does not exist.
{
    my $src = q{package App::Consts;
use strict;
BEGIN {
    my $TRUE  = sub(){!!1};
    my $FALSE = sub(){!!0};
    *_HAVE_UTF8_CHECK = defined &utf8::is_utf8 ? $TRUE : $FALSE;
    *_ANSWER = sub () { 42 };
}
sub answer { return _HAVE_UTF8_CHECK ? _ANSWER : 0 }
package main;
print App::Consts::answer();
};
    my (undef, $lex, $subs) = collect_bundle_globals($src);
    ok exists $subs->{_HAVE_UTF8_CHECK}, 'glob-installed constant collected into sub map';
    ok exists $subs->{_ANSWER},          'glob-installed anon sub collected into sub map';
    my $out = process($src, global_lexicals => $lex, global_subs => $subs);
    unlike $out, qr/_HAVE_UTF8_CHECK|_ANSWER/, 'glob and callers renamed together';
    my $got = do { local *STDOUT; open STDOUT, '>', \my $buf; eval $out; $buf };
    is $got, '42', 'glob-installed constants still callable after renaming'
        or diag "error: $@\n$out";
}

# The sub map is shared by the whole bundle: a name used as a data glob in one
# module must not be renamed as a sub in another, or the data alias and the
# code referring to it would disagree.
{
    my @src = (
        q{package App::A; sub counter { 1 } 1;},
        q{package App::B; our @list; *counter = \@list; sub n { scalar @counter } 1;},
    );
    my (undef, undef, $subs) = collect_bundle_globals(@src);
    ok !exists $subs->{counter}, 'name aliased as data anywhere is never renamed as a sub';
}

# Bundle globals interpolated inside regex pattern text must follow their
# renames (lockstep), even when the global map is keyed on the RENAMED package
# name but Pass-1 regex rewriting still sees the ORIGINAL package word.  This
# is the bin/slimpack flow: it re-keys the gmap via rename_module_name, and
# _rewrite_names_in_regexes runs before the module-rename pass rewrites the
# package statements, so _gmap_key must resolve original->renamed too.
{
    my $src = q{
package Module::Runtime;
our $module_name_rx = qr{[A-Z_a-z][0-9A-Z_a-z]*(?:::[0-9A-Z_a-z]+)*};
sub valid_module_name { $_[0] =~ /\A$module_name_rx\z/o }
our $sub_module_spec_rx = qr{(?:/|::)[A-Z_a-z][0-9A-Z_a-z]*};
sub is_module_spec { $_[1] =~ /\A$sub_module_spec_rx\z/o }
1;
};
    my $mods = {
        map  => { 'Module' => 'cq', 'Runtime' => 'cx' },
        pkgs => ['Module::Runtime'],
        rev  => { 'cq::cx' => 'Module::Runtime' },
    };
    my $gmap_ren = { 'cq::cx' => { module_name_rx => 'g',
                                    sub_module_spec_rx => 'k' } };
    my $out = process($src, rename_vars => 1,
        global_rename_vars => $gmap_ren,
        global_modules     => $mods,
        rewrite            => 1);
    like $out, qr/\\A\$g\\z\/o/,      'regex \A$module_name_rx\z follows rename';
    like $out, qr/\\A\$k\\z\/o/,      'regex \A$sub_module_spec_rx\z follows rename';
    unlike $out, qr/module_name_rx|sub_module_spec_rx/, 'no original global name left';
}

# `$self` / `$class` / `$file` are ordinary my-lexicals in classic OO code and
# rename like any other variable (`my $self = shift` etc.).  They are only
# special under Perl's 5.38+ `class` feature, where `self` is an implicit (never
# my-declared) pseudo-variable in method bodies and `class` is a bareword
# keyword -- so their use must survive when the source enables that feature.
{
    my $src = q{package Foo;
sub new  { my ($class, @args) = @_; bless { @args }, $class }
sub meth { my ($self, $file) = @_; return $self->{ $file } }
1;
};
    my $out = process($src, rename_vars => 1, rewrite => 1);
    unlike $out, qr/\$(?:self|class|file)\b/,
        '$self/$class/$file renamed as classic lexicals';
    like $out, qr/\bnew\s*\{/, 'module renamed / subs kept';
}

{
    # feature 'class': implicit $self in methods must survive renaming.
    my $src = q{use v5.40;
use feature 'class';
class Point {
    method x { return $self->[0] }
    method y { return $self->[1] }
}
1;
};
    my $out = process($src, rename_vars => 1, rename_subs => 0, rewrite => 1);
    like $out, qr/\$self/, 'implicit class-feature $self kept verbatim';
    like $out, qr/\bclass\s*Point\b/, 'class keyword untouched';
}

done_testing;