package Acme::CPANModules::Desktop;

our $DATE = '2018-12-22'; # DATE
our $VERSION = '0.002'; # VERSION

our $LIST = {
    summary => "Modules related to GUI desktop environment",
    entries => [
        {module=>'Desktop::Detect'},
        {module=>'Screensaver::Any'},
        {module=>'App::ScreensaverUtils'},
    ],
};

1;
# ABSTRACT: Modules related to GUI desktop environment

__END__

=pod

=encoding UTF-8

=head1 NAME

Acme::CPANModules::Desktop - Modules related to GUI desktop environment

=head1 VERSION

This document describes version 0.002 of Acme::CPANModules::Desktop (from Perl distribution Acme-CPANModules-Desktop), released on 2018-12-22.

=head1 DESCRIPTION

Modules related to GUI desktop environment.

=head1 INCLUDED MODULES

=over

=item * L<Desktop::Detect>

=item * L<Screensaver::Any>

=item * L<App::ScreensaverUtils>

=back

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Acme-CPANModules-Desktop>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Acme-CPANModules-Desktop>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Acme-CPANModules-Desktop>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Acme::CPANModules> - about the Acme::CPANModules namespace

L<cpanmodules> - CLI tool to let you browse/view the lists

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
