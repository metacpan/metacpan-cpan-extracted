package Acme::CPANLists::PERLANCAR::MyGetoptLongExperiment;

our $DATE = '2017-06-19'; # DATE
our $VERSION = '0.22'; # VERSION

our @Module_Lists = (
    {
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
    },
);

1;
# ABSTRACT: My experiments writing Getopt::Long replacements/alternatives

__END__

=pod

=encoding UTF-8

=head1 NAME

Acme::CPANLists::PERLANCAR::MyGetoptLongExperiment - My experiments writing Getopt::Long replacements/alternatives

=head1 VERSION

This document describes version 0.22 of Acme::CPANLists::PERLANCAR::MyGetoptLongExperiment (from Perl distribution Acme-CPANLists-PERLANCAR), released on 2017-06-19.

=head1 MODULE LISTS

=head2 My experiments writing Getopt::Long replacements/alternatives

Most of these modules provide a L<Getopt::Long>-compatible interface, but they
differ in some aspect: either they offer more features (or less).


=over

=item * L<Getopt::Long::Less>

=item * L<Getopt::Long::EvenLess>

=item * L<Getopt::Long::More>

=item * L<Getopt::Long::Complete>

=item * L<Getopt::Long::Subcommand>

=item * L<Getopt::Panjang>

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
