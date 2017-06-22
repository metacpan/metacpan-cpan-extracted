package Acme::CPANLists::PERLANCAR::MooseStyleClassBuilder;

our $DATE = '2017-06-19'; # DATE
our $VERSION = '0.22'; # VERSION

our @Module_Lists = (
    {
        summary => 'Moose-style (Perl 6-style) class builders',
        entries => [
            {module => 'Class::Accessor',
             summary => 'Supports basic form of "has"'},
            {module => 'Moo'},
            {module => 'MooX::BuildClass',
             summary => 'Utility to build Moo class at runtime'},
            {module => 'Moos'},
            {module => 'Moose'},
            {module => 'Mouse'},
        ],
    },
);

1;
# ABSTRACT: Moose-style (Perl 6-style) class builders

__END__

=pod

=encoding UTF-8

=head1 NAME

Acme::CPANLists::PERLANCAR::MooseStyleClassBuilder - Moose-style (Perl 6-style) class builders

=head1 VERSION

This document describes version 0.22 of Acme::CPANLists::PERLANCAR::MooseStyleClassBuilder (from Perl distribution Acme-CPANLists-PERLANCAR), released on 2017-06-19.

=head1 MODULE LISTS

=head2 Moose-style (Perl 6-style) class builders

=over

=item * L<Class::Accessor> - Supports basic form of "has"

=item * L<Moo>

=item * L<MooX::BuildClass> - Utility to build Moo class at runtime

=item * L<Moos>

=item * L<Moose>

=item * L<Mouse>

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
