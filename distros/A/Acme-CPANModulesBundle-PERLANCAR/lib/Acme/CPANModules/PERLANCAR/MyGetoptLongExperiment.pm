package Acme::CPANModules::PERLANCAR::MyGetoptLongExperiment;

our $DATE = '2020-07-21'; # DATE
our $VERSION = '0.006'; # VERSION

our $LIST = {
    summary => 'My experiments writing Getopt::Long replacements/alternatives',
    description => <<'_',

Most of these modules provide a <pm:Getopt::Long>-compatible interface, but they
differ in some aspect: either they offer more features (or less).

_
    entries => [
        {module => 'Getopt::Long::Less'},
        {module => 'Getopt::Long::EvenLess'},
        {module => 'Getopt::Long::More'},
        {module => 'Getopt::Long::Complete'},

        {module => 'Getopt::Long::Subcommand'},

        {module => 'Getopt::Panjang'},
    ],
};

1;
# ABSTRACT: My experiments writing Getopt::Long replacements/alternatives

__END__

=pod

=encoding UTF-8

=head1 NAME

Acme::CPANModules::PERLANCAR::MyGetoptLongExperiment - My experiments writing Getopt::Long replacements/alternatives

=head1 VERSION

This document describes version 0.006 of Acme::CPANModules::PERLANCAR::MyGetoptLongExperiment (from Perl distribution Acme-CPANModulesBundle-PERLANCAR), released on 2020-07-21.

=head1 DESCRIPTION

Most of these modules provide a L<Getopt::Long>-compatible interface, but they
differ in some aspect: either they offer more features (or less).

=head1 INCLUDED MODULES

=over

=item * L<Getopt::Long::Less>

=item * L<Getopt::Long::EvenLess>

=item * L<Getopt::Long::More>

=item * L<Getopt::Long::Complete>

=item * L<Getopt::Long::Subcommand>

=item * L<Getopt::Panjang>

=back

=head1 FAQ

=head2 What are ways to use this module?

Aside from reading it, you can install all the listed modules using
L<cpanmodules>:

    % cpanmodules ls-entries PERLANCAR::MyGetoptLongExperiment | cpanm -n

or L<Acme::CM::Get>:

    % perl -MAcme::CM::Get=PERLANCAR::MyGetoptLongExperiment -E'say $_->{module} for @{ $LIST->{entries} }' | cpanm -n

This module also helps L<lcpan> produce a more meaningful result for C<lcpan
related-mods> when it comes to finding related modules for the modules listed
in this Acme::CPANModules module.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Acme-CPANModulesBundle-PERLANCAR>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Acme-CPANModulesBundle-PERLANCAR>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Acme-CPANModulesBundle-PERLANCAR>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Acme::CPANModules> - about the Acme::CPANModules namespace

L<cpanmodules> - CLI tool to let you browse/view the lists

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020, 2019, 2018 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
