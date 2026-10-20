#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use FindBin;

use lib "$FindBin::Bin/../lib";
use App::SlimPacker qw(process name_gen needs_space pack_string
    rename_module_name rename_module_path collect_bundle_globals);

# ── name_gen ──────────────────────────────────────────────────────────────
is name_gen(0),  'a',  'name_gen(0) = a';
is name_gen(1),  'b',  'name_gen(1) = b';
is name_gen(25), 'z',  'name_gen(25) = z';
is name_gen(26), 'aa', 'name_gen(26) = aa';
is name_gen(27), 'ab', 'name_gen(27) = ab';

# ── process: comment + POD stripping ──────────────────────────────────────
{
    my $out = process("use strict;\n# comment\nmy \$foo = 1;\n=head1 DOC\n=cut\nprint \"\$foo\\n\";\n");
    unlike $out, qr/comment/, 'comments stripped';
    unlike $out, qr/=head1/,  'POD stripped';
    like $out, qr/print ?"\$[a-z]\\n";/, 'code preserved (var renamed in print-string too)';
}

# ── process: whitespace stripping ─────────────────────────────────────────
{
    my $src = "use strict;\n\n\nuse warnings;\n";
    my $out = process($src);
    unlike $out, qr/\n\n/, 'blank lines collapsed';
}

