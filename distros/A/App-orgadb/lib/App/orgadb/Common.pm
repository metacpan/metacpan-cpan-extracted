package App::orgadb::Common;

use 5.010001;
use strict;
use warnings;
use Log::ger;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2022-10-09'; # DATE
our $DIST = 'App-orgadb'; # DIST
our $VERSION = '0.010'; # VERSION

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
        description => <<'_',

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

_
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
    %argspecopt1_field,
    %argspecopt_category,
    hide_category => {
        summary => 'Do not show category',
        schema => 'true*',
        cmdline_aliases => {C=>{}},
        tags => ['category:display'],
    },
    hide_entry => {
        summary => 'Do not show entry headline',
        schema => 'true*',
        cmdline_aliases => {E=>{}},
        tags => ['category:display'],
    },
    hide_field_name => {
        summary => 'Do not show field names, just show field values',
        schema => 'true*',
        cmdline_aliases => {N=>{}},
        tags => ['category:display'],
    },
    detail => {
        schema => 'bool*',
        cmdline_aliases => {l=>{}},
        tags => ['category:display'],
    },
    count => {
        summary => 'Return just the number of matching entries instead of showing them',
        schema => 'true*',
    },
    no_formatters => {
        summary => 'Do not apply any formatters to field value (overrides --formatter option)',
        schema => 'true*',
        cmdline_aliases => {raw_field_values=>{}, F=>{}},
        tags => ['category:display'],
    },
    default_formatter_rules => {
        'x.name.is_plural' => 1,
        'x.name.singular' => 'default_formatter_rule',
        schema => ['array*', of=>'any*'],
        description => <<'_',

Specify conditional default formatters. This is for convenience and best
specified in the configuration as opposed to on the command-line option.
An example:

    default_formatter_rules={"field_name_matches":"/phone|wa|whatsapp/i","formatters":[ ["Phone::format_phone_idn"] ]}

_
        tags => ['category:display'],
    },
    formatters => {
        'x.name.is_plural' => 1,
        'x.name.singular' => 'formatter',
        summary => 'Add one or more formatters to display field value',
        #schema => ['array*', of=>'perl::perl_sah_filter::modname_with_optional_args*'], ## doesn't work yet with Perinci::Sub::GetArgs::Argv
        schema => ['array*', of=>'str*'],
        element_completion => sub {
            require Complete::Module;
            my %args = @_;
            Complete::Module::complete_module(
                word => $args{word},
                ns_prefix => 'Data::Sah::Filter::perl',
            );
        },
        cmdline_aliases => {f=>{}},
        tags => ['category:display'],
        description => <<'_',

Specify one or more formatters to apply to the field value before displaying.

A formatter is name of `Data::Sah::Filter::perl::*` module, without the prefix.
For example: `Str::uc` will convert the field value to uppercase. Another
formatter, `Str::remove_comment` can remove comment.

A formatter can have arguments, which is specified using this format:

    [FORMATTER_NAME, {ARG1NAME => ARG1VAL, ...}]

If formatter name begins with `[` character, it will be parsed as JSON. Example:

 ['Str::remove_comment', {'style':'cpp'}]

Overrides `--default_formatter_rule` but overridden by the `--no-formatters`
(`--raw-field-values`, `-F`) option.

_
    },

    num_entries => {
        summary => 'Specify maximum number of entries to return (0 means unlimited)',
        schema => 'uint*',
        tags => ['category:result'],
    },
    num_fields => {
        summary => 'Specify maximum number of fields (per entry) to return (0 means unlimited)',
        schema => 'uint*',
        tags => ['category:result'],
    },

    %argspecopt_filter_entry_by_fields,
);

1;
# ABSTRACT:

__END__

=pod

=encoding UTF-8

=head1 NAME

App::orgadb::Common

=head1 VERSION

This document describes version 0.010 of App::orgadb::Common (from Perl distribution App-orgadb), released on 2022-10-09.

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

This software is copyright (c) 2022 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-orgadb>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
