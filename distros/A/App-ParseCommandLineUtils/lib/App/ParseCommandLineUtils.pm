package App::ParseCommandLineUtils;

use strict;
use warnings;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2022-11-04'; # DATE
our $DIST = 'App-ParseCommandLineUtils'; # DIST
our $VERSION = '0.001'; # VERSION

our %SPEC;

my %mods = (
    'Text::ParseWords' => {
        parse => sub {
            require Text::ParseWords; # for scan_prereqs
            my $cmdline = shift;
            [200, "OK", [Text::ParseWords::shellwords($cmdline)]];
        },
    },
    'Complete::Bash' => {
        parse => sub {
            require Complete::Bash; # for scan_prereqs
            my $cmdline = shift;
            [200, "OK", Complete::Bash::parse_command_line($cmdline, 0)];
        },
    },
    'Parse::CommandLine' => {
        parse => sub {
            require Parse::CommandLine; # for scan_prereqs
            my $cmdline = shift;
            [200, "OK", [Parse::CommandLine::parse_command_line($cmdline)]];
        },
    },
    'Parse::CommandLine::Regexp' => {
        parse => sub {
            require Parse::CommandLine::Regexp; # for scan_prereqs
            my $cmdline = shift;
            [200, "OK", [Parse::CommandLine::Regexp::parse_command_line($cmdline)]];
        },
    },
);

$SPEC{parse_command_line} = {
    v => 1.1,
    summary => 'Parse a command-line using one of the Perl command-line parsing modules',
    description => <<'_',

This is mainly for testing.

_
    args => {
        cmdline => {
            schema => 'str*',
            req => 1,
            pos => 0,
            cmdline_src => 'stdin_or_args',
            description => <<'_',

You can also feed command-line from standard input, to avoid having to escape if
specified as shell argument.

_
        },
        module => {
            schema => ['str*', in=>[sort keys %mods]],
            default => 'Text::ParseWords',
        },
    },
    examples => [
    ],
};
sub parse_command_line {

    my %args = @_;

    $mods{ $args{module} }->{parse}->($args{cmdline});
}

1;
# ABSTRACT: CLIs for parsing command-line

__END__

=pod

=encoding UTF-8

=head1 NAME

App::ParseCommandLineUtils - CLIs for parsing command-line

=head1 VERSION

This document describes version 0.001 of App::ParseCommandLineUtils (from Perl distribution App-ParseCommandLineUtils), released on 2022-11-04.

=head1 DESCRIPTION

This distribution includes the following command-line utilities:

=over

=item * L<parse-command-line>

=back

=head1 FUNCTIONS


=head2 parse_command_line

Usage:

 parse_command_line(%args) -> [$status_code, $reason, $payload, \%result_meta]

Parse a command-line using one of the Perl command-line parsing modules.

This is mainly for testing.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<cmdline>* => I<str>

You can also feed command-line from standard input, to avoid having to escape if
specified as shell argument.

=item * B<module> => I<str> (default: "Text::ParseWords")

(No description)


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

Please visit the project's homepage at L<https://metacpan.org/release/App-ParseCommandLineUtils>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-ParseCommandLineUtils>.

=head1 SEE ALSO

L<Bencher::Scenario::CmdLineParsingModules>

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

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-ParseCommandLineUtils>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
