package Acme::CPANLists::PERLANCAR::Test;

our $DATE = '2016-11-17'; # DATE
our $VERSION = '0.04'; # VERSION

our @Module_Lists = (
    {
        id => 'cba525a5-436c-364f-b5d0-6d8bda85b386',
        summary => 'Test list',
        entries => [
            {module=>'Foo::Bar', summary=>'bar', related_modules=>['Foo::Qux']},
            {module=>'Foo::Baz', summary=>'baz', alternate_modules=>['Foo::Quux', 'Foo::Corge']},
        ],
    },
    {
        summary => 'Test list 2',
        entries => [
            {module=>'File::Slurp', rating=>5},
            {module=>'File::Slurp::Tiny', rating=>6},
            {module=>'File::Slurper', rating=>8},
        ],
    },
    {
        summary => 'Test list 3',
        entries => [
            {module=>'File::Slurper', rating=>9},
        ],
    },
);

our @Author_Lists = (
    {
        id => '43151a18-dcf5-873b-ad35-1486c8925cb6',
        summary => 'Test list',
        entries => [
            {author=>'BARBIE'},
            {author=>'NEILB'},
            {author=>'RJBS'},
            {author=>'PERLANCAR', related_authors=>['SHARYANTO']},
        ],
    },
);

1;
# ABSTRACT: A test CPAN lists

__END__

=pod

=encoding UTF-8

=head1 NAME

Acme::CPANLists::PERLANCAR::Test - A test CPAN lists

=head1 VERSION

This document describes version 0.04 of Acme::CPANLists::PERLANCAR::Test (from Perl distribution Acme-CPANLists-PERLANCAR-Test), released on 2016-11-17.

=head1 AUTHOR LISTS

=head2 Test list

=over

=item * L<BARBIE|https://metacpan.org/author/BARBIE>

=item * L<NEILB|https://metacpan.org/author/NEILB>

=item * L<RJBS|https://metacpan.org/author/RJBS>

=item * L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

Related authors: L<SHARYANTO|https://metacpan.org/author/SHARYANTO>

=back

=head1 MODULE LISTS

=head2 Test list

=over

=item * L<Foo::Bar> - bar

Related modules: L<Foo::Qux>

=item * L<Foo::Baz> - baz

Alternate modules: L<Foo::Quux>, L<Foo::Corge>

=back

=head2 Test list 2

=over

=item * L<File::Slurp>

Rating: 5/10

=item * L<File::Slurp::Tiny>

Rating: 6/10

=item * L<File::Slurper>

Rating: 8/10

=back

=head2 Test list 3

=over

=item * L<File::Slurper>

Rating: 9/10

=back

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Acme-CPANLists-PERLANCAR-Test>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Acme-CPANLists-Test>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Acme-CPANLists-PERLANCAR-Test>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Acme::CPANLists> - about the Acme::CPANLists namespace

L<acme-cpanlists> - CLI tool to let you browse/view the lists

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
