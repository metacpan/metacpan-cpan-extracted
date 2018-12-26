package Acme::CPANModules::ColorEnv;

our $DATE = '2018-12-22'; # DATE
our $VERSION = '0.001'; # VERSION

our $LIST = {
    summary => "Modules that observe environment variable (other than ".
        "NO_COLOR/COLOR) to disable/enable colored output",
    description => <<'_',

This is a list of modules that observe some environment variable to
disable/enable colored output, but does not follow either the NO_COLOR
convention or the COLOR convention.

If you know of other modules that should be listed here, please contact me.

_
    entries => [
        {module=>'Term::ANSIColor', env=>'ANSI_COLORS_DISABLED'},
    ],
    links => [
        {url=>'pm:Acme::CPANModules::NO_COLOR'},
        {url=>'pm:Acme::CPANModules::COLOR'},
    ],
};

1;
# ABSTRACT: Modules that observe environment variable (other than NO_COLOR/COLOR) to disable/enable colored output

__END__

=pod

=encoding UTF-8

=head1 NAME

Acme::CPANModules::ColorEnv - Modules that observe environment variable (other than NO_COLOR/COLOR) to disable/enable colored output

=head1 VERSION

This document describes version 0.001 of Acme::CPANModules::ColorEnv (from Perl distribution Acme-CPANModules-ColorEnv), released on 2018-12-22.

=head1 DESCRIPTION

Modules that observe environment variable (other than NO_COLOR/COLOR) to disable/enable colored output.

This is a list of modules that observe some environment variable to
disable/enable colored output, but does not follow either the NO_COLOR
convention or the COLOR convention.

If you know of other modules that should be listed here, please contact me.

=head1 INCLUDED MODULES

=over

=item * L<Term::ANSIColor>

=back

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Acme-CPANModules-ColorEnv>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Acme-CPANModules-ColorEnv>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Acme-CPANModules-ColorEnv>

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
