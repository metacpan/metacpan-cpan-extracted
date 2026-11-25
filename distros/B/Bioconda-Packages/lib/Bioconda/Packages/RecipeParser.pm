package Bioconda::Packages::RecipeParser;

use strict;
use warnings;
use Exporter 'import';

our $VERSION = '0.01';
our @EXPORT_OK = qw(parse_file parse_string);

=head1 NAME

Bioconda::Packages::RecipeParser - Extract structured metadata from a Bioconda
C<meta.yaml> recipe file.

=head1 SYNOPSIS

    use Bioconda::Packages::RecipeParser qw(parse_file);

    my $info = parse_file('bioconda-recipes/recipes/samtools/meta.yaml');
    print $info->{name};             # samtools
    print $info->{version};          # 1.25
    print "@{ $info->{depends}{run} }";

=head1 DESCRIPTION

Bioconda recipes are Jinja2-templated YAML, which is not valid YAML on its own.
This module does just enough Jinja rendering and a deliberately small YAML-subset
walk to pull out the handful of fields we care about. It is intentionally
dependency-free (core Perl only) and forgiving: anything it cannot resolve is
flagged rather than fatal.

Extracted fields (hashref):

    name version package_names build_number noarch
    summary license license_family home dev_url doc_url
    identifiers outputs depends {build,host,run}
    warnings   (arrayref of parse notes; empty on a clean parse)

Each dependency is C<< { name => 'python', constraint => '>=3.9', platform => undef } >>.

=cut

# Sentinel used for unresolved Jinja function calls like {{ compiler('c') }}.
# Dependency entries containing it are dropped (they are build-system pins, not
# real package dependencies).
my $JINJA_SENTINEL = "\0JINJA\0";

#-----------------------------------------------------------------------------
# Public
#-----------------------------------------------------------------------------

sub parse_file {
    my ($path) = @_;
    open my $fh, '<:encoding(UTF-8)', $path
        or die "Cannot read recipe '$path': $!\n";
    local $/;
    my $text = <$fh>;
    close $fh;
    return parse_string($text);
}

