package App::Greple::xlate::Mask;

use v5.24;
use warnings;
use Data::Dumper;

use Hash::Util qw(lock_keys);

my %default = (
    TAG       => 'm',
    INDEX     => 'id',
    NUMBER    => 0,
    PATTERN   => [],
    TABLE     => [],
    AUTORESET => 0,
    # --- stable (anonymization) path ---
    STABLE    => 0,     # same (tag, string) -> same tag
    RULES     => undef, # permanent [ [tag, pattern], ... ]
    FILERULES => undef, # per-document rules, replaced via file_rules()
    COUNTER   => undef, # per-tag counters
    ASSIGNED  => undef, # "tag\0string" -> tag string
    ASSIGN_ORDER => undef, # tag strings in assignment order
    ORIGIN    => undef, # tag string -> original string
    TRACK     => undef, # tag string -> 1 (must come back in response)
);

sub new {
    my $class = shift;
    my $obj = bless { %default }, $class;
    # NOTE: reference-valued defaults must get fresh copies here
    $obj->{PATTERN} = [];
    $obj->{TABLE} = [];
    $obj->{RULES} = [];
    $obj->{FILERULES} = [];
    $obj->{COUNTER} = {};
    $obj->{ASSIGNED} = {};
    $obj->{ASSIGN_ORDER} = [];
    $obj->{ORIGIN} = {};
    $obj->{TRACK} = {};
    lock_keys %{$obj};
    $obj->configure(@_);
    $obj;
}

sub reset {
    my $obj = shift;
    $obj->{NUMBER} = 0;
    $obj->{TABLE} = [];
    $obj->{TRACK} = {};
    $obj;
}

sub configure {
    my $obj = shift;
    while (my($a, $b) = splice @_, 0, 2) {
        if ($a eq 'pattern') {
            my @pattern = ref $b ? @$b : $b;
            push @{$obj->{PATTERN}}, @pattern;
        }
        elsif ($a eq 'file') {
            open my $fh, '<:encoding(utf8)', $b or die "$b: $!\n";
            my @p = map s/\\(?=\n)//gr, split /(?<!\\)\n/, do { local $/; <$fh> };
            push @{$obj->{PATTERN}}, @p;
        }
        else {
            $obj->{$a} = $b;
        }
    }
}

sub add_rule {
    my($obj, $tag, $pattern) = @_;
    $tag =~ /\A[a-z][a-z0-9_]*\z/
        or die "$tag: invalid category name.\n";
    push @{$obj->{RULES}}, [ $tag, $pattern ];
    $obj;
}

sub file_rules {
    my($obj, $rules) = @_;
    $obj->{FILERULES} = [ @$rules ];
    $obj;
}

##
## Escape rule: hide pre-existing tag-shaped literals so that every
## tag in the working text is one of ours.  Must be the first rule;
## restored last (rules are restored in reverse order of the TABLE).
##
sub add_escape_rule {
    my $obj = shift;
    unshift @{$obj->{RULES}}, [ 'lit', '<[a-z][a-z0-9_]* [a-z0-9_]+=\d+ */>' ];
    $obj;
}

use JSON;

