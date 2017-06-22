package Acme::CPANLists::PERLANCAR::OneLetter;

our $DATE = '2017-06-19'; # DATE
our $VERSION = '0.22'; # VERSION

our @Module_Lists = (
    {
        summary => 'One-letter CPAN modules',
        description => <<'_',

Just a list of one-letter modules on CPAN.

_
        entries => [
            {module=>'B'},
            {module=>'K'},
            {module=>'L'},
            {module=>'M'},
            {module=>'O'},
            {module=>'P'},
            {module=>'U'},
            {module=>'V'},
            {module=>'c'},
        ],
    },
);

1;
# ABSTRACT: One-letter CPAN modules

__END__

=pod

=encoding UTF-8

=head1 NAME

Acme::CPANLists::PERLANCAR::OneLetter - One-letter CPAN modules

=head1 VERSION

This document describes version 0.22 of Acme::CPANLists::PERLANCAR::OneLetter (from Perl distribution Acme-CPANLists-PERLANCAR), released on 2017-06-19.

=head1 MODULE LISTS

=head2 One-letter CPAN modules

Just a list of one-letter modules on CPAN.


=over

=item * L<B>

=item * L<K>

=item * L<L>

=item * L<M>

=item * L<O>

=item * L<P>

=item * L<U>

=item * L<V>

=item * L<c>

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
