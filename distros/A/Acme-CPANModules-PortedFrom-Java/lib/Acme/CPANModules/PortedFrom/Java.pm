package Acme::CPANModules::PortedFrom::Java;

our $DATE = '2020-02-07'; # DATE
our $VERSION = '0.002'; # VERSION

our $LIST = {
    summary => "Modules/applications that are ported from (or inspired by) ".
        "Java",
    description => <<'_',

If you know of others, please drop me a message.

_
    entries => [
        {
            module => 'Log::Log4perl',
            summary => 'Log4j',
        },
        {
            module => 'Test::Unit',
            summary => 'jUnit',
        },
        {
            module => 'Getopt::ApacheCommonsCLI',
            summary => 'Apache Commons CLI',
        },
    ],
};

1;
# ABSTRACT: Modules/applications that are ported from (or inspired by) Java

__END__

=pod

=encoding UTF-8

=head1 NAME

Acme::CPANModules::PortedFrom::Java - Modules/applications that are ported from (or inspired by) Java

=head1 VERSION

This document describes version 0.002 of Acme::CPANModules::PortedFrom::Java (from Perl distribution Acme-CPANModules-PortedFrom-Java), released on 2020-02-07.

=head1 DESCRIPTION

Modules/applications that are ported from (or inspired by) Java.

If you know of others, please drop me a message.

=head1 INCLUDED MODULES

=over

=item * L<Log::Log4perl> - Log4j

=item * L<Test::Unit> - jUnit

=item * L<Getopt::ApacheCommonsCLI> - Apache Commons CLI

=back

=head1 FAQ

=head2 What are ways to use this module?

Aside from reading it, you can install all the listed modules using
L<cpanmodules>:

    % cpanmodules ls-entries PortedFrom::Java | cpanm -n

or L<Acme::CM::Get>:

    % perl -MAcme::CM::Get=PortedFrom::Java -E'say $_->{module} for @{ $LIST->{entries} }' | cpanm -n

This module also helps L<lcpan> produce a more meaningful result for C<lcpan
related-mods> when it comes to finding related modules for the modules listed
in this Acme::CPANModules module.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Acme-CPANModules-PortedFrom-Java>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Acme-CPANModules-PortedFrom-Java>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Acme-CPANModules-PortedFrom-Java>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Acme::CPANModules> - about the Acme::CPANModules namespace

L<cpanmodules> - CLI tool to let you browse/view the lists

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020, 2019 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
