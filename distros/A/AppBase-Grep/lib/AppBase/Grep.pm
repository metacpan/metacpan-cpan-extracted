package AppBase::Grep;

use 5.010001;
use strict;
use warnings;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2022-11-04'; # DATE
our $DIST = 'AppBase-Grep'; # DIST
our $VERSION = '0.010'; # VERSION

our %SPEC;

$SPEC{grep} = {
    v => 1.1,
    summary => 'A base for grep-like CLI utilities',
    description => <<'_',

This routine provides a base for grep-like CLI utilities. It accepts coderef as
source of lines, which in the actual utilities can be from files or other
sources. It provides common options like `-i`, `-v`, `-c`, color highlighting,
and so on.

Examples of CLI utilities that are based on this: <prog:abgrep>,
<prog:grep-coin> (from <pm:App::CryptoCurrencyUtils>).

Why? For grepping lines from files or stdin, <prog:abgrep> is no match for the
standard grep (or its many alternatives): it's orders of magnitude slower and
currently has fewer options. But AppBase::Grep is a quick way to create
grep-like utilities that grep from a custom sources but have common/standard
grep features.

Compared to the standard grep, AppBase::Grep also has these unique features:

* `--all` option to match all patterns instead of just one;
* observe the `COLOR` environment variable to set `--color` default;

_
    args => {
        pattern => {
            summary => 'Specify *string* to search for',
            schema => 'str*',
            pos => 0,
        },
        regexps => {
            summary => 'Specify additional *regexp pattern* to search for',
            'x.name.is_plural' => 1,
            'x.name.singular' => 'regexp',
            schema => ['array*', of=>'str*'],
            cmdline_aliases => {e=>{code=>sub { $_[0]{regexps} //= []; push @{$_[0]{regexps}}, $_[1] }}},
        },

        ignore_case => {
            summary => 'If set to true, will search case-insensitively',
            schema => 'bool*',
            cmdline_aliases => {i=>{}},
            tags => ['category:matching-control'],
        },
        invert_match => {
            summary => 'Invert the sense of matching',
            schema => 'bool*',
            cmdline_aliases => {v=>{}},
            tags => ['category:matching-control'],
        },
        dash_prefix_inverts => { # not in grep
            summary => 'When given pattern that starts with dash "-FOO", make it to mean "^(?!.*FOO)"',
            schema => 'bool*',
            description => <<'_',

This is a convenient way to search for lines that do not match a pattern.
Instead of using `-v` to invert the meaning of all patterns, this option allows
you to invert individual pattern using the dash prefix, which is also used by
Google search and a few other search engines.

_
            tags => ['category:matching-control'],
        },
        all => { # not in grep
            summary => 'Require all patterns to match, instead of just one',
            schema => 'true*',
            tags => ['category:matching-control'],
        },
        count => {
            summary => 'Supress normal output, return a count of matching lines',
            schema => 'true*',
            cmdline_aliases => {c=>{}},
            tags => ['category:general-output-control'],
        },
        color => {
            summary => 'Specify when to show color (never, always, or auto/when interactive)',
            schema => ['str*', in=>[qw/never always auto/]],
            default => 'auto',
            tags => ['category:general-output-control'],
        },
        quiet => {
            summary => 'Do not print matches, only return appropriate exit code',
            schema => ['true*'],
            cmdline_aliases => {silent=>{}, q=>{}},
            tags => ['category:general-output-control'],
        },

        line_number => {
            summary => 'Show line number along with matches',
            schema => ['true*'],
            cmdline_aliases => {n=>{}},
            tags => ['category:output-line-prefix-control'],
        },
        # XXX max_count
        # word_regexp (-w) ?
        # line_regexp (-x) ?
        # --after-context (-A)
        # --before-context (-B)
        # --context (-C)

        _source => {
            schema => 'code*',
            tags => ['hidden'],
            description => <<'_',

Code to produce lines of text to grep form. Required.

Will be called with these arguments:

    ()

Should return the following:

    ($line, $label, $chomp)

Where `$line` is the line (with newline ending, unless `$chomp` is true),
`$label` is source label (e.g. filename without line number if text source is
from files), and `$chomp` is boolean that can be set to true to indicate that
line is already chomped and should not be chomped again.

_
        },
        _highlight_regexp => {
            schema => 're*',
            tags => ['hidden'],
            description => <<'_',

Regexp pattern to capture each pattern for highlighting. Optional.

_
        },
        _filter_code => {
            schema => 'code*',
            tags => ['hidden'],
            description => <<'_',

Custom filtering. If set, then `pattern` and `regexps` arguments are not
required and lines of text will be filtered by this code. Used e.g. for grepping
custom stuffs, e.g. email address or URL from lines of text instead of plain
string or regexp patterns.

Will be called for each line of text with these arguments:

    ($line, \%args)

where `$line` is the line of text and `%args` are the arguments given to the
`grep()` function.

_
        },

    },
};
sub grep {
    require ColorThemeUtil::ANSI;
    require Module::Load::Util;

    my %args = @_;

    my $opt_ci     = $args{ignore_case};
    my $opt_invert = $args{invert_match};
    my $opt_count  = $args{count};
    my $opt_quiet  = $args{quiet};
    my $opt_linum  = $args{line_number};

    my $ct = $ENV{APPBASE_GREP_COLOR_THEME} // 'Light';

    require Module::Load::Util;
    my $ct_obj = Module::Load::Util::instantiate_class_with_optional_args(
        {ns_prefixes=>['ColorTheme::Search','ColorTheme','']}, $ct);

    my (@str_patterns, @re_patterns);
    for my $p ( grep {defined} $args{pattern}, @{ $args{regexps} // [] }) {
        if ($args{dash_prefix_inverts} && $p =~ s/\A-//) {
            $p = "^(?!.*$p)";
        }
        push @str_patterns, $p;
        push @re_patterns , $opt_ci ? qr/$p/i : qr/$p/;
    }
    return [400, "Please specify at least one pattern"] unless $args{_filter_code} || @re_patterns;

    my $re_highlight = $args{_highlight_regexp} // join('|', @str_patterns);
    $re_highlight = $opt_ci ? qr/$re_highlight/i : qr/$re_highlight/;

    my $color = $args{color} // 'auto';
    my $use_color =
        ($color eq 'always' ? 1 : $color eq 'never' ? 0 : undef) //
        (defined $ENV{NO_COLOR} ? 0 : undef) //
        ($ENV{COLOR} ? 1 : defined($ENV{COLOR}) ? 0 : undef) //
        (-t STDOUT); ## no critic: InputOutput::ProhibitInteractiveTest

    my $source = $args{_source};

    my $logic = 'or';
    $logic = 'and' if $args{all};

    my $num_matches = 0;
    my ($line, $label, $linum, $chomp);

    my $ansi_highlight = ColorThemeUtil::ANSI::item_color_to_ansi($ct_obj->get_item_color('highlight'));
    my $code_print = sub {
        if (defined $label && length $label) {
            if ($use_color) {
                print ColorThemeUtil::ANSI::item_color_to_ansi($ct_obj->get_item_color('location')) . $label . "\e[0m:"; # XXX separator color?
            } else {
                print $label, ":";
            }
        }

        if ($opt_linum) {
            if ($use_color) {
                print ColorThemeUtil::ANSI::item_color_to_ansi($ct_obj->get_item_color('location')) . $linum . "\e[0m:";
            } else {
                print $linum, ":";
            }
        }

        if ($use_color) {
            $line =~ s/($re_highlight)/$ansi_highlight$1\e[0m/g;
            print $line;
        } else {
            print $line;
        }
        print "\n" if $chomp;
    };

    my $prevlabel;
    while (1) {
        ($line, $label, $chomp) = $source->();
        last unless defined $line;

        chomp($line) if $chomp;

        $label //= '';

        if ($opt_linum) {
            if (!defined $prevlabel) {
                $prevlabel = $label;
                $linum = 1;
            } else {
                if ($label ne $prevlabel) {
                    $prevlabel = $label;
                    $linum = 1;
                } else {
                    $linum++;
                }
            }
        }

        my $is_match;
        if ($args{_filter_code}) {
            $is_match = $args{_filter_code}->($line, \%args);
        } elsif ($logic eq 'or') {
            $is_match = 0;
            for my $re (@re_patterns) {
                if ($line =~ $re) {
                    $is_match = 1;
                    last;
                }
            }
        } else {
            $is_match = 1;
            for my $re (@re_patterns) {
                unless ($line =~ $re) {
                    $is_match = 0;
                    last;
                }
            }
        }

        if ($is_match) {
            next if $opt_invert;
            if ($opt_quiet || $opt_count) {
                $num_matches++;
            } else {
                $code_print->();
            }
        } else {
            next unless $opt_invert;
            if ($opt_quiet || $opt_count) {
                $num_matches++;
            } else {
                $code_print->();
            }
        }
    }

    return [
        200,
        "OK",
        $opt_count ? $num_matches : "",
        {"cmdline.exit_code"=>$num_matches ? 0:1},
    ];
}

1;
# ABSTRACT: A base for grep-like CLI utilities

__END__

=pod

=encoding UTF-8

=head1 NAME

AppBase::Grep - A base for grep-like CLI utilities

=head1 VERSION

This document describes version 0.010 of AppBase::Grep (from Perl distribution AppBase-Grep), released on 2022-11-04.

=head1 FUNCTIONS


=head2 grep

Usage:

 grep(%args) -> [$status_code, $reason, $payload, \%result_meta]

A base for grep-like CLI utilities.

This routine provides a base for grep-like CLI utilities. It accepts coderef as
source of lines, which in the actual utilities can be from files or other
sources. It provides common options like C<-i>, C<-v>, C<-c>, color highlighting,
and so on.

Examples of CLI utilities that are based on this: L<abgrep>,
L<grep-coin> (from L<App::CryptoCurrencyUtils>).

Why? For grepping lines from files or stdin, L<abgrep> is no match for the
standard grep (or its many alternatives): it's orders of magnitude slower and
currently has fewer options. But AppBase::Grep is a quick way to create
grep-like utilities that grep from a custom sources but have common/standard
grep features.

Compared to the standard grep, AppBase::Grep also has these unique features:

=over

=item * C<--all> option to match all patterns instead of just one;

=item * observe the C<COLOR> environment variable to set C<--color> default;

=back

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<all> => I<true>

Require all patterns to match, instead of just one.

=item * B<color> => I<str> (default: "auto")

Specify when to show color (never, always, or autoE<sol>when interactive).

=item * B<count> => I<true>

Supress normal output, return a count of matching lines.

=item * B<dash_prefix_inverts> => I<bool>

When given pattern that starts with dash "-FOO", make it to mean "^(?!.*FOO)".

This is a convenient way to search for lines that do not match a pattern.
Instead of using C<-v> to invert the meaning of all patterns, this option allows
you to invert individual pattern using the dash prefix, which is also used by
Google search and a few other search engines.

=item * B<ignore_case> => I<bool>

If set to true, will search case-insensitively.

=item * B<invert_match> => I<bool>

Invert the sense of matching.

=item * B<line_number> => I<true>

Show line number along with matches.

=item * B<pattern> => I<str>

Specify *string* to search for.

=item * B<quiet> => I<true>

Do not print matches, only return appropriate exit code.

=item * B<regexps> => I<array[str]>

Specify additional *regexp pattern* to search for.


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)

=head1 ENVIRONMENT

=head2 NO_COLOR

If set, will disable color. Takes precedence over L</COLOR> but not C<--color>.

=head2 COLOR

Boolean. If set to true, will set default C<--color> to C<always> instead of
C<auto>. If set to false, will set default C<--color> to C<never> instead of
C<auto>. This behavior is not in GNU grep.

=head2 COLOR_THEME

String. Will search color themes in C<AppBase::Grep::ColorTheme::*> as well as
C<Generic::ColorTheme::*> modules.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/AppBase-Grep>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-AppBase-Grep>.

=head1 SEE ALSO

Some scripts that use us as a base: L<abgrep> (from L<App::abgrep>),
L<grep-email> (from L<App::grep::email>), L<grep-url> (from L<App::grep::url>),
L<pdfgrep> (a.k.a. L<grep-from-pdf>, from L<App::PDFUtils>).

L<Regexp::From::String> is related to C<--dash-prefix-inverts> option.

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

This software is copyright (c) 2022, 2021, 2020, 2018 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=AppBase-Grep>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
