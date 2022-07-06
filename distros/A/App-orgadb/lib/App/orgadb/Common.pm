package App::orgadb::Common;

use 5.010001;
use strict;
use warnings;
use Log::ger;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2022-07-04'; # DATE
our $DIST = 'App-orgadb'; # DIST
our $VERSION = '0.004'; # VERSION

our %argspecs_common = (
    files => {
        summary => 'Path to addressbook files',
        'summary.alt.plurality.singular' => 'Path to addressbook file',
        'x.name.is_plural' => 1,
        'x.name.singular' => 'file',
        schema => ['array*', of=>'filename*', min_len=>1],
        cmdline_aliases=>{f=>{}},
        tags => ['category:input'],
    },
    shell => {
        schema => 'true*',
        cmdline_aliases=>{s=>{}},
        tags => ['category:mode'],
    },
    reload_files_on_change => {
        schema => 'bool*',
        default => 1,
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
);

our %argspecopt_category = (
    category => {
        summary => 'Find entry by string or regex search against the category title',
        schema => 'str_or_re*',
        cmdline_aliases=>{c=>{}},
        tags => ['category:filter'],
    },
);

our %argspecopt0_entry = (
    entry => {
        summary => 'Find entry by string or regex search against its title',
        schema => 'str_or_re*',
        pos => 0,
        tags => ['category:filter'],
    },
);

our %argspecopt1_field = (
    fields => {
        'x.name.is_plural' => 1,
        'x.name.singular' => 'field',
        summary => 'Find (sub)fields by string or regex search',
        schema => ['array*', of=>'str_or_re*'],
        pos => 1,
        slurpy => 1,
        tags => ['category:filter'],
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
    formatters => {
        'x.name.is_plural' => 1,
        'x.name.singular' => 'formatter',
        summary => 'Add one or more formatters to display field value',
        schema => ['array*', of=>'str*'],
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
);

1;
# ABSTRACT:

__END__

=pod

=encoding UTF-8

=head1 NAME

App::orgadb::Common

=head1 VERSION

This document describes version 0.004 of App::orgadb::Common (from Perl distribution App-orgadb), released on 2022-07-04.

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
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla plugin and/or Pod::Weaver::Plugin. Any additional steps required
beyond that are considered a bug and can be reported to me.

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
