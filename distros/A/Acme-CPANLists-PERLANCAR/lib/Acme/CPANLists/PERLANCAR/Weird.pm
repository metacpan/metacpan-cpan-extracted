package Acme::CPANLists::PERLANCAR::Weird;

our $DATE = '2017-06-19'; # DATE
our $VERSION = '0.22'; # VERSION

our @Module_Lists = (
    {
        summary => 'Weird modules',
        description => <<'_',

List of modules I find weird (non-pejoratively speaking) in one way or another,
e.g. peculiar API, name.

_
        entries => [
            {
                module => 'String::Tools',
                description => <<'_',

Function names chosen are too similar with perl's builtins and will be prone to
typos: `subst` (`substr`), `define` (`defined`). I don't think `stitch` is more
intuitive to me compared to `join()`.

_
            },
        ],
    },
);

1;
# ABSTRACT: Weird modules

__END__

=pod

=encoding UTF-8

=head1 NAME

Acme::CPANLists::PERLANCAR::Weird - Weird modules

=head1 VERSION

This document describes version 0.22 of Acme::CPANLists::PERLANCAR::Weird (from Perl distribution Acme-CPANLists-PERLANCAR), released on 2017-06-19.

=head1 MODULE LISTS

=head2 Weird modules

List of modules I find weird (non-pejoratively speaking) in one way or another,
e.g. peculiar API, name.


=over

=item * L<String::Tools>

Function names chosen are too similar with perl's builtins and will be prone to
typos: C<subst> (C<substr>), C<define> (C<defined>). I don't think C<stitch> is more
intuitive to me compared to C<join()>.


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
