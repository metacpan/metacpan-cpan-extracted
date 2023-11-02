package Acme::CPANModules::COLOR;

use strict;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-08-06'; # DATE
our $DIST = 'Acme-CPANModules-COLOR'; # DIST
our $VERSION = '0.005'; # VERSION

our $LIST = {
    summary => "List of modules that follow the COLOR & NO_COLOR convention",
    description => <<'_',

The NO_COLOR convention (see https://no-color.org) lets user disable color
output of console programs by defining an environment variable called NO_COLOR.
The existence of said environment variable, regardless of its value (including
empty string, undef, or 0), signals that programs should not use colored output.

Another similar convention is the use of the COLOR environment variable. False
value (empty string or the value 0) means that programs should disable colored
output, while true value (values other than the mentioned false values) means
that programs should enable colored output. This convention allows
force-enabling colored output instead of just force-disabling it, although
programs supporting it need to add a line of code or two to check the value of
the environment variable.

If you know of other modules that should be listed here, please contact me.

_
    entries => [
        {module=>'AppBase::Grep'},
        {module=>'App::abgrep', script=>'abgrep'},
        {module=>'App::diffdb'},
        {module=>'App::DiffTarballs'},
        {module=>'App::diffwc'},
        {module=>'App::hr'},
        {module=>'App::riap'},
        {module=>'App::wordlist'},
        {module=>'Color::ANSI::Util'},
        {module=>'Data::Dump::Color'},
        {module=>'Data::Format::Pretty::JSON'},
        {module=>'Data::Format::Pretty::Perl'},
        {module=>'Data::Format::Pretty::YAML'},
        {module=>'Debug::Print'},
        {module=>'Log::Any::Adapter::Screen'},
        {module=>'Log::ger::Output::Screen'},
        {module=>'Perinci::CmdLine::Classic'},
        {module=>'Perinci::CmdLine::Lite'},
        {module=>'Perinci::Result::Format'},
        {module=>'Perinci::Result::Format::Lite'},
        {module=>'Progress::Any::Output::TermProgressBar'},
        {module=>'Term::ANSIColor::Conditional'},
        {module=>'Term::ANSIColor::Patch::Conditional'},
        {module=>'Term::App::Roles'},
        {module=>'Text::ANSITable'},
        {module=>'Text::DiffU'},
    ],
    links => [
        {url=>'pm:Acme::CPANModules::NO_COLOR'},
        {url=>'pm:Acme::CPANModules::ColorEnv'},
    ],
};

1;
# ABSTRACT: List of modules that follow the COLOR & NO_COLOR convention

__END__

=pod

=encoding UTF-8

=head1 NAME

Acme::CPANModules::COLOR - List of modules that follow the COLOR & NO_COLOR convention

=head1 VERSION

This document describes version 0.005 of Acme::CPANModules::COLOR (from Perl distribution Acme-CPANModules-COLOR), released on 2023-08-06.

=head1 DESCRIPTION

The NO_COLOR convention (see https://no-color.org) lets user disable color
output of console programs by defining an environment variable called NO_COLOR.
The existence of said environment variable, regardless of its value (including
empty string, undef, or 0), signals that programs should not use colored output.

Another similar convention is the use of the COLOR environment variable. False
value (empty string or the value 0) means that programs should disable colored
output, while true value (values other than the mentioned false values) means
that programs should enable colored output. This convention allows
force-enabling colored output instead of just force-disabling it, although
programs supporting it need to add a line of code or two to check the value of
the environment variable.

If you know of other modules that should be listed here, please contact me.

=head1 ACME::CPANMODULES ENTRIES

=over

=item L<AppBase::Grep>

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item L<App::abgrep>

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

Script: L<abgrep>

=item L<App::diffdb>

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item L<App::DiffTarballs>

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item L<App::diffwc>

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item L<App::hr>

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item L<App::riap>

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item L<App::wordlist>

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item L<Color::ANSI::Util>

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item L<Data::Dump::Color>

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item L<Data::Format::Pretty::JSON>

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item L<Data::Format::Pretty::Perl>

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item L<Data::Format::Pretty::YAML>

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item L<Debug::Print>

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item L<Log::Any::Adapter::Screen>

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item L<Log::ger::Output::Screen>

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item L<Perinci::CmdLine::Classic>

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item L<Perinci::CmdLine::Lite>

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item L<Perinci::Result::Format>

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item L<Perinci::Result::Format::Lite>

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item L<Progress::Any::Output::TermProgressBar>

=item L<Term::ANSIColor::Conditional>

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item L<Term::ANSIColor::Patch::Conditional>

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item L<Term::App::Roles>

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item L<Text::ANSITable>

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item L<Text::DiffU>

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

 % cpanm-cpanmodules -n COLOR

Alternatively you can use the L<cpanmodules> CLI (from L<App::cpanmodules>
distribution):

    % cpanmodules ls-entries COLOR | cpanm -n

or L<Acme::CM::Get>:

    % perl -MAcme::CM::Get=COLOR -E'say $_->{module} for @{ $LIST->{entries} }' | cpanm -n

or directly:

    % perl -MAcme::CPANModules::COLOR -E'say $_->{module} for @{ $Acme::CPANModules::COLOR::LIST->{entries} }' | cpanm -n

This Acme::CPANModules module also helps L<lcpan> produce a more meaningful
result for C<lcpan related-mods> command when it comes to finding related
modules for the modules listed in this Acme::CPANModules module.
See L<App::lcpan::Cmd::related_mods> for more details on how "related modules"
are found.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Acme-CPANModules-COLOR>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Acme-CPANModules-COLOR>.

=head1 SEE ALSO

L<Acme::CPANModules> - about the Acme::CPANModules namespace

L<cpanmodules> - CLI tool to let you browse/view the lists

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

This software is copyright (c) 2023, 2021, 2020, 2018 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Acme-CPANModules-COLOR>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
