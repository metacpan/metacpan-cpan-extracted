package App::orgadb::Common;

use 5.010001;
use strict;
use warnings;
use Log::ger;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2025-06-19'; # DATE
our $DIST = 'App-orgadb'; # DIST
our $VERSION = '0.020'; # VERSION

sub _heading_from_line {
    my $heading = shift;

    # string tags
    $heading =~ s/(.+?)\s+:(?:\w+:)+\z/$1/;
    # XXX strip radio target, todo keywords, count cookies

    $heading;
}

sub _complete_category {
    my %args = @_;

    my $word = $args{word} // '';

    # only run under pericmd
    my $cmdline = $args{cmdline} or return;
    my $r = $args{r};

    # force read config file, because by default it is turned off when in
    # completion
    $r->{read_config} = 1;
    my $parse_res = $cmdline->parse_argv($r);
    my $cli_args = $parse_res->[2];

    # read all heading lines from all files
    my @l1_headings;
    {
        last unless $cli_args->{files} && @{ $cli_args->{files} };
        for my $file (@{ $cli_args->{files} }) {
            open my $fh, "<", $file or do {
                log_trace "Addressbook file %s cannot be opened, skipped", $file;
                next;
            };
            while (my $line = <$fh>) {
                next unless $line =~ /^\* (.+)/;
                chomp(my $heading = $1);
                push @l1_headings, _heading_from_line($heading);
            }
        }
    }

    require Complete::Util;
    Complete::Util::complete_array_elem(
        array => \@l1_headings,
        word  => $word,
    );
}

sub _complete_entry {
    my %args = @_;

    my $word = $args{word} // '';

    # only run under pericmd
    my $cmdline = $args{cmdline} or return;
    my $r = $args{r};

    # force read config file, because by default it is turned off when in
    # completion
    $r->{read_config} = 1;
    my $parse_res = $cmdline->parse_argv($r);
    my $cli_args = $parse_res->[2];

    require Regexp::From::String;

    # read all heading lines from all files
    my @l2_headings;
    {
        last unless $cli_args->{files} && @{ $cli_args->{files} };
        for my $file (@{ $cli_args->{files} }) {
            open my $fh, "<", $file or do {
                log_trace "Addressbook file %s cannot be opened, skipped", $file;
                next;
            };
            my $cur_l1_heading = '';
            my $category_re;
            while (my $line = <$fh>) {
                if ($line =~ /^\* (.+)/) {
                    chomp($cur_l1_heading = _heading_from_line($1));
                    next;
                } elsif ($line =~ /^\*\* (.+)/) {
                    # if user has specified category, only consider entries that
                    # match the category
                    if (defined $cli_args->{category}) {
                        unless (defined $category_re) {
                            $category_re = Regexp::From::String::str_to_re({case_insensitive=>1}, $cli_args->{category});
                        }
                        next unless $cur_l1_heading =~ $category_re;
                    }

                    chomp(my $heading = $1);
                    push @l2_headings, _heading_from_line($heading);
                }
            }
        }
    }

    require Complete::Util;
    Complete::Util::complete_array_elem(
        array => \@l2_headings,
        word  => $word,
    );
}

sub _complete_field {
    my %args = @_;

    my $word = $args{word} // '';

    # only run under pericmd
    my $cmdline = $args{cmdline} or return;
    my $r = $args{r};

    # force read config file, because by default it is turned off when in
    # completion
    $r->{read_config} = 1;
    my $parse_res = $cmdline->parse_argv($r);
    my $cli_args = $parse_res->[2];

    unless (defined $cli_args->{entry}) {
        return {message=>"Please specify entry first", static=>1};
    }

    require Regexp::From::String;

    # read all heading lines from all files
    my @fields;
    {
        last unless $cli_args->{files} && @{ $cli_args->{files} };
        for my $file (@{ $cli_args->{files} }) {
            open my $fh, "<", $file or do {
                log_trace "Addressbook file %s cannot be opened, skipped", $file;
                next;
            };
            my $cur_l1_heading = '';
            my $cur_l2_heading = '';
            my $category_re;
            my $entry_re = Regexp::From::String::str_to_re({case_insensitive=>1}, $cli_args->{entry});
            while (my $line = <$fh>) {
                if ($line =~ /^\* (.+)/) {
                    chomp($cur_l1_heading = $1);
                    # XXX strip radio target, tags, todo keywords, count cookies
                    next;
                } elsif ($line =~ /^\*\* (.+)/) {
                    # if user has specified category, only consider entries that
                    # match the category
                    if (defined $cli_args->{category}) {
                        unless (defined $category_re) {
                            $category_re = Regexp::From::String::str_to_re({case_insensitive=>1}, $cli_args->{category});
                        }
                        next unless $cur_l1_heading =~ $category_re;
                    }

                    chomp($cur_l2_heading = $1);
                    # XXX strip radio target, tags, todo keywords, count cookies
                    next;
                } elsif ($line =~ /^\s*[+*-]\s+(.+?)\s+::/) {
                    my $field = $1;

                    # only consider field under the matching category & entry
                    if (defined $category_re) {
                        next unless $cur_l1_heading =~ $category_re;
                    }
                    next unless defined $entry_re;
                    next unless $cur_l2_heading =~ $entry_re;

                    push @fields, $field;
                }
            }
        }
    }

    require Complete::Util;
    Complete::Util::complete_array_elem(
        array => \@fields,
        word  => $word,
    );
}