# ── process: `use Foo VERSION (LIST)` keeps the space before the paren ────
# `use Foo 5.57(qw/x/)` (no space) is a Perl syntax error.
{
    my $src = "use Exporter 5.57   (qw/import/);\n1;\n";
    my $out = process($src);
    like $out, qr/5\.57 \(/, 'space preserved between VERSION and (LIST)';
    ok eval $out, 'minified use VERSION(LIST) still compiles';
}

# ── process: newline-split postfix `if` keeps a space before the keyword ──
# `push @x, $path\n  if $cond` must not become `$pathif$cond`.
{
    my $src = "my (\@dirs, \$path);\npush \@dirs, \$path\n  if \$path =~ /x/;\n1;\n";
    my $out = process($src);
    unlike $out, qr/\$pathif/, 'no bare-var/keyword merge across a newline';
    ok(do { no warnings 'uninitialized'; eval $out }, 'minified newline-split postfix if compiles');
}

# ── process: rename => 0 disables renaming ────────────────────────────────
{
    my $src = 'my $longname = 1; print $longname;';
    my $out = process($src, rename => 0);
    like $out, qr/\$longname/, 'rename=0 keeps variable names';
}

# ── process: renames variables ────────────────────────────────────────────
{
    my $src = 'my $longname = 1; print $longname;';
    my $out = process($src, rename => 1);
    unlike $out, qr/\$longname/, 'long variable renamed';
    like $out, qr/\$[a-z]+/,     'short name assigned';
}

# ── process: single-char names NOT renamed ────────────────────────────────
{
    my $src = 'my $x = 1; print $x;';
    my $out = process($src);
    like $out, qr/\$x/, 'single-char $x preserved';
}

# ── process: uppercase names ARE renamed now (only %KEEP specials stay) ───
{
    my $src = 'my $COUNT = 1; my $STATE_FILE = "x"; print $COUNT, $STATE_FILE;';
    my $out = process($src);
    unlike $out, qr/\$COUNT/,         'ALL_CAPS $COUNT renamed (was $COUNT)';
    unlike $out, qr/\$STATE_FILE/,    'ALL_CAPS $STATE_FILE renamed';
    like $out, qr/my\$([a-z]+)="x";/, 'declaration renamed to a short';
}

# ── process: %KEEP names (Perl specials + conventions) NOT renamed ─────────
# `self`/`class` are keywords only under the 5.38+ feature 'class', so as plain
# classic lexicals they now rename like anything else (their freeze is tested
# in rewrite.t under `use feature 'class'`).
{
    for my $name (qw(VERSION ENV INC SIG ARGV STDIN ISA AUTOLOAD)) {
        my $src = "my \$$name = 1; print \$$name;";
        my $out = process($src);
        like $out, qr/\$$name/, "\%KEEP name \$$name preserved";
    }
    for my $name (qw(self class file)) {
        my $src = "my \$$name = 1; print \$$name;";
        my $out = process($src);
        unlike $out, qr/\$$name/, "classic lexical \$$name renamed";
    }
}

# ── process: variables inside double-quoted strings renamed with the code ──
{
    my $src = q{my $title = "hello"; print "$title\n";};
    my $out = process($src);
    unlike $out, qr/\$title/, '$title in a string renamed with its lexical';
    like   $out, qr/^my\$(?<n>[a-z])="hello";print "\$\k<n>\\n";$/, 'string uses the same new name as the code';
}

# ── process: variables inside m// renamed with the code ────────────────────
{
    my $src = q{my $only = "foo"; $x =~ m!$only!;};
    my $out = process($src);
    unlike $out, qr/\$only/, 'name inside m// pattern renamed with the code';
}

# ── process: variables inside s/// renamed with the code ───────────────────
{
    my $src = q{my $pkg_dir = "Foo"; $d =~ s/\Q$pkg_dir\E/$pkg_dir/i;};
    my $out = process($src);
    unlike $out, qr/\$pkg_dir/, 'name inside s/// pattern+replacement renamed';
}

# ── process: variables inside qr// renamed with the code ───────────────────
{
    my $src = q{my $file_regex = qr/\.pm$/; $f =~ /(.*$file_regex)$/;};
    my $out = process($src);
    unlike $out, qr/\$file_regex/, 'name inside qr// renamed with the code';
}

# ── process: escaped \$name inside a regex stays literal ───────────────────
{
    my $src = q{my $q = "x"; $t =~ m/\Q\$q\E/;};
    my $out = process($src);
    like $out, qr/\\\$q/, 'escaped \$q in regex stays literal';
}

# ── process: single-quoted m'...' (no interpolation) untouched ─────────────
{
    my $src = q{my $q = "x"; $t =~ m'$q';};
    my $out = process($src);
    like $out, qr/m'\$q'/, "single-quoted regex delimiters not interpolated";
}

# ── process: regex code regions ((?{ ... })) kept verbatim ─────────────────
{
    my $src = q{my $inner = 5; $t =~ m{(?{ $inner }) }x;};
    my $out = process($src);
    my $found = $out =~ /\$inner/ ? "inner seen" : "inner gone";
    is $found, "inner seen", 'name inside (?{ ... }) code block preserved';
}

# ── process: s///e replacement is code, kept verbatim ──────────────────────
{
    my $src = q{my $inner = 5; $t =~ s/(\d)/$inner/e;};
    my $out = process($src);
    my $found = $out =~ /\$inner/ ? "inner seen" : "inner gone";
    is $found, "inner seen", 'name inside s///e replacement preserved';
}

# ── process: paired delimiters s{...}{...} renamed correctly ───────────────
{
    my $src = q{my $left = "l"; my $right = "r"; $t =~ s{$left}{x$right};};
    my $out = process($src);
    unlike $out, qr/\$(?:left|right)/, 'paired s{}{} names renamed in both halves';
}

# ── process: heredoc bodies renamed in sync with the code ──────────────────
{
    my $src = "my \$greeting = \"hi\";\nmy \$tmpl = <<\"EOF\";\nhello \$greeting\nEOF\nprint \$tmpl;\n";
    my $out = process($src);
    unlike $out, qr/\$greeting/, 'name inside interpolating heredoc body renamed';
    my ($g) = $out =~ /my\$([a-z])="hi";/;
    like $out, qr/hello \$$g/m, "heredoc body uses the same new name (\$$g)";
}

# ── process: backtick / readline interpolations renamed with the code ──────
{
    my $src = q{my $dir = "/tmp"; my $listing = `ls $dir`; my $self = <$fh>;};
    my $out = process($src);
    my ($d) = $out =~ /my\$([a-z])="\/tmp";/;
    like $out, qr/`ls \$$d`/, "name inside backticks renamed (\$$d)";
}

# ── process: ${var} brace form renamed with the code ───────────────────────
{
    my $src = q{my $yrs = 30; print "${yrs}yo";};
    my $out = process($src);
    my ($y) = $out =~ /my\$([a-z])=30;/;
    like $out, qr/"\$\{$y\}yo"/, "\${name} inside string renamed (\$$y)";
}

# ── needs_space: every spacing rule, both outcomes ────────────────────────
use PPI ();
sub nt { my ($c, $s) = @_; my $cl = "PPI::Token::$c"; no strict 'refs'; return $cl->new($s) }
{
    # rule 1: word-char left, word-char right  → space
    is needs_space(nt('Word','foo'), nt('Word','bar')), 1, 'wc+wc → space';
    # rule 2: trailing sigil left, word right   → space
    is needs_space(nt('Symbol','$@'), nt('Word','zap')), 1, 'sigil+wc → space';
    # left neither word nor sigil end → no space on all rules
    is needs_space(nt('Word','foo'), nt('Symbol','$x')), 0, 'wc + nonwc → none';
    is needs_space(nt('Word',';'),   nt('Word','zz')), 0, '; + wc → none';
    # rule 3: word-char left, quote right       → space
    is needs_space(nt('Word','foo'), nt('Quote::Double','"1"')), 1, 'wc+quote → space';
    # rule 4: quote left, word-char right       → space
    is needs_space(nt('Quote::Double','""'), nt('Word','bar')), 1, 'quote+wc → space';
    is needs_space(nt('Quote::Double','""'), nt('Symbol','$x')), 0, 'quote + nonwc → none';
    # rule 5: symbol+symbol                     → space
    is needs_space(nt('Symbol','$a'), nt('Symbol','$b')), 1, 'sym+sym → space';
    is needs_space(nt('Symbol','$a'), nt('Word','b')), 1, 'sym($a)+wc(b) → space (else $ab)';
    # rule 6: word-char left, quote char right  → space
    is needs_space(nt('Word','eq'), nt('Word','"x"')), 1, 'wc+quotechar → space';
    # rule 7: regexp left, word-char right      → space
    is needs_space(nt('Regexp','abc/'), nt('Word','bar')), 1, 'regexp+wc → space';
    is needs_space(nt('Regexp','abc/'), nt('Symbol','$x')), 0, 'regexp + nonwc → none';
    # rule 2's A-true/B-false: sigil-ending left, non-word right
    is needs_space(nt('Symbol','$@'), nt('Word',';')), 0, 'sigil + nonwc → none';
    # Cast rule: bare sigil ($, @, %) must not be glued to the token before it
    is needs_space(nt('Symbol','$fh'), nt('Cast','$')), 1, 'sym+cast($) → space (prevents $$merge)';
    is needs_space(nt('Symbol','$fh'), nt('Cast','@')), 1, 'sym+cast(@) → space (prevents @$merge)';
    is needs_space(nt('Cast','$'), nt('Symbol','$src')), 0, 'cast+sym → no double-space (cast-sym stays glued)';
}

# ── pack_string: shortest exact Perl literal for arbitrary bytes ───────────
# The bundler embeds whole module sources this way.  Every produced literal
# must eval back to the exact original string; the form chosen must be the
# cheapest that round-trips (single-quote when possible, then q<delim>).
{
    sub rt { my ($s) = @_; my $lit = pack_string($s); my $got = eval $lit; ok (defined $got && $got eq $s, "round-trip " . (length($s) > 28 ? substr($s,0,28).'...' : "`$s`")); return $lit }

    is pack_string(''), "''", 'empty string → empty literal';
    is pack_string('abc'),            "'abc'",            'plain → single-quoted';
    is pack_string('my$x="hi";'),     q{'my$x="hi";'},    'sigils + double quotes → single-quoted, no escaping';

    # contains a quote → q<delim> with an absent delimiter
    my $quote_content = q{say 'x';
print "$_";};
    my $lit = pack_string($quote_content);
    like $lit, qr/^q[\^~|?]/, 'string with quote → q<delim> form';
    is eval $lit, $quote_content, 'q<delim> form round-trips exactly';

    # backslashes are escaped in place, never handed to perlstring
    my $bs = pack_string('print "a\nb\nc";');
    like $bs, qr/'print "a\\\\nb\\\\nc";'/, 'backslash content → singleton quote, backslashes doubled';
    is eval $bs, 'print "a\nb\nc";', 'escaped single-quote round-trips exactly';
    like pack_string("ab\\"), qr/'ab\\\\'/, 'trailing backslash → terminator-safe doubled backslash';
    is eval(pack_string("ab\\")), "ab\\", 'trailing-backslash literal round-trips exactly';

    # quote AND backslash together → escaped q<delim> (quotes stay raw)
    my $qw = pack_string('q^ twice? "a\\b" \'it\'');
    like $qw, qr/^q[\^~|?]/, 'quote + backslash → q<delim> with escaped backslashes';
    is eval $qw, 'q^ twice? "a\\b" \'it\'', 'escaped q<delim> round-trips exactly';

    # every candidate delimiter present AND a quote → escaped q<delim> (rarest
    # delimiter chosen), never per-quote escaping
    my $nasty = "'a^~|?,;!#&-=+*/%:<>'";
    my $fallback = pack_string($nasty);
    like $fallback, qr/^q/, 'every delimiter present → q<delim> with escaped delimiter';
    like $fallback, qr/\\\^/, 'the single ^ occurrence is escaped';
    unlike $fallback, qr/^"/, 'no double-quoted perlstring output';
    is eval $fallback, $nasty, 'every-delimiter fallback round-trips exactly';

    # quote-heavy module source (like the saisons UI): must stay q<delim>,
    # not inflate every ' into \'
    my $heavy = "'^~|?,;!#&-=+*/%:<>" .
        q{use constant RESET=>color('reset');color('yellow');color('cyan');color('bold green');};
    my $heavy_lit = pack_string($heavy);
    like $heavy_lit, qr/^q/, 'quote-heavy + all-delimiter source → q<delim>';
    unlike $heavy_lit, qr/\\'/, 'quotes stay unescaped inside q<delim>';
    is eval $heavy_lit, $heavy, 'quote-heavy source round-trips exactly';

    # `;` must never be picked as a q delimiter: q;...; is a syntax error on
    # perl <= 5.16, and bundles should run there
    my $no_semi = q{'^~|?,!#&-+*/%:'};    # every candidate present, no `;`
    unlike pack_string($no_semi), qr/^q;/, 'q; never chosen as delimiter';

    # binary-ish / multiline / backslash runs
    rt("multi\nline\ttab");
    rt('trailing\\');
    rt('a\\b' . '\\' . '\\');    # contains `\\` two-backslash run
    rt("\x00\x01\xff");

    # seeded differential corpus: pack_string must round-trip any byte string,
    # however it is composed (delimiters, quotes and backslashes included)
    srand 20260907;
    my $alpha = join('', "aZ09.'~^\" ", "\t\n", '\\$@%(){}[]=,;:/_-.!#&*+?<>|');
    my $diff_fail = 0;
    for (1 .. 1000) {
        my $len = int(rand 90);
        my $s = join('', map { substr($alpha, int(rand length $alpha), 1) } 1 .. $len);
        $s .= '\\' if rand() < 0.2;
        my $lit = pack_string($s);
        my $v = eval $lit;
        $diff_fail++ if !defined $v || $v ne $s;
    }
    is $diff_fail, 0, '1000-string differential corpus round-trips through pack_string';
}

# ── process: empty source short-circuits ──────────────────────────────────
{
    is process(''), '', 'empty source → empty output';
}

# ── process: my ($a, $b) list declaration ─────────────────────────────────
{
    my $src = 'sub pair { my ($left_arg, $right_arg) = @_; return [$left_arg, $right_arg] }';
    my $out = process($src);
    unlike $out, qr/\$left_arg/,  'list-declared variable renamed';
    unlike $out, qr/\$right_arg/, 'list-declared variable renamed';
}

# ── process: local declaration is NOT a rename candidate ─────────────────
# `local $x` may be the package global $PKG::x read via a qualified
# reference elsewhere, so we conservatively leave it untouched. Only
# `my` (a true file lexical) is renamed.
{
    my $src = 'local $signal = 0; print $signal;';
    my $out = process($src);
    like $out, qr/\$signal/, 'local variable left unrenamed (may be a global)';
}

# ── process: repeated same-name declaration only renamed once ─────────────
{
    my $src = 'my $counter_val = 1; { my $counter_val = 2 } print $counter_val;';
    my $out = process($src);
    unlike $out, qr/\$counter_val/, 'duplicate declaration renamed consistently';
}

# ── process: variables inside <> renamed in sync with the code ────────────
{
    my $src = q{my $fh = "x"; open my $fh2, '<', $fh; while (<$fh2>) { print }};
    my $out = process($src);
    unlike $out, qr/\$fh2/, '$fh2 (and <$fh2>) renamed with its lexical';
    like   $out, qr/<\$[a-z]>/, 'readline <> uses the new name';
}

# ── process: heredoc body renamed with the code ────────────────────────────
{
    my $src = "my \$name = \"world\"; print <<\"EOT\";\nHello \$name\nEOT\n";
    my $out = process($src);
    my ($n) = $out =~ /my\$([a-z])="world";/;
    like $out, qr/Hello \$$n/, "heredoc body renamed with the code (\$$n)";
}

# ── process: ${} interpolation renamed with the code ───────────────────────
{
    my $src = q{my $path = "Foo"; print "${path}::Plugin";};
    my $out = process($src);
    my ($p) = $out =~ /my\$([a-z])="Foo";/;
    like $out, qr/"\$\{$p\}::Plugin"/, "\${path} renamed with the code (\$$p)";
}

# ── process: variable used ONLY in code IS renamed ────────────────────────
{
    my $src = q{my $counter = 0; $counter++; print $counter;};
    my $out = process($src);
    unlike $out, qr/\$counter/, '$counter renamed (code only)';
}

# ── process: variable used in code AND string renamed in both ──────────────
{
    my $src = q{my $widget = "hi"; print "val=$widget\n";};
    my $out = process($src);
    my ($w) = $out =~ /my\$([a-z])="hi";/;
    unlike $out, qr/\$widget/, '$widget renamed';
    like   $out, qr/"val=\$$w\\n"/, "string uses the new name (\$$w)";
}

# ── process: @array in string renamed with the code ────────────────────────
{
    my $src = q{my @items = (1,2); print "@items";};
    my $out = process($src);
    my ($i) = $out =~ /my\@([a-z])=/;
    unlike $out, qr/\@items/, '\@items renamed';
    like   $out, qr/"\@$i"/, "string uses the new name (\@$i)";
}

# ── process: %hash in string renamed with the code ─────────────────────────
{
    my $src = q{my %map = (a=>1); print "%map";};
    my $out = process($src);
    my ($m) = $out =~ /my\%([a-z])=/;
    unlike $out, qr/\%map/, '\%map renamed';
    like   $out, qr/"%$m"/, "string uses the new name (%$m)";
}

# ── process: package-qualified globals NOT renamed ────────────────────────
# `$Archive::Tar::WARN` is a cross-package global; renaming it to $p
# inside the current file silently breaks Archive::Tar's own logic.
{
    my $src = 'local $Archive::Tar::WARN = 0; print $Archive::Tar::WARN;';
    my $out = process($src);
    like $out, qr/\$Archive::Tar::WARN/, 'package-qualified global not renamed';
    unlike $out, qr/\$[a-z]{1,2}\b(?![.:])/, 'no short replacement used for package global';
}

# ── process: bare local globals NOT renamed (my is) ──────────────────────
# `local $warn` creates/localises the package global $PKG::warn; a reader
# via `$A::warn` must still resolve. Renaming it breaks that silently.
# `my $warn` is a file lexical and IS safe to rename.
{
    my $src = "package A;\nlocal \$warn = \"hi\";\npackage main;\nprint \$A::warn, \"\\n\";\n1;\n";
    my $out = process($src);
    like $out, qr/\$warn/,        'bare local global NOT renamed';
    like $out, qr/\$A::warn/,     'qualified read kept in sync';

    # Runtime proof: original and minified print identical output.
    require File::Temp;
    my $run = sub {
        my ($fh, $f) = File::Temp::tempfile(SUFFIX => '.pl');
        print $fh $_[0]; close $fh or return "write-fail";
        my $got = `$^X $f 2>&1`; unlink $f; return $got;
    };
    is $run->($out), $run->($src), 'minified local global prints identically to original';

    my $my_src = "package A;\nmy \$warn = 1;\npackage main;\nprint \$warn;\n1;\n";
    my $my_out = process($my_src);
    unlike $my_out, qr/\$warn/, 'my package-lexical still renamed';
}

# ── process: no crash on empty source ─────────────────────────────────────
{
    my $out = process("1;\n");
    like $out, qr/1;/, 'minimal valid source processed';
}

# ── process: $#array index renamed consistently with @array ───────────────
{
    my $src = 'my @letters = (1,2); print $#letters;';
    my $out = process($src);
    unlike $out, qr/\$#letters/, '$#letters renamed (matches @letters rename)';
    like $out, qr/\$#[a-z]+/,    'short $#name assigned';
}

# ── process: multiple variables with correct renaming ─────────────────────
{
    my $src = 'my $alpha = 1; my $beta = 2; print $alpha + $beta;';
    my $out = process($src);
    unlike $out, qr/\$alpha/, '$alpha renamed';
    unlike $out, qr/\$beta/,  '$beta renamed';
    # Both should get distinct short names
    my ($a1) = $out =~ /(\$[a-z]+)/;
    my @all = $out =~ /(\$[a-z]+)/g;
    ok scalar(@all) >= 2, 'multiple variables renamed';
}

# ── process: rename_subs renames sub/method names ─────────────────────────
{
    my $src = 'package Foo; sub get_answer { my ($s,$x)=@_; $s->compute($x) } sub compute { 42 } sub make { bless {}, shift } my $o = Foo->make; $o->get_answer(0) == 42 or die "bad";';
    my $out = process($src, rename_subs => 1);
    unlike $out, qr/get_answer/, 'definition renamed';
    unlike $out, qr/compute/,    'method renamed';
    like $out,    qr/sub [a-z]\{/,  'short sub definition';
    like $out,    qr/->[a-z]\(/,    'method call renamed with definition';
    like $out,    qr/Foo->[a-z]\b/, 'constructor renamed';
    my $res = eval $out;
    ok !$@ && $res, 'renamed package still compiles and runs correctly';
}

# ── process: rename_subs leaves name-magic subs alone ─────────────────────
{
    my @magic = qw(new clone DESTROY AUTOLOAD VERSION import unimport export can isa DOES BEGIN END);
    for my $name (@magic) {
        my $src = "sub $name { 1 } foo(); sub foo { 2 }";
        my $out = process($src, rename_subs => 1);
        like $out, qr/sub \Q$name\E\{/, "magic sub $name kept";
    }
}

# ── process: rename_subs refuses perl keywords / builtins ─────────────────
{
    for my $name (qw(map grep keys each print die)) {
        my $src = "sub $name { 1 }\n";
        my $out = process($src, rename_subs => 1);
        like $out, qr/sub \Q$name\E\{/, "keyword sub $name kept";
    }
}

# ── process: rename_subs refuses names seen in stringy tokens ─────────────
{
    my $src = q{sub run { 1 } sub main { 2 } my $m = 'run'; print $obj->can($m),qq{$o->main\n};};
    my $out = process($src, rename_subs => 1);
    like $out, qr/sub run\{/,  'name in can("run") string keeps sub run';
    like $out, qr/sub main\{/,  'name in interpolated string keeps sub main';
    like $out, qr/'run'/,   'dispatch string untouched';
}

# ── process: rename_subs keeps hash keys and deref targets ────────────────
{
    my $src = q{sub run { 1 } sub get { 2 } my $h = { run => 1 }; sub show { my($o)=@_; print $h->{get}, " ", $o->{run}; }};
    my $out = process($src, rename_subs => 1);
    like $out, qr/\{run=>1\}/,  'hash key run kept';
    like $out, qr/\$h->\{get\}/, 'deref key get kept';
    like $out, qr/sub [a-z]\{/, 'subs still renamed';
}

# ── process: rename_subs consistent for qualified names and code-refs ─────
{
    my $src = q{my $r = \&App::X::do_it; sub App::Y::helper { 1 } my $y = \&helper; print $r->(), $y->(); sub do_it { sub helper { 3 } helper() }};
    my $out = process($src, rename_subs => 1);
    unlike $out, qr/do_it/, 'qualified def+call renamed';
    unlike $out, qr/helper/, '&code-ref and def renamed';
    like $out, qr/\\&[A-Za-z_:]*[a-z]\b/, 'code-ref tail shortened';
}

# ── process: rename_subs bareword calls in term position ──────────────────
{
    my $src = q{sub color { 'red' } print color . "!", "\n";};
    my $out = process($src, rename_subs => 1);
    unlike $out, qr/color/, 'bareword term-position call renamed';
    like $out, qr/print [a-z]\."!",/, 'call kept in term position';
}

# ── process: rename_subs labels, goto, ternary `:` and `=>` keys ─────────
{
    my $src = q{sub run { goto run } NEST: { run; } sub x { 1 } my %h = (x => 1); my $v = $h{x};};
    my $out = process($src, rename_subs => 1);
    like $out, qr/goto run/,  'goto target label kept';
    like $out, qr/NEST/,      'label definition kept verbatim';
    like $out, qr/\(x=>1\)/,  'fat-comma key kept';
    like $out, qr/\$h\{x\}/,  'subscript key kept';
}

# ── process: rename_subs off keeps everything ─────────────────────────────
{
    my $src = q{sub run { 1 } run();};
    my $out = process($src, rename_subs => 0);
    like $out, qr/sub run\{/, 'rename_subs=0 keeps sub';
    like $out, qr/run\(\);/,   'rename_subs=0 keeps call';
}

# ── process: short sub names never collide with file tests.  The fifth sub
#    would get `e`, and `10 - fifth` (glued to `10-fifth`) would become the
#    file test `10-e` (Sub::Quote: `... - _NVMANTBITS`) ──
{
    my $src = q{sub one {1} sub two {2} sub three {3} sub four {4} sub fifth {5}
print 10 - fifth, one() + two() + three() + four();};
    my $out = process($src, rename_subs => 1);
    unlike $out, qr/-[rwxoRWXOezsfdlpSbctugkTBAMC]\b/, 'no sub renamed to a file-test letter';
    my $got = do { local *STDOUT; open STDOUT, '>', \my $buf; eval "package Filetest; $out"; $buf };
    is $got, '510', 'minus before a renamed sub still subtracts' or diag "$@\n$out";
}

# ── process: a bareword call that ends its expression is still a call
#    (Sub::Defer: `if ($target && !_CAN_SUBNAME) {`), but a hash key is not ──
{
    my $src = q{sub flag { 7 } my %h = (flag => 1);
sub last_in_block { flag }
print last_in_block(), (1 && flag), [flag]->[0], $h{flag}, $h{ flag };};
    my $out = process($src, rename_subs => 1);
    unlike $out, qr/(?<!\$h)[(&\[{]flag[)\]}]/, 'bareword call at end of expression renamed';
    like $out, qr/\$h\{flag\}\S*\$h\{flag\}/, 'hash subscript keys kept';
    my $got = do { local *STDOUT; open STDOUT, '>', \my $buf; eval $out; $buf };
    is $got, '777' . '11', 'renamed program still runs' or diag "$@\n$out";
}

# ── process: rename_subs + heredocs: names inside the heredoc body are kept,
#    real definitions elsewhere are still renamed (regression for a crash on
#    single-line heredoc content)
{
    my $src = q{sub table_src { my ($s)=@_; return $s; }
sub scrape { my ($self,$id)=@_; my $q = $self->table_src(<<'SQL'); return $q->($id); }
SELECT id FROM t WHERE name = 'process'
SQL
sub ref2 { scalar table_src() }};
    my $out = process($src, rename_subs => 1);
    like $out, qr/sub [a-z]\{/,       'real subs renamed with heredoc module';
    unlike $out, qr/sub table_src\{/,  'definition of heredoc-called sub renamed';
    like $out, qr/->[a-z]\(<<'SQL'\)/, 'heredoc call minified and renamed';
    like $out, qr/<<'SQL'\)[^\n]*\nSELECT/, 'heredoc body follows opener in place';
    unlike $out, qr/SQL$/,             'no heredoc dumped at EOF';
}

# ── process: rename_subs never generates a Perl keyword/operator sub name ──
# A sub called bare as m()/q()/s()/y() parses as the operator, not the call
# (a real regression: _db_path was renamed to `m`, so the SQLite path became
#  an empty m// match and the opencode adapter silently lost every session).
{
    my $src = "package P;\n"
        . "sub new { bless {}, shift }\n"
        . join('', map { "sub s$_ { $_ }\n" } 0 .. 60);
    my $out = process($src, rename_subs => 1);
    unlike $out, qr/sub (?:m|q|qq|qr|qw|qx|s|tr|y|x|print|printf|say|cmp|eq|ne|lt|gt|le|ge)\{/,
        'no generated sub is a Perl operator/keyword name';
}

# ── rename_module_name / rename_module_path ──────────────────────────────
{
    my $mods = {
        map => { App => 'c', Pack => 'd' },
        pkgs => ['App::Pack::Blue', 'App::Pack::Red'],
    };
    is rename_module_name('App::Pack::Red', $mods), 'c::d::Red',
        'declared package: ancestors renamed, leaf kept';
    is rename_module_name('App::Pack::Blue::Inner', $mods), 'c::d::Blue::Inner',
        'deeper name under declared package: prefix minus leaf renamed';
    is rename_module_name('App::Pack', $mods), 'c::d',
        'namespace ancestor of a declared package: all components renamed';
    is rename_module_name('App::Saisons::UI', $mods), 'App::Saisons::UI',
        'unrelated namespace untouched';
    is rename_module_name('Dashboard', $mods), 'Dashboard',
        'single-component name untouched';
    is rename_module_path('App/Pack/Red.pm', $mods), 'c/d/Red.pm',
        'path form (leaf kept, ancestors shortened)';
    is rename_module_path('App/Pack/Blue/Inner.pm', $mods), 'c/d/Blue/Inner.pm',
        'path form: deeper tail preserved';
    is rename_module_path('App/Pack.pm', $mods), 'c/d.pm',
        'path form: namespace-ancestor path maps all components';
}

# ── process: interpolated fully-qualified globals follow module rename ───
# "saisons $App::Saisons::VERSION" inside one double-quoted token: the
# namespace prefix is rewritten even though VERSION (all-caps) is exempt
# from variable renaming, and even when variable renaming is disabled.
{
    my $mods = {
        map => { App => 'aq', Saisons => 'ar' },
        pkgs => ['App::Saisons::UI', 'App::Saisons'],
    };
    my $src = q{my $v = "saisons $App::Saisons::VERSION\n";};

    my $mod_only = process($src, rename_vars => 0, global_modules => $mods);
    like $mod_only, qr/\$aq::ar::VERSION/, 'prefix renamed with rename_vars off';
    like $mod_only, qr/VERSION\\n/,        'base name untouched (all-caps)';

    my $with_vars = process($src,
        global_rename_vars => { 'aq::ar' => { VERSION => 'v' } },
        global_modules     => $mods);
    like $with_vars, qr/"saisons \$v\\n"/s,
        'renamed-package key in the global map also renames the base';
}
{
    my %subs = (squeak => 'c', launch => 'd', guard => 'e');
    my $src = q{package Chair;
our @EXPORT_OK = qw(squeak);
sub import { my $c = shift; my $code = $c->can('squeak'); }
sub via_can { my $o = shift; $o->can('squeak') }
sub guard { 1 }
1;};
    my $off = process($src, rename_subs => 1, rename_exports => 0, global_subs => \%subs);
    unlike $off, qr/squeak\)\},/,     'can() string frozen without rename_exports';
    my $on = process($src, rename_subs => 1, rename_exports => 1, global_subs => \%subs);
    like $on, qr/qw\(c\)/,            'export-table qw entry renamed';
    like $on, qr/can\('c'\)/,         'can() string renamed at protocol site';
    unlike $on, qr/squeak/,           'squeak gone from all protocol sites';
}

# ── process: rename_exports leaves data qw/strings alone ─────────────────
{
    my %subs = (squeak => 'c', lib => 'x');
    my %seen;
    my $src = q{my @word = qw(squeak);
use lib qw(lib);
my $m = q{squeak};
# my @pod = qw(squeak)
};
    my $on = process($src, rename_subs => 0, rename_exports => 1, global_subs => \%subs);
    like $on, qr/qw\(squeak\)/, 'non-protocol qw data untouched';
    like $on, qr/use lib/,      'pragma module name untouched';
}

# ── module renaming: class names in qw() follow the rename (Moo's
#    Method::Generate::Accessor: `our @ISA = qw(Moo::Object)`), and XS
#    modules keep their names so XSLoader can find their compiled code ──
{
    my @src = (
        q{package App::Base; sub new { bless {}, shift } 1;},
        q{package App::Child; use App::Base (); our @ISA = qw(App::Base); 1;},
        q{package App::Fast; require XSLoader; XSLoader::load('App::Fast'); 1;},
        q{package App::Fast::Heavy; 1;},
    );
    my (undef, undef, undef, $mods) = collect_bundle_globals(@src);
    my $child = process($src[1], global_modules => $mods);
    my $base  = rename_module_name('App::Base', $mods);
    isnt $base, 'App::Base', 'bundled class renamed';
    like $child, qr/\@ISA=qw\(\Q$base\E\)/, 'class name in qw() renamed with it';
    is rename_module_name('App::Fast', $mods), 'App::Fast', 'XS package keeps its name';
    is rename_module_name('App::Fast::Heavy', $mods), 'App::Fast::Heavy',
        'package under an XS package keeps its name';
    like process($src[2], global_modules => $mods), qr/XSLoader::load\('App::Fast'\)/,
        'XSLoader::load argument untouched';
}

# ── collect_bundle_globals: fourth value is the module struct ────────────
{
    my @data = (
        q{package App::Pack::Red; sub me { 1 } 1;},
        q{package App::Pack::Blue; our @EXPORT_OK = qw(pick); sub pick { 1 } 1;},
        q{use App::Pack::Red; use App::Pack::Blue qw(pick); pick();},
    );
    my ($gmap, $glex, $gsubs, $mods) = collect_bundle_globals(@data, { rename_exports => 1 });
    isa_ok $mods, 'HASH', 'collect_bundle_globals returns module struct';
    ok exists $mods->{pkgs}, 'module struct has pkgs';
is scalar(@{ $mods->{pkgs} }), 2, 'both packages declared';
ok grep($_ eq 'App::Pack::Blue' || $_ eq 'App::Pack::Red', @{ $mods->{pkgs} }),
    'longest package names recorded';
ok exists $mods->{map}->{App} && exists $mods->{map}->{Pack},
    'map has namespace-component keys';
    ok exists $gsubs->{pick}, 'export name eligible via protocol relaxation';
}

done_testing;