package App::SlimPacker;
use strict;
use warnings;
use App::SlimPacker::Minify qw(
    process process_deps minify_file name_gen needs_space
    module_deps collect_bundle_globals
    rename_module_name rename_module_path
);
use Exporter 'import';
our $VERSION = '0.07';
our @EXPORT_OK = qw(
    process process_deps minify_file name_gen needs_space
    pack_string perl_switches plugin_search_paths inline_plugins
    module_deps collect_bundle_globals
    rename_module_name rename_module_path
);

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

# ── Bundle / packing helpers ────────────────────────────────────────

# Quotes that must never be run through B::perlstring()'s blunt double-quoted
# form. Candidate q<delim> delimiters — any punctuation would do, so we use the
# ones least likely to occur in code.  ' and " are excluded (they re-enable
# escaping), \ is excluded (never a delimiter), = is excluded (q= literals
# break on >= => <= inside the content), and the paired brackets ( ) [ ] { } < >
# are excluded because Perl closes them with the *partner* (q<...> closes on >,
# never on <).  All remaining candidates are validated safe with delimiter
# escaping against an adversarial corpus; see pack_string() for the cost rules.
# q-literal delimiter candidates.  `;` is excluded: q;...; is a syntax error
# on perl <= 5.16 (allowed from 5.18), and bundles should run on old perls.
my @_QDELIM = ('^', '~', '|', '?', ',', '!', '#', '&', '-', '+', '*', '/', '%', ':');

# pack_string LITERAL  — shortest exact Perl string literal for arbitrary bytes.
# B::perlstring always emits double quotes and escapes every sigil ("\$x"),
# inflating the bundler's module table by ~15%.  pack_string never uses
# perlstring; content is escaped in place inside quote literals, keeping every
# $ @ % " raw.  Two literal families, priced per byte so the cheaper wins:
#   '...'    cost = 2 (delimiters) + \ occurrences + ' occurrences
#   q<d>...  cost = 3 (q + 2 delimiters) + \ occurrences + <d> occurrences
# because both families must double backslashes (q<d> collapses \\ to \ in
# perl — the same as single quotes do), and each must escape its own delimiter
# character.  ' occurring in code is far more common than ^ (or any other
# candidate), so the q<delim> form wins once the content holds a quote, and on
# a tie the q form is preferred for the same reason.  The delimiter with
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

=head1 NAME

App::SlimPacker - fatpack-style bundling helpers with PPI-based minification for standalone Perl scripts

=head1 VERSION

Version 0.07

=head1 SYNOPSIS

    use App::SlimPacker qw(minify_file pack_string);

    # minify a module and turn it into a Perl string literal for embedding
    my $min     = minify_file('lib/My/Module.pm');
    my $literal = pack_string($min);    # 'package My::Module;...' or q^...^

=head1 DESCRIPTION

App::SlimPacker packs a Perl script and the non-core
modules it uses into a single file that runs on a plain perl, with nothing to
install.  It minifies what it packs: comments, POD
and whitespace are removed, variables, subs and package names are shortened
consistently across the whole bundle, and the result is compressed.

It finds the modules by compiling the script to see what it loads, and by
following the C<use> and C<require> statements in what it finds.  It leaves
out core modules and copies the rest from their installed locations.  Modules found with L<Module::Pluggable> are listed in
the bundle directly, since there is no directory to scan at runtime.

Most users want the L<slimpack> command.  This module holds the helpers it is
built from, and re-exports the minifier from L<App::SlimPacker::Minify>.

=head1 EXPORTS

Nothing by default.  Import what you need:

    use App::SlimPacker qw(pack_string inline_plugins);

=head1 FUNCTIONS

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

a C<q<delim>> literal -- delimiter chosen from C<^ ~ | ? , ! # & - + * / % :>,
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

=head1 AUTHOR

Nicolas Mendoza, C<< <mendoza at pvv.ntnu.no> >>

=head1 LICENSE AND COPYRIGHT

This software is licensed under the Artistic License 2.0.  See the F<LICENSE>
file in this distribution for the full text.

=head1 SEE ALSO

L<App::SlimPacker::Minify>, L<slimpack>, L<PPI>, L<App::FatPacker>

=cut

1;