our $DEFAULT_MARK =
    q[\{\{\s*(?<category>[a-z][a-z0-9_]*)\(\s*(?<q>["'])(?<text>.+?)\k<q>\s*\)\s*\}\}];

sub _check_category {
    my $tag = shift;
    die "lit: reserved category name.\n" if $tag eq 'lit';
    $tag =~ /\A[a-z][a-z0-9_]*\z/
        or die "$tag: invalid category name.\n";
    $tag;
}

sub load_anonymize_file {
    my($obj, $path) = @_;
    open my $fh, '<:encoding(utf8)', $path or die "$path: $!\n";
    my $data = do { local $/; <$fh> };
    $data =~ s/\A\x{FEFF}//;    # tolerate a UTF-8 BOM
    if ($data =~ /\A\s*\[/) {
        my $list = JSON->new->decode($data);
        ref $list eq 'ARRAY' or die "$path: JSON array expected.\n";
        for my $e (@$list) {
            ref $e eq 'HASH' or die "$path: object expected.\n";
            my $cat = _check_category($e->{category}
                // die "$path: category missing.\n");
            my $has_text  = defined $e->{text};
            my $has_regex = defined $e->{regex};
            die "$path: both text and regex given.\n"
                if $has_text and $has_regex;
            die "$path: either text or regex required.\n"
                unless $has_text or $has_regex;
            $obj->add_rule($cat,
                           $has_text ? quotemeta($e->{text}) : $e->{regex});
        }
    } else {
        my @lines = map s/\\(?=\n)//gr, split /(?<!\\)\n/, $data;
        for my $line (@lines) {
            next if $line =~ /^\s*(#|$)/;
            my($cat, $pat) = $line =~ /\A\s*(\S+)\s+(.*?)\s*\z/s
                or die "$path: unparsable line: $line\n";
            _check_category($cat);
            if ($pat =~ m{\A/(.*)/\z}s) {
                $obj->add_rule($cat, $1);
            } else {
                $obj->add_rule($cat, quotemeta($pat));
            }
        }
    }
    $obj;
}

sub extract_marks {
    my($text, $regex) = @_;
    index($regex, '(?<category>') >= 0 and index($regex, '(?<text>') >= 0
        or die "mark regex needs (?<category>...) and (?<text>...) named captures.\n";
    my(%cat, @rules);
    while ($text =~ /$regex/g) {
        my($cat, $str) = ($+{category}, $+{text});
        _check_category($cat);
        if (exists $cat{$str}) {
            $cat{$str} eq $cat
                or die "\"$str\": conflicting categories ($cat{$str} vs $cat).\n";
            next;
        }
        $cat{$str} = $cat;
        push @rules, [ $cat, quotemeta($str) ];
    }
    \@rules;
}

sub _all_rules {
    my $obj = shift;
    (@{$obj->{RULES}}, @{$obj->{FILERULES}});
}

sub _stable_tag {
    my($obj, $tag, $matched) = @_;
    my $key = "$tag\0$matched";
    $obj->{ASSIGNED}{$key} //= do {
        my $t = sprintf("<%s %s=%d />",
                        $tag, $obj->{INDEX}, ++$obj->{COUNTER}{$tag});
        $obj->{ORIGIN}{$t} = $matched;
        push @{$obj->{ASSIGN_ORDER}}, $t;
        $t;
    };
}

sub _mask_stable {
    my($obj, $track) = splice @_, 0, 2;
    for (@_) {
        for my $rule ($obj->_all_rules) {
            my($tag, $pat) = @$rule;
            s{$pat}{
                my $t = $obj->_stable_tag($tag, ${^MATCH});
                $obj->{TRACK}{$t} = 1 if $track;
                $t;
            }gpe;
        }
    }
    return $obj;
}

sub mask {
    my $obj = shift;
    if ($obj->{STABLE}) {
        return $obj->_mask_stable(1, @_);
    }
    my $pattern = $obj->{PATTERN} // die;
    my @patterns = ref $pattern ? @$pattern : $pattern;
    my $fromto = $obj->{TABLE};
    # edit parameters in place
    for (@_) {
        for my $pat (@patterns) {
            next if $pat =~ /^\s*(#|$)/;
            s{$pat}{
                my $tag = sprintf("<%s %s=%d />",
                                  $obj->{TAG}, $obj->{INDEX}, ++$obj->{NUMBER});
                push @$fromto, [ $tag, ${^MATCH} ];
                $tag;
            }gpe;
        }
    }
    return $obj;
}

sub mask_reference {
    my $obj = shift;
    $obj->{STABLE} or die "mask_reference requires STABLE mode.\n";
    $obj->_mask_stable(0, @_);
}

sub unmask {
    my $obj = shift;
    if ($obj->{STABLE}) {
        my %missing = %{$obj->{TRACK}};
        for (@_) {
            # Restore in REVERSE assignment order: the escape rule runs
            # first, so its tags are assigned first and must be restored
            # last -- an escaped literal may itself look like one of our
            # later tags, and restoring it earlier would let a later
            # substitution corrupt it.
            for my $t (reverse @{$obj->{ASSIGN_ORDER}}) {
                my $orig = $obj->{ORIGIN}{$t};
                if (s/\Q$t/$orig/g) {
                    delete $missing{$t};
                }
            }
        }
        if (%missing) {
            die sprintf("Masking error: \"%s\" missing in the output(%s).\n",
                        join('", "', sort keys %missing),
                        join('', @_),
                    );
        }
        return $obj;
    }
    my @tags = map $_->[0], @{$obj->{TABLE}};
    my %tags = map { $_ => 1 } @tags;
    # edit parameters in place
    for (@_) {
        for my $fromto (reverse @{$obj->{TABLE}}) {
            my($from, $to) = @$fromto;
            # update the first one
            if (my $n = s/\Q$from/$to/) {
                if ($n > 1 or not exists $tags{$from}) {
                    warn "Masking error: \"$from\" duplicated.\n";
                }
                delete $tags{$from};
            }
        }
    }
    if (%tags) {
        die sprintf("Masking error: \"%s\" missing in the output(%s).\n",
                    join('", "', keys %tags),
                    join('', @_),
                );
    }
    $obj->reset if $obj->{AUTORESET};
    return $obj;
}

1;
