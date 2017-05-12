package Config::IOD::Document;

our $DATE = '2016-12-29'; # DATE
our $VERSION = '0.33'; # VERSION

use 5.010;
use strict;
use warnings;
#use Carp; # avoided to shave a bit of startup time

use Config::IOD::Constants qw(:ALL);

sub new {
    my ($class, %attrs) = @_;

    if (!$attrs{_parsed}) {
        $attrs{_parsed} = [];
    }
    if (!$attrs{_parser}) {
        require Config::IOD;
        $attrs{_parser} = Config::IOD->new;
    }

    bless \%attrs, $class;
}

sub empty {
    my $self = shift;
    $self->_discard_cache;
    $self->{_parsed} = [];
}

# all _validate_*() methods return ($err_msg, $validated_val)

sub _validate_section {
    my ($self, $name) = @_;
    $name =~ s/\A\s+//;
    $name =~ s/\s+\z//;
    if (!length($name)) { return ("Section name must be non-zero string") }
    if ($name =~ /\R|\]/) { return ("Section name must not contain ] or newline") }
    return ("", $name);
}

sub _validate_key {
    my ($self, $name) = @_;
    $name =~ s/\A\s+//;
    $name =~ s/\s+\z//;
    if (!length($name)) { return ("Key name must be non-zero string") }
    if ($name =~ /\R|=/) { return ("Key name must not contain = or newline") }
    if ($name =~ /\A(?:;|#|\[)/) { return ("Key name must not start with ;, #, [") }
    return ("", $name);
}

sub _validate_value {
    my ($self, $value) = @_;
    $value =~ s/\s+\z//;
    if ($value =~ /\R/) { return ("Value must not contain newline") }
    return ("", $value);
}

sub _validate_comment {
    my ($self, $comment) = @_;
    if ($comment =~ /\R/) { return ("Comment must not contain newline") }
    return ("", $comment);
}

sub _validate_linum {
    my ($self, $value) = @_;
    if ($value < 1) { return ("linum must be at least 1") }
    if ($value > @{$self->{_parsed}}) { return ("linum must not be larger than number of document's lines") }
    return ("", $value);
}

sub _blank_line {
    ["B", "\n"];
}

# cache is used for get_value() and get_raw_value() to avoid re-scanning the
# files on every invocation. but whenever one of document-modifying methods is
# called, we discard the cache
sub _discard_cache {
    my $self = shift;
    delete $self->{_dump_cache};
}

sub dump {
    my $self = shift;
    my $opts;
    if (ref($_[0]) eq 'HASH') {
        $opts = shift;
    } else {
        $opts = {};
    }

    my $parser = $self->{_parser};

    my $linum = 0;
    my $merge;
    my $cur_section = $parser->{default_section};
    my $res = {};
    my $arrayified = {};
    my $num_seen_section_lines = 0;

    my $_merge = sub {
        return if $cur_section eq $merge;
        die "IOD document:$linum: Can't merge section '$merge' to ".
            "'$cur_section': Section '$merge' not seen yet"
                unless exists $res->{$merge};
        for my $k (keys %{ $res->{$merge} }) {
            $res->{$cur_section}{$k} //= $res->{$merge}{$k};
        }
    };

    # TMP HACK. for _decode_expr, this is currently rather hackish because
    # Config::IOD::Base expects some state in $parser
    local $parser->{_res} = $res if $parser->{enable_expr};
    local $parser->{_cur_section} = $cur_section if $parser->{enable_expr};

    for my $line (@{ $self->{_parsed} }) {
        $linum++;
        next if defined($opts->{linum_start}) && $linum < $opts->{linum_start};
        next if defined($opts->{linum_end}  ) && $linum > $opts->{linum_end};

        my $type = $line->[COL_TYPE];
        if ($type eq 'D') {
            my $directive = $line->[COL_D_DIRECTIVE];
            if ($directive eq 'merge') {
                my $args = $parser->_parse_command_line(
                    $line->[COL_D_ARGS_RAW]);
                if (!defined($args)) {
                    die "IOD document:$linum: Invalid arguments syntax '".
                        $line->[COL_D_ARGS_RAW]."'";
                }
                $merge = @$args ? $args->[0] : undef;
            } # ignore the other directives
        } elsif ($type eq 'S') {
            $num_seen_section_lines++;
            # merge previous section
            $_merge->() if defined($merge) && $num_seen_section_lines > 1;
            $cur_section = $line->[COL_S_SECTION];
            $parser->{_cur_section} = $cur_section if $parser->{enable_expr}; #TMP HACK
            $res->{$cur_section} //= {};
        } elsif ($type eq 'K') {
            # the common case is that value are not decoded or
            # quoted/bracketed/braced, so we avoid calling _parse_raw_value here
            # to avoid overhead
            my $key = $line->[COL_K_KEY];
            my $val = $line->[COL_K_VALUE_RAW];
            if ($val =~ /\A["!\\[\{]/) {
                my ($err, $parse_res, $decoded_val) =
                    $parser->_parse_raw_value($val);
                die "IOD document:$linum: Invalid value: $err" if $err;
                $val = $decoded_val;
            } else {
                $val =~ s/\s*[#;].*//; # strip comment
            }

            if (exists $res->{$cur_section}{$key}) {
                if (!$parser->{allow_duplicate_key}) {
                    die "IOD document:$linum: Duplicate key: $key ".
                        "(section $cur_section)";
                } elsif ($arrayified->{$cur_section}{$key}++) {
                    push @{ $res->{$cur_section}{$key} }, $val;
                } else {
                    $res->{$cur_section}{$key} = [
                        $res->{$cur_section}{$key}, $val];
                }
            } else {
                $res->{$cur_section}{$key} = $val;
            }
        } # ignore the other line types
    }

    $_merge->() if defined($merge) && $num_seen_section_lines > 1;;

    $res;
}

sub each_key {
    my $self = shift;
    my $opts;
    if (ref($_[0]) eq 'HASH') {
        $opts = shift;
    } else {
        $opts = {};
    }
    my ($code) = @_;

    my $parser = $self->{_parser};

    my $linum = 0;
    my $cur_section = $parser->{default_section};

    my $skip_section;
    my %seen_sections;
    my %seen_keys;
    for my $line (@{ $self->{_parsed} }) {
        $linum++;
        next if defined($opts->{linum_start}) && $linum < $opts->{linum_start};
        next if defined($opts->{linum_end}  ) && $linum > $opts->{linum_end};

        my $type = $line->[COL_TYPE];
        if ($type eq 'S') {
            $cur_section = $line->[COL_S_SECTION];
            %seen_keys = ();
            $skip_section = $opts->{unique_section} &&
                $seen_sections{$cur_section}++;
        } elsif ($type eq 'K') {
            next if $skip_section;
            my $key = $line->[COL_K_KEY];
            next if $opts->{unique_key} && $seen_keys{$key}++;
            $code->(
                $self,
                linum     => $linum,
                section   => $cur_section,
                key       => $key,
                raw_value => $line->[COL_K_VALUE_RAW],
            );
        }
    }
}

sub get_value {
    my ($self, $section, $key) = @_;
    $self->{_dump_cache} = $self->dump unless $self->{_dump_cache};
    $self->{_dump_cache}{$section}{$key};
}

sub get_directive_before_key {
    my ($self, $section, $key) = @_;

    my $found;
    $self->each_key(
        sub {
            my ($self, %args) = @_;
            return if $found;
            return unless $args{linum} > 1;
            return unless $args{section} eq $section;
            return unless $args{key} eq $key;
            my $l = $self->{_parsed}[ $args{linum}-1-1 ];
            return unless $l->[COL_TYPE] eq 'D';
            my $p = $self->{_parser};
            $found = [
                $l->[COL_D_DIRECTIVE],
                @{ $p->_parse_command_line($l->[COL_D_ARGS_RAW]) // [] },
            ];
        },
    );
    $found;
}

sub list_keys {
    my $self = shift;
    my $opts;
    if (ref($_[0]) eq 'HASH') {
        $opts = shift;
    } else {
        $opts = {};
    }
    my ($section) = @_;

    my @res;
    my %mem;
    $self->each_key(
        sub {
            my ($self, %args) = @_;
            return unless $args{section} eq $section;
            return if $opts->{unique} && $mem{$args{key}}++;
            push @res, $args{key};
        },
    );
    @res;
}

sub _find_section {
    my $self = shift;
    my $opts;
    if (ref($_[0]) eq 'HASH') {
        $opts = shift;
    } else {
        $opts = {};
    }
    my ($name) = @_;

    my @res;

    my $linum = 0;
    for my $line (@{ $self->{_parsed} }) {
        $linum++;
        next unless $line->[COL_TYPE] eq 'S';
        if (defined $name) {
            next unless $line->[COL_S_SECTION] eq $name;
        }
        return $linum unless $opts->{all};
        push @res, $linum;
    }
    return undef unless $opts->{all};
    return @res;
}

sub each_section {
    my $self = shift;
    my $opts;
    if (ref($_[0]) eq 'HASH') {
        $opts = shift;
    } else {
        $opts = {};
    }
    my ($code) = @_;

    my $parsed = $self->{_parsed};
    my @linums = $self->_find_section({all=>1});
    my %seen;
    for my $linum (@linums) {
        my $section = $parsed->[$linum-1][COL_S_SECTION];
        next if $opts->{unique} && $seen{$section}++;

        my $linum_end = $linum;
        while (1) {
            last if $linum_end >= @$parsed;
            last if $parsed->[$linum_end][COL_TYPE] eq 'S';
            $linum_end++;
        }

        $code->(
            $self,
            linum       => $linum,
            linum_start => $linum,
            linum_end   => $linum_end,
            parsed      => $parsed->[$linum-1],
            section     => $section,
        );
    }
}

sub list_sections {
    my $self = shift;
    my $opts;
    if (ref($_[0]) eq 'HASH') {
        $opts = shift;
    } else {
        $opts = {};
    }

    my @res;
    $self->each_section(
        $opts,
        sub {
            my ($self, %args) = @_;
            push @res, $args{section};
        }
    );
    @res;
}

sub _get_section_line_range {
    my $self = shift;
    my $opts;
    if (ref($_[0]) eq 'HASH') {
        $opts = shift;
    } else {
        $opts = {};
    }
    my ($name) = @_;

    my @res;

    my $linum = 0;
    my $cur_section = $self->{_parser}{default_section};
    my $prev_section;
    my $start;
    for my $line (@{ $self->{_parsed} }) {
        $linum++;
        if ($line->[COL_TYPE] eq 'S') {
            $cur_section = $line->[COL_S_SECTION];
            if ($cur_section eq $name) {
                $start = $linum+1;
                $res[-1][1] = $linum if @res && !defined $res[-1][1];
                push @res, [$start, undef];
            } else {
                $res[-1][1] = $linum if @res;
                last if @res && !$opts->{all};
            }
        }
    }
    $res[-1][1] = $linum+1 if @res && !defined($res[-1][1]);

  L1:
    if ($opts->{all}) { return @res } else { return $res[0] }
}

sub _find_key {
    my $self = shift;
    my $opts;
    if (ref($_[0]) eq 'HASH') {
        $opts = shift;
    } else {
        $opts = {};
    }
    my ($section, $name) = @_;

    my @res;

    my $linum = 0;
    my $cur_section = $self->{_parser}{default_section};
    for my $line (@{ $self->{_parsed} }) {
        $linum++;
        if ($line->[COL_TYPE] eq 'S') {
            $cur_section = $line->[COL_S_SECTION];
            next;
        }
        next unless $line->[COL_TYPE] eq 'K';
        next unless $cur_section eq $section;
        next unless $line->[COL_K_KEY] eq $name;
        return $linum unless $opts->{all};
        push @res, $linum;
    }
    return undef unless $opts->{all};
    return @res;
}

sub _line_in_section {
    my $self = shift;
    my $opts;
    if (ref($_[0]) eq 'HASH') {
        $opts = shift;
    } else {
        $opts = {};
    }
    my ($asked_linum, $asked_section) = @_;

    my @res;

    my $linum = 0;
    my $cur_section = $self->{_parser}{default_section};
    for my $line (@{ $self->{_parsed} }) {
        $linum++;
        if ($linum == $asked_linum) {
            return $asked_section eq $cur_section;
        }
        if ($line->[COL_TYPE] eq 'S') {
            $cur_section = $line->[COL_S_SECTION];
        }
    }
    return 0;
}

sub insert_section {
    my $self = shift;
    my $opts;
    if (ref($_[0]) eq 'HASH') {
        $opts = shift;
    } else {
        $opts = {};
    }

    my ($err, $name) = $self->_validate_section($_[0]);
    die $err if $err;

    my $p = $self->{_parsed};

    if (defined $opts->{comment}) {
        ($err, $opts->{comment}) = $self->_validate_comment($opts->{comment});
        die $err if $err;
    }

    if ($self->_find_section($name)) {
        if ($opts->{ignore}) {
            return undef;
        } else {
            die "Can't insert section '$name': already exists";
        }
    }

    my $linum;
    if (defined $opts->{linum}) {
        ($err, $opts->{linum}) = $self->_validate_linum($opts->{linum});
        die $err if $err;
        $linum = $opts->{linum};
    } elsif ($opts->{top}) {
        $linum = $self->_find_section;
        $linum //= 1;
    } else {
        $linum = @$p + 1;
    }

    splice @$p, $linum-1, 0, [
        'S',
        '', # COL_S_WS1
        '', # COL_S_WS2
        $name, # COL_S_SECTION
        '', # COL_S_WS3
        defined($opts->{comment}) ? ' ' : undef, # COL_S_WS4
        defined($opts->{comment}) ? ';' : undef, # COL_S_COMMENT_CHAR
        $opts->{comment}, # COL_S_COMMENT
        "\n", # COL_S_NL
    ];

    $self->_discard_cache;
    $linum;
}

sub insert_key {
    my $self = shift;
    my $opts;
    if (ref($_[0]) eq 'HASH') {
        $opts = shift;
    } else {
        $opts = {};
    }

    my $err;
    my ($err_section, $section) = $self->_validate_section($_[0]);
    die $err_section if $err_section;
    my ($err_name, $name)       = $self->_validate_key($_[1]);
    die $err_name if $err_name;
    my ($err_value, $value)     = $self->_validate_value($_[2]);
    die $err_value if $err_value;

    my $p = $self->{_parsed};

    my $linum;

    if ($opts->{replace}) {
        $self->delete_key({all=>1}, $section, $name);
    }

    # find section
    my $line_range = $self->_get_section_line_range($section);
    if (!$line_range) {
        if ($opts->{create_section}) {
            $linum = $self->insert_section($section) + 1;
            $line_range = [$linum, $linum];
        } else {
            die "Can't insert key '$name': unknown section '$section'";
        }
    }

    unless (defined $linum) {
        $linum = $self->_find_key($section, $name);
        if ($linum) {
            if ($opts->{ignore}) {
                return undef;
            } elsif ($opts->{add}) {
                #
            } elsif ($opts->{replace}) {
                # delete already done above
            } else {
                die "Can't insert key '$name': already exists";
            }
        }

        if ($opts->{linum}) {
            ($err, $opts->{linum}) = $self->_validate_linum($opts->{linum});
            die $err if $err;
            $self->_line_in_section($opts->{linum}, $section)
                or die "Invalid linum $opts->{linum}: not inside section '$section'";
            $linum = $opts->{linum};
        } else {
            if ($opts->{top}) {
                $linum = $line_range->[0];
            } else {
                $linum = $line_range->[1];
                if ($p->[$linum-1]) {
                    if ($p->[$linum-1][COL_TYPE] eq 'S') {
                    } else {
                        $linum++;
                    }
                }
            }
        }
    }

    #XXX implement option: replace

    splice @$p, $linum-1, 0, [
        'K',
        '', # COL_K_WS1
        $name, # COL_K_KEY
        '', # COL_K_WS2
        '', # COL_K_WS3
        $value, # COL_K_VALUE_RAW
        "\n", # COL_K_NL
    ];
    $self->_discard_cache;
    $linum;
}

sub delete_section {
    my $self = shift;
    my $opts;
    if (ref($_[0]) eq 'HASH') {
        $opts = shift;
    } else {
        $opts = {};
    }

    my ($err, $section) = $self->_validate_section($_[0]);
    die $err if $err;

    my $p = $self->{_parsed};

    my @line_ranges;
    if ($opts->{all}) {
        @line_ranges = $self->_get_section_line_range({all=>1}, $section);
    } else {
        @line_ranges = ($self->_get_section_line_range($section));
        @line_ranges = () if !defined($line_ranges[0]);
    }

    if ($opts->{cond}) {
        @line_ranges = grep {
            $opts->{cond}->(
                $self,
                linum_start => $_->[0],
                linum_end   => $_->[1],
            );
        } @line_ranges;
    }

    my $num_deleted = 0;
    for my $line_range (reverse @line_ranges) {
        next unless defined $line_range;
        my $line1 = $line_range->[0] - 1; $line1 = 1 if $line1 < 1;
        my $line2 = $line_range->[1] - 1;
        splice @$p, $line1-1, ($line2-$line1+1);
        $num_deleted++;
    }
    $self->_discard_cache if $num_deleted;
    $num_deleted;
}

sub delete_key {
    my $self = shift;
    my $opts;
    if (ref($_[0]) eq 'HASH') {
        $opts = shift;
    } else {
        $opts = {};
    }

    my ($err_section, $section) = $self->_validate_section($_[0]);
    die $err_section if $err_section;
    my ($err_name, $name) = $self->_validate_key($_[1]);
    die $err_name if $err_name;

    my $p = $self->{_parsed};

    my @linums;
    if ($opts->{all}) {
        @linums = $self->_find_key({all=>1}, $section, $name);
    } else {
        @linums = ($self->_find_key($section, $name));
        @linums = () if !defined($linums[0]);
    }

    if ($opts->{cond}) {
        @linums = grep {
            my $line = $self->{_parsed}[$_-1];
            $opts->{cond}->(
                $self,
                linum     => $_,
                parsed    => $line,
                key       => $line->[COL_K_KEY],
                raw_value => $line->[COL_K_VALUE_RAW],
                # XXX value
            );
        } @linums;
    }

    my $num_deleted = 0;
    for my $linum (reverse @linums) {
        splice @$p, $linum-1, 1;
        $num_deleted++;
    }

    $self->_discard_cache if $num_deleted;
    $num_deleted;
}

sub set_value {
    my $self = shift;
    my $opts;
    if (ref($_[0]) eq 'HASH') {
        $opts = shift;
    } else {
        $opts = {};
    }

    my $section = $_[0];
    my $key     = $_[1];
    my ($err_value, $value) = $self->_validate_value($_[2]);
    die $err_value if $err_value;

    my $found;
    $self->each_key(
        sub {
            my ($self, %args) = @_;
            return if $found && !$opts->{all};
            return unless $args{section} eq $section;
            return unless $args{key} eq $key;
            $found++;
            my $l = $self->{_parsed}[ $args{linum}-1 ];
            $l->[COL_K_VALUE_RAW] = $value;
        },
    );
}

sub as_string {
    my $self = shift;

    my $abo = $self->{_parser}{allow_bang_only};

    my @str;
    my $linum = 0;
    for my $line (@{$self->{_parsed}}) {
        $linum++;
        my $type = $line->[COL_TYPE];
        if ($type eq 'B') {
            push @str, $line->[COL_B_RAW];
        } elsif ($type eq 'D') {
            push @str, join(
                "",
                ($abo ? $line->[COL_D_COMMENT_CHAR] : ";"),
                $line->[COL_D_WS1], "!",
                $line->[COL_D_WS2],
                $line->[COL_D_DIRECTIVE],
                $line->[COL_D_WS3],
                $line->[COL_D_ARGS_RAW],
                $line->[COL_D_NL],
            );
        } elsif ($type eq 'C') {
            push @str, join(
                "",
                $line->[COL_C_WS1],
                $line->[COL_C_COMMENT_CHAR],
                $line->[COL_C_COMMENT],
                $line->[COL_C_NL],
            );
        } elsif ($type eq 'S') {
            push @str, join(
                "",
                $line->[COL_S_WS1], "[",
                $line->[COL_S_WS2],
                $line->[COL_S_SECTION],
                $line->[COL_S_WS3], "]",
                $line->[COL_S_WS4] // '',
                $line->[COL_S_COMMENT_CHAR] // '',
                $line->[COL_S_COMMENT] // '',
                $line->[COL_S_NL],
            );
        } elsif ($type eq 'K') {
            push @str, join(
                "",
                $line->[COL_K_WS1],
                $line->[COL_K_KEY],
                $line->[COL_K_WS2], "=",
                $line->[COL_K_WS3],
                $line->[COL_K_VALUE_RAW],
                $line->[COL_K_NL],
            );
        } else {
            die "BUG: Unknown type '$type' in line $linum";
        }
    }

    join "", @str;
}

use overload '""' => \&as_string;

1;
# ABSTRACT: Represent IOD document

__END__

=pod

=encoding UTF-8

=head1 NAME

Config::IOD::Document - Represent IOD document

=head1 VERSION

This document describes version 0.33 of Config::IOD::Document (from Perl distribution Config-IOD), released on 2016-12-29.

=head1 SYNOPSIS

Obtain a document object C<$doc> from parsing an IOD document text using
L<Config::IOD>'s C<read_file> or C<read_string> method. Or, to produce an empty
document:

 $doc = Config::IOD::Document->new;

Dump document as hash of hashes:

 $hoh = $doc->dump;

Get a value:

 $val = $doc->get_value('section', 'key');

Insert a section:

 $doc->insert_section('name');

 # no nothing (instead of die) if section already exists
 $doc->insert_section({ignore=>1}, 'name');

 # insert at the top of document instead of bottom
 $doc->insert_section({top=>1}, 'name');

 # insert at specific location (line number), add some comment
 $doc->insert_section({linum=>12, comment=>"foo"}, 'name');

Insert a key:

 $doc->insert_key('section', 'key', 'value');

 # do nothing (instead of die) if key already exists
 $doc->insert_key({ignore=>1}, 'section', 'key', 'value');

 # add key anyway (creating multivalue key) if key already exists
 $doc->insert_key({add=>1}, 'section', 'key', 'value');

 # replace (delete all occurrences of previous key first) if key already exists
 $doc->insert_key({replace=>1}, 'section', 'key', 'value');

 # insert at the top of section, instead of at the bottom
 $doc->insert_key({top=>1}, 'section', 'key', 'value');

 # insert at specific location (line number)
 $doc->insert_key({linum=>12}, 'section', 'name', 'value');

Delete a section (and all keys under it):

 $doc->delete_section('name');

 # delete all occurrences instead of just the first one
 $doc->delete_section({all=>1}, 'name');

Delete a key:

 $doc->delete_key('section', 'key');

 # delete all occurrences instead of just the first one
 $doc->delete_key({all=>1}, 'section', 'key');

Empty document:

 $doc->empty;

Dump object as IOD document string:

 print $doc->as_string;

 # or just:
 print $doc;

=head1 ATTRIBUTES

=head1 METHODS

=head2 new(%attrs) => obj

=head2 $doc->as_string => str

Return document object rendered as string. Automatically used for
stringification.

=head2 $doc->delete_key([\%opts, ]$section, $name) => $num_deleted

Delete key named C<$name> in section named C<$section>.

Options:

=over

=item * all => bool

If set to 1, then will delete all occurrences. By default only delete the first
occurrence.

=item * cond => code

Will only delete key if C<cond> returns true. C<cond> will be called with C<<
($self, %args) >> where the hash will contain these keys: C<linum> (int, line
number), C<parsed> (array, parsed line), C<key> (string, key name), C<value>
(NOT YET IMPLEMENTED), C<raw_value> (str, raw/undecoded value).

=back

=head2 $doc->delete_section([\%opts, ]$section) => $num_deleted

Delete section named C<$section>.

Options:

=over

=item * all => bool

If set to 1, then will delete all occurrences. By default only delete the first
occurrence.

=item * cond => code

Will only delete section if C<cond> returns true. C<cond> will be called with
C<< ($self, %args) >> where the hash will contain these keys: C<linum_start>
(int, starting line number), C<linum_end> (int, ending line number).

=back

=head2 $doc->dump([ \%opts ]) => hoh

Return a hoh (hash of section names and hashes, where each of the second-level
hash is of keys and values), Values will be decoded and merging will be done,
but includes are not processed (even though C<include> directive is active).

Options:

=over

=item * linum_start => int

Only dump beginning from this line number.

=item * linum_end => int

Only dump until this line number.

=back

=head2 $doc->each_key([ \%opts , ] $code) => LIST

Execute C<$code> for each key found in document, in order of occurrence.
C<$code> will be called with arguments C<< ($self, %args) >> where C<%args> will
contain these keys: C<section> (str, current section name), C<key> (str, key
name), C<value> (any, value, NOT YET IMPLEMENTED/AVAILABLE), C<raw_value> (str,
raw/undecoded value), C<linum> (int, line number, 1-based), C<parsed> (array,
parsed line).

Options:

=over

=item * linum_start => int

Only dump beginning from this line number.

=item * linum_end => int

Only dump until this line number.

=item * unique_section => bool

If set to 1, will only list the first occurence of each section.

=item * unique_key => bool

If set to 1, will only list the first occurence of each key in the same section.

=back

=head2 $doc->each_section([ \%opts , ] $code) => LIST

Execute C<$code> for each section found in document, in order of occurrence.
C<$code> will be called with arguments C<< ($self, %args) >> where C<%args> will
contain these keys: C<section> (str, section name), C<linum> (int, line number,
1-based), C<linum_start> (the same as C<linum>), C<linum_end> (int, line number
of the last line of the section), C<parsed> (array, parsed line).

Options:

=over

=item * unique => bool

If set to 1, will only list the first occurence of each section.

=back

=head2 $doc->empty()

Empty document.

=head2 $doc->get_directive_before_key($section, $key) => array

Find directive right before a key. Directive must directly precede key line
without any blank line, e.g.:

 ;!lint_prereqs assume-used "undetected, used via Riap"
 App::MyApp=0

If found, will return an arrayref containing directive name and arguments.
Otherwise, will return undef.

=head2 $doc->get_value($section, $key) => $value

Get value. Values are decoded and section merging is respected, but includes are
not processed.

Internally, will do a C<dump()> and cache the result so subsequent
C<get_value()> will avoid re-parsing the whole document. (The cache will
automatically be discarded is one of document-modifying methods like
C<delete_section()> is called.)

=head2 $doc->insert_key([\%opts, ]$section, $key, $value) => int

Insert a key named C<$name> with value C<$value> under C<$section>. Return line
number where the key is inserted, or undef if nothing is inserted (e.g. when
C<ignore> option is set to true). Die on failure.

Options:

=over

=item * create_section => bool

If set to 1, will create section (at the end of document) if it doesn't exist.

=item * add => bool

If set to 1, will add another key if key with the same name already exists.
Conflicts with C<ignore> and <replace>.

=item * ignore => bool

If set to 1, will do nothing if key already exists. Conflicts with C<add> and
C<replace>.

=item * replace => bool

If set to 1, will delete (all) previous keys first. Conflicts with C<add> and
C<ignore>.

=item * top => bool

If set to 1, will insert at the top of section before other keys. By default
will add at the end of section.

=item * linum => posint

Optional. Insert at this specific line number. Line number must fall within
section. Ignores C<top>.

=back

=head2 $doc->insert_section([\%opts, ]$name) => int

Insert empty section named C<$name>. Return line number where the section is
inserted, or undef if nothing is inserted (e.g. when C<ignore> option is set to
true). Die on failure.

Options:

=over

=item * ignore => bool

If set to 1, then if section already exists will do nothing instead of die.

=item * top => bool

If set to 1, will insert before any other section. By default will insert at the
end of document. See also: C<linum>.

=item * comment => str

Optional. Comment to add at the end of section line.

=item * linum => posint

Optional. Insert at this specific line number. Ignores C<top>.

=back

=head2 $doc->list_keys([ \%opts ], $section) => LIST

List keys in the section named <$section>.

Options:

=over

=item * unique => bool

If set to 1, will only list the first occurrence of each key.

=back

=head2 $doc->list_sections([ \%opts ]) => LIST

List sections in the document, in order of occurrence.

Options:

=over

=item * unique => bool

If set to 1, will only list the first occurrence of each section.

=back

=head2 $doc->set_value([ \%opts ], $section, $key, $new_value)

Set value of a key.

Options:

=over

=item * all => bool

=back

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Config-IOD>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Config-IOD>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Config-IOD>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Config::IOD>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
