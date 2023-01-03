## no critic: InputOutput::RequireBriefOpen

package App::pmgrep;

use 5.010001;
use strict;
use warnings;
use Log::ger;

use AppBase::Grep;
use Perinci::Sub::Util qw(gen_modified_sub);

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2022-09-28'; # DATE
our $DIST = 'App-PMUtils'; # DIST
our $VERSION = '0.742'; # VERSION

our %SPEC;

gen_modified_sub(
    output_name => 'pmgrep',
    base_name   => 'AppBase::Grep::grep',
    summary     => 'Print lines from installed Perl module sources matching a pattern',
    description => <<'_',

This is a like the Unix command **grep** but instead of specifying filenames,
you specify module names or prefixes. The utility will search module source
files from Perl's `@INC`.

Examples:

    # Find pre-increment in all Perl module files
    % pmgrep '\+\+\$'

    # Find some pattern in all Data::Sah::Coerce::* modules (note ** wildcard for recursing)
    % pmgrep 'return ' Data::Sah::Coerce::**

_
    add_args    => {
        modules => {
            'x.name.is_plural' => 1,
            'x.name.singular' => 'module',
            schema => 'perl::modnames*',
            pos => 1,
            greedy => 1,
            description => <<'_',

If not specified, all installed Perl modules will be searched.

_
        },
        pm  => {
            schema => 'bool*',
            default => 1,
            summary => 'Whether to include .pm files',
            'summary.alt.bool.neg' => 'Do not include .pm files',
        },
        pod => {
            schema => 'bool*',
            summary => 'Whether to include .pod files',
        },
        pmc => {
            schema => 'bool*',
            summary => 'Whether to include .pmc files',
        },
        recursive => {
            schema => 'true*',
            cmdline_aliases => {r=>{}},
        },
    },
    output_code => sub {
        require Module::List::More;
        require Module::Path::More;

        my %args = @_;
        $args{pm} //= 1;

        my %files;
        for my $q (@{ $args{modules} // [""] }) {
            if ($q eq '' || $q =~ /::\z/ || $args{recursive}) {
                my $mods = Module::List::More::list_modules(
                    $q eq '' || $q =~ /::\z/ ? $q : "$q\::",
                    {
                        list_modules => $args{pm} || $args{pmc},
                        list_pod     => $args{pod},
                        recurse      => $args{recursive},
                        return_path  => 1,
                    },
                );
                $files{ $mods->{$_} }++ for keys %$mods;
            }
            if ($q =~ /\A\w+(\::\w+)*\z/) {
                my $path = Module::Path::More::module_path(
                    module   => $q,
                    find_pm  => $args{pm},
                    find_pmc => $args{pmc},
                    find_pod => $args{pod},
                );
                $files{$path}++ if $path;
            }
        }
        my @files = sort keys %files;
        die "No module source files found!\n" unless @files;

        my ($fh, $file);
        $args{_source} = sub {
          READ_LINE:
            {
                if (!defined $fh) {
                    return unless @files;
                    $file = shift @files;
                    log_trace "Opening $file ...";
                    open $fh, "<", $file or do {
                        warn "pmgrep: Can't open '$file': $!, skipped\n";
                        undef $fh;
                    };
                    redo READ_LINE;
                }

                my $line = <$fh>;
                if (defined $line) {
                    return ($line, $file);
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
# ABSTRACT: Print lines from installed Perl module sources matching a pattern

__END__

=pod

=encoding UTF-8

=head1 NAME

App::pmgrep - Print lines from installed Perl module sources matching a pattern

=head1 VERSION

This document describes version 0.742 of App::pmgrep (from Perl distribution App-PMUtils), released on 2022-09-28.

=head1 FUNCTIONS


=head2 pmgrep

Usage:

 pmgrep(%args) -> [$status_code, $reason, $payload, \%result_meta]

Print lines from installed Perl module sources matching a pattern.

This is a like the Unix command B<grep> but instead of specifying filenames,
you specify module names or prefixes. The utility will search module source
files from Perl's C<@INC>.

Examples:

 # Find pre-increment in all Perl module files
 % pmgrep '\+\+\$'
 
 # Find some pattern in all Data::Sah::Coerce::* modules (note ** wildcard for recursing)
 % pmgrep 'return ' Data::Sah::Coerce::**

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

=item * B<ignore_case> => I<bool>

=item * B<invert_match> => I<bool>

Invert the sense of matching.

=item * B<line_number> => I<true>

=item * B<modules> => I<perl::modnames>

If not specified, all installed Perl modules will be searched.

=item * B<pattern> => I<str>

=item * B<pm> => I<bool> (default: 1)

Whether to include .pm files.

=item * B<pmc> => I<bool>

Whether to include .pmc files.

=item * B<pod> => I<bool>

Whether to include .pod files.

=item * B<quiet> => I<true>

=item * B<recursive> => I<true>

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

Please visit the project's homepage at L<https://metacpan.org/release/App-PMUtils>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-PMUtils>.

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

This software is copyright (c) 2022, 2021, 2020, 2019, 2018, 2017, 2016, 2015, 2014 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-PMUtils>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