sub parse_string {
    my ($text) = @_;

    my @warnings;
    my $vars = _collect_jinja_vars($text);

    # Render each line: drop {% ... %} control lines, substitute {{ ... }}.
    my @lines;
    for my $line (split /\n/, $text, -1) {
        next if $line =~ /^\s*\{%/;        # {% set ... %}, {% if ... %}, etc.
        push @lines, _render_jinja($line, $vars);
    }
    my $rendered = join "\n", @lines;

    my $tree = _parse_yaml_subset($rendered);

    my %info = (
        name          => undef,
        version       => undef,
        package_names => [],
        build_number  => undef,
        noarch        => undef,
        summary       => undef,
        license       => undef,
        license_family=> undef,
        home          => undef,
        dev_url       => undef,
        doc_url       => undef,
        identifiers   => [],
        outputs       => [],
        depends       => { build => [], host => [], run => [] },
        warnings      => \@warnings,
    );

    # package:
    if (my $pkg = $tree->{package}) {
        $info{name}    = _clean_scalar($pkg->{name});
        $info{version} = _clean_scalar($pkg->{version});
    }

    # build:
    if (my $build = $tree->{build}) {
        $info{build_number} = _clean_scalar($build->{number});
        $info{noarch}       = _clean_scalar($build->{noarch});
    }

    # requirements:
    if (my $req = $tree->{requirements}) {
        for my $kind (qw(build host run)) {
            $info{depends}{$kind} = _deps_from_list($req->{$kind});
        }
    }

    # about:
    if (my $about = $tree->{about}) {
        $info{summary}        = _clean_scalar($about->{summary});
        $info{license}        = _clean_scalar($about->{license});
        $info{license_family} = _clean_scalar($about->{license_family});
        $info{home}           = _clean_scalar($about->{home});
        $info{dev_url}        = _clean_scalar($about->{dev_url});
        $info{doc_url}        = _clean_scalar($about->{doc_url});
    }

    # extra.identifiers:
    if (my $extra = $tree->{extra}) {
        if (ref $extra->{identifiers} eq 'ARRAY') {
            $info{identifiers} =
                [ grep { defined && !/$JINJA_SENTINEL/ }
                  map { _clean_scalar($_) } @{ $extra->{identifiers} } ];
        }
    }

    # outputs: (multi-package recipes). Capture each output's package name and,
    # when present, merge its run requirements into the run dependency set so the
    # names are discoverable.
    my @output_names;
    if (ref $tree->{outputs} eq 'ARRAY') {
        for my $out (@{ $tree->{outputs} }) {
            next unless ref $out eq 'HASH';
            my $oname = _clean_scalar($out->{name});
            next unless defined $oname && length $oname
                     && $oname !~ /$JINJA_SENTINEL/;
            push @output_names, $oname;
        }
    }
    $info{outputs} = \@output_names;

    # The set of installable package names this recipe provides.
    my %names;
    $names{ $info{name} } = 1 if defined $info{name} && length $info{name};
    $names{$_} = 1 for @output_names;
    $info{package_names} = [ sort keys %names ];

    # Sanity flags.
    push @warnings, 'missing package name'
        if !defined $info{name} || !length $info{name};
    push @warnings, 'unresolved jinja in name'
        if defined $info{name} && $info{name} =~ /$JINJA_SENTINEL|\{\{/;
    push @warnings, 'missing version'
        if (!defined $info{version} || !length $info{version})
           && !@output_names;
    push @warnings, 'unresolved jinja in version'
        if defined $info{version} && $info{version} =~ /$JINJA_SENTINEL|\{\{/;

    return \%info;
}

#-----------------------------------------------------------------------------
# Jinja handling
#-----------------------------------------------------------------------------

# Collect {% set key = expr %} declarations into a hash, resolving references to
# previously-set vars and simple string concatenation with '~'.
sub _collect_jinja_vars {
    my ($text) = @_;
    my %vars;
    while ($text =~ /\{%\s*set\s+(\w+)\s*=\s*(.+?)\s*%\}/g) {
        my ($key, $expr) = ($1, $2);
        $vars{$key} = _eval_jinja_expr($expr, \%vars);
    }
    return \%vars;
}

# Evaluate a very small subset of Jinja expressions: quoted strings, numbers,
# bare variable references (optionally with |lower / |upper), and '~'
# concatenation of those. Returns the sentinel for anything else.
sub _eval_jinja_expr {
    my ($expr, $vars) = @_;
    $expr =~ s/^\s+|\s+$//g;

    my @parts = split /\s*~\s*/, $expr;
    my @out;
    for my $p (@parts) {
        push @out, _eval_jinja_atom($p, $vars);
    }
    return $JINJA_SENTINEL if grep { $_ eq $JINJA_SENTINEL } @out;
    return join '', @out;
}

sub _eval_jinja_atom {
    my ($atom, $vars) = @_;
    $atom =~ s/^\s+|\s+$//g;

    # String literal.
    return $1 if $atom =~ /^"([^"]*)"$/;
    return $1 if $atom =~ /^'([^']*)'$/;
    # Number literal.
    return $atom if $atom =~ /^-?\d+(?:\.\d+)?$/;

    # Variable with an optional chain of filters, e.g.
    #   name|lower            version|replace("-", "_")      x|lower|replace('a','b')
    if ($atom =~ /^(\w+)((?:\s*\|\s*\w+(?:\([^)]*\))?)*)\s*$/) {
        my ($name, $filters) = ($1, $2);
        return $JINJA_SENTINEL unless exists $vars->{$name};
        my $val = $vars->{$name};
        return $JINJA_SENTINEL if $val eq $JINJA_SENTINEL;
        while ($filters =~ /\|\s*(\w+)(?:\(([^)]*)\))?/g) {
            my ($f, $args) = ($1, $2);
            if    ($f eq 'lower') { $val = lc $val }
            elsif ($f eq 'upper') { $val = uc $val }
            elsif ($f eq 'replace' && defined $args
                   && $args =~ /["']([^"']*)["']\s*,\s*["']([^"']*)["']/) {
                my ($from, $to) = ($1, $2);
                my $q = quotemeta $from;
                $val =~ s/$q/$to/g;
            }
            # Unknown filters are ignored (keep the value as-is).
        }
        return $val;
    }

    return $JINJA_SENTINEL;   # function calls and anything unsupported
}

