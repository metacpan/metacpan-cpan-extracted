package App::orgadb;

use 5.010001;
use strict;
use warnings;
use Log::ger;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2022-06-12'; # DATE
our $DIST = 'App-orgadb'; # DIST
our $VERSION = '0.001'; # VERSION

our %SPEC;

$SPEC{':package'} = {
    v => 1.1,
    summary => 'An opinionated Org addressbook tool',
};

our %argspecs_common = (
    files => {
        summary => 'Path to addressbook files',
        'summary.alt.plurality.singular' => 'Path to addressbook file',
        'x.name.is_plural' => 1,
        'x.name.singular' => 'file',
        schema => ['array*', of=>'filename*', min_len=>1],
        tags => ['category:input'],
    },
);

our %argspec_category = (
    entry => {
        summary => 'Find entry by string or regex search against the category title',
        schema => 'str_or_re*',
        cmdline_aliases=>{c=>{}},
    },
);

our %argspecopt0_entry = (
    entry => {
        summary => 'Find entry by string or regex search against its title',
        schema => 'str_or_re*',
        pos => 0,
    },
);

our %argspecopt1_field = (
    field => {
        summary => 'Find field by string or regex search',
        schema => 'str_or_re*',
        pos => 1,
    },
);

sub _highlight {
    my ($clrtheme_obj, $re, $text) = @_;
    return $text unless $clrtheme_obj && $re;

    require ColorThemeUtil::ANSI;
    my $ansi_highlight = ColorThemeUtil::ANSI::item_color_to_ansi($clrtheme_obj->get_item_color('highlight'));
    $text =~ s/($re)/$ansi_highlight$1\e[0m/g;
    $text;
}

$SPEC{select_addressbook_entries} = {
    v => 1.1,
    summary => 'Select Org document elements using CSel (CSS-selector-like) syntax',
    args => {
        %argspecs_common,
        %argspecopt0_entry,
        %argspecopt1_field,
        category => {
            schema => 'str_or_re*',
            cmdline_aliases=>{c=>{}},
        },
        hide_category => {
            summary => 'Do not show category',
            schema => 'true*',
            cmdline_aliases => {C=>{}},
        },
        hide_entry => {
            summary => 'Do not entry headline',
            schema => 'true*',
            cmdline_aliases => {E=>{}},
        },
        color => {
            summary => 'Whether to use color',
            schema => ['str*', in=>[qw/auto always never/]],
            default => 'auto',
        },
        color_theme => {
            schema => 'perl::colortheme::modname_with_optional_args*',
        },
        detail => {
            schema => 'bool*',
            cmdline_aliases => {l=>{}},
        },
    },
    'x.envs' => {
        'ORGADB_COLOR_THEME' => {
            summary => 'Set default color theme',
            schema => 'perl::colortheme::modname_with_optional_args*',
            description => <<'_',

Color theme is Perl module name under the `ColorTheme::Search::` namespace,
without the namespace prefix. The default is `Light`. You can set color theme
using the `--color-theme` command-line option as well as this environment
variable.

_
        },
    },
};
sub select_addressbook_entries {
    my %args = @_;

    my @trees;
  PARSE_FILES: {
        require Org::Parser;
        my $parser = Org::Parser->new;

        for my $file (@{ $args{files} }) {
            my $doc;
            if ($file eq '-') {
                binmode STDIN, ":encoding(utf8)";
                $doc = $parser->parse(join "", <>);
            } else {
                local $ENV{PERL_ORG_PARSER_CACHE} = $ENV{PERL_ORG_PARSER_CACHE} // 1;
                $doc = $parser->parse_file($file);
            }
            push @trees, $doc;
        } # for file
    } # PARSe_FILES

    my @entries;
    my ($re_category, $re_entry, $re_field);
  FIND_ENTRIES: {
        require Data::CSel;
        require Data::Dmp;

        my $expr = '';

        if (defined $args{category}) {
            $expr .= 'Headline[level=1][title.text';
            if (ref $args{category} eq 'Regexp') {
                $re_category = $args{category};
            } else {
                $re_category = quotemeta($args{category});
                $re_category = qr/$re_category/;
            }
            $expr .= " =~ " . Data::Dmp::dmp($re_category) . "]";
        }

        $expr .= (length $expr ? " " : "") . 'Headline[level=2]';
        if (defined $args{entry}) {
            $expr .= '[title.text';
            if (ref $args{entry} eq 'Regexp') {
                $re_entry = $args{entry};
            } else {
                $re_entry = quotemeta($args{entry});
                $re_entry = qr/$re_entry/;
            }
            $expr .= " =~ " . Data::Dmp::dmp($re_entry) . "]";
        }

        log_trace "CSel expression: <$expr>";
        #log_trace "Number of trees: %d", scalar(@trees);

        for my $tree (@trees) {
            my @nodes = Data::CSel::csel({
                class_prefixes => ["Org::Element"],
            }, $expr, $tree);
            push @entries, @nodes;
        }
    } # FIND_ENTRIES
    log_trace "Number of matching entries: %d", scalar(@entries);

  DISPLAY_ENTRIES: {
        my ($clrtheme, $clrtheme_obj);
      LOAD_COLOR_THEME: {
            my $color = $args{color} // 'auto';
            my $use_color =
                ($color eq 'always' ? 1 : $color eq 'never' ? 0 : undef) //
                (defined $ENV{NO_COLOR} ? 0 : undef) //
                ($ENV{COLOR} ? 1 : defined($ENV{COLOR}) ? 0 : undef) //
                (-t STDOUT); ## no critic: InputOutput::ProhibitInteractiveTest
            last unless $use_color;
            require Module::Load::Util;
            $clrtheme = $args{color_them} // $ENV{ORGADB_COLOR_THEME} // 'Light';
            $clrtheme_obj = Module::Load::Util::instantiate_class_with_optional_args(
                {ns_prefixes=>['ColorTheme::Search','ColorTheme','']}, $clrtheme);
        };

        my ($re_field, $expr_field);
      ENTRY:
        for my $entry (@entries) {

            my @fields;
            if (defined $args{field}) {
                unless (defined $expr_field) {
                    $expr_field = '';
                    $expr_field .= 'ListItem[desc_term.text';
                    if (ref $args{field} eq 'Regexp') {
                        $re_field = $args{field};
                    } else {
                        $re_field = quotemeta($args{field});
                        $re_field = qr/$re_field/;
                    }
                    $expr_field .= " =~ " . Data::Dmp::dmp($re_field) . "]";
                }

                @fields = Data::CSel::csel({
                    class_prefixes => ["Org::Element"],
                }, $expr_field, $entry);

                next ENTRY unless @fields;
            }

            unless ($args{detail} && $args{hide_entry}) {
                unless ($args{hide_category}) {
                    print _highlight(
                        $clrtheme_obj,
                        $re_category,
                        $entry->parent->title->text) . "/";
                }
                print _highlight(
                    $clrtheme_obj,
                    $re_entry,
                    $entry->title->text,
                );
                print "\n";
            }

            if ($args{detail} && !defined($args{field})) {
                print $entry->children_as_string;
            } elsif (@fields) {
                for my $field (@fields) {
                    my $str = _highlight(
                        $clrtheme_obj,
                        $re_field,
                        $field->desc_term->text,
                    ) . " ::" . $field->children_as_string;
                    $str =~ s/^/  /gm;
                    print $str;
                }
            }
        }
    }

    [200];
}
1;
# ABSTRACT: An opinionated Org addressbook tool

__END__

=pod

=encoding UTF-8

=head1 NAME

App::orgadb - An opinionated Org addressbook tool

=head1 VERSION

This document describes version 0.001 of App::orgadb (from Perl distribution App-orgadb), released on 2022-06-12.

=head1 SYNOPSIS

=head1 FUNCTIONS


=head2 select_addressbook_entries

Usage:

 select_addressbook_entries(%args) -> [$status_code, $reason, $payload, \%result_meta]

Select Org document elements using CSel (CSS-selector-like) syntax.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<category> => I<str_or_re>

=item * B<color> => I<str> (default: "auto")

Whether to use color.

=item * B<color_theme> => I<perl::colortheme::modname_with_optional_args>

=item * B<detail> => I<bool>

=item * B<entry> => I<str_or_re>

Find entry by string or regex search against its title.

=item * B<field> => I<str_or_re>

Find field by string or regex search.

=item * B<files> => I<array[filename]>

Path to addressbook files.

=item * B<hide_category> => I<true>

Do not show category.

=item * B<hide_entry> => I<true>

Do not entry headline.


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)

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
