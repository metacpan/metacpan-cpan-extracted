package Acme::CPANModules::ShellCompleters;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-05-22'; # DATE
our $DIST = 'Acme-CPANModules-ShellCompleters'; # DIST
our $VERSION = '0.001'; # VERSION

use strict;
use warnings;

our $LIST = {
    summary => 'Modules that provide shell tab completion for other commands/scripts',
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
# ABSTRACT: Modules that provide shell tab completion for other commands/scripts

__END__

=pod

=encoding UTF-8

=head1 NAME

Acme::CPANModules::ShellCompleters - Modules that provide shell tab completion for other commands/scripts

=head1 VERSION

This document describes version 0.001 of Acme::CPANModules::ShellCompleters (from Perl distribution Acme-CPANModules-ShellCompleters), released on 2021-05-22.

=head1 ACME::CPANMODULES ENTRIES

=over

=item * L<App::ShellCompleter::cpanm>

=item * L<App::ShellCompleter::emacs>

=item * L<App::ShellCompleter::meta> - meta is the CLI for Acme::MetaSyntactic

=item * L<App::ShellCompleter::mpv>

=item * L<App::ShellCompleter::pause>

=item * L<App::ShellCompleter::perlbrew>

=item * L<App::ShellCompleter::YoutubeDl>

=back

=head1 FAQ

=head2 What is an Acme::CPANModules::* module?

An Acme::CPANModules::* module, like this module, contains just a list of module
names that share a common characteristics. It is a way to categorize modules and
document CPAN. See L<Acme::CPANModules> for more details.

=head2 What are ways to use this Acme::CPANModules module?

Aside from reading this Acme::CPANModules module's POD documentation, you can
install all the listed modules (entries) using L<cpanmodules> CLI (from
L<App::cpanmodules> distribution):

    % cpanmodules ls-entries ShellCompleters | cpanm -n

or L<Acme::CM::Get>:

    % perl -MAcme::CM::Get=ShellCompleters -E'say $_->{module} for @{ $LIST->{entries} }' | cpanm -n

or directly:

    % perl -MAcme::CPANModules::ShellCompleters -E'say $_->{module} for @{ $Acme::CPANModules::ShellCompleters::LIST->{entries} }' | cpanm -n

This Acme::CPANModules module also helps L<lcpan> produce a more meaningful
result for C<lcpan related-mods> command when it comes to finding related
modules for the modules listed in this Acme::CPANModules module.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Acme-CPANModules-ShellCompleters>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Acme-CPANModules-ShellCompleters>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://github.com/perlancar/perl-Acme-CPANModules-ShellCompleters/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Acme::CPANModules> - about the Acme::CPANModules namespace

L<cpanmodules> - CLI tool to let you browse/view the lists

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
