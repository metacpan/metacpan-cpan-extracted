package Acme::CPANModules::PortedFrom::Python;

our $DATE = '2020-02-07'; # DATE
our $VERSION = '0.002'; # VERSION

our $LIST = {
    summary => "Modules/applications that are ported from (or inspired by) ".
        "Python libraries",
    description => <<'_',

If you know of others, please drop me a message.

_
    entries => [
        {
            module => 'Docopt',
            python_package => 'docopt',
            tags => ['cli'],
        },
        {
            module => 'Getopt::ArgParse',
            python_package => 'argparse',
            tags => ['cli'],
        },
    ],
};

1;
# ABSTRACT: Modules/applications that are ported from (or inspired by) Python libraries

__END__

=pod

=encoding UTF-8

=head1 NAME

Acme::CPANModules::PortedFrom::Python - Modules/applications that are ported from (or inspired by) Python libraries

=head1 VERSION

This document describes version 0.002 of Acme::CPANModules::PortedFrom::Python (from Perl distribution Acme-CPANModules-PortedFrom-Python), released on 2020-02-07.

=head1 DESCRIPTION

Modules/applications that are ported from (or inspired by) Python libraries.

If you know of others, please drop me a message.

=head1 INCLUDED MODULES

=over

=item * L<Docopt>

=item * L<Getopt::ArgParse>

=back

=head1 FAQ

=head2 What are ways to use this module?

Aside from reading it, you can install all the listed modules using
L<cpanmodules>:

    % cpanmodules ls-entries PortedFrom::Python | cpanm -n

or L<Acme::CM::Get>:

    % perl -MAcme::CM::Get=PortedFrom::Python -E'say $_->{module} for @{ $LIST->{entries} }' | cpanm -n

This module also helps L<lcpan> produce a more meaningful result for C<lcpan
related-mods> when it comes to finding related modules for the modules listed
in this Acme::CPANModules module.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Acme-CPANModules-PortedFrom-Python>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Acme-CPANModules-PortedFrom-Python>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Acme-CPANModules-PortedFrom-Python>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Acme::CPANModules> - about the Acme::CPANModules namespace

L<cpanmodules> - CLI tool to let you browse/view the lists

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020, 2018 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