our %argspecs_common = (
    files => {
        summary => 'Path to addressbook files',
        'summary.alt.plurality.singular' => 'Path to addressbook file',
        'x.name.is_plural' => 1,
        'x.name.singular' => 'file',
        schema => ['array*', of=>'filename*', min_len=>1],
        'x.element_completion' => ['filename', {file_ext_filter=>[qw/org ORG/]}],
        tags => ['category:input'],
    },
    reload_files_on_change => {
        schema => 'bool*',
        default => 1,
        tags => ['category:input'],
    },

    color => {
        summary => 'Whether to use color',
        schema => ['str*', in=>[qw/auto always never/]],
        default => 'auto',
        tags => ['category:color'],
    },
    color_theme => {
        schema => 'perl::colortheme::modname_with_optional_args*',
        tags => ['category:color'],
    },

    shell => {
        schema => 'true*',
        cmdline_aliases=>{s=>{}},
        tags => ['category:mode'],
    },
);

our %argspecopt_category = (
    category => {
        summary => 'Find entry by string or regex search against the category title',
        schema => 'str_or_re*',
        cmdline_aliases=>{c=>{}},
        completion => \&_complete_category,
        tags => ['category:filter'],
    },
);

our %argspecopt0_entry = (
    entry => {
        summary => 'Find entry by string or regex search against its title',
        schema => 'str_or_re*',
        pos => 0,
        completion => \&_complete_entry,
        tags => ['category:entry-selection'],
    },
);

our %argspecopt_filter_entry_by_fields = (
    filter_entries_by_fields => {
        'x.name.is_plural' => 1,
        'x.name.singular' => 'filter_entries_by_field',
        summary => 'Find entry by the fields or subfields it has',
        schema => ['array*', of=> 'str*'],
        tags => ['category:entry-selection'],
        description => <<'MARKDOWN',

The format of each entry_by_field is one of:

    str
    /re/
    str = str2
    str = /re2/
    /re/ = str2
    /re/ = /re2/

That is, it can search for a string (`str`) or regex (`re`) in the field name,
and optionally also search for a string (`str2`) or regex (`re2`) in the field
value.

MARKDOWN
    },
);

our %argspecopt1_field = (
    fields => {
        summary => 'Find (sub)fields by string or regex search',
        'x.name.is_plural' => 1,
        'x.name.singular' => 'field',
        schema => ['array*', of=>'str_or_re*'],
        pos => 1,
        slurpy => 1,
        element_completion => \&_complete_field,
        tags => ['category:field-selection'],
    },
);

