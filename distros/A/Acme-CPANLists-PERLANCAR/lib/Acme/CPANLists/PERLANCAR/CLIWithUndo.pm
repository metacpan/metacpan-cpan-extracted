package Acme::CPANLists::PERLANCAR::CLIWithUndo;

our $DATE = '2017-07-28'; # DATE
our $VERSION = '0.25'; # VERSION

our @Module_Lists = (
    {
        summary => 'CLI utilities with undo feature',
        entries => [
            {
                module => 'App::trash::u', scripts => ['trash-u'],
            },
            {
                module => 'App::perlmv::u', scripts => ['perlmv-u'],
            },
        ],
    },
);

1;
# ABSTRACT: CLI utilities with undo feature

__END__

=pod

=encoding UTF-8

=head1 NAME

Acme::CPANLists::PERLANCAR::CLIWithUndo - CLI utilities with undo feature

=head1 VERSION

This document describes version 0.25 of Acme::CPANLists::PERLANCAR::CLIWithUndo (from Perl distribution Acme-CPANLists-PERLANCAR), released on 2017-07-28.

=head1 MODULE LISTS

=head2 CLI utilities with undo feature

=over

=item * L<App::trash::u>

=item * L<App::perlmv::u>

=back

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Acme-CPANLists-PERLANCAR>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Acme-CPANLists-PERLANCAR>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Acme-CPANLists-PERLANCAR>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Acme::CPANLists> - about the Acme::CPANLists namespace

L<acme-cpanlists> - CLI tool to let you browse/view the lists

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017, 2016, 2015 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