# Substitute {{ ... }} expressions within a single line.
sub _render_jinja {
    my ($line, $vars) = @_;
    $line =~ s/\{\{\s*(.+?)\s*\}\}/ _eval_jinja_expr($1, $vars) /ge;
    return $line;
}

#-----------------------------------------------------------------------------
# Minimal YAML-subset parser
#
# Handles mappings, block sequences, nested structures and scalar values -
# enough for the regular shape of Bioconda recipes. It is not a general YAML
# implementation and does not try to be.
#-----------------------------------------------------------------------------

sub _parse_yaml_subset {
    my ($text) = @_;

    # Pre-tokenise into (indent, content) pairs, dropping blanks, full-line
    # comments and YAML document markers. Inline comments (" #...") are stripped
    # YAML-style: only a '#' preceded by whitespace starts a comment, so URLs
    # containing '#' are safe.
    my @toks;
    for my $raw (split /\n/, $text) {
        next if $raw =~ /^\s*$/;
        next if $raw =~ /^\s*#/;
        next if $raw =~ /^---\s*$/ || $raw =~ /^\.\.\.\s*$/;
        (my $noindent = $raw) =~ s/^(\s*)//;
        my $indent = length $1;
        $noindent =~ s/\s+#.*$//;          # strip inline comment / selector
        $noindent =~ s/\s+$//;
        next if $noindent eq '';
        push @toks, [ $indent, $noindent ];
    }

    my $pos = 0;
    my $build;
    $build = sub {
        my ($min_indent) = @_;
        return undef if $pos > $#toks;
        my $indent = $toks[$pos][0];
        return undef if $indent < $min_indent;

        # Sequence?
        if ($toks[$pos][1] =~ /^-\s|^-$/) {
            my @list;
            while ($pos <= $#toks
                   && $toks[$pos][0] == $indent
                   && $toks[$pos][1] =~ /^-(\s+|$)/) {
                my $item = $toks[$pos][1];
                $item =~ s/^-\s*//;
                if ($item eq '') {
                    # "-" alone: nested block follows on deeper indent.
                    $pos++;
                    push @list, $build->($indent + 1);
                }
                elsif ($item =~ /^(\S[^:]*?):(\s.*)?$/
                       && $item !~ m{://}) {
                    # "- key: value" begins an inline mapping within the item.
                    # A mapping requires whitespace after the colon, so scalars
                    # such as "biotools:samtools" are NOT treated as mappings.
                    my $map = {};
                    my ($k, $v) = ($1, $2);
                    $k =~ s/\s+$//;
                    $v = defined $v ? do { (my $t = $v) =~ s/^\s+//; $t } : '';
                    $map->{$k} = ($v eq '') ? undef : $v;
                    $pos++;
                    # Continuation keys of this mapping live at indent+2.
                    my $child_indent = $indent + 2;
                    while ($pos <= $#toks
                           && $toks[$pos][0] >= $child_indent
                           && $toks[$pos][1] !~ /^-/) {
                        my $sub = $build->($child_indent);
                        if (ref $sub eq 'HASH') {
                            %$map = (%$map, %$sub);
                        }
                        last;
                    }
                    # Handle a nested value (e.g. "- name: x" then "  run:" list)
                    while ($pos <= $#toks && $toks[$pos][0] > $indent
                           && $toks[$pos][1] !~ /^-/) {
                        my $sub = $build->($toks[$pos][0]);
                        if (ref $sub eq 'HASH') { %$map = (%$map, %$sub) }
                        else { last }
                    }
                    push @list, $map;
                }
                else {
                    push @list, $item;
                    $pos++;
                }
            }
            return \@list;
        }

        # Mapping.
        my %map;
        while ($pos <= $#toks && $toks[$pos][0] == $indent
               && $toks[$pos][1] !~ /^-/) {
            my ($key, $val) = _split_kv($toks[$pos][1]);
            $pos++;
            if (defined $val && $val ne '') {
                # Block scalar ( "key: |" / "key: >" ): absorb the more-indented
                # body so it cannot leak into following keys.
                if ($val =~ /^[|>][-+]?\d*\s*$/) {
                    my @body;
                    while ($pos <= $#toks && $toks[$pos][0] > $indent) {
                        push @body, $toks[$pos][1];
                        $pos++;
                    }
                    $map{$key} = join ' ', @body;
                }
                # Multi-line quoted scalar: the value opens a quote that is not
                # closed on this line, so keep absorbing lines until it closes.
                elsif (_has_unclosed_quote($val)) {
                    my $full = $val;
                    while ($pos <= $#toks && $toks[$pos][0] > $indent
                           && _has_unclosed_quote($full)) {
                        $full .= ' ' . $toks[$pos][1];
                        $pos++;
                    }
                    $map{$key} = $full;
                }
                else {
                    $map{$key} = $val;
                }
            }
            else {
                # Value is on deeper-indented following lines (block or map).
                if ($pos <= $#toks && $toks[$pos][0] > $indent) {
                    $map{$key} = $build->($indent + 1);
                }
                else {
                    $map{$key} = undef;
                }
            }
        }
        return \%map;
    };

    my $root = $build->(0) // {};
    return ref $root eq 'HASH' ? $root : { _root => $root };
}

# True if the string opens a quote that is not closed on the same line.
sub _has_unclosed_quote {
    my ($s) = @_;
    if ($s =~ /^'/) {
        return $s =~ /^'(?:[^']|'')*'\s*$/ ? 0 : 1;
    }
    if ($s =~ /^"/) {
        return $s =~ /^"(?:[^"\\]|\\.)*"\s*$/ ? 0 : 1;
    }
    return 0;
}

