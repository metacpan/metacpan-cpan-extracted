package DMS::Parser::Tier1;
# Tier-1 decoder/encoder for DMS.
# Parses _dms_tier:1 documents: extracts imports, scans for decorator calls
# at the four position types (leading, inner, trailing, flow-inner), and
# emits tier-1 wrapper JSON.
#
# Design: two-pass.
#  Pass 1 — source scan: split FM from body, parse FM, validate imports,
#            scan body text for decorator tokens, record (position, path, call).
#  Pass 2 — value parse: feed the decorator-stripped body to the tier-0
#            parser; combine resulting value tree with decorator sidecar.
#
# The tier-0 parser currently rejects _dms_tier:1 in FM and also rejects
# reserved sigil chars at body value positions. We handle FM ourselves (pass 1)
# and strip decorator tokens before handing the body to the tier-0 parser.

use strict;
use warnings;
use utf8;
use Encode qw(decode encode);

our $VERSION = '0.5.3';

# ── ASCII reserved decorator sigil characters ──────────────────────────────────
# (TIER1.md §"Tier-0 reserved decorator sigil set")
my %SIGIL_CHAR = map { $_ => 1 } split //, '!@$%^&*|~`.,><;?=';

sub is_sigil_char { exists $SIGIL_CHAR{$_[0]} }

# ── Extended_Pictographic ranges (frozen Unicode 15.1) ─────────────────────────
# Ported from dms-rs/crates/dms/src/lib.rs `EXTENDED_PICTOGRAPHIC_RANGES`.
my @EXTENDED_PICTOGRAPHIC_RANGES = (
    [0x00A9, 0x00A9], [0x00AE, 0x00AE], [0x203C, 0x203C], [0x2049, 0x2049],
    [0x2122, 0x2122], [0x2139, 0x2139], [0x2194, 0x2199], [0x21A9, 0x21AA],
    [0x231A, 0x231B], [0x2328, 0x2328], [0x2388, 0x2388], [0x23CF, 0x23CF],
    [0x23E9, 0x23F3], [0x23F8, 0x23FA], [0x24C2, 0x24C2], [0x25AA, 0x25AB],
    [0x25B6, 0x25B6], [0x25C0, 0x25C0], [0x25FB, 0x25FE], [0x2600, 0x2605],
    [0x2607, 0x2612], [0x2614, 0x2685], [0x2690, 0x2705], [0x2708, 0x2712],
    [0x2714, 0x2714], [0x2716, 0x2716], [0x271D, 0x271D], [0x2721, 0x2721],
    [0x2728, 0x2728], [0x2733, 0x2734], [0x2744, 0x2744], [0x2747, 0x2747],
    [0x274C, 0x274C], [0x274E, 0x274E], [0x2753, 0x2755], [0x2757, 0x2757],
    [0x2763, 0x2767], [0x2795, 0x2797], [0x27A1, 0x27A1], [0x27B0, 0x27B0],
    [0x27BF, 0x27BF], [0x2934, 0x2935], [0x2B05, 0x2B07], [0x2B1B, 0x2B1C],
    [0x2B50, 0x2B50], [0x2B55, 0x2B55], [0x3030, 0x3030], [0x303D, 0x303D],
    [0x3297, 0x3297], [0x3299, 0x3299], [0x1F000, 0x1F0FF], [0x1F10D, 0x1F10F],
    [0x1F12F, 0x1F12F], [0x1F16C, 0x1F171], [0x1F17E, 0x1F17F], [0x1F18E, 0x1F18E],
    [0x1F191, 0x1F19A], [0x1F1AD, 0x1F1E5], [0x1F201, 0x1F20F], [0x1F21A, 0x1F21A],
    [0x1F22F, 0x1F22F], [0x1F232, 0x1F23A], [0x1F23C, 0x1F23F], [0x1F249, 0x1F3FA],
    [0x1F400, 0x1F53D], [0x1F546, 0x1F64F], [0x1F680, 0x1F6FF], [0x1F774, 0x1F77F],
    [0x1F7D5, 0x1F7FF], [0x1F80C, 0x1F80F], [0x1F848, 0x1F84F], [0x1F85A, 0x1F85F],
    [0x1F888, 0x1F88F], [0x1F8AE, 0x1F8FF], [0x1F90C, 0x1F93A], [0x1F93C, 0x1F945],
    [0x1F947, 0x1FAFF], [0x1FC00, 0x1FFFD],
);

