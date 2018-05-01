package Acme::CPANModules::PortedFrom::NPM;

our $DATE = '2018-04-29'; # DATE
our $VERSION = '0.001'; # VERSION

our $LIST = {
    summary => "Modules/applications that are ported (or inspired from) NPM libraries",
    description => <<'_',

If you know of others, please drop me a message.

_
    entries => [
        {
            module => 'App::chalk',
            npm_module => 'chalk',
            tags => ['cli', 'color'],
        },
        {
            module => 'Inky',
            npm_module => 'inky',
            tags => ['html', 'template'],
        },
        {
            module => 'Smart::Options',
            npm_module => 'optimist',
            tags => ['html', 'template'],
        },
    ],
};

1;
# ABSTRACT: Modules/applications that are ported (or inspired from) NPM libraries

__END__

=pod

=encoding UTF-8

=head1 NAME

Acme::CPANModules::PortedFrom::NPM - Modules/applications that are ported (or inspired from) NPM libraries

=head1 VERSION

This document describes version 0.001 of Acme::CPANModules::PortedFrom::NPM (from Perl distribution Acme-CPANModules-PortedFrom-NPM), released on 2018-04-29.

=head1 DESCRIPTION

Modules/applications that are ported (or inspired from) NPM libraries.

If you know of others, please drop me a message.

=head1 INCLUDED MODULES

=over

=item * L<App::chalk>

=item * L<Inky>

=item * L<Smart::Options>

=back

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Acme-CPANModules-PortedFrom-NPM>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Acme-CPANModules-PortedFrom-NPM>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Acme-CPANModules-PortedFrom-NPM>

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