# Split "key: value", being careful not to split on ':' inside a URL or value.
sub _split_kv {
    my ($line) = @_;
    # A mapping key requires whitespace after the colon (or nothing after it).
    # Note some recipes write "name : value" with a space before the colon, so
    # the captured key is right-trimmed.
    if ($line =~ /^([^:][^:]*?)\s*:\s+(.+)$/) {
        (my $k = $1) =~ s/\s+$//;
        return ($k, $2);
    }
    if ($line =~ /^([^:][^:]*?)\s*:\s*$/) {
        (my $k = $1) =~ s/\s+$//;
        return ($k, '');
    }
    return ($line, undef);
}

#-----------------------------------------------------------------------------
# Value helpers
#-----------------------------------------------------------------------------

sub _clean_scalar {
    my ($v) = @_;
    return undef unless defined $v;
    return undef if ref $v;
    $v =~ s/^\s+|\s+$//g;
    # Strip matching surrounding quotes.
    $v =~ s/^"(.*)"$/$1/ or $v =~ s/^'(.*)'$/$1/;
    return undef if $v eq '';
    return undef if $v =~ /$JINJA_SENTINEL/;
    # Normalise YAML booleans/nulls we care about.
    return $v;
}

# Turn a YAML list of dependency strings into structured entries, dropping
# pure-Jinja (build-system) entries.
sub _deps_from_list {
    my ($list) = @_;
    return [] unless ref $list eq 'ARRAY';
    my @deps;
    for my $raw (@$list) {
        next if ref $raw;                      # skip nested structures
        next unless defined $raw;
        my $s = $raw;
        $s =~ s/^\s+|\s+$//g;
        next if $s eq '';
        next if $s =~ /$JINJA_SENTINEL/;       # {{ compiler('c') }} etc.
        next if $s =~ /\{\{/;                  # any leftover jinja
        my ($name, $constraint) = split /\s+/, $s, 2;
        next unless defined $name && length $name;
        push @deps, {
            name       => $name,
            constraint => (defined $constraint && length $constraint)
                          ? $constraint : undef,
            platform   => undef,
        };
    }
    return \@deps;
}

1;