our %argspecs_select = (

    %argspecopt0_entry,
    entry_match_mode => {
        summary => 'How entry should be matched',
        schema => ['str*', in=>['default', 'exact', 'exact-ci']], # TODO: fuzzy matching
        default => 'default',
        description => <<'MARKDOWN',

The default matching mode is as follow:

    str       Substring matching
    /re/      Regular expression matching

If matching mode is set to `exact`, then matching will be done by string
equality test. This mode is basically a shorter alternative to having to
specify:

    /^\Qre\E$/

Matching mode `exact-ci` is like `exact` except case-insensitive. It is
equivalent to:

    /^\Qre\E$/i

MARKDOWN
        cmdline_aliases => {
            x => { is_flag=>1, summary=>'Turn on exact entry matching (shortcut for `--entry-match-mode=exact`)', code => sub { $_[0]{entry_match_mode} = 'exact' } },
        },
    },

    %argspecopt_category,

    %argspecopt1_field,
    %argspecopt_filter_entry_by_fields,
    field_match_mode => {
        summary => 'How entry should be matched',
        schema => ['str*', in=>['default', 'exact', 'exact-ci']], # TODO: fuzzy matching
        default => 'default',
        description => <<'MARKDOWN',

The default matching mode is as follow:

    str       Substring matching
    /re/      Regular expression matching

If matching mode is set to `exact`, then matching will be done by string
equality test. This mode is basically a shorter alternative to having to
specify:

    /^\Qre\E$/

Matching mode `exact-ci` is like `exact` except case-insensitive. It is
equivalent to:

    /^\Qre\E$/i

MARKDOWN
        cmdline_aliases => {
            X => { is_flag=>1, summary=>'Turn on exact field matching (shortcut for `--field-match-mode=exact`)', code => sub { $_[0]{field_match_mode} = 'exact' } },
        },
    },

    hide_category => {
        summary => 'Do not show category',
        schema => 'true*',
        cmdline_aliases => {C=>{}},
        tags => ['category:output'],
    },
    hide_entry => {
        summary => 'Do not show entry headline',
        schema => 'true*',
        cmdline_aliases => {E=>{}},
        tags => ['category:output'],
    },
    hide_field_name => {
        summary => 'Do not show field names, just show field values',
        schema => 'true*',
        cmdline_aliases => {N=>{}},
        tags => ['category:output'],
        description => <<'MARKDOWN',

Mnemonic for short option `-N`: field *N*ame (uppercase letter usually means
/no/).

MARKDOWN
    },
    detail => {
        schema => 'bool*',
        cmdline_aliases => {l=>{}},
        tags => ['category:output'],
        description => <<'MARKDOWN',

Instead of showing matching field values, display the whole entry.

Mnemonic for shortcut option `-l`: the option `-l` is usually used for the short
version of `--detail`, as in *ls* Unix command.

MARKDOWN
    },
    count => {
        summary => 'Return just the number of matching entries instead of showing them',
        schema => 'true*',
    },
    no_field_value_formatters => {
        summary => 'Do not apply formatters for field value (overrides --field-value-formatter option)',
        schema => 'true*',
        description => <<'MARKDOWN',

Note that this option has higher precedence than
`--default-field-value-formatter-rules` or the `--field-value-formatter`
(`--fvfmt`) option.

MARKDOWN
        cmdline_aliases => {raw_field_values=>{}, F=>{}},
        tags => ['category:output'],
    },
    field_value_formatter_rules => {
        'x.name.is_plural' => 1,
        'x.name.singular' => 'default_field_value_formatter_rule',
        schema => ['array*', of=>'hash*'],
        description => <<'MARKDOWN',

Specify field value formatters to use when conditions are met, specified as an
array of hashes. Each element is a rule that is as a hash containing condition
keys and formatters keys. If all conditions are met then the formatters will be
applied. The rules will be tested when each field is about to be outputted.
Multiple rules can match and the matching rules' formatters are all applied in
succession.

Note that this option will be overridden by the `--field-value-formatter`
(`-fvfmt`) or the `--no-field-value-formatters` (`-F`) option.

The rules are best specified in the configuration as opposed to on the
command-line option. An example (the lines below are writen in configuration
file in IOD syntax, as rows of JSON hashes):

    ; remove all comments in field values when 'hide_field_name' option is set
    ; (which usually means we want to copy paste things)

    field_value_formatter_rules={"hide_field_name":true, "formatters":[ ["Str::remove_comment"] ]}

    ; normalize phone numbers using Phone::format + Str::remove_whitespace when
    ; 'hide_field_name' option is set (which usually means we want to copy paste
    ; things). e.g. '0812-1234-5678' becomes '+6281212345678'.

    field_value_formatter_rules={"field_name_matches":"/phone|wa|whatsapp/i", "hide_field_name":true, "formatters":[ ["Phone::format", "Str::remove_whitespace"] ]}

    ; but if 'hide_field_name' field is not set, normalize phone numbers using
    ; Phone::format without removing whitespaces, which is easier to see (e.g.
    ; '+62 812 1234 5678').

    field_value_formatter_rules={"field_name_matches":"/phone|wa|whatsapp/i", "hide_field_name":false, "formatters":[ ["Phone::format"] ]}

Condition keys:

* `field_name_matches` (value: str/re): Check if field name matches a regex pattern.

* `hide_field_name` (value: bool): Check if `--hide-field-name` (`-N`) option is
  set (true) or unset (false).

Formatter keys:

* `formatters`: an array of formatters, to be applied. Each formatter is a name
  of perl Sah filter rule, or a two-element array of perl Sah filter rule name
  followed by hash containing arguments. See `--formatter` for more detais on
  specifying formatter.

MARKDOWN
        tags => ['category:output'],
    },
    field_value_formatters => {
        'x.name.is_plural' => 1,
        'x.name.singular' => 'field_value_formatter',
        summary => 'Add one or more formatters to display field value',
        #schema => ['array*', of=>'perl::perl_sah_filter::modname_with_optional_args*'], ## doesn't work yet with Perinci::Sub::GetArgs::Argv
        schema => ['array*', of=>[
            'str*', {
                prefilters=>['Perl::normalize_perl_modname'],
                'x.completion' => ['perl_perl_sah_filter_modname_with_optional_args'],
            }],
               ],
        cmdline_aliases => {
            fvfmt=>{},
            f=>{},
            remove_nondigits   => {is_flag=>1, summary=>'Shortcut for --field-value-formatter Str::remove_nondigit'   , code=>sub { $_[0]{field_value_formatters} //= []; push @{ $_[0]{field_value_formatters} }, 'Str::remove_nondigit'   } },
            remove_comments    => {is_flag=>1, summary=>'Shortcut for --field-value-formatter Str::remove_comment'    , code=>sub { $_[0]{field_value_formatters} //= []; push @{ $_[0]{field_value_formatters} }, 'Str::remove_comment'    } },
            remove_whitespaces => {is_flag=>1, summary=>'Shortcut for --field-value-formatter Str::remove_whitespaces', code=>sub { $_[0]{field_value_formatters} //= []; push @{ $_[0]{field_value_formatters} }, 'Str::remove_whitespace' } },
            format_phone       => {is_flag=>1, summary=>'Shortcut for --field-value-formatter Phone::format'          , code=>sub { $_[0]{field_value_formatters} //= []; push @{ $_[0]{field_value_formatters} }, 'Phone::format'          } },
        },
        tags => ['category:output'],
        description => <<'MARKDOWN',

Specify one or more formatters to apply to the field value before displaying.

A formatter is name of `Data::Sah::Filter::perl::*` module, without the prefix.
For example: `Str::uc` will convert the field value to uppercase. Another
formatter, `Str::remove_comment` can remove comment.

A formatter can have arguments, which is specified using this format:

    [FORMATTER_NAME, {ARG1NAME => ARG1VAL, ...}]

If formatter name begins with `[` character, it will be parsed as JSON. Example:

 ['Str::remove_comment', {'style':'cpp'}]

Note that this option overrides `--field-value-formatter-rules` but is
overridden by the `--no-field-value-formatters` (`--raw-field-values`, `-F`)
option.

MARKDOWN
    },

    num_entries => {
        summary => 'Specify maximum number of entries to return (0 means unlimited)',
        schema => 'uint*',
        tags => ['category:output'],
    },
    num_fields => {
        summary => 'Specify maximum number of fields (per entry) to return (0 means unlimited)',
        schema => 'uint*',
        cmdline_aliases => {
            n=>{},
            1 => {is_flag=>1, summary=>'Shortcut for --num-fields=1', code=>sub { $_[0]{num_fields} = 1 }},
        },
        tags => ['category:output'],
    },

    clipboard => {
        summary => 'Whether to copy matching field values to clipboard',
        schema => ['str*', in=>[qw/tee only/]],
        description => <<'MARKDOWN',

If set to `tee`, then will display matching fields to terminal as well as copy
matching field values to clipboard.

If set to `only`, then will not display matching fields to terminal and will
only copy matching field values to clipboard.

Mnemonic for short option `-y` and `-Y`: *y*ank as in Emacs (`C-y`).

MARKDOWN
        cmdline_aliases => {
            clipboard_only => {is_flag=>1, summary=>'Shortcut for --clipboard=only', code=>sub { $_[0]{clipboard} = 'only' }},
            y => {is_flag=>1, summary=>'Shortcut for --clipboard=tee', code=>sub { $_[0]{clipboard} = 'tee' }},
            Y => {is_flag=>1, summary=>'Shortcut for --clipboard=only', code=>sub { $_[0]{clipboard} = 'only' }},
        },
        tags => ['category:output'],
    },
);

1;
# ABSTRACT:

__END__

=pod

=encoding UTF-8

=head1 NAME

App::orgadb::Common

=head1 VERSION

This document describes version 0.020 of App::orgadb::Common (from Perl distribution App-orgadb), released on 2025-06-19.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/App-orgadb>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-orgadb>.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 CONTRIBUTING


To contribute, you can send patches by email/via RT, or send pull requests on
GitHub.

Most of the time, you don't need to build the distribution yourself. You can
simply modify the code, then test via:

 % prove -l

If you want to build the distribution (e.g. to try to install it locally on your
system), you can install L<Dist::Zilla>,
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>,
L<Pod::Weaver::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla- and/or Pod::Weaver plugins. Any additional steps required beyond
that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2025 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-orgadb>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
