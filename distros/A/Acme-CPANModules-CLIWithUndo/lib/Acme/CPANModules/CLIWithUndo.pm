package Acme::CPANModules::CLIWithUndo;

our $DATE = '2019-01-09'; # DATE
our $VERSION = '0.001'; # VERSION

our $LIST = {
    summary => 'CLI utilities with undo feature',
    entries => [
        {
            module => 'App::trash::u', scripts => ['trash-u'],
        },
        {
            module => 'App::perlmv::u', scripts => ['perlmv-u'],
        },
    ],
};

1;
# ABSTRACT: CLI utilities with undo feature

__END__

=pod

=encoding UTF-8

=head1 NAME

Acme::CPANModules::CLIWithUndo - CLI utilities with undo feature

=head1 VERSION

This document describes version 0.001 of Acme::CPANModules::CLIWithUndo (from Perl distribution Acme-CPANModules-CLIWithUndo), released on 2019-01-09.

=head1 DESCRIPTION

CLI utilities with undo feature.

=head1 INCLUDED MODULES

=over

=item * L<App::trash::u>

=item * L<App::perlmv::u>

=back

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Acme-CPANModules-CLIWithUndo>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Acme-CPANModules-CLIWithUndo>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Acme-CPANModules-CLIWithUndo>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Acme::CPANModules> - about the Acme::CPANModules namespace

L<cpanmodules> - CLI tool to let you browse/view the lists

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
