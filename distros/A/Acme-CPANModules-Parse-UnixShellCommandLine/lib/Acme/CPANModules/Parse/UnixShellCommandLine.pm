package Acme::CPANModules::Parse::UnixShellCommandLine;

use strict;
use warnings;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-10-31'; # DATE
our $DIST = 'Acme-CPANModules-Parse-UnixShellCommandLine'; # DIST
our $VERSION = '0.003'; # VERSION

our $LIST = {
    summary => "List of modules that parse command-line like Unix shells",
    description => <<'_',

Sometimes you need to parse a Unix shell command-line string, e.g. when you want
to break it into "words".

In general I recommend <pm:Text::ParseWords> as it is a core module. If you want
a little more speed, try <pm:Parse::CommandLine::Regexp> (see reference to
benchmark in See Also).

_
    entries => [
        {
            module=>'Complete::Bash',
            description => <<'_',

Its `parse_cmdline()` function can break a command-line string into words. This
function is geared for tab completion, so by default it also breaks on some
other word-breaking characters like "=", "@", and so on. Probably not what you
want generally, unless you are working with tab completion.

_
        },
        {
            module=>'Complete::Zsh',
        },
        {
            module=>'Complete::Fish',
        },
        {
            module=>'Complete::Tcsh',
        },
        {
            module=>'Text::ParseWords',
            description => <<'_',

This core module can split string into words with customizable quoting character
and support for escaping using backslash. Its `shellwords()` function is
suitable for breaking command-line string into words.

_
        },
        {
            module=>'Parse::CommandLine',
        },
        {
            module=>'Parse::CommandLine::Regexp',
        },
    ],
};

1;
# ABSTRACT: List of modules that parse command-line like Unix shells

__END__

=pod

=encoding UTF-8

=head1 NAME

Acme::CPANModules::Parse::UnixShellCommandLine - List of modules that parse command-line like Unix shells

=head1 VERSION

This document describes version 0.003 of Acme::CPANModules::Parse::UnixShellCommandLine (from Perl distribution Acme-CPANModules-Parse-UnixShellCommandLine), released on 2023-10-31.

=head1 DESCRIPTION

Sometimes you need to parse a Unix shell command-line string, e.g. when you want
to break it into "words".

In general I recommend L<Text::ParseWords> as it is a core module. If you want
a little more speed, try L<Parse::CommandLine::Regexp> (see reference to
benchmark in See Also).

=head1 ACME::CPANMODULES ENTRIES

=over

=item L<Complete::Bash>

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

Its C<parse_cmdline()> function can break a command-line string into words. This
function is geared for tab completion, so by default it also breaks on some
other word-breaking characters like "=", "@", and so on. Probably not what you
want generally, unless you are working with tab completion.


=item L<Complete::Zsh>

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item L<Complete::Fish>

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item L<Complete::Tcsh>

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item L<Text::ParseWords>

Author: L<NEILB|https://metacpan.org/author/NEILB>

This core module can split string into words with customizable quoting character
and support for escaping using backslash. Its C<shellwords()> function is
suitable for breaking command-line string into words.


=item L<Parse::CommandLine>

Author: L<SONGMU|https://metacpan.org/author/SONGMU>

=item L<Parse::CommandLine::Regexp>

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=back

=head1 FAQ

=head2 What is an Acme::CPANModules::* module?

An Acme::CPANModules::* module, like this module, contains just a list of module
names that share a common characteristics. It is a way to categorize modules and
document CPAN. See L<Acme::CPANModules> for more details.

=head2 What are ways to use this Acme::CPANModules module?

Aside from reading this Acme::CPANModules module's POD documentation, you can
install all the listed modules (entries) using L<cpanm-cpanmodules> script (from
L<App::cpanm::cpanmodules> distribution):

 % cpanm-cpanmodules -n Parse::UnixShellCommandLine

Alternatively you can use the L<cpanmodules> CLI (from L<App::cpanmodules>
distribution):

    % cpanmodules ls-entries Parse::UnixShellCommandLine | cpanm -n

or L<Acme::CM::Get>:

    % perl -MAcme::CM::Get=Parse::UnixShellCommandLine -E'say $_->{module} for @{ $LIST->{entries} }' | cpanm -n

or directly:

    % perl -MAcme::CPANModules::Parse::UnixShellCommandLine -E'say $_->{module} for @{ $Acme::CPANModules::Parse::UnixShellCommandLine::LIST->{entries} }' | cpanm -n

This Acme::CPANModules module also helps L<lcpan> produce a more meaningful
result for C<lcpan related-mods> command when it comes to finding related
modules for the modules listed in this Acme::CPANModules module.
See L<App::lcpan::Cmd::related_mods> for more details on how "related modules"
are found.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Acme-CPANModules-Parse-UnixShellCommandLine>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Acme-CPANModules-Parse-UnixShellCommandLine>.

=head1 SEE ALSO

L<Acme::CPANModules> - about the Acme::CPANModules namespace

L<cpanmodules> - CLI tool to let you browse/view the lists

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

This software is copyright (c) 2023, 2021 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Acme-CPANModules-Parse-UnixShellCommandLine>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
