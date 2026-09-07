package App::SlimPacker;
use strict;
use warnings;
use PPI;
use Exporter 'import';
our $VERSION = '0.04';
our @EXPORT_OK = qw(process process_deps minify_file name_gen needs_space pack_string perl_switches plugin_search_paths inline_plugins module_deps);

sub needs_space {
    my ($l, $r) = @_;
    my $lc = $l->content; my $rc = $r->content;
    my $lr = ref($l);     my $rr = ref($r);
    return 1 if $lc =~ /\w$/ && $rc =~ /^\w/;
    return 1 if $lc =~ /[\$\@\%]$/ && $rc =~ /^\w/;
    return 1 if $lc =~ /\w$/ && $rr =~ /Quote/;
    return 1 if $lr =~ /Quote/ && $rc =~ /^\w/;
    return 1 if $lr =~ /Symbol/ && $rr =~ /Symbol/;
    # A bare Cast sigil (`$`, `@`, `%`) must not be glued to the token before
    # it: `print $fh $$source` -> `print$fh$$source` (or `$fh@$source`)
    # silently changes meaning / breaks parsing.
    return 1 if $rr =~ /Cast/;
    return 1 if $lc =~ /\w$/ && $rc =~ /^['"\/]/;
    return 1 if $lr =~ /Regexp/ && $rc =~ /^\w/;
    # `use Foo VERSION (LIST)` needs the space before the paren; dropping it
    # (e.g. `use Foo 5.57(qw/x/)`) is a Perl syntax error. The paren arrives as
    # a Structure whose content starts with '('.
    return 1 if $lr =~ /Number/ && $rc =~ /^\(/;
    return 0;
}

my @_chars = ('a'..'z');
sub name_gen {
    my ($n) = @_;
    my $out = '';
    $n++;
    while ($n > 0) { $out = $_chars[($n-1)%26] . $out; $n = int(($n-1)/26) }
    return $out;
}

my %KEEP = map { $_ => 1 } qw(
    _ a b 0 1 2 3 4 5 6 7 8 9
    ENV INC ISA ARGV ARGVOUT STDOUT STDERR STDIN
    VERSION AUTOLOAD self class
);

# Quotes that must never be run through B::perlstring()'s blunt double-quoted
# form. Candidate q<delim> delimiters — any punctuation would do, so we use the
# ones least likely to occur in code.  ' and " are excluded (they re-enable
# escaping), \ is excluded (never a delimiter), = is excluded (q= literals
# break on >= => <= inside the content), and the paired brackets ( ) [ ] { } < >
# are excluded because Perl closes them with the *partner* (q<...> closes on >,
# never on <).  All remaining candidates are validated safe with delimiter
# escaping against an adversarial corpus; see pack_string() for the cost rules.
my @_QDELIM = ('^', '~', '|', '?', ',', ';', '!', '#', '&', '-', '+', '*', '/', '%', ':');

# pack_string LITERAL  — shortest exact Perl string literal for arbitrary bytes.
# B::perlstring always emits double quotes and escapes every sigil ("\$x"),
# inflating the bundler's module table by ~15%.  pack_string never uses
# perlstring; content is escaped in place inside quote literals, keeping every
# $ @ % " raw.  Two literal families, priced per byte so the cheaper wins:
#   '...'    cost = 2 (delimiters) + \ occurrences + ' occurrences
#   q<d>...  cost = 3 (q + 2 delimiters) + \ occurrences + <d> occurrences
# because both families must double backslashes, and each must escape its own
# delimiter character.  ' occurring in code is far more common than ^ (or any
# other candidate), so the q<delim> form wins once the content holds a quote,
# and on a tie the q form is preferred for the same reason.  The delimiter with
# the fewest occurrences is picked — no candidate needs to be absent at all.
# Every form round-trips byte-for-byte; validated against a seeded random
# differential corpus.
sub pack_string {
    my ($s) = @_;
    return "''" if $s eq '';
    my $bs = () = $s =~ /\\/g;
    my $q  = () = $s =~ /'/g;
    my ($best_d, $best_occ) = (undef, length($s) + 1);
    for my $d (@_QDELIM) {
        my $occ = () = $s =~ /\Q$d\E/g;
        ($best_d, $best_occ) = ($d, $occ) if $occ < $best_occ;
    }
    if (3 + $bs + $best_occ <= 2 + $bs + $q) {
        (my $e = $s) =~ s/\\/\\\\/g;
        $e =~ s/\Q$best_d\E/\\$best_d/g;
        return 'q' . $best_d . $e . $best_d;
    }
    (my $e = $s) =~ s/([\\'])/\\$1/g;
    return "'$e'";
}

sub process {
    my ($src, %opts) = @_;
    my $doc = PPI::Document->new(\$src) or return $src;
    return _minify_doc($doc, %opts);
}

# Minification core shared by process() and process_deps(): apply the PPI
# comment/POD prune and the rename/whitespace passes to an already-parsed
# document, then optionally the rewrite pass (rewrite => 1).  Returns the
# serialized, minified string.
sub _minify_doc {
    my ($doc, %opts) = @_;
    my $rename_vars = $opts{rename} // 1;
    $doc->prune('PPI::Token::Comment');
    $doc->prune('PPI::Token::Pod');

    return $doc->serialize unless $doc->children;

    my %rename;     # original name -> short name (global per file)
    my $counter = 0;

    if ($rename_vars) {
        my %in_string;

        # Pass 1a: collect variable names inside opaque tokens
        # These embed vars as text, not as PPI::Token::Symbol:
        #   Quote::Double/Interpolate  — "$var", "${var}"
        #   Regexp::Match/Substitute   — m/$var/, s/$old/$new/
        #   QuoteLike::Regexp/Readline/Backtick — qr/$var/, <$fh>, `$cmd`
        #   HereDoc                    — <<"EOF" with $var inside
        my $tok = $doc->first_token;
        while ($tok) {
            my $r = ref($tok);
            if ($r =~ /^PPI::Token::(?:Quote::(?:Interpolate|Double)|Regexp::(?:Match|Substitute)|QuoteLike::(?:Regexp|Readline|Backtick)|HereDoc)$/) {
                my $str = $tok->content;
                $str .= join('', $tok->heredoc) if $r eq 'PPI::Token::HereDoc' && $tok->can('heredoc');
                while ($str =~ /[\$\@]\{?(\w{2,})\b/g) { $in_string{$1} = 1 }
            }
            $tok = $tok->next_token;
        }

        # Pass 1b: collect rename candidates from my declarations only.
        # `local $x` declares a package global (even bare: it localises
        # $PKG::x), and `our $x` is likewise a package global; renaming a
        # global while any surviving $PKG::x reference reads it would break
        # cross-package semantics. `my $x` is a true file lexical, never
        # reachable as a package global, so it is always safe to rename.
        my @decl_names;
        $tok = $doc->first_token;
        while ($tok) {
            if (ref($tok) eq 'PPI::Token::Word' && $tok->content eq 'my') {
                my $next = $tok->snext_sibling or do { $tok = $tok->next_token; next };
                my @syms;
                if ($next->isa('PPI::Token::Symbol')) {
                    @syms = ($next);
                } elsif ($next->isa('PPI::Structure::List')) {
                    @syms = @{ $next->find('PPI::Token::Symbol') // [] };
                }
                for my $sym (@syms) {
                    my (undef, $name) = $sym->content =~ /^([\$\@\%])(.+)$/ or next;
                    # Never rename package globals ($Foo::Bar) or pseudo-vars;
                    # renaming them breaks cross-package semantics. (Bare
                    # `local`/`our` globals are now excluded at the `my`-only
                    # gate above; this guard defends the qualified form.)
                    next if $name =~ /::/;
                    next if length($name) <= 1 || $KEEP{$name}
                         || $name =~ /^[A-Z_]+$/ || $in_string{$name};
                    push @decl_names, $name unless $rename{$name};
                }
            }
            $tok = $tok->next_token;
        }

        # Pass 1c: reserve every symbol name that survives unrenamed,
        # so generated short names can never shadow or collide with them
        my %reserved;
        $tok = $doc->first_token;
        while ($tok) {
            if (ref($tok) eq 'PPI::Token::Symbol' || ref($tok) eq 'PPI::Token::ArrayIndex') {
                my (undef, $name) = $tok->content =~ /^((?:\$#|[\$\@\%]))(.+)$/;
                $reserved{$name} = 1 if defined $name && length $name;
            }
            $tok = $tok->next_token;
        }

        # Assign short names in declaration order
        for my $name (@decl_names) {
            next if exists $rename{$name};
            my $short;
            do { $short = name_gen($counter++) } while $KEEP{$short} || $reserved{$short};
            $rename{$name} = $short;
        }
    }

    # Pass 2: strip whitespace + optionally rename symbols
    my $tok = $doc->first_token;
    while ($tok) {
        my $ref = ref($tok);

        if ($ref eq 'PPI::Token::Whitespace') {
            my $prev = $tok->previous_sibling;
            my $next = $tok->next_sibling;
            $prev = $prev->previous_sibling while $prev && ref($prev) eq 'PPI::Token::Whitespace';
            $next = $next->next_sibling     while $next && ref($next) eq 'PPI::Token::Whitespace';
            if ($prev && $prev->isa('PPI::Token::Separator') && $tok->content =~ /\n/) {
                # __END__ / __DATA__ marker: freeze the whitespace after the
                # marker (skip the collapse below). The marker must finish
                # its own line, or the following data is folded into the
                # marker's line — changing what <DATA> yields, and, when the
                # data starts with punctuation, gluing it onto the marker
                # (`__DATA__\n{pod}` -> `__DATA__{pod}`), ending the data
                # section where it did not before.
            } elsif ($next && ($next->isa('PPI::Statement::Data') || $next->isa('PPI::Statement::End'))
                     && $tok->content =~ /\n/) {
                # ... and the newline before it: collapsing that turns
                # `;__DATA__` into one line, and a mid-line marker is no
                # marker at all — perl only honours it at the start of a line,
                # so the data section would silently vanish.
            } elsif ($prev && $next && needs_space($prev, $next)) {
                $tok->set_content(' ');
            } else {
                $tok->set_content('');
            }
        } elsif ($rename_vars && ($ref eq 'PPI::Token::Symbol' || $ref eq 'PPI::Token::ArrayIndex')) {
            my ($sigil, $name) = $tok->content =~ /^((?:\$#|[\$\@\%]))(.+)$/ or do {
                $tok = $tok->next_token; next;
            };
            if (exists $rename{$name}) {
                $tok->set_content($sigil . $rename{$name});
            }
        }

        $tok = $tok->next_token;
    }

    _rewrite_doc($doc) if $opts{rewrite};

    return $doc->serialize;
}

# Optional pass that rewrites code to shorter equivalent forms, on top of the
# prune/rename/whitespace passes.  Kept as its own method with a single call
# site above so it can be disabled (rewrite => 0) or deleted wholesale (drop
# this method and that one call) if it ever proves unsafe.  Only rewrites that
# are value-preserving are attempted:
#   foreach -> for                      keywords are synonyms
#   m/.../  -> /.../ after =~ or !~     m is optional with / delimiters
#   `;` before `}` dropped              trailing empty statement
#   `$x += 1;` -> `$x++;` (mid-block)   *= 1 vs ++ differ in return value
#   `$x = $x OP $y;` -> `$x OP= $y;`    both assignment forms return OP= value
#   `print($x);` -> `print $x;`         parens dropped on builtin calls
my %PAREN_DROP = map { $_ => 1 } qw(
    print printf sprintf say warn die return exit chomp chop shift unshift
    push pop splice keys values each delete exists defined ref bless length
    substr join split reverse sort grep map scalar rand srand int sqrt abs
    exp log sin cos lc uc lcfirst ucfirst ord chr caller wantarray
);
my %OP_ASSIGN = map { $_ => 1 } qw(. + - * / %);

sub _rewrite_doc {
    my ($doc) = @_;

    # first_token-style walk that skips (already-collapsed) whitespace tokens
    my $tok = $doc->first_token;
    while ($tok) {
        if (ref($tok) eq 'PPI::Token::Word' && $tok->content eq 'foreach') {
            # foreach after an arrow or brace is a method name / hash key
            # ($o->foreach, ->{foreach}), not the loop keyword, so only rewrite
            # it in any other position.
            my $prev = $tok->previous_token;
            $prev = $prev->previous_token while $prev && $prev->isa('PPI::Token::Whitespace');
            $tok->set_content('for')
                unless $prev && ($prev->content eq '->' || $prev->content eq '{' || $prev->content eq '::');
        } elsif ($tok->isa('PPI::Token::Regexp::Match') && $tok->content =~ /^m\//) {
            my $prev = $tok->previous_token;
            $prev = $prev->previous_token while $prev && $prev->isa('PPI::Token::Whitespace');
            $tok->set_content(substr $tok->content, 1)
                if $prev && $prev->isa('PPI::Token::Operator')
                   && ($prev->content eq '=~' || $prev->content eq '!~');
        } elsif ($tok->isa('PPI::Token::Structure') && $tok->content eq ';') {
            my $next = $tok->next_token;
            $next = $next->next_token while $next && $next->isa('PPI::Token::Whitespace');
            $tok->set_content('') if $next && $next->content eq '}';
        }
        $tok = $tok->next_token;
    }

    for my $stmt (@{ $doc->find('PPI::Statement') || [] }) {
        _rewrite_incdec($stmt);
        _rewrite_opassign($stmt);
        _rewrite_parendrop($stmt);
    }
}

sub _rewrite_incdec {
    my ($stmt) = @_;
    return unless $stmt->isa('PPI::Statement');
    my @k = grep { !$_->isa('PPI::Token::Whitespace') } $stmt->children;
    return unless @k == 4;
    return unless $k[0]->isa('PPI::Token::Symbol') || $k[0]->isa('PPI::Token::ArrayIndex');
    return unless $k[1]->isa('PPI::Token::Operator') && $k[1]->content =~ /^[+-]=$/;
    return unless $k[2]->isa('PPI::Token::Number') && $k[2]->content eq '1';
    return unless $k[3]->isa('PPI::Token::Structure') && $k[3]->content eq ';';
    # `$x += 1` returns the new value but `$x++` the old one, so only rewrite
    # statements that are NOT the last one of their enclosing block: the value
    # of any non-final statement is always discarded (void context).
    my $next = $stmt->next_sibling;
    $next = $next->next_sibling while $next && $next->isa('PPI::Token::Whitespace');
    return unless $next;
    $k[1]->set_content($k[1]->content eq '+=' ? '++' : '--');
    $k[2]->set_content('');
}

sub _rewrite_opassign {
    my ($stmt) = @_;
    return unless $stmt->isa('PPI::Statement');
    my @k = grep { !$_->isa('PPI::Token::Whitespace') } $stmt->children;
    return unless @k == 5 || (@k == 6 && $k[5]->isa('PPI::Token::Structure') && $k[5]->content eq ';');
    return unless $k[0]->isa('PPI::Token::Symbol') || $k[0]->isa('PPI::Token::ArrayIndex');
    return unless $k[1]->isa('PPI::Token::Operator') && $k[1]->content eq '=';
    return unless $k[2]->isa(ref $k[0]) && $k[2]->content eq $k[0]->content;
    return unless $k[3]->isa('PPI::Token::Operator') && $OP_ASSIGN{$k[3]->content};
    # Both `$x = $x OP $y` and `$x OP= $y` return $x OP $y, so the rewrite is
    # value-preserving in any context.  The RHS is restricted (by the @k shape
    # above) to a single token, ruling out precedence surprises.
    $k[1]->set_content($k[3]->content . '=');
    $k[2]->set_content('');
    $k[3]->set_content('');
}

sub _rewrite_parendrop {
    my ($stmt) = @_;
    return unless $stmt->isa('PPI::Statement');
    my @k = grep { !$_->isa('PPI::Token::Whitespace') } $stmt->children;
    return unless @k == 2 || (@k == 3 && $k[2]->isa('PPI::Token::Structure') && $k[2]->content eq ';');
    return unless $k[0]->isa('PPI::Token::Word') && $PAREN_DROP{$k[0]->content};
    return unless $k[1]->isa('PPI::Structure::List');
    # Start/end must be exactly the call's argument list (statement-terminal
    # above), and the first argument must be a plain scalar/array/hash variable
    # so the keyword can never glue onto a literal ('print 1' -> print1).
    my $t = $k[1]->start->next_token;
    while ($t && $t->isa('PPI::Token::Whitespace')) { $t = $t->next_token }
    return unless $t && ($t->isa('PPI::Token::Symbol') || $t->isa('PPI::Token::ArrayIndex'));
    $k[1]->start->set_content(' ');
    $k[1]->finish->set_content('');
    return;
}

sub minify_file {
    my ($path, %opts) = @_;
    open my $fh, '<', $path or die "Cannot read $path: $!";
    my $src = do { local $/; <$fh> };
    close $fh;
    # The #! line is a PPI comment, so process() strips it like any other;
    # a minified script must stay runnable, so put it back.
    my ($bang) = $src =~ m{^(\#![^\n]*(?:\n|\z))};
    my $min = process($src, %opts);
    return $bang && $min !~ /^\#/ ? $bang . $min : $min;
}

# Build a perl program from -m/-M/-e/-E switch arguments, perl-binary style.
#   perl_switches(\@m, \@M, \@e, \@E) -> program text
#   -m Foo          -> use Foo ();
#   -M Foo          -> use Foo;
#   -M Foo=bar,baz  -> use Foo qw(bar baz);
#   -M Foo=5.010    -> use Foo 5.010;
#   -M 5.010        -> use 5.010;
#   -E CODE         -> use feature qw(:all); CODE
sub perl_switches {
    my ($m, $M, $e, $E) = @_;
    $_ ||= [] for ($m, $M, $e, $E);
    my @out;
    for my $arg (@$m) { push @out, _use_line($arg, 0) }
    for my $arg (@$M) { push @out, _use_line($arg, 1) }
    if (@$E) { push @out, 'use feature qw(:all);' }
    if (@$e || @$E) { push @out, join("\n", @$e, @$E) }
    return join("\n", @out) . "\n";
}

sub _use_line {
    my ($arg, $with_imports) = @_;
    my ($mod, $terms) = $arg =~ /^([^=\s]+)(?:=(.*))?$/;
    die "bad -m/-M argument: '$arg'\n" unless defined $mod;
    $terms = '' unless defined $terms;
    return "use $mod ();" unless $with_imports;
    return "use $mod;" unless length $terms;
    my @t = split /,/, $terms;
    if (@t == 1 && $t[0] =~ /^(?:\d[\d.]*|v[\d.]+)$/) {
        return "use $mod $t[0];";
    }
    return "use $mod qw(@t);";
}

# Extract the Module::Pluggable search_path(s) from a program's
# 'use Module::Pluggable (...)' statement. Returns a hashref of namespace => 1.
sub plugin_search_paths {
    my ($program) = @_;
    my %searched;
    if ($program =~ m{\buse\s+Module::Pluggable\s*\((.*?)\)\s*;}s) {
        my $args = $1;
        while ($args =~ m~search_path\s*=>\s*(?:(\[[^\]]*\])|("[^"]*")|('[^']*')|(q\{[^}]*\}|q\([^)]*\)|q\[[^\]]*\]|q<[^>]*>))~g) {
            my ($array, $double, $single, $q) = ($1, $2, $3, $4);
            my $spec = defined $array ? $array : defined $double ? $double
                     : defined $single ? $single : $q;
            if (defined $array) {
                $searched{$_} = 1 for _quoted_values($array);
            } else {
                my ($v) = _quoted_values($spec);
                $searched{$v} = 1 if defined $v;
            }
        }
    }
    return \%searched;
}

# Pull the string contents out of any common Perl quote form.
sub _quoted_values {
    my ($s) = @_;
    my @v;
    while ($s =~ m~(?:'([^']*)'|"([^"]*)"|q\{([^}]*)\}|q\(([^)]*)\)|q\[([^\]]*)\]|q<([^>]*)>)~g) {
        my @m = grep { defined } ($1, $2, $3, $4, $5, $6);
        push @v, $m[0];
    }
    return @v;
}

# Extract the statically-declared module dependencies from Perl source.
# Returns a list of module names found via `use`, `require`, `use base`,
# `use parent`, and string-form `require "Foo/Bar.pm"`.  Pragmas (strict,
# warnings, lib, etc.) are skipped.
# Minify and extract dependencies in a single PPI parse.  Returns
# ($minified, @deps) where the minified string is what process() would return
# and @deps is what module_deps() would return on the same source.  Like
# process(), a source that PPI cannot parse is passed through unchanged and
# yields no dependencies.
sub process_deps {
    my ($src, %opts) = @_;
    my $doc = PPI::Document->new(\$src);
    return ($src) unless $doc;
    my @deps = _deps_from_document($doc);
    my $min = _minify_doc($doc, %opts);
    return ($min, @deps);
}

# Extract the statically-declared module dependencies from an already-parsed
# PPI document.  Shared by module_deps() and process_deps() so both report the
# same dependency list.
sub _deps_from_document {
    my ($doc) = @_;
    my @deps;
    my $incs = $doc->find('PPI::Statement::Include') || [];
    for my $i (@$incs) {
        my $type = $i->type;
        next unless defined $type && ($type eq 'use' || $type eq 'require');
        my $mod = $i->module;
        if (defined $mod && length $mod) {
            if ($mod eq 'parent' || $mod eq 'base') {
                for my $tok ($i->arguments) {
                    if ($tok->isa('PPI::Token::QuoteLike::Words')) {
                        push @deps, $tok->literal;
                    } elsif ($tok->isa('PPI::Token::Quote')) {
                        my $str = $tok->string;
                        push @deps, $str if defined $str && length $str;
                    }
                }
                next;
            }
            next if $i->pragma;
            push @deps, $mod;
        } elsif ($type eq 'require') {
            for my $tok ($i->schildren) {
                next unless $tok->isa('PPI::Token::Quote')
                         || $tok->isa('PPI::Token::HereDoc');
                my $str = $tok->string // next;
                next unless $str =~ s{\.pm$}{};
                $str =~ s{/}{::}g;
                push @deps, $str if length $str && $str !~ /[\$\@\%\$\{]/;
            }
        }
    }
    return @deps;
}

sub module_deps {
    my ($src) = @_;
    my $doc = PPI::Document->new(\$src) // die "PPI parse failed";
    return _deps_from_document($doc);
}

# Inline a plugin class list into plugins() based on the Module::Pluggable
# search_path(s) in $program and the available $classes (Class::Name => 1).
# Classes are matched one level deep (Module::Pluggable's default), sorted.
# The 'use Module::Pluggable' statement is removed so it never loads. Programs
# without Module::Pluggable (or without a search_path) are returned unchanged.
sub inline_plugins {
    my ($program, $classes) = @_;
    $classes ||= {};
    my $searched = plugin_search_paths($program);
    return $program unless %$searched;

    my @plugins;
    for my $ns (sort keys %$searched) {
        for my $cp (sort grep { m{^\Q$ns\E::[^:]+$} } keys %$classes) {
            push @plugins, $cp;
        }
    }

my $list = join(',', map { "\"$_\"" } @plugins);
    my $requires = join '', map {
        (my $path = $_) =~ s{::}{/}g; $path .= '.pm'; "require \"$path\";"
    } @plugins;
    $program =~ s{\buse\s+Module::Pluggable\s*\(.*?\)\s*;}{$requires}gs;
    $program =~ s{plugins\(\)}{($list)}gs;
    return $program;
}

1;

=head1 NAME

App::SlimPacker - PPI-based minifier and fatpack-style bundler for standalone Perl scripts

=head1 VERSION

Version 0.04

=head1 SYNOPSIS

    use App::SlimPacker qw(process module_deps inline_plugins);

    # Minify Perl source (strip comments/POD, collapse whitespace, rename vars)
    my $minified = process($source, rename => 1);

    # Extract static dependencies from source
    my @deps = module_deps('use App::Foo; require App::Bar;');

    # Inline Module::Pluggable plugin list
    my $boot = inline_plugins($program, \%classes);

=head1 DESCRIPTION

App::SlimPacker provides a PPI-based minifier and bundling helpers for building
standalone Perl scripts.  It is used by the C<slimpack> CLI to assemble
fatpacked, minified executables.

The minifier (C<process>) strips comments and POD, collapses whitespace, and
optionally renames C<my> variables to short names while respecting
string interpolation, regexes, heredocs, and readlines. C<local>/C<our>
declarations are left untouched because they may be package globals reachable
by a fully-qualified C<$PKG::name> reference elsewhere.  It can also apply an
optional C<rewrite> pass that shortens keywords and operators
(C<foreach> -> C<for>, C<m/.../> -> C</.../> after C<=~>/C<!~>, trailing C<;>
before C<}>, C<+= 1> -> C<++>, C<$x = $x OP $y> -> C<$x OP= $y>, builtin
call parens); see L</process($source, %options)>.  The rewrite pass is
opt-in and self-contained so it can be disabled (C<rewrite => 0>) or removed
from the pipeline entirely if it ever proves unsafe.

The bundling helpers resolve static dependencies, inline Module::Pluggable
plugin lists, and build perl-style switch programs from C<-m>/C<-M>/C<-e>/C<-E>
arguments.

Unlike C<fatpack>, which copies bundled modules verbatim, the C<slimpack>
pipeline runs every module through the PPI minifier.  Packing this C<Moo>
hello-world into a self-contained script:

    package MyGreeter;
    use Moo;
    has name => (is => 'ro', default => sub { 'world' });
    sub greet { my $self = shift; return "Hello, " . $self->name . "!\n"; }
    package main;
    print MyGreeter->new->greet;

with Moo on the module path:

    fatpack pack helloworld.pl > helloworld.fatpack.pl
    slimpack -o helloworld.slimpack.pl helloworld.pl

C<fatpack> produced 294 KB across 9,929 lines, C<slimpack> 59 KB across 27
lines; both print C<Hello, world!> with no C<Moo> and no C<PERL5LIB> at run
time.  Sizes vary with the module set.

=head1 EXPORTS

Nothing is exported by default.  All functions are available for import:

    use App::SlimPacker qw(process module_deps);

=head1 FUNCTIONS

=head2 process($source, %options)

Minifies Perl source code using PPI.  Returns the minified string.

Options:

=over 4

=item rename => 0|1

Rename C<my> variables to short names (C<a>, C<b>, ... C<aa>, ...).
Enabled by default.  Set to C<0> to keep variable names intact (useful for
C<fatlib> core modules).

=item rewrite => 0|1

Apply an additional, optional pass that rewrites code into shorter equivalent
forms.  Disabled by default.  The rewrites are all value-preserving and built
as a self-contained, removable step so the whole pass can be switched off
(C<rewrite => 0>) or deleted (the C<_rewrite_doc> method and its one call site
in C<_minify_doc>) if it ever causes problems.

Currently: C<foreach> -> C<for>; C<m/.../> -> C</.../> when preceded by
C<=~> or C<!~> (the C<m> is optional with C</> delimiters); trailing C<;>
before a closing C<}> is dropped; a C<$x += 1;> statement in a non-final
position becomes C<$x++;> (and C<->= 1> -> C<-->); C<$x = $x OP $y;> with a
single-token RHS becomes C<$x OP= $y;> for C<. + - * / %>; and
parentheses are dropped from statement-terminal builtin calls that take a
variable argument (C<print($x)>, C<return($y)>, C<push(@a, $x)>).

=back

Variable renaming skips names used inside strings, regexes, heredocs, readlines,
backticks, C<%KEEP> names, ALL_CAPS names, and single-character names.

=head2 process_deps($source, %options)

Minifies and resolves dependencies in a single PPI parse.  Returns
C<< ($minified, @deps) >> where C<$minified> is what L</process($source, %options)> would return
for the same source and C<@deps> is what L</module_deps($source)> would return.  Use it
when both quantities are needed for the same file to avoid parsing it twice;
this is what the bundler does for every reachable module.

=head2 minify_file($path, %options)

Reads the file at C<$path> and runs it through L</process($source, %options)> with the given
options.  Dies if the file cannot be read.  Returns the minified string.

A leading C<#!> shebang line is preserved: C<process> strips it as a comment,
and a minified script must stay runnable.

=head2 module_deps($source)

Returns a list of module names statically declared as dependencies in the given
Perl source.  Extracts modules from C<use>, C<require>, C<use base>,
C<use parent>, and string-form C<require "Foo/Bar.pm">.  Pragmas (C<strict>,
C<warnings>, C<lib>, etc.) are skipped.

=head2 plugin_search_paths($program)

Extracts C<Module::Pluggable> search paths from a program's
C<use Module::Pluggable (...)> statement.  Returns a hashref of
C<< namespace => 1 >>.

=head2 inline_plugins($program, \%classes)

Inlines a plugin class list into C<plugins()> calls based on the
C<Module::Pluggable> search paths in C<$program> and the available classes
(hashref of C<< Class::Name => 1 >>).  Classes are matched one level deep
(Module::Pluggable's default), sorted.  The C<use Module::Pluggable> statement
is removed so it never loads at runtime.

Returns the modified program text.  Programs without C<Module::Pluggable> or
without a C<search_path> are returned unchanged.

=head2 perl_switches(\@m, \@M, \@e, \@E)

Builds a Perl program string from C<-m>/C<-M>/C<-e>/C<-E> switch arguments
(perl-binary style).  Returns the program text with appropriate C<use>
statements prepended.

=head2 name_gen($n)

Returns a short variable name for the index C<$n>: C<0> -> C<a>, C<1> -> C<b>,
C<25> -> C<z>, C<26> -> C<aa>, etc.

=head2 needs_space($left_token, $right_token)

Returns 1 if a space is needed between two PPI tokens to prevent them from
merging into a single token, 0 otherwise.

=head2 pack_string($literal)

Returns the shortest exact Perl string literal for an arbitrary byte string.
Used by the bundler to embed minified module sources, where
L<B::perlstring> would double-quote and escape every sigil (C<"\$x">,
C<"\@_">), inflating the bundle by ~15%.  pack_string never uses perlstring;
content is escaped in place inside quote literals, keeping C<$ @ % "> raw.

Two literal families are priced so the cheaper wins:

=over 4

=item *

C<'...'> -- cost 2 (delimiters) + backslash occurrences + single-quote
occurrences, since both C<'> and C<\> must be escaped;

=item *

a C<q<delim>> literal -- delimiter chosen from C<^ ~ | ? , ; ! # & - + * / % :>,
the candidate occurring fewest times in the content.  Cost 3 + backslash
occurrences + delimiter occurrences, since backslashes and the delimiter
character must be escaped.  C<=> is excluded (a C<q=...=> literal breaks when
the content contains a comparison like C< >= >), as are C<< < >> and C<< > >>
(paired delimiters already close on C<< > >>, so C<q<< ... >> > cannot nest);
every candidate above is validated safe with escaping.

=back

C<'> occurs far more often in code than C<^> or any other candidate, so the
q<delim> form wins as soon as the content holds a quote, and wins ties for the
same reason.  No candidate needs to be absent: its occurrences are simply
escaped (C<\^>).  The returned literal always C<eval>s back to the exact
input bytes.

=head1 AUTHOR

Nicolas Mendoza, C<< <mendoza at pvv.ntnu.no> >>

=head1 LICENSE AND COPYRIGHT

This software is licensed under the Artistic License 2.0.  See the F<LICENSE>
file in this distribution for the full text.

=head1 SEE ALSO

L<slimpack>, L<PPI>, L<App::FatPacker>

=cut