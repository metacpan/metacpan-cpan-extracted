package Acme::CPANModules::PERLANCAR::Weird;

our $DATE = '2018-06-11'; # DATE
our $VERSION = '0.002'; # VERSION

our $LIST = {
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
};

1;
# ABSTRACT: Weird modules

__END__

=pod

=encoding UTF-8

=head1 NAME

Acme::CPANModules::PERLANCAR::Weird - Weird modules

=head1 VERSION

This document describes version 0.002 of Acme::CPANModules::PERLANCAR::Weird (from Perl distribution Acme-CPANModulesBundle-PERLANCAR), released on 2018-06-11.

=head1 DESCRIPTION

Weird modules.

List of modules I find weird (non-pejoratively speaking) in one way or another,
e.g. peculiar API, name.

=head1 INCLUDED MODULES

=over

=item * L<String::Tools>

Function names chosen are too similar with perl's builtins and will be prone to
typos: C<subst> (C<substr>), C<define> (C<defined>). I don't think C<stitch> is more
intuitive to me compared to C<join()>.


=back

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

This software is copyright (c) 2018 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