# Binary search over @EXTENDED_PICTOGRAPHIC_RANGES.
sub _is_extended_pictographic {
    my ($cp) = @_;
    return 0 if $cp < 0xA9;
    my ($lo, $hi) = (0, $#EXTENDED_PICTOGRAPHIC_RANGES);
    while ($lo <= $hi) {
        my $mid = int(($lo + $hi) / 2);
        my ($rlo, $rhi) = @{$EXTENDED_PICTOGRAPHIC_RANGES[$mid]};
        if ($cp < $rlo)    { $hi = $mid - 1; }
        elsif ($cp > $rhi) { $lo = $mid + 1; }
        else               { return 1; }
    }
    return 0;
}

# True iff $cp is in the Reserved Emoji Set (SPEC/TIER1).
sub _is_reserved_emoji_codepoint {
    my ($cp) = @_;
    return 1 if $cp >= 0x1F1E6 && $cp <= 0x1F1FF;  # Regional Indicators
    return 1 if $cp >= 0x1F3FB && $cp <= 0x1F3FF;  # Skin-tone modifiers
    return 1 if $cp == 0x20E3;                       # Combining Enclosing Keycap
    return _is_extended_pictographic($cp);
}

sub _is_regional_indicator { my ($cp) = @_; $cp >= 0x1F1E6 && $cp <= 0x1F1FF }
sub _is_emoji_modifier     { my ($cp) = @_; $cp >= 0x1F3FB && $cp <= 0x1F3FF }

# Read one Reserved-Emoji extended grapheme cluster from a *character* string
# starting at character offset $pos. Returns the new position (past the cluster)
# or undef if no emoji cluster starts at $pos.
# The input $str must be a Perl character string (decoded Unicode).
sub _read_reserved_emoji_atom_char {
    my ($str, $pos) = @_;
    my $len = length($str);
    return undef if $pos >= $len;

    my $c0 = substr($str, $pos, 1);
    my $cp0 = ord($c0);
    return undef unless _is_reserved_emoji_codepoint($cp0);

    my $end = $pos + 1;

    # Regional-indicator pair (UAX #29 GB12/GB13)
    if (_is_regional_indicator($cp0)) {
        if ($end < $len) {
            my $c1 = substr($str, $end, 1);
            if (_is_regional_indicator(ord($c1))) {
                $end++;
            }
        }
        return $end;
    }

    # GB9/GB9a/GB11 loop: extend across modifiers, VS-16, keycap combiner, ZWJ+EP
    while ($end < $len) {
        my $c = substr($str, $end, 1);
        my $cp = ord($c);
        if (_is_emoji_modifier($cp) || $cp == 0xFE0F || $cp == 0x20E3) {
            $end++;
            next;
        }
        if ($cp == 0x200D) {
            # ZWJ — continue only if followed by Extended_Pictographic
            my $after_zwj = $end + 1;
            if ($after_zwj < $len) {
                my $nc = substr($str, $after_zwj, 1);
                if (_is_extended_pictographic(ord($nc))) {
                    $end = $after_zwj + 1;
                    next;
                }
            }
            last;  # ZWJ not followed by E_P
        }
        last;
    }
    return $end;
}

# True iff a sigil atom can start at character offset $pos in $str.
# An atom is either an ASCII sigil char or a Reserved-Emoji cluster start.
sub _is_sigil_atom_start {
    my ($str, $pos) = @_;
    return 0 if $pos >= length($str);
    my $c = substr($str, $pos, 1);
    return 1 if is_sigil_char($c);
    return _is_reserved_emoji_codepoint(ord($c));
}

# Consume one sigil atom from character string $str at position $pos.
# Returns new position (past the atom), or undef if not a sigil atom.
sub _consume_sigil_atom {
    my ($str, $pos) = @_;
    return undef if $pos >= length($str);
    my $c = substr($str, $pos, 1);
    if (is_sigil_char($c)) {
        return $pos + 1;
    }
    return _read_reserved_emoji_atom_char($str, $pos);
}

# Bare-key identifier chars (ASCII subset only — we only need this for
# the decorator name after the sigil, which must be ASCII ident).
sub _is_ident_start { defined($_[0]) && $_[0] =~ /[A-Za-z_]/ }
sub _is_ident_cont  { defined($_[0]) && $_[0] =~ /[A-Za-z0-9_\-]/ }

# ── Semver validation ──────────────────────────────────────────────────────────
# Accepts MAJOR.MINOR.PATCH with optional -pre and +build.
# Returns 1 on valid, 0 on invalid.
sub _valid_semver {
    my ($s) = @_;
    # Drop build metadata
    $s =~ s/\+.*$//;
    # Split pre-release
    my ($core, $pre) = split /-/, $s, 2;
    my @parts = split /\./, $core, -1;
    return 0 unless @parts == 3;
    for my $p (@parts) {
        return 0 unless defined $p && $p =~ /^\d+$/;
        return 0 if length($p) > 1 && substr($p, 0, 1) eq '0';  # leading zero
    }
    if (defined $pre) {
        return 0 if $pre eq '';
        for my $id (split /\./, $pre, -1) {
            return 0 if $id eq '';
            if ($id =~ /^\d+$/) {
                return 0 if length($id) > 1 && substr($id, 0, 1) eq '0';
            } else {
                return 0 unless $id =~ /^[A-Za-z0-9\-]+$/;
            }
        }
    }
    return 1;
}

# ── Import extraction and validation ──────────────────────────────────────────
# Extract and validate _dms_imports from a lite-mode parsed meta hashref.
# Returns arrayref of ImportSpec hashrefs, or dies with error message.
sub extract_imports {
    my ($meta) = @_;

    # _dms_imports absent → valid empty
    my $ORDER_KEY = "\0_keys";
    my @meta_keys = $meta->{$ORDER_KEY} ? @{$meta->{$ORDER_KEY}} : ();
    my $raw_list;
    for my $k (@meta_keys) {
        if ($k eq '_dms_imports') { $raw_list = $meta->{$k}; last; }
    }
    return [] unless defined $raw_list;

    # Must be a list
    unless (ref($raw_list) eq 'ARRAY') {
        die "0:0: _dms_imports must be a list\n";
    }

    my @specs;
    # collision tracking: set of (sigil, ns_repr, family) strings
    my %seen_triples;

    for my $ei (0 .. $#$raw_list) {
        my $entry = $raw_list->[$ei];
        unless (ref($entry) eq 'HASH') {
            die "0:0: _dms_imports[$ei] must be a table\n";
        }
        my @entry_keys = $entry->{$ORDER_KEY} ? @{$entry->{$ORDER_KEY}} : keys %$entry;
        # Helper to get value from entry
        my $get = sub { $entry->{$_[0]} };

        # dialect (required string)
        my $dialect_v = $get->('dialect');
        unless (defined $dialect_v && !ref($dialect_v)) {
            if (!defined $dialect_v) {
                die "0:0: _dms_imports[$ei] is missing required field 'dialect'\n";
            }
            die "0:0: _dms_imports[$ei].dialect must be a string\n";
        }
        my $dialect = "$dialect_v";
        die "0:0: _dms_imports[$ei].dialect must be a non-empty string\n" unless length($dialect);

        # version (required string, semver shape, no range specifiers)
        my $version_v = $get->('version');
        unless (defined $version_v && !ref($version_v)) {
            if (!defined $version_v) {
                die "0:0: _dms_imports[$ei] is missing required field 'version'\n";
            }
            die "0:0: _dms_imports[$ei].version must be a string\n";
        }
        my $version = "$version_v";
        die "0:0: _dms_imports[$ei].version must be a non-empty string\n" unless length($version);
        # Reject range specifiers
        my $vtrimmed = $version;
        $vtrimmed =~ s/^\s+//;
        if ($vtrimmed =~ /^[\^~><=]/ || $vtrimmed =~ /^>=/) {
            die "0:0: range-specifier syntax in version not supported"
              . " (_dms_imports[$ei].version \"$version\"):"
              . " write a plain semver string\n";
        }
        unless (_valid_semver($version)) {
            die "0:0: _dms_imports[$ei].version \"$version\" is not a valid semver string"
              . " (expected MAJOR.MINOR.PATCH with optional -pre and +build)\n";
        }

        # ns (optional string)
        my $ns_v = $get->('ns');
        my $ns;
        if (defined $ns_v) {
            unless (!ref($ns_v)) {
                die "0:0: _dms_imports[$ei].ns must be a string\n";
            }
            $ns = "$ns_v";
            die "0:0: _dms_imports[$ei].ns must be a non-empty string when present\n"
                unless length($ns);
        }

        # bind (optional table: sigil → list of family names)
        my %bind;
        my $bind_v = $get->('bind');
        if (defined $bind_v) {
            unless (ref($bind_v) eq 'HASH') {
                die "0:0: _dms_imports[$ei].bind must be a table\n";
            }
            my @bind_keys = $bind_v->{$ORDER_KEY} ? @{$bind_v->{$ORDER_KEY}} : keys %$bind_v;
            for my $sigil (@bind_keys) {
                next if $sigil eq $ORDER_KEY;
                # Validate sigil: each atom must be ASCII sigil char or Reserved-Emoji cluster
                die "0:0: _dms_imports[$ei].bind has an empty sigil key\n" unless length($sigil);
                {
                    my $spos = 0;
                    my $slen = length($sigil);
                    while ($spos < $slen) {
                        my $sc = substr($sigil, $spos, 1);
                        if ($sc eq '_') {
                            die "0:0: _dms_imports[$ei].bind key \"_\" (or containing '_') is invalid:"
                              . " underscore is not in the tier-0 reserved decorator sigil set\n";
                        }
                        my $new_pos = _consume_sigil_atom($sigil, $spos);
                        unless (defined $new_pos) {
                            die "0:0: _dms_imports[$ei].bind key \"$sigil\" contains '$sc'"
                              . " which is not in the tier-0 reserved decorator sigil set\n";
                        }
                        $spos = $new_pos;
                    }
                }
                # Value must be a list of strings
                my $fams_v = $bind_v->{$sigil};
                unless (ref($fams_v) eq 'ARRAY') {
                    die "0:0: _dms_imports[$ei].bind[\"$sigil\"] must be a list"
                      . " (use list form even for a single family)\n";
                }
                my @families;
                for my $fv (@$fams_v) {
                    unless (defined $fv && !ref($fv)) {
                        die "0:0: _dms_imports[$ei].bind[\"$sigil\"] must be a list of strings\n";
                    }
                    push @families, "$fv";
                }
                $bind{$sigil} = \@families;
            }
        }

        # allow (optional table: family → list of names)
        my %allow;
        my $allow_v = $get->('allow');
        if (defined $allow_v) {
            unless (ref($allow_v) eq 'HASH') {
                die "0:0: _dms_imports[$ei].allow must be a table\n";
            }
            my @ak = $allow_v->{$ORDER_KEY} ? @{$allow_v->{$ORDER_KEY}} : keys %$allow_v;
            for my $fam (@ak) {
                next if $fam eq $ORDER_KEY;
                my $names_v = $allow_v->{$fam};
                unless (ref($names_v) eq 'ARRAY') {
                    die "0:0: _dms_imports[$ei].allow[\"$fam\"] must be a list\n";
                }
                my @names;
                for my $nv (@$names_v) {
                    unless (defined $nv && !ref($nv)) {
                        die "0:0: _dms_imports[$ei].allow[\"$fam\"] must be a list of strings\n";
                    }
                    push @names, "$nv";
                }
                $allow{$fam} = \@names;
            }
        }

        # deny (optional table: family → list of names)
        my %deny;
        my $deny_v = $get->('deny');
        if (defined $deny_v) {
            unless (ref($deny_v) eq 'HASH') {
                die "0:0: _dms_imports[$ei].deny must be a table\n";
            }
            my @dk = $deny_v->{$ORDER_KEY} ? @{$deny_v->{$ORDER_KEY}} : keys %$deny_v;
            for my $fam (@dk) {
                next if $fam eq $ORDER_KEY;
                my $names_v = $deny_v->{$fam};
                unless (ref($names_v) eq 'ARRAY') {
                    die "0:0: _dms_imports[$ei].deny[\"$fam\"] must be a list\n";
                }
                my @names;
                for my $nv (@$names_v) {
                    unless (defined $nv && !ref($nv)) {
                        die "0:0: _dms_imports[$ei].deny[\"$fam\"] must be a list of strings\n";
                    }
                    push @names, "$nv";
                }
                $deny{$fam} = \@names;
            }
        }

        # allow/deny mutual exclusion per family
        for my $fam (keys %allow) {
            if (exists $deny{$fam}) {
                die "0:0: _dms_imports[$ei]: family \"$fam\" appears in both"
                  . " 'allow' and 'deny' — they are mutually exclusive for the same family\n";
            }
        }

        # alias (optional table: family → table: alias → canonical)
        my %alias;
        my $alias_v = $get->('alias');
        if (defined $alias_v) {
            unless (ref($alias_v) eq 'HASH') {
                die "0:0: _dms_imports[$ei].alias must be a table\n";
            }
            my @afk = $alias_v->{$ORDER_KEY} ? @{$alias_v->{$ORDER_KEY}} : keys %$alias_v;
            for my $fam (@afk) {
                next if $fam eq $ORDER_KEY;
                my $inner_v = $alias_v->{$fam};
                unless (ref($inner_v) eq 'HASH') {
                    die "0:0: _dms_imports[$ei].alias[\"$fam\"] must be a table (alias → canonical)\n";
                }
                my @ik = $inner_v->{$ORDER_KEY} ? @{$inner_v->{$ORDER_KEY}} : keys %$inner_v;
                my %inner_map;
                for my $alias_name (@ik) {
                    next if $alias_name eq $ORDER_KEY;
                    my $canon_v = $inner_v->{$alias_name};
                    unless (defined $canon_v && !ref($canon_v)) {
                        die "0:0: _dms_imports[$ei].alias[\"$fam\"][\"$alias_name\"] must be a string\n";
                    }
                    $inner_map{$alias_name} = "$canon_v";
                }
                $alias{$fam} = \%inner_map;
            }
        }

        # Cross-import collision check: (sigil, ns_repr, family) must be unique
        my $ns_repr = defined $ns ? $ns : '<unset>';
        for my $sigil (keys %bind) {
            for my $family (@{$bind{$sigil}}) {
                my $triple = "$sigil\0$ns_repr\0$family";
                if (exists $seen_triples{$triple}) {
                    my $prev_idx = $seen_triples{$triple};
                    my $prev = $specs[$prev_idx];
                    die "0:0: Decorator binding collision on (sigil='$sigil', ns=$ns_repr,"
                      . " family='$family'): import #$prev_idx dialect '${\$prev->{dialect}}'"
                      . " v${\$prev->{version}} and import #$ei dialect '$dialect' v$version"
                      . " both bind '$sigil' → '$family'. Resolve by remapping one.\n";
                }
                $seen_triples{$triple} = $ei;
            }
        }

        push @specs, {
            dialect => $dialect,
            version => $version,
            ns      => $ns,        # undef if absent
            bind    => \%bind,
            allow   => \%allow,
            deny    => \%deny,
            alias   => \%alias,
        };
    }

    return \@specs;
}

# ── Decorator call lexer ───────────────────────────────────────────────────────
# Lex a decorator call from string $s starting at offset $pos.
# Returns (sigil, ns_or_undef, fn_name, params_text, end_pos) or undef on failure.
# params_text is everything inside the outermost (...), without the parens.
# Multiple param groups handled by the caller (we lex only one at a time).
#
# On entry, $s[$pos] must be the first sigil char.
# Bound sigils come from the imports array (longest-match).
sub _lex_decorator_call {
    my ($s, $pos, $bound_sigils) = @_;
    my $len = length($s);

    # Consume sigil atoms (ASCII sigil chars and/or Reserved-Emoji clusters)
    my $sig_start = $pos;
    while ($pos < $len) {
        my $new_pos = _consume_sigil_atom($s, $pos);
        last unless defined $new_pos;
        $pos = $new_pos;
    }
    my $raw_sigil = substr($s, $sig_start, $pos - $sig_start);
    return undef unless length($raw_sigil);

    # Match longest registered prefix
    my $sigil = undef;
    for my $bs (sort { length($b) <=> length($a) } @$bound_sigils) {
        if (substr($raw_sigil, 0, length($bs)) eq $bs) {
            $sigil = $bs;
            last;
        }
    }
    return undef unless defined $sigil;
    # Rewind to after sigil
    $pos = $sig_start + length($sigil);

    # Consume identifier (name or ns.name)
    return undef unless $pos < $len && _is_ident_start(substr($s, $pos, 1));
    my $name_start = $pos;
    while ($pos < $len && _is_ident_cont(substr($s, $pos, 1))) {
        $pos++;
    }
    my $first_name = substr($s, $name_start, $pos - $name_start);

    my ($ns, $fn_name);
    if ($pos < $len && substr($s, $pos, 1) eq '.') {
        # Qualified: ns.fn_name
        $pos++;
        return undef unless $pos < $len && _is_ident_start(substr($s, $pos, 1));
        my $fn_start = $pos;
        while ($pos < $len && _is_ident_cont(substr($s, $pos, 1))) {
            $pos++;
        }
        $ns = $first_name;
        $fn_name = substr($s, $fn_start, $pos - $fn_start);
    } else {
        $ns = undef;
        $fn_name = $first_name;
    }

    # Collect param groups: zero or more (...) immediately following
    my @param_groups;
    while ($pos < $len && substr($s, $pos, 1) eq '(') {
        my ($params_text, $new_pos) = _lex_balanced_parens($s, $pos);
        return undef unless defined $params_text;
        push @param_groups, $params_text;
        $pos = $new_pos;
    }
    # If no explicit parens, one empty Named group
    if (!@param_groups) {
        push @param_groups, '';  # bare name → empty named group
    }

    return ($sigil, $ns, $fn_name, \@param_groups, $pos);
}

# Lex balanced parentheses starting at $pos (which must be '(').
# Returns (inner_text, pos_after_close) or (undef, undef) on error.
# String-aware: skips " " and ' ' content, handles \" \' escapes.
sub _lex_balanced_parens {
    my ($s, $pos) = @_;
    my $len = length($s);
    return (undef, undef) unless substr($s, $pos, 1) eq '(';
    $pos++;  # consume opening '('
    my $depth = 1;
    my $start = $pos;
    while ($pos < $len && $depth > 0) {
        my $c = substr($s, $pos, 1);
        if ($c eq '"') {
            $pos++;
            while ($pos < $len) {
                my $ic = substr($s, $pos, 1);
                if ($ic eq '\\') { $pos += 2; next; }
                if ($ic eq '"') { $pos++; last; }
                $pos++;
            }
        } elsif ($c eq "'") {
            $pos++;
            while ($pos < $len) {
                my $ic = substr($s, $pos, 1);
                if ($ic eq "'") { $pos++; last; }
                $pos++;
            }
        } elsif ($c eq '(') {
            $depth++;
            $pos++;
        } elsif ($c eq ')') {
            $depth--;
            $pos++ unless $depth == 0;
            last if $depth == 0;
        } else {
            $pos++;
        }
    }
    return (undef, undef) if $depth != 0;  # unbalanced
    my $inner = substr($s, $start, $pos - $start);
    $pos++;  # consume closing ')'
    return ($inner, $pos);
}

# ── Param group parsing ────────────────────────────────────────────────────────
# Parse the interior of one param group as either named (flow-table) or
# positional (flow-array), using the tier-0 parser.
# Returns a ParamGroup hashref: {kind => 'named'|'positional', value => ...}
sub _parse_param_group {
    my ($inner) = @_;
    # Empty inner → named with empty value
    my $trimmed = $inner;
    $trimmed =~ s/^\s+|\s+$//g;
    if ($trimmed eq '') {
        return { kind => 'named', value => {} };
    }

    # Determine mode by first non-whitespace token:
    # If it looks like `ident:` or `"key":` → named (flow-table)
    # Otherwise → positional (flow-array)
    my $is_named = _looks_like_named($trimmed);

    if ($is_named) {
        # Parse as flow table: `k: { <inner> }` using the tier-0 parser
        my $val = eval {
            require DMS::Parser;
            DMS::Parser::decode_lite_document("k: { $inner }")->{body}{k};
        };
        if ($@ || !defined $val) {
            $val = {};
        }
        return { kind => 'named', value => $val };
    } else {
        # Parse as flow array: `k: [<inner>]`
        my $val = eval {
            require DMS::Parser;
            DMS::Parser::decode_lite_document("k: [$inner]")->{body}{k};
        };
        if ($@ || !ref($val) || ref($val) ne 'ARRAY') {
            $val = [];
        }
        return { kind => 'positional', value => $val };
    }
}

sub _looks_like_named {
    my ($s) = @_;
    # Named if first token is `ident:` or `"key":` etc.
    $s =~ s/^\s+//;
    # Quoted key
    if ($s =~ /^"/) { return 1 if $s =~ /^"(?:[^"\\]|\\.)*"\s*:/; return 0; }
    if ($s =~ /^'/) { return 1 if $s =~ /^'[^']*'\s*:/; return 0; }
    # Bare key
    return 1 if $s =~ /^[A-Za-z_][A-Za-z0-9_\-]*\s*:/;
    return 0;
}


# ── Family resolution ─────────────────────────────────────────────────────────
# Resolve sigil + fn_name through imports.
# Returns (family, canonical_fn) or dies.
sub resolve_call {
    my ($sigil, $ns, $fn_name, $imports) = @_;

    # Filter imports by ns
    my @cand;
    if (defined $ns) {
        @cand = grep { defined($_->{ns}) && $_->{ns} eq $ns } @$imports;
        die "0:0: unknown namespace '$ns'\n" unless @cand;
    } else {
        @cand = @$imports;
    }

    my @accepted;  # (family, canonical)
    for my $imp (@cand) {
        my $families = $imp->{bind}{$sigil};
        next unless defined $families;
        for my $fam (@$families) {
            # Alias resolution
            my $alias_map = $imp->{alias}{$fam};
            my $canonical;
            if ($alias_map) {
                if (exists $alias_map->{$fn_name}) {
                    $canonical = $alias_map->{$fn_name};
                } else {
                    # Check if fn_name is a canonical that has an alias
                    my ($alias_key) = grep { $alias_map->{$_} eq $fn_name } keys %$alias_map;
                    if (defined $alias_key) {
                        die "0:0: '$fn_name' must be written as '$alias_key' (alias declared in import)\n";
                    }
                    $canonical = $fn_name;
                }
            } else {
                $canonical = $fn_name;
            }

            # Allow/deny check
            my $ok;
            if (my $allow = $imp->{allow}{$fam}) {
                $ok = grep { $_ eq $canonical } @$allow;
            } elsif (my $deny = $imp->{deny}{$fam}) {
                $ok = !(grep { $_ eq $canonical } @$deny);
                if (!$ok) {
                    die "0:0: fn '$canonical' is in the deny list for family '$fam'\n";
                }
            } else {
                $ok = 1;
            }
            push @accepted, { family => $fam, canonical => $canonical } if $ok;
        }
    }

    if (!@accepted) {
        die "0:0: name '$fn_name' not found in any family bound to sigil '$sigil'\n";
    }
    if (@accepted > 1) {
        # Collapse: if all agree on family+canonical, unambiguous
        my $first = $accepted[0];
        my $ambiguous = grep {
            $_->{family} ne $first->{family} || $_->{canonical} ne $first->{canonical}
        } @accepted;
        if ($ambiguous) {
            my @fams = do { my %s; grep { !$s{$_->{family}}++ } @accepted };
            my $flist = join(', ', map { "'$_->{family}'" } @fams);
            die "0:0: name '$fn_name' is ambiguous between families $flist under sigil '$sigil';"
              . " qualify as |<ns>.$fn_name(...)\n";
        }
    }

    return ($accepted[0]{family}, $accepted[0]{canonical});
}

# ── Source-level decorator scanner ────────────────────────────────────────────
# Given the body source text and the bound sigils, scan for decorator calls
# and record them with their positions.
#
# Returns:
#   $clean_body — body text with decorator tokens removed (for tier-0 parsing)
#   $raw_decorators — arrayref of raw decorator records:
#     { position => 'leading'|'inner'|'trailing'|'floating',
#       sigil => ..., ns => ..., fn_name => ..., param_groups => [...],
#       path_hint => 'before:<key>' | 'at:<key>' | 'flow_index:<n>' | ... }
#     (path_hint is a string hint used to map to the final path after parsing)
#
# Strategy: process line by line.
#   - A line starting with a sigil char (after indent) → leading decorator
#   - After `key: ` or `+ `, a sigil char → inner decorator; value follows
#   - After a value on a `key:` or `+` line, a sigil char → trailing
#   - Inside `[...]`, a sigil char before a value → flow-inner
#
# We do a single-pass scan using a state machine over the source characters.

sub scan_body {
    my ($body_src, $imports, $line_offset) = @_;
    $line_offset //= 0;

    # Build list of all bound sigils from all imports
    my %all_sigils;
    for my $imp (@$imports) {
        $all_sigils{$_} = 1 for keys %{$imp->{bind}};
    }
    my @bound_sigils = sort { length($b) <=> length($a) } keys %all_sigils;

    # We process the body text character-by-character, tracking context.
    # For simplicity, we process line-by-line for block context and
    # character-by-character within flow expressions.

    my @lines = split /\n/, $body_src, -1;
    my @raw_decs;
    my @clean_lines;
    my $cur_line = $line_offset;

    # State: accumulated leading decorators waiting to attach to next key
    my @pending_leading;

    for my $li (0 .. $#lines) {
        my $line = $lines[$li];
        $cur_line++;

        # Check if line is a decorator-only line (leading position)
        # A leading decorator line starts with optional whitespace then a sigil atom
        # (ASCII sigil char or Reserved-Emoji cluster start).
        my $_leading_indent = '';
        $_leading_indent = $1 if $line =~ /^([ \t]*)/;
        my $_rest_for_check = substr($line, length($_leading_indent));
        if (length($_rest_for_check) > 0 && _is_sigil_atom_start($_rest_for_check, 0)) {
            my $indent = $_leading_indent;
            my $rest = $_rest_for_check;
            # Try to lex a decorator call
            my ($sig, $ns, $fn, $pgs, $end) = eval {
                _lex_decorator_call($rest, 0, \@bound_sigils);
            };
            if (defined $sig) {
                # Check remainder after the call is empty (or whitespace/comment)
                my $after = substr($rest, $end);
                $after =~ s/^\s+//;
                if ($after eq '' || $after =~ /^[#\/]/) {
                    # This is a leading decorator line
                    push @pending_leading, {
                        position   => 'leading',
                        sigil      => $sig,
                        ns         => $ns,
                        fn_name    => $fn,
                        param_groups => $pgs,
                        line       => $cur_line,
                        indent     => length($indent),
                    };
                    push @clean_lines, '';  # remove line
                    next;
                }
            }
        }

        # Not a leading decorator — process as regular content
        # First, flush pending_leading to the first key on this line
        my $processed = _process_line($line, \@bound_sigils, \@pending_leading,
                                       \@raw_decs, $cur_line, $li, \@lines);
        push @clean_lines, $processed;
        @pending_leading = ();  # reset after each non-decorator line
    }

    my $clean_body = join("\n", @clean_lines);
    return ($clean_body, \@raw_decs);
}

# Process one non-leading-only line: handle inner, trailing, and flow-inner
# decorators. Returns the cleaned line text.
sub _process_line {
    my ($line, $bound_sigils, $pending_leading, $raw_decs, $cur_line, $li, $all_lines) = @_;

    # Detect line type: kvpair (`key: ...`), list item (`+ ...`), or other
    # Check for: indent + key + ':' + ' '
    if ($line =~ /^([ \t]*)([A-Za-z_"][^\n]*?:)[ \t](.*)$/ ||
        $line =~ /^([ \t]*)(\+)[ \t](.*)$/) {
        my $indent_str = $1;
        my $key_part   = $2;
        my $value_part = $3;
        my $indent     = length($indent_str);
        my $is_list_item = ($key_part eq '+');

        # Try to extract key name for path purposes
        my $key_name = undef;
        if (!$is_list_item) {
            # Extract key from key_part (strip trailing ':')
            my $kp = $key_part;
            $kp =~ s/:$//;
            $kp =~ s/^\s+|\s+$//g;
            # Remove quotes if quoted
            $kp =~ s/^"(.*)"$/$1/ || $kp =~ s/^'(.*)'$/$1/;
            $key_name = $kp;
        }

        # Check if value_part starts with a sigil (inner decoration)
        my $clean_value = $value_part;
        my $inner_dec = undef;
        my $decoration_only = 0;  # true if inner dec leaves no explicit value

        if (length($value_part) > 0 && _is_sigil_atom_start($value_part, 0)) {
            # Try to lex decorator call at start of value_part
            my ($sig, $ns, $fn, $pgs, $end) = eval {
                _lex_decorator_call($value_part, 0, $bound_sigils);
            };
            if (defined $sig) {
                $inner_dec = {
                    position   => 'inner',
                    sigil      => $sig,
                    ns         => $ns,
                    fn_name    => $fn,
                    param_groups => $pgs,
                    line       => $cur_line,
                    indent     => $indent,
                    key_name   => $key_name,
                    is_list_item => $is_list_item,
                };
                # Strip the decorator from value_part
                my $rest = substr($value_part, $end);
                $rest =~ s/^\s+//;
                $rest =~ s/\s+$//;
                if ($rest eq '' || $rest =~ /^[#\/]/) {
                    # Decoration-only: no explicit value after decorator
                    # Use {} as placeholder so tier-0 parser gets a valid value
                    $clean_value = '{}';
                    $decoration_only = 1;
                } else {
                    $clean_value = $rest;
                }
            }
        }

        # Check for trailing decoration: after the value, a sigil char appears
        my $trailing_dec = undef;
        if (defined $inner_dec) {
            # Look for trailing on the remaining value
            ($clean_value, $trailing_dec) = _extract_trailing($clean_value, $bound_sigils,
                $cur_line, $indent, $key_name, $is_list_item);
        } else {
            ($clean_value, $trailing_dec) = _extract_trailing($value_part, $bound_sigils,
                $cur_line, $indent, $key_name, $is_list_item);
        }

        # Check if value_part has flow-array content with inner decorators
        # (e.g., `[1, |tag() 2, 3]`)
        my ($final_value, $flow_decs) = _extract_flow_decorators(
            $clean_value, $bound_sigils, $cur_line, $indent, $key_name, $is_list_item
        );

        # Rebuild the line
        my $new_line;
        if ($is_list_item) {
            $new_line = "$indent_str+ $final_value";
        } else {
            $new_line = "$indent_str$key_part $final_value";
        }

        # Record decorators with key_name/path hints
        # Flush pending leading onto this key
        for my $ld (@$pending_leading) {
            $ld->{key_name} = $key_name;
            $ld->{is_list_item} = $is_list_item;
            push @$raw_decs, $ld;
        }
        push @$raw_decs, $inner_dec if defined $inner_dec;
        push @$raw_decs, $trailing_dec if defined $trailing_dec;
        push @$raw_decs, @$flow_decs;

        return $new_line;
    }

    # Non-kvpair line: just return as-is
    # Flush any pending leading (they were floating, but we won't handle that now)
    return $line;
}

# Extract a trailing decorator from the end of a value string.
# Returns ($clean_value, $dec_or_undef).
sub _extract_trailing {
    my ($val, $bound_sigils, $cur_line, $indent, $key_name, $is_list_item) = @_;

    # Strip trailing comment
    my $comment = '';
    if ($val =~ s/(\s*(?:#|\/\/).*?)$//) {
        $comment = $1;
    }

    # Check if, after the value, there's a sigil (trailing decorator).
    # The value is everything before any trailing whitespace+sigil.
    # We need to parse from right-to-left: find a sigil run after whitespace.
    # Pattern: `<value> <sigil_chars><ident>[(...)]`
    #
    # Try: scan for the last space+sigil sequence (ASCII or emoji sigil atom)
    if ($val =~ /^(.*?)(\s+)(\S.*)$/) {
        my $value_part = $1;
        my $ws         = $2;
        my $sigil_rest = $3;
        # Only proceed if sigil_rest starts with a sigil atom
        unless (_is_sigil_atom_start($sigil_rest, 0)) {
            return ($val . $comment, undef);
        }
        # Try to lex a decorator call at start of sigil_rest
        my ($sig, $ns, $fn, $pgs, $end) = eval {
            _lex_decorator_call($sigil_rest, 0, $bound_sigils);
        };
        if (defined $sig) {
            # Verify the rest after the call is empty/comment
            my $after = substr($sigil_rest, $end);
            $after =~ s/^\s+//;
            if ($after eq '' || $after =~ /^[#\/]/) {
                my $dec = {
                    position   => 'trailing',
                    sigil      => $sig,
                    ns         => $ns,
                    fn_name    => $fn,
                    param_groups => $pgs,
                    line       => $cur_line,
                    indent     => $indent,
                    key_name   => $key_name,
                    is_list_item => $is_list_item,
                };
                return ($value_part . $comment, $dec);
            }
        }
    }

    return ($val . $comment, undef);
}

# Extract flow-inner decorators from a value that might be a flow array.
# e.g., `[1, |tag() 2, 3]` → clean `[1, 2, 3]`, decs at flow indexes
sub _extract_flow_decorators {
    my ($val, $bound_sigils, $cur_line, $indent, $key_name, $is_list_item) = @_;

    # Quick check: does val look like a flow array with sigil chars?
    my $trimmed = $val;
    $trimmed =~ s/^\s+|\s+$//g;
    # Quick skip: must start with [ to be a flow array
    unless ($trimmed =~ /^\[/) {
        return ($val, []);
    }

    # Parse the flow array, collecting decorators
    my @flow_decs;
    my $new_val = _scan_flow_array($trimmed, $bound_sigils, $cur_line, $indent,
                                    $key_name, $is_list_item, \@flow_decs);
    return (defined $new_val ? $new_val : $val, \@flow_decs);
}

# Scan a flow array string `[...]`, collect inner decorators, return cleaned array.
sub _scan_flow_array {
    my ($src, $bound_sigils, $cur_line, $indent, $key_name, $is_list_item, $flow_decs) = @_;

    return undef unless $src =~ /^\[/;
    my $inner = substr($src, 1, length($src) - 2);  # strip [ ]

    my @elements;
    my @clean_elements;
    my $pos = 0;
    my $len = length($inner);
    my $elem_idx = 0;

    while ($pos < $len) {
        # Skip whitespace
        while ($pos < $len && substr($inner, $pos, 1) =~ /[ \t]/) { $pos++; }
        last if $pos >= $len || substr($inner, $pos, 1) eq ']';

        # Check for inner decorator before this element
        if (_is_sigil_atom_start($inner, $pos)) {
            my ($sig, $ns, $fn, $pgs, $end) = eval {
                _lex_decorator_call($inner, $pos, $bound_sigils);
            };
            if (defined $sig) {
                # Inner decorator on the next element
                push @$flow_decs, {
                    position   => 'inner',
                    sigil      => $sig,
                    ns         => $ns,
                    fn_name    => $fn,
                    param_groups => $pgs,
                    line       => $cur_line,
                    indent     => $indent,
                    key_name   => $key_name,
                    is_list_item => $is_list_item,
                    flow_index => $elem_idx,
                };
                $pos = $end;
                # Skip whitespace
                while ($pos < $len && substr($inner, $pos, 1) =~ /[ \t]/) { $pos++; }
            }
        }

        # Consume the element value
        my ($elem_str, $new_pos) = _consume_flow_element($inner, $pos);
        last unless defined $elem_str;
        push @clean_elements, $elem_str;
        $elem_idx++;
        $pos = $new_pos;

        # Skip whitespace and comma
        while ($pos < $len && substr($inner, $pos, 1) =~ /[ \t]/) { $pos++; }
        if ($pos < $len && substr($inner, $pos, 1) eq ',') { $pos++; }
    }

    return '[' . join(', ', @clean_elements) . ']';
}

# Consume one flow element (a simple value: string, number, bool, nested []).
# Returns (element_string, new_pos) or (undef, undef).
sub _consume_flow_element {
    my ($s, $pos) = @_;
    my $len = length($s);
    my $start = $pos;
    return (undef, undef) if $pos >= $len;

    my $c = substr($s, $pos, 1);
    if ($c eq '"') {
        # Quoted string
        $pos++;
        while ($pos < $len) {
            my $ic = substr($s, $pos, 1);
            if ($ic eq '\\') { $pos += 2; next; }
            if ($ic eq '"') { $pos++; last; }
            $pos++;
        }
    } elsif ($c eq "'") {
        $pos++;
        while ($pos < $len) {
            last if substr($s, $pos, 1) eq "'";
            $pos++;
        }
        $pos++;
    } elsif ($c eq '[') {
        my $depth = 1;
        $pos++;
        while ($pos < $len && $depth > 0) {
            my $ic = substr($s, $pos, 1);
            $depth++ if $ic eq '[';
            $depth-- if $ic eq ']';
            $pos++;
        }
    } elsif ($c eq '{') {
        my $depth = 1;
        $pos++;
        while ($pos < $len && $depth > 0) {
            my $ic = substr($s, $pos, 1);
            $depth++ if $ic eq '{';
            $depth-- if $ic eq '}';
            $pos++;
        }
    } else {
        # Bare value: consume until comma, ], whitespace
        while ($pos < $len) {
            my $ic = substr($s, $pos, 1);
            last if $ic =~ /[,\]\s]/;
            $pos++;
        }
    }

    my $elem = substr($s, $start, $pos - $start);
    $elem =~ s/\s+$//;
    return ($elem, $pos);
}

# ── FM pre-scan ───────────────────────────────────────────────────────────────
# Split source into (fm_src, body_src, tier, fm_line_count).
# Also pre-validate _dms_tier.
sub split_source {
    my ($src) = @_;

    # Look for front matter
    my $fm_end = 0;
    my $tier = 0;
    my $fm_src = '';
    my $body_src = $src;
    my $fm_lines = 0;

    if ($src =~ /\A\s*\+\+\+\r?\n/) {
        # Find closing +++
        if ($src =~ /\A(\s*\+\+\+\r?\n)(.*?)(\+\+\+\r?\n)(.*)\z/s) {
            $fm_src = $2;
            $body_src = $4;
            # Count FM lines
            $fm_lines = ($1 =~ tr/\n//) + ($2 =~ tr/\n//) + ($3 =~ tr/\n//);
        }
    }

    return ($fm_src, $body_src, $fm_lines);
}

# ── Path mapping ──────────────────────────────────────────────────────────────
# Given the raw decorator records (with key_name hints) and the parsed body,
# map each decorator to its actual path in the value tree.
#
# Strategy: walk the raw_decs in order. For each, find the path using key_name.
# Leading decorators: path is the same as the following key's path.
# Inner/trailing: path is the key's path in the body.
# Flow-inner: path is key's path + [index].
#
# We need to know the insertion order of keys to assign leading decorators.
# Since we clean the body before parsing, leading decorator lines are removed,
# but the key they precede is still there.

sub map_decorator_paths {
    my ($raw_decs, $body, $imports) = @_;
    # Group raw_decs by key_name
    # For now, we resolve paths based on key_name and flow_index

    my @entries_map;  # path_str → {path, calls, comments}
    my %path_to_entry;

    for my $rd (@$raw_decs) {
        my $key = $rd->{key_name};
        my $flow_index = $rd->{flow_index};

        # Build path
        my @path;
        if (defined $key && $key ne '') {
            push @path, { key => $key };
        }
        if (defined $flow_index) {
            push @path, { index => $flow_index };
        }

        # Resolve family/canonical from imports
        my ($family, $canonical);
        eval {
            ($family, $canonical) = resolve_call(
                $rd->{sigil}, $rd->{ns}, $rd->{fn_name}, $imports
            );
        };
        if ($@) {
            die $@;
        }

        # Parse param groups
        my @params;
        for my $pg (@{$rd->{param_groups}}) {
            push @params, _parse_param_group($pg);
        }

        my $call = {
            family    => $family,
            fn        => $canonical,
            ns        => $rd->{ns},
            position  => $rd->{position},
            params    => \@params,
            params_dec => [],
            sigil     => $rd->{sigil},
        };

        # Find or create entry for this path
        my $path_key = join('/', map { defined $_->{key} ? "k:$_->{key}" : "i:$_->{index}" } @path);
        if (!exists $path_to_entry{$path_key}) {
            my $entry = {
                path     => \@path,
                calls    => {},
                comments => [],
            };
            push @entries_map, $entry;
            $path_to_entry{$path_key} = $entry;
        }
        my $entry = $path_to_entry{$path_key};
        push @{$entry->{calls}{$rd->{sigil}}}, $call;
    }

    return \@entries_map;
}

# ── Hoist pass ────────────────────────────────────────────────────────────────
# For each inner decorator call with a param named 'children' (content_slot),
# check if body has content at the same path. If body is empty, hoist.
# If body has content AND params have children → conflict error.
sub hoist_pass {
    my ($body, $entries, $imports) = @_;

    for my $entry (@$entries) {
        for my $sigil_calls (values %{$entry->{calls}}) {
            for my $call (@$sigil_calls) {
                # Only hoist for inner position (decoration-only form)
                # Hoist if the call has a 'children' param
                next unless @{$call->{params}};
                my $first_group = $call->{params}[0];
                next unless $first_group->{kind} eq 'named';
                my $named_val = $first_group->{value};
                next unless ref($named_val) eq 'HASH';

                # Check for children key (the content_slot for html/tag family)
                my $ORDER_KEY = "\0_keys";
                my @named_keys = $named_val->{$ORDER_KEY}
                    ? @{$named_val->{$ORDER_KEY}}
                    : grep { $_ ne $ORDER_KEY } keys %$named_val;

                my $has_children = grep { $_ eq 'children' } @named_keys;
                next unless $has_children;

                my $children_val = $named_val->{'children'};

                # Navigate to path in body
                my $body_val = _body_at_path($body, $entry->{path});

                # Check conflict: body value is non-empty?
                my $body_empty = !defined($body_val) || _is_value_empty($body_val);

                if (!$body_empty) {
                    die "0:0: Element |$call->{fn} has content specified via both 'children:' parameter and indent block. Pick one.\n";
                }

                # Hoist: remove children from params, set body
                my %new_named;
                my @new_order;
                for my $k (@named_keys) {
                    next if $k eq 'children';
                    $new_named{$k} = $named_val->{$k};
                    push @new_order, $k;
                }
                $new_named{$ORDER_KEY} = \@new_order;
                $first_group->{value} = \%new_named;

                # Set body at path
                _set_body_at_path($body, $entry->{path}, $children_val);
            }
        }
    }
}

sub _body_at_path {
    my ($body, $path) = @_;
    my $cur = $body;
    for my $seg (@$path) {
        if (defined $seg->{key}) {
            return undef unless ref($cur) eq 'HASH';
            return undef unless exists $cur->{$seg->{key}};
            $cur = $cur->{$seg->{key}};
        } elsif (defined $seg->{index}) {
            return undef unless ref($cur) eq 'ARRAY';
            return undef unless $seg->{index} < scalar @$cur;
            $cur = $cur->[$seg->{index}];
        }
    }
    return $cur;
}

sub _is_value_empty {
    my ($v) = @_;
    return 1 unless defined $v;
    if (ref($v) eq 'HASH') {
        my $ORDER_KEY = "\0_keys";
        my @keys = grep { $_ ne $ORDER_KEY } keys %$v;
        return @keys == 0;
    }
    if (ref($v) eq 'ARRAY') { return @$v == 0; }
    return 1;  # scalars treated as empty for conflict purposes
}

sub _set_body_at_path {
    my ($body, $path, $val) = @_;
    return unless @$path;
    my $cur = $body;
    for my $i (0 .. $#$path - 1) {
        my $seg = $path->[$i];
        if (defined $seg->{key}) {
            $cur = $cur->{$seg->{key}};
        } elsif (defined $seg->{index}) {
            $cur = $cur->[$seg->{index}];
        }
    }
    my $last = $path->[-1];
    if (defined $last->{key}) {
        $cur->{$last->{key}} = $val;
    } elsif (defined $last->{index}) {
        $cur->[$last->{index}] = $val;
    }
}

# ── Decoration-only body fill ─────────────────────────────────────────────────
# For inner-position decoration-only form (`key: |tag()`), the parser sees
# `key: ` with nothing after (or `key: {}` if we add a placeholder).
# We need the body to have `{}` as the value for those keys.
# The clean-body pass should already strip the decorator, leaving `key: `
# which the parser will treat as a block header (empty table).
# No action needed here — the existing parser handles this correctly.

# ── Main entry point ──────────────────────────────────────────────────────────
# decode_t1($src) → hashref with:
#   tier => 1 or 0
#   imports => [...ImportSpec...]
#   body => { tier-0 body }
#   decorators => [...DecoratorEntry...]
#   _raw_doc => the parsed tier-0 document (for body extraction)
#
# Dies with "LINE:COL: message\n" on error.
sub decode_t1 {
    my ($src) = @_;
    require DMS::Parser;

    # ── Step 0: Decode bytes → Perl character string ──
    # encoder.pl reads raw bytes from STDIN; we need a character string for
    # character-level substring ops (especially for multi-byte emoji).
    # NFC-normalize to match the tier-0 parser's behaviour.
    unless (utf8::is_utf8($src)) {
        my $copy = $src;
        if (!utf8::decode($copy)) {
            die "0:0: source is not valid UTF-8\n";
        }
        $src = $copy;
    }
    # NFC-normalize if any non-ASCII chars present (matches Parser behaviour)
    if ($src =~ /[^\x00-\x7F]/) {
        require Unicode::Normalize;
        $src = Unicode::Normalize::NFC($src);
    }

    # ── Step 1: Split source into FM and body ──
    my ($has_fm, $fm_text, $body_text, $fm_line_count) = _split_fm($src);

    # ── Step 2: Detect tier ──
    my $tier = 0;
    if ($has_fm && $fm_text =~ /^[ \t]*_dms_tier[ \t]*:[ \t]*(\d+)[ \t]*$/m) {
        $tier = int($1);
    }

    if ($tier == 0) {
        # Tier-0 doc: parse normally and return tier-0 wrapper
        my $doc = eval { DMS::Parser::decode_lite_document($src) };
        if ($@) { my $err = $@; chomp $err; die "$err\n"; }
        return {
            tier       => 0,
            imports    => [],
            body       => $doc->{body},
            decorators => [],
            _raw_doc   => $doc,
        };
    }

    # ── Step 3: Parse the full FM as tier-0 DMS (allowing _dms_* keys) ──
    # Parse as a plain DMS table (without front matter markers)
    my $fm_parsed = eval { DMS::Parser::decode_lite($fm_text) };
    if ($@) { my $err = $@; chomp $err; die "$err\n"; }

    # ── Step 4: Extract and validate imports ──
    my $imports;
    eval { $imports = extract_imports($fm_parsed); };
    if ($@) { my $err = $@; chomp $err; die "$err\n"; }

    # ── Step 5: Build clean FM (remove _dms_tier and _dms_imports) ──
    # We'll reconstruct a clean version for the tier-0 parser
    my $clean_fm = _strip_dms_reserved_keys($fm_text);

    # ── Step 6: Scan body for decorators ──
    my ($clean_body, $raw_decs) = scan_body($body_text, $imports, $fm_line_count);

    # ── Step 7: Parse clean source with tier-0 parser ──
    my $clean_src;
    if ($has_fm && $clean_fm =~ /\S/) {
        $clean_src = "+++\n${clean_fm}\n+++\n${clean_body}";
    } else {
        $clean_src = $clean_body;
    }

    my $t0_doc = eval { DMS::Parser::decode_lite_document($clean_src) };
    if ($@) { my $err = $@; chomp $err; die "$err\n"; }

    my $body = $t0_doc->{body};

    # ── Step 8: Map decorator records to paths ──
    my $decorator_entries;
    eval { $decorator_entries = map_decorator_paths($raw_decs, $body, $imports); };
    if ($@) { my $err = $@; chomp $err; die "$err\n"; }

    # Hoist pass is registry-dependent (requires dialect spec to know content_slot).
    # Without a registry, skip hoisting — the conformance tests use no registry.
    # eval { hoist_pass($body, $decorator_entries, $imports); };
    # if ($@) { my $err = $@; chomp $err; die "$err\n"; }

    return {
        tier       => 1,
        imports    => $imports,
        body       => $body,
        decorators => $decorator_entries,
        _raw_doc   => $t0_doc,
    };
}

# Split source into (has_fm, fm_text, body_text, fm_line_count).
sub _split_fm {
    my ($src) = @_;
    if ($src =~ /\A([ \t]*\+\+\+[ \t]*\r?\n)(.*?)([ \t]*\+\+\+[ \t]*(?:\r?\n|\z))(.*)\z/s) {
        my ($opener, $fm, $closer, $body) = ($1, $2, $3, $4);
        my $lc = ($opener =~ tr/\n//) + ($fm =~ tr/\n//) + ($closer =~ tr/\n//);
        return (1, $fm, $body, $lc);
    }
    return (0, '', $src, 0);
}

# Remove _dms_tier and _dms_imports from FM text.
# Works by line-scanning: skip _dms_tier line and _dms_imports block.
sub _strip_dms_reserved_keys {
    my ($fm_text) = @_;
    my @lines = split /\n/, $fm_text, -1;
    my @out;
    my $i = 0;
    while ($i < @lines) {
        my $ln = $lines[$i];
        if ($ln =~ /^[ \t]*_dms_tier[ \t]*:/) {
            # Skip this line
            $i++;
            next;
        }
        if ($ln =~ /^[ \t]*_dms_imports[ \t]*:/) {
            # Skip this line and all following indented lines
            $i++;
            while ($i < @lines && ($lines[$i] =~ /^[ \t]+/ || $lines[$i] =~ /^[ \t]*$/)) {
                # Only skip if it's indented (part of the block) or blank
                # But we must not skip next top-level key
                last if $lines[$i] =~ /^[^ \t]/ && $lines[$i] !~ /^[ \t]*$/;
                $i++;
            }
            next;
        }
        push @out, $ln;
        $i++;
    }
    return join("\n", @out);
}

1;

__END__

=encoding UTF-8

=head1 NAME

DMS::Parser::Tier1 - Tier-1 DMS decoder: decorator calls, imports, sigil lexing

=head1 SYNOPSIS

  # Typically called via the high-level wrapper:
  use DMS::Parser;
  my $result = DMS::Parser::decode_t1($src);
  # $result->{tier}       — 0 or 1
  # $result->{imports}    — arrayref of ImportSpec hashrefs
  # $result->{body}       — value tree (same shape as decode())
  # $result->{decorators} — arrayref of decorator entry hashrefs

  # Internal helpers (advanced use):
  use DMS::Parser::Tier1;
  my $imports = DMS::Parser::Tier1::extract_imports($fm_hashref);
  my ($clean_body, $raw_decs) = DMS::Parser::Tier1::scan_body($body_text, $imports);

=head1 DESCRIPTION

DMS::Parser::Tier1 implements the tier-1 DMS decoder. Tier-1 documents carry an
C<_dms_tier: 1> key in their front matter and may contain decorator calls —
sigil-prefixed annotations attached to values at leading, inner, trailing, or
flow-inner positions.

This module is B<internal-ish>: most callers should use C<DMS::Parser::decode_t1>
rather than calling these helpers directly. The public functions are documented
here for integrators who need low-level access to the sigil lexer or import
extractor.

=head1 FUNCTIONS

=head2 decode_t1($src)

Main entry point. Parses C<$src> as a tier-0 or tier-1 DMS document. Returns a
hashref:

=over 4

=item * C<tier> — integer 0 or 1.

=item * C<imports> — arrayref of ImportSpec hashrefs (empty for tier-0 docs).
Each ImportSpec has keys C<dialect>, C<version>, C<ns>, C<bind>, C<allow>,
C<deny>, C<alias>.

=item * C<body> — the decoded value tree (same shape as C<DMS::Parser::decode>).

=item * C<decorators> — arrayref of decorator entry hashrefs, each with C<path>,
C<calls> (hashref of sigil → arrayref of call records), and C<comments>.

=item * C<_raw_doc> — the underlying tier-0 Document (for callers that need the
full Document including front matter and comments).

=back

Dies with a C<line:col: message> diagnostic on parse or validation error.

=head2 extract_imports($meta_hashref)

Extract and validate the C<_dms_imports> list from a parsed front-matter hashref.
Returns an arrayref of ImportSpec hashrefs. Dies on validation error (bad semver,
binding collision, invalid sigil, etc.).

=head2 scan_body($body_src, $imports, $line_offset)

Scan the body source text for decorator calls. Returns C<($clean_body,
$raw_decs)> where C<$clean_body> has all decorator tokens removed (safe to feed
to the tier-0 parser) and C<$raw_decs> is an arrayref of raw decorator records.

=head2 is_sigil_char($char)

Returns true if C<$char> is in the tier-0 reserved ASCII decorator sigil set
(C<! @ $ % ^ & * | ~ ` . , E<gt> E<lt> ; ? =>).

=head2 resolve_call($sigil, $ns, $fn_name, $imports)

Resolve a decorator call through the import table. Returns C<($family,
$canonical_fn)>. Dies on unknown namespace, ambiguous family, or deny-listed
function.

=head1 SEE ALSO

L<DMS::Parser>, L<DMS::Parser::Emitter>,
L<https://gitlab.com/flo-labs/pub/dms>

=head1 AUTHOR

Filip Lopes

=head1 LICENSE

Dual-licensed under the Apache License 2.0 and the MIT license, at your option.

=cut
