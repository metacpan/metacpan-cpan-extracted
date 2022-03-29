package Acme::CPANModules::ShellCompleters;

use strict;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2022-03-18'; # DATE
our $DIST = 'Acme-CPANModules-ShellCompleters'; # DIST
our $VERSION = '0.002'; # VERSION

our $LIST = {
    summary => 'List of modules that provide shell tab completion for other commands/scripts',
    entries => [
        {'x.command' => 'cpanm'     , module=>'App::ShellCompleter::cpanm'},
        {'x.command' => 'emacs'     , module=>'App::ShellCompleter::emacs'},
        {'x.command' => 'meta'      , module=>'App::ShellCompleter::meta', summary=>'meta is the CLI for Acme::MetaSyntactic'},
        {'x.command' => 'mpv'       , module=>'App::ShellCompleter::mpv'},
        {'x.command' => 'pause'     , module=>'App::ShellCompleter::pause', },
        {'x.command' => 'perlbrew'  , module=>'App::ShellCompleter::perlbrew'},
        {'x.command' => 'youtube-dl', module=>'App::ShellCompleter::YoutubeDl'},
    ],
};

1;
# ABSTRACT: List of modules that provide shell tab completion for other commands/scripts

__END__

=pod

=encoding UTF-8

=head1 NAME

Acme::CPANModules::ShellCompleters - List of modules that provide shell tab completion for other commands/scripts

=head1 VERSION

This document describes version 0.002 of Acme::CPANModules::ShellCompleters (from Perl distribution Acme-CPANModules-ShellCompleters), released on 2022-03-18.

=head1 ACME::CPANMODULES ENTRIES

=over

=item * L<App::ShellCompleter::cpanm> - Shell completion for cpanm

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item * L<App::ShellCompleter::emacs> - Shell completion for emacs

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item * L<App::ShellCompleter::meta> - meta is the CLI for Acme::MetaSyntactic

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item * L<App::ShellCompleter::mpv> - Shell completion for mpv

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item * L<App::ShellCompleter::pause> - Improved shell completion for pause

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item * L<App::ShellCompleter::perlbrew> - Shell completion for perlbrew

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item * L<App::ShellCompleter::YoutubeDl> - Shell completion for youtube-dl

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

 % cpanm-cpanmodules -n ShellCompleters

Alternatively you can use the L<cpanmodules> CLI (from L<App::cpanmodules>
distribution):

    % cpanmodules ls-entries ShellCompleters | cpanm -n

or L<Acme::CM::Get>:

    % perl -MAcme::CM::Get=ShellCompleters -E'say $_->{module} for @{ $LIST->{entries} }' | cpanm -n

or directly:

    % perl -MAcme::CPANModules::ShellCompleters -E'say $_->{module} for @{ $Acme::CPANModules::ShellCompleters::LIST->{entries} }' | cpanm -n

This Acme::CPANModules module also helps L<lcpan> produce a more meaningful
result for C<lcpan related-mods> command when it comes to finding related
modules for the modules listed in this Acme::CPANModules module.
See L<App::lcpan::Cmd::related_mods> for more details on how "related modules"
are found.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Acme-CPANModules-ShellCompleters>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Acme-CPANModules-ShellCompleters>.

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
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla plugin and/or Pod::Weaver::Plugin. Any additional steps required
beyond that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022, 2021 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Acme-CPANModules-ShellCompleters>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
