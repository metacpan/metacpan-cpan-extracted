package AppBase::Grep;

our $DATE = '2018-01-30'; # DATE
our $VERSION = '0.004'; # VERSION

use 5.010001;
use strict;
use warnings;

our %SPEC;

our %Colors = (
    label     => "\e[35m",   # magenta
    separator => "\e[36m",   # cyan
    linum     => "\e[32m",   # green
    match     => "\e[1;31m", # bold red
);

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
grep-like utilities that greps from a custom sources but have common features
with the standard grep.

Compared to the standard grep, AppBase::Grep also has these unique features:

* `--all` option to match all patterns instead of just one;
* observe the `COLOR` environment variable to set `--color` default;

_
    args => {
        pattern => {
            schema => 're*',
            pos => 0,
        },
        regexps => {
            'x.name.is_plural' => 1,
            'x.name.singular' => 'regexp',
            schema => ['array*', of=>'re*'],
            cmdline_aliases => {e=>{code=>sub { $_[0]{regexps} //= []; push @{$_[0]{regexps}}, $_[1] }}},
        },

        ignore_case => {
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
            schema => ['str*', in=>[qw/never always auto/]],
            tags => ['category:general-output-control'],
        },
        quiet => {
            schema => ['true*'],
            cmdline_aliases => {silent=>{}, q=>{}},
            tags => ['category:general-output-control'],
        },

        line_number => {
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
    },
};
sub grep {
    my %args = @_;

    my $opt_ci     = $args{ignore_case};
    my $opt_invert = $args{invert_match};
    my $opt_count  = $args{count};
    my $opt_quiet  = $args{quiet};
    my $opt_linum  = $args{line_number};

    my (@str_patterns, @re_patterns);
    for my $p ( grep {defined} $args{pattern}, @{ $args{regexps} // [] }) {
        push @str_patterns, $p;
        push @re_patterns , $opt_ci ? qr/$p/i : qr/$p/;
    }
    return [400, "Please specify at least one pattern"] unless @re_patterns;
    my $re_pat = join('|', @str_patterns);
    $re_pat = $opt_ci ? qr/$re_pat/i : qr/$re_pat/;

    my $color = $args{color} //
        (defined $ENV{COLOR} ? ($ENV{COLOR} ? 'always' : 'never') : undef) //
        'auto';
    my $use_color;
    if ($color eq 'always') {
        $use_color = 1;
    } elsif ($color eq 'never') {
        $use_color = 0;
    } else {
        $use_color = (-t STDOUT);
    }

    my $source = $args{_source};

    my $logic = 'or';
    $logic = 'and' if $args{all};

    my $num_matches = 0;
    my ($line, $label, $linum);

    my $code_print = sub {
        if (defined $label && length $label) {
            if ($use_color) {
                print "$Colors{label}$label\e[0m$Colors{separator}:\e[0m";
            } else {
                print $label, ":";
            }
        }

        if ($opt_linum) {
            if ($use_color) {
                print "$Colors{linum}$linum\e[0m$Colors{separator}:\e[0m";
            } else {
                print $linum, ":";
            }
        }

        if ($use_color) {
            $line =~ s/($re_pat)/$Colors{match}$1\e[0m/g;
            print $line;
        } else {
            print $line;
        }
    };

    my $prevlabel;
    while (1) {
        ($line, $label) = $source->();
        last unless defined $line;

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
        if ($logic eq 'or') {
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

This document describes version 0.004 of AppBase::Grep (from Perl distribution AppBase-Grep), released on 2018-01-30.

=head1 FUNCTIONS


=head2 grep

Usage:

 grep(%args) -> [status, msg, result, meta]

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
grep-like utilities that greps from a custom sources but have common features
with the standard grep.

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

=item * B<color> => I<str>

=item * B<count> => I<true>

Supress normal output, return a count of matching lines.

=item * B<ignore_case> => I<bool>

=item * B<invert_match> => I<bool>

Invert the sense of matching.

=item * B<line_number> => I<true>

=item * B<pattern> => I<re>

=item * B<quiet> => I<true>

=item * B<regexps> => I<array[re]>

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (result) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)

=head1 ENVIRONMENT

=head2 COLOR

Boolean. If set to true, will set default C<--color> to C<always> instead of
C<auto>. If set to false, will set default C<--color> to C<never> instead of
C<auto>. This behavior is not in GNU grep.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/AppBase-Grep>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-AppBase-Grep>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=AppBase-Grep>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
