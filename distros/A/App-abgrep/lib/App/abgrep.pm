## no critic: InputOutput::RequireBriefOpen

package App::abgrep;

use 5.010001;
use strict;
use warnings;
use Log::ger;

use AppBase::Grep;
use Perinci::Sub::Util qw(gen_modified_sub);

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-11-14'; # DATE
our $DIST = 'App-abgrep'; # DIST
our $VERSION = '0.008'; # VERSION

our %SPEC;

gen_modified_sub(
    output_name => 'abgrep',
    base_name   => 'AppBase::Grep::grep',
    summary     => 'Print lines matching a pattern',
    description => <<'_',

This is a grep-like utility that is based on <pm:AppBase::Grep>, mainly for
demoing and testing the module. The unique features include multiple patterns
and `--dash-prefix-inverts`.

_
    add_args    => {
        files => {
            'x.name.is_plural' => 1,
            'x.name.singular' => 'file',
            schema => ['array*', of=>'filename*'],
            pos => 1,
            slurpy => 1,
        },
        # XXX recursive (-r)
    },
    modify_meta => sub {
        my $meta = shift;
        $meta->{examples} = [
            {
                summary => 'Show lines that contain foo, bar, AND baz (in no particular order), but do not contain qux NOR quux',
                'src' => q([[prog]] --all --dash-prefix-inverts -e foo -e bar -e baz -e -qux -e -quux),
                'src_plang' => 'bash',
                'test' => 0,
                'x.doc.show_result' => 0,
            },
        ];
        $meta->{links} = [
            {url=>'prog:grep-terms'},
        ];
    },
    output_code => sub {
        my %args = @_;
        my ($fh, $file);

        my @files = @{ $args{files} // [] };
        # pattern (arg0) can actually be a file or regexp
        if (defined $args{pattern}) {
            if ($args{regexps} && @{ $args{regexps} }) {
                unshift @files, delete $args{pattern};
            } else {
                unshift @{ $args{regexps} }, delete $args{pattern};
            }
        }

        my $show_label = 0;
        if (!@files) {
            $file = "(stdin)";
            $fh = \*STDIN;
        } elsif (@files > 1) {
            $show_label = 1;
        }

        $args{_source} = sub {
          READ_LINE:
            {
                if (!defined $fh) {
                    return unless @files;
                    $file = shift @files;
                    log_trace "Opening $file ...";
                    open $fh, "<", $file or do {
                        warn "abgrep: Can't open '$file': $!, skipped\n";
                        undef $fh;
                    };
                    redo READ_LINE;
                }

                my $line = <$fh>;
                if (defined $line) {
                    return ($line, $show_label ? $file : undef);
                } else {
                    undef $fh;
                    redo READ_LINE;
                }
            }
        };

        AppBase::Grep::grep(%args);
    },
);

1;
# ABSTRACT: Print lines matching a pattern

__END__

=pod

=encoding UTF-8

=head1 NAME

App::abgrep - Print lines matching a pattern

=head1 VERSION

This document describes version 0.008 of App::abgrep (from Perl distribution App-abgrep), released on 2021-11-14.

=head1 FUNCTIONS


=head2 abgrep

Usage:

 abgrep(%args) -> [$status_code, $reason, $payload, \%result_meta]

Print lines matching a pattern.

This is a grep-like utility that is based on L<AppBase::Grep>, mainly for
demoing and testing the module. The unique features include multiple patterns
and C<--dash-prefix-inverts>.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<all> => I<true>

Require all patterns to match, instead of just one.

=item * B<color> => I<str> (default: "auto")

=item * B<count> => I<true>

Supress normal output, return a count of matching lines.

=item * B<dash_prefix_inverts> => I<bool>

When given pattern that starts with dash "-FOO", make it to mean "^(?!.*FOO)".

This is a convenient way to search for lines that do not match a pattern.
Instead of using C<-v> to invert the meaning of all patterns, this option allows
you to invert individual pattern using the dash prefix, which is also used by
Google search and a few other search engines.

=item * B<files> => I<array[filename]>

=item * B<ignore_case> => I<bool>

=item * B<invert_match> => I<bool>

Invert the sense of matching.

=item * B<line_number> => I<true>

=item * B<pattern> => I<str>

=item * B<quiet> => I<true>

=item * B<regexps> => I<array[str]>


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

Please visit the project's homepage at L<https://metacpan.org/release/App-abgrep>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-abgrep>.

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

This software is copyright (c) 2021, 2020, 2018 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-abgrep>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
